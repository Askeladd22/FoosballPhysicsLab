-- Match Lab v0.2.1 - headless, deterministic simulation.
-- A physical ball, no possession magnetism, one permanent human-controlled disc.
local AI = require("src.ai")
local Passing = require("src.passing")
local Offside = require("src.offside")
local Corners = require("src.corners")
local Control = require("src.ball_control")
local Combinations = require("src.combinations")
local Settings = require("src.tactical_settings")
local Coach = require("src.coach")
local Sim = {}
local awardOffside
local sqrt, exp, min, max, abs = math.sqrt, math.exp, math.min, math.max, math.abs
local function clamp(x,a,b) return max(a,min(b,x)) end
local function distance(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return sqrt(dx*dx+dy*dy)
end
local roles={
    {"GK",1,6,35}, {"DF",4,24,35},
    {"LM",8,40,19}, {"RM",10,40,51}, {"ST",9,53,35}
}
local fullRoles={
    {"GK",1,6,35}, {"DF",4,24,24},
    {"LM",8,41,12}, {"RM",10,41,58}, {"ST",9,53,27},
    {"DF",5,24,46}, {"FB",3,27,8}, {"FB",2,27,62},
    {"CM",6,39,26}, {"CM",7,39,44}, {"ST",11,53,43}
}
local function takerForTeam(s,team,ball,side)
    local best,cost=nil,math.huge
    for _,p in ipairs(s.players) do
        if p.team==team and p~=s.controlled then
            local d=distance(p,ball)
            local penalty=(p.role=="GK" and side~="left" and side~="right") and 25 or 0
            if d+penalty<cost then best,cost=p,d+penalty end
        end
    end
    return best
end
local function resetPositions(s,kickoffTeam)
    Passing.finish(s,"missed","goal")
    Combinations.reset(s);AI.reset(s)
    kickoffTeam=kickoffTeam or 1
    for _,p in ipairs(s.players) do
        p.x,p.y=p.homeX,p.homeY
        p.vx,p.vy=0,0
        p.moveX,p.moveY=0,0
        p.cooldown=0
        p.sprinting=false
        p.protectInput,p.shielding=false,false
        p.controlCooldown,p.controlFlash,p.controlMoveScale=0,0,1
        p.decision="hold"
    end
    local b=s.ball
    b.x,b.y=s.field.w/2,s.field.h/2
    b.vx,b.vy=0,0
    -- Only the designated striker approaches midfield before play.
    local taker,other
    for _,p in ipairs(s.players) do
        if p.number==9 then
            if p.team==kickoffTeam then taker=p else other=p end
        end
    end
    local attack=kickoffTeam==1 and 1 or -1
    taker.x=b.x-attack*2.6
    taker.y=b.y
    other.x=b.x+attack*15
    other.y=b.y+4
    s.phase="kickoff"
    s.phaseClock=0.8
    s.setPiece={kind="kickoff",team=kickoffTeam,taker=taker}
    s.setPieceProtect=0
    s.setPieceTaker=nil
    s.requestTimer=0
    s.lastTouch=0
    s.directRestart=nil
    s.offside=nil
    s.offsidePhases={}
    s.ballContacts={}
    s.lastKicker=nil
    s.lastKickTime=-100
    s.aiTimer=0
    s.pressers={}
    s.presserSince={}
end
function Sim.new(controlRole,teamSize)
    -- Select one permanent human-controlled disc for the entire match.
    -- Default remains RM for backward compatibility with Physics/Match Labs.
    controlRole=controlRole or "RM"
    assert(controlRole=="RM" or controlRole=="GK", "unsupported controlled role")
    -- The game always uses 11. Five-player fixtures remain available for
    -- isolated passing/tactics regressions from the earlier prototype.
    teamSize=teamSize or 11
    assert(teamSize==5 or teamSize==11,"unsupported team size")
    local s={
        field={w=teamSize==11 and 105 or 120,h=teamSize==11 and 68 or 70,
            goalHalf=teamSize==11 and 3.66 or 8,postRadius=teamSize==11 and 0.12 or 0.6},
        params={
            acceleration=54,maxSpeed=7.2,playerDrag=7.5,sprintMultiplier=1.4,
            ballDrag=1.0,ballStopSpeed=0.12,
            restitution=0.36,playerRestitution=0.16,
            wallBounce=0.64,kickSpeed=26,passMultiplier=1.35
        },
        ball={x=60,y=35,vx=0,vy=0,r=0.83,mass=0.65},
        players={},score={0,0},elapsed=0,limit=300,phase="kickoff",clockStarted=false,
        offsideCount={0,0},
        phaseClock=0,aiTimer=0,requestTimer=0,lastTouch=0,
        controlled=nil,totalKicks=0,passAttempts=0,shotAttempts=0,
        restartCount=0,lastAction="",lastKickTime=-100,
        pressers={},presserSince={},setPiece=nil,setPieceProtect=0
    }
    for _,team in ipairs({1,2}) do
        for _,r in ipairs(teamSize==11 and fullRoles or roles) do
            local hx,hy=r[3]*s.field.w/120,r[4]*s.field.h/70
            local x=team==1 and hx or s.field.w-hx
            local y=team==1 and hy or s.field.h-hy
            local p={
                team=team,role=r[1],number=r[2],
                homeX=x,homeY=y,x=x,y=y,
                vx=0,vy=0,moveX=0,moveY=0,
                r=1.32,mass=3.1,cooldown=0,sprinting=false,
                targetX=x,targetY=y,decision="hold"
            }
            s.players[#s.players+1]=p
            if team==1 and r[1]==controlRole then s.controlled=p end
        end
    end
    assert(s.controlled, "missing controlled player")
    Settings.attach(s)
    Passing.reset(s)
    resetPositions(s,1)
    Coach.reset(s)
    s.kick=function(p,tx,ty,power,action,plan)
        return Sim.kick(s,p,tx,ty,power,action,plan)
    end
    return s
end
function Sim.restart(s)
    s.score[1],s.score[2]=0,0
    s.elapsed,s.totalKicks,s.passAttempts,s.shotAttempts,s.restartCount=0,0,0,0,0
    s.lastAction=""
    s.aiPassAttempts=0
    s.clockStarted=false
    s.offsideCount={0,0}
    s.cornerSequence=nil
    Passing.reset(s)
    resetPositions(s,1)
    Coach.reset(s)
end
-- Kicks have an impulse, not an ownership or auto-pass animation.
function Sim.kick(s,p,tx,ty,power,action,plan)
    if s.phase~="play" or p.cooldown>0 then return false end
    local b=s.ball
    local dx,dy=b.x-p.x,b.y-p.y
    local d=sqrt(dx*dx+dy*dy)
    if d<0.0001 or d>p.r+b.r+1.05 then return false end
    if Offside.involved(s,p) then awardOffside(s,p); return false end
    if s.directRestart and s.directRestart.taker~=p then s.directRestart=nil end
    Combinations.onTouch(s,p)
    Passing.touch(s,p)
    Passing.finish(s,"missed","replaced")
    local spec=s.setPiece
    local exempt=spec and (spec.kind=="throw_in" or spec.kind=="goal_kick" or spec.kind=="corner")
    -- A save of an incoming shot does not reset an opponent's offside phase.
    local ownGoal=p.team==1 and 0 or s.field.w
    local towardGoal=p.team==1 and b.vx<0 or p.team==2 and b.vx>0
    local goalFactor=towardGoal and (ownGoal-b.x)/b.vx or -1
    local save=Offside.phase(s,3-p.team) and
        abs(b.x-ownGoal)<16.5 and goalFactor>=0 and
        goalFactor<=Passing.travelFactor(s.params.ballDrag,8) and
        abs(b.y+b.vy*goalFactor-s.field.h/2)<s.field.goalHalf+b.r
    Offside.touch(s,p,not save,exempt)
    b.vx,b.vy=Passing.kickVelocity(s,p,tx,ty,power,action)
    p.cooldown=0.34
    s.totalKicks=s.totalKicks+1
    s.lastTouch=p.team
    s.lastKickTime=s.elapsed
    s.lastKicker=p
    s.lastAction=action or "kick"
    if action=="pass" then
        s.passAttempts=s.passAttempts+1
        Passing.begin(s,p,plan)
    end
    if action=="shot" then s.shotAttempts=s.shotAttempts+1 end
    Combinations.onKick(s,p,action,plan)
    AI.noteKick(s,p,action,plan)
    return true
end
-- A tap seeks a physically reachable teammate in the current contact direction.
-- No teleport, forced possession or movement of the human receiver is used.
function Sim.pass(s,p,oneTwo)
    local best,cost=nil,math.huge
    for _,mate in ipairs(s.players) do
        if mate.team==p.team and mate~=p and not Offside.inPosition(s,mate) then
            local plan=Passing.plan(s,p,mate)
            if plan and Passing.canLaunch(s,p,plan) then
                local risk=AI.laneRisk(s,s.ball.x,s.ball.y,plan.targetX,plan.targetY,p.team)
                local value=distance(mate,s.ball)+risk*3
                if value<cost then best,cost=plan,value end
            end
        end
    end
    if best then
        best.oneTwo=oneTwo==true
        return Sim.kick(s,p,best.aimX,best.aimY,best.power,"pass",best)
    end
    return Sim.kick(s,p,nil,nil,0.52,"pass")
end
local function resolvePair(a,b,restitution)
    local dx,dy=b.x-a.x,b.y-a.y
    local d2=dx*dx+dy*dy
    local target=a.r+b.r
    if d2>=target*target then return false,0 end
    local d=sqrt(d2)
    if d<0.00001 then dx,dy,d=1,0,1 end
    local nx,ny=dx/d,dy/d
    local ia,ib=1/a.mass,1/b.mass
    local inv=ia+ib
    local overlap=target-d
    a.x,a.y=a.x-nx*overlap*ia/inv,a.y-ny*overlap*ia/inv
    b.x,b.y=b.x+nx*overlap*ib/inv,b.y+ny*overlap*ib/inv
    local rvx,rvy=b.vx-a.vx,b.vy-a.vy
    local approach=rvx*nx+rvy*ny
    if approach<0 then
        local impulse=-(1+restitution)*approach/inv
        a.vx,a.vy=a.vx-nx*impulse*ia,a.vy-ny*impulse*ia
        b.vx,b.vy=b.vx+nx*impulse*ib,b.vy+ny*impulse*ib
    end
    return true,-approach
end
local function collidePost(ball,x,y,r,bounce)
    local dx,dy=ball.x-x,ball.y-y
    local d=sqrt(dx*dx+dy*dy)
    local target=ball.r+r
    if d>=target then return end
    if d<0.0001 then dx,dy,d=1,0,1 end
    local nx,ny=dx/d,dy/d
    ball.x,ball.y=x+nx*target,y+ny*target
    local vn=ball.vx*nx+ball.vy*ny
    if vn<0 then
        ball.vx=ball.vx-(1+bounce)*vn*nx
        ball.vy=ball.vy-(1+bounce)*vn*ny
    end
end
local function moveDisc(s,p,dt)
    local par=s.params
    -- Preserve AI analog input magnitude: previous norm() converted 0.1 to 1.
    local dx,dy=p.moveX,p.moveY
    local mag=sqrt(dx*dx+dy*dy)
    if mag>1 then dx,dy=dx/mag,dy/mag end
    local boost=(p.sprinting and par.sprintMultiplier or 1)*(p.controlMoveScale or 1)
    local maxSpeed=par.maxSpeed*boost
    p.vx=(p.vx+dx*par.acceleration*boost*dt)*exp(-par.playerDrag*dt)
    p.vy=(p.vy+dy*par.acceleration*boost*dt)*exp(-par.playerDrag*dt)
    local speed=sqrt(p.vx*p.vx+p.vy*p.vy)
    if speed>maxSpeed then
        p.vx,p.vy=p.vx*maxSpeed/speed,p.vy*maxSpeed/speed
    end
    -- Players can step beyond a line to approach a ball still partly in play.
    p.x=clamp(p.x+p.vx*dt,-4,s.field.w+4)
    p.y=clamp(p.y+p.vy*dt,-4,s.field.h+4)
    p.cooldown=max(0,p.cooldown-dt)
end
local function prepareRestart(s,side,forcedKind,forcedTeam)
    Passing.finish(s,"missed","out")
    Combinations.reset(s);AI.reset(s)
    local b,f=s.ball,s.field
    local team=forcedTeam or (s.lastTouch==1 and 2 or 1)
    local lateral=side=="top" or side=="bottom"
    local defending=side=="left" and 1 or 2
    local kind=forcedKind or (lateral and "throw_in" or
        (team==defending and "goal_kick" or "corner"))
    local x,y
    if kind=="offside" then
        x,y=clamp(b.x,0,f.w),clamp(b.y,0,f.h)
    elseif kind=="throw_in" then
        x,y=clamp(b.x,0,f.w),side=="top" and 0 or f.h
    elseif kind=="goal_kick" then
        x=side=="left" and 4.75 or f.w-4.75
        y=f.h/2+(b.y<f.h/2 and -5 or 5)
    else
        x=side=="left" and 0.7 or f.w-0.7
        y=b.y<f.h/2 and 0.7 or f.h-0.7
    end
    b.x,b.y,b.vx,b.vy=x,y,0,0
    local taker=takerForTeam(s,team,b,kind=="goal_kick" and side or "touchline")
    if kind=="goal_kick" then
        for _,p in ipairs(s.players) do
            if p.team==team and p.role=="GK" then taker=p; break end
        end
    end
    local tx,ty
    if kind=="offside" then
        tx,ty=clamp(x+(team==1 and 18 or -18),5,f.w-5),clamp(y,10,f.h-10)
        if abs(tx-x)+abs(ty-y)<1 then ty=f.h/2 end
    elseif kind=="throw_in" then
        tx,ty=x+(team==1 and 10 or -10),y+(side=="top" and 16 or -16)
    elseif kind=="corner" then
        tx=side=="left" and 14 or f.w-14
        ty=f.h/2
    else
        tx,ty=side=="left" and f.w*0.28 or f.w*0.72,y
    end
    tx=clamp(tx,5,f.w-5)
    local dx,dy=tx-x,ty-y
    local length=sqrt(dx*dx+dy*dy)
    local gap=taker.r+b.r+0.48
    taker.x,taker.y=x-dx/length*gap,y-dy/length*gap
    for _,p in ipairs(s.players) do
        p.vx,p.vy,p.moveX,p.moveY=0,0,0,0
        p.sprinting=false
        p.protectInput,p.shielding=false,false
        p.controlCooldown,p.controlFlash,p.controlMoveScale=0,0,1
        if p~=taker then
            if kind=="goal_kick" and p.team~=team then
                p.x=side=="left" and max(p.x,19) or min(p.x,f.w-19)
            end
            local px,py=p.x-x,p.y-y
            local d=sqrt(px*px+py*py)
            local clearance=p.r+b.r+3
            if p.team~=team and (kind=="corner" or kind=="offside") then clearance=max(clearance,9.15+p.r) end
            if d<clearance then
                if d<0.0001 then px,py=f.w/2-x,f.h/2-y; d=sqrt(px*px+py*py) end
                p.x=clamp(x+px/d*clearance,p.r,f.w-p.r)
                p.y=clamp(y+py/d*clearance,p.r,f.h-p.r)
            end
        end
    end
    taker.cooldown=0
    s.phase="restart"
    s.phaseClock=0.72
    s.restartCount=s.restartCount+1
    s.setPiece={kind=kind,side=side,team=team,taker=taker,targetX=tx,targetY=ty}
    s.setPieceProtect=0
    s.setPieceTaker=nil
    s.directRestart=nil
    s.offside=nil
    s.offsidePhases={}
    s.ballContacts={}
    s.lastKicker=nil
    if kind=="corner" then Corners.prepare(s,s.setPiece) end
end
awardOffside=function(s,p)
    local x,y=p.x,p.y
    s.offsideCount[p.team]=s.offsideCount[p.team]+1
    s.ball.x,s.ball.y=x,y
    prepareRestart(s,nil,"offside",3-p.team)
    s.lastAction="offside"
end
local function activateSetPiece(s,power)
    local spec=s.setPiece
    s.phase="play"
    if not spec then return end
    local b=s.ball
    local attack=spec.team==1 and 1 or -1
    local tx,ty=spec.targetX,spec.targetY
    if spec.kind=="kickoff" then
        tx,ty=b.x+attack*17,b.y+(spec.team==1 and -5 or 5)
    end
    -- Top-down abstraction: throw-ins use an inward physical launch, no
    -- overhead animation. Their direct-goal restriction is tracked below.
    local plan=spec.receiver and Passing.plan(s,spec.taker,spec.receiver)
    if plan then tx,ty=plan.aimX,plan.aimY end
    local kicked=Sim.kick(s,spec.taker,tx,ty,
        power or (plan and plan.power) or (spec.kind=="goal_kick" and 0.95 or 0.68),"pass",plan)
    if not kicked then s.phase="restart"; return end
    s.clockStarted=true
    s.setPieceTaker=spec.taker
    s.setPieceProtect=0.72
    s.directRestart={kind=spec.kind,team=spec.team,taker=spec.taker}
    s.setPiece=nil
    s.aiTimer=0
end
-- Earliest complete crossing in the step wins, including diagonal corner exits.
local function outOfPlay(s,oldX,oldY)
    local b,f=s.ball,s.field
    local side,bestT=nil,math.huge
    local function cross(name,old,value,line,lower)
        if (lower and value<line) or (not lower and value>line) then
            local t=value==old and 0 or clamp((line-old)/(value-old),0,1)
            if t<bestT then side,bestT=name,t end
        end
    end
    cross("top",oldY,b.y,-b.r,true)
    cross("bottom",oldY,b.y,f.h+b.r,false)
    cross("left",oldX,b.x,-b.r,true)
    cross("right",oldX,b.x,f.w+b.r,false)
    if not side then return false end
    local crossingX=oldX+(b.x-oldX)*bestT
    local crossingY=oldY+(b.y-oldY)*bestT
    b.x,b.y=crossingX,crossingY
    local endline=side=="left" or side=="right"
    local mouth=abs(crossingY-f.h/2)+b.r<f.goalHalf
    if endline and mouth then
        local scoring=side=="right" and 1 or 2
        local direct=s.directRestart
        if direct and (direct.kind=="throw_in" or direct.kind=="offside" or scoring~=direct.team) then
            local ownGoal=scoring~=direct.team
            prepareRestart(s,side,ownGoal and "corner" or "goal_kick",
                ownGoal and scoring or 3-scoring)
        else
            s.score[scoring]=s.score[scoring]+1
            resetPositions(s,3-scoring)
        end
    else
        prepareRestart(s,side)
    end
    return true
end
function Sim.step(s,dt,input)
    input=input or {}
    if s.phase=="fulltime" or s.phase=="paused" then return end
    if s.clockStarted or s.phase=="play" then
        s.clockStarted=true
        s.elapsed=min(s.limit,s.elapsed+dt)
        if s.elapsed>=s.limit then
            s.phase="fulltime"
            Passing.finish(s,"missed","fulltime")
            s.setPiece,s.offside=nil,nil
            s.offsidePhases={}
            Combinations.reset(s);AI.reset(s)
            for _,p in ipairs(s.players) do
                p.protectInput,p.shielding,p.sprinting=false,false,false
                p.controlCooldown,p.controlFlash,p.controlMoveScale=0,0,1
            end
            return
        end
    end
    if s.phase=="kickoff" or s.phase=="restart" then
        s.phaseClock=s.phaseClock-dt
        if s.phaseClock<=0 then
            local spec=s.setPiece
            if spec and spec.taker==s.controlled then
                if input.kick or input.pass then activateSetPiece(s,input.kick) end
            else activateSetPiece(s) end
        end
        return
    end
    if outOfPlay(s,s.ball.x,s.ball.y) then return end
    Coach.update(s,dt)
    Passing.update(s)
    Combinations.update(s)
    s.setPieceProtect=max(0,s.setPieceProtect-dt)
    if s.setPieceProtect==0 then s.setPieceTaker=nil end
    s.requestTimer=max(0,s.requestTimer-dt)
    if input.call then s.requestTimer=1.15 end
    s.aiTimer=s.aiTimer+dt
    if s.aiTimer>=0.10 then
        s.aiTimer=s.aiTimer-0.10
        AI.update(s)
        if s.phase~="play" then return end
    end
    local human=s.controlled
    human.moveX,human.moveY=input.x or 0,input.y or 0
    human.protectInput=input.protect==true and not input.pass and not input.kick
    for _,p in ipairs(s.players) do Control.update(s,p,dt) end
    human.sprinting=input.sprint==true and
        human.moveX*human.moveX+human.moveY*human.moveY>0 and not human.shielding
    for _,p in ipairs(s.players) do moveDisc(s,p,dt) end
    for i=1,#s.players-1 do
        for j=i+1,#s.players do
            local a,b=s.players[i],s.players[j]
            if a.team~=b.team and distance(a,b)<a.r+b.r then
                for _,p in ipairs({a,b}) do
                    if Offside.involved(s,p) and distance(p,s.ball)<p.r+s.ball.r+1.05 and
                        p.moveX*(s.ball.x-p.x)+p.moveY*(s.ball.y-p.y)>0 then
                        awardOffside(s,p); return
                    end
                end
            end
            resolvePair(a,b,s.params.playerRestitution)
        end
    end
    local b=s.ball
    local decay=exp(-s.params.ballDrag*dt)
    b.vx,b.vy=b.vx*decay,b.vy*decay
    if b.vx*b.vx+b.vy*b.vy<s.params.ballStopSpeed^2 then
        b.vx,b.vy=0,0
    end
    local oldX,oldY=b.x,b.y
    b.x,b.y=b.x+b.vx*dt,b.y+b.vy*dt
    if outOfPlay(s,oldX,oldY) then return end
    local contacts={}
    for _,p in ipairs(s.players) do
        if distance(p,b)<p.r+b.r and Offside.involved(s,p) then
            awardOffside(s,p); return
        end
        local incomingVx,incomingVy=b.vx,b.vy
        local collided=resolvePair(p,b,s.params.restitution)
        if collided then
            contacts[p]=true
            if not s.ballContacts[p] and not (p==s.lastKicker and s.elapsed-s.lastKickTime<0.12) then
                Offside.touch(s,p,false)
            end
            local receiving=s.activePass and s.activePass.receiver==p
            local combo=s.combinations and s.combinations[p.team]
            receiving=receiving or (combo and combo.wall==p and combo.stage=="outbound")
            Combinations.onTouch(s,p)
            Passing.touch(s,p)
            if Control.contact(s,p,incomingVx,incomingVy,receiving==true) then
                -- Cushioning is deliberate play; saving a goal-bound ball
                -- preserves the attacking phase, just like a kicked save.
                local goal=p.team==1 and 0 or s.field.w
                local toward=p.team==1 and incomingVx<0 or p.team==2 and incomingVx>0
                local factor=toward and (goal-b.x)/incomingVx or -1
                local save=Offside.phase(s,3-p.team) and abs(b.x-goal)<16.5 and factor>=0 and
                    factor<=Passing.travelFactor(s.params.ballDrag,8) and
                    abs(b.y+incomingVy*factor-s.field.h/2)<s.field.goalHalf+b.r
                Offside.touch(s,p,not save)
            end
            s.lastTouch=p.team
            if s.directRestart and s.directRestart.taker~=p then s.directRestart=nil end
        end
    end
    s.ballContacts=contacts
    if input.pass then Sim.pass(s,human,input.oneTwo)
    elseif input.kick then Sim.kick(s,human,nil,nil,input.kick,input.shot and "shot" or nil) end
    if s.phase~="play" then return end
    local f=s.field
    for _,x in ipairs({0,f.w}) do
        for _,y in ipairs({f.h/2-f.goalHalf-f.postRadius,f.h/2+f.goalHalf+f.postRadius}) do
            collidePost(b,x,y,f.postRadius,s.params.wallBounce)
        end
    end
    outOfPlay(s,oldX,oldY)
end
return Sim
