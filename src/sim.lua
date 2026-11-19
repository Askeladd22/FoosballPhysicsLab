-- Match Lab v0.2.1 - headless, deterministic simulation.
-- A physical ball, no possession magnetism, one permanent human-controlled disc.
local AI = require("src.ai")
local Sim = {}
local sqrt, exp, min, max, abs = math.sqrt, math.exp, math.min, math.max, math.abs
local function clamp(x,a,b) return max(a,min(b,x)) end
local function norm(x,y)
    local length=sqrt(x*x+y*y)
    if length<0.000001 then return 0,0 end
    return x/length,y/length
end
local function distance(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return sqrt(dx*dx+dy*dy)
end
local roles={
    {"GK",1,6,35}, {"DF",4,24,35},
    {"LM",8,40,19}, {"RM",10,40,51}, {"ST",9,53,35}
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
    kickoffTeam=kickoffTeam or 1
    for _,p in ipairs(s.players) do
        p.x,p.y=p.homeX,p.homeY
        p.vx,p.vy=0,0
        p.moveX,p.moveY=0,0
        p.cooldown=0
        p.decision="hold"
    end
    local b=s.ball
    b.x,b.y=s.field.w/2,s.field.h/2
    b.vx,b.vy=0,0
    -- Only the designated striker approaches midfield before play.
    local taker=s.players[kickoffTeam==1 and 5 or 10]
    local attack=kickoffTeam==1 and 1 or -1
    taker.x=b.x-attack*2.6
    taker.y=b.y
    local other=s.players[kickoffTeam==1 and 10 or 5]
    other.x=b.x+attack*15
    other.y=b.y+4
    s.phase="kickoff"
    s.phaseClock=0.8
    s.setPiece={kind="kickoff",team=kickoffTeam,taker=taker}
    s.setPieceProtect=0
    s.setPieceTaker=nil
    s.requestTimer=0
    s.lastTouch=0
    s.lastKickTime=-100
    s.aiTimer=0
    s.pressers={}
    s.presserSince={}
end
function Sim.new()
    local s={
        field={w=120,h=70,goalHalf=8,postRadius=0.6},
        params={
            acceleration=115,maxSpeed=14.4,playerDrag=8.0,
            ballDrag=1.45,ballStopSpeed=0.12,
            restitution=0.36,playerRestitution=0.16,
            wallBounce=0.64,kickSpeed=37
        },
        ball={x=60,y=35,vx=0,vy=0,r=0.83,mass=0.65},
        players={},score={0,0},elapsed=0,limit=180,phase="kickoff",
        phaseClock=0,aiTimer=0,requestTimer=0,lastTouch=0,
        controlled=nil,totalKicks=0,passAttempts=0,shotAttempts=0,
        restartCount=0,lastAction="",lastKickTime=-100,
        pressers={},presserSince={},setPiece=nil,setPieceProtect=0
    }
    for _,team in ipairs({1,2}) do
        for _,r in ipairs(roles) do
            local x=team==1 and r[3] or s.field.w-r[3]
            local y=team==1 and r[4] or s.field.h-r[4]
            local p={
                team=team,role=r[1],number=r[2],
                homeX=x,homeY=y,x=x,y=y,
                vx=0,vy=0,moveX=0,moveY=0,
                r=1.32,mass=3.1,cooldown=0,
                targetX=x,targetY=y,decision="hold"
            }
            s.players[#s.players+1]=p
            if team==1 and r[1]=="RM" then s.controlled=p end
        end
    end
    resetPositions(s,1)
    s.kick=function(p,tx,ty,power,action)
        return Sim.kick(s,p,tx,ty,power,action)
    end
    return s
end
function Sim.restart(s)
    s.score[1],s.score[2]=0,0
    s.elapsed,s.totalKicks,s.passAttempts,s.shotAttempts,s.restartCount=0,0,0,0,0
    s.lastAction=""
    resetPositions(s,1)
end
-- Kicks have an impulse, not an ownership or auto-pass animation.
function Sim.kick(s,p,tx,ty,power,action)
    if s.phase~="play" or p.cooldown>0 then return false end
    local b=s.ball
    local dx,dy=b.x-p.x,b.y-p.y
    local d=sqrt(dx*dx+dy*dy)
    if d<0.0001 or d>p.r+b.r+1.05 then return false end
    local nx,ny=dx/d,dy/d
    if tx and ty then
        local ax,ay=norm(tx-b.x,ty-b.y)
        if ax*nx+ay*ny>0.25 then
            nx,ny=norm(nx*0.52+ax*0.48,ny*0.52+ay*0.48)
        end
    end
    local approach=max(0,p.vx*nx+p.vy*ny)
    local impulse=s.params.kickSpeed*clamp(power or 1,0.45,1.35)+approach*0.12
    b.vx,b.vy=b.vx+nx*impulse,b.vy+ny*impulse
    p.cooldown=0.34
    s.totalKicks=s.totalKicks+1
    s.lastTouch=p.team
    s.lastKickTime=s.elapsed
    s.lastAction=action or "kick"
    if action=="pass" then s.passAttempts=s.passAttempts+1 end
    if action=="shot" then s.shotAttempts=s.shotAttempts+1 end
    return true
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
    p.vx=(p.vx+dx*par.acceleration*dt)*exp(-par.playerDrag*dt)
    p.vy=(p.vy+dy*par.acceleration*dt)*exp(-par.playerDrag*dt)
    local speed=sqrt(p.vx*p.vx+p.vy*p.vy)
    if speed>par.maxSpeed then
        p.vx,p.vy=p.vx*par.maxSpeed/speed,p.vy*par.maxSpeed/speed
    end
    p.x=clamp(p.x+p.vx*dt,p.r,s.field.w-p.r)
    p.y=clamp(p.y+p.vy*dt,p.r,s.field.h-p.r)
    p.cooldown=max(0,p.cooldown-dt)
end
local function prepareRestart(s,side)
    local b,f=s.ball,s.field
    local team=s.lastTouch==1 and 2 or 1
    local x=clamp(b.x,8,f.w-8)
    local y=clamp(b.y,8,f.h-8)
    if side=="top" then y=4.75
    elseif side=="bottom" then y=f.h-4.75
    elseif side=="left" then x=4.75
    else x=f.w-4.75 end
    b.x,b.y=x,y
    b.vx,b.vy=0,0
    local taker=takerForTeam(s,team,b,side)
    local gap=taker.r+b.r+0.48
    if side=="top" then
        taker.x,taker.y=x,y-gap
    elseif side=="bottom" then
        taker.x,taker.y=x,y+gap
    elseif side=="left" then
        taker.x,taker.y=x-gap,y
    else
        taker.x,taker.y=x+gap,y
    end
    taker.vx,taker.vy=0,0
    taker.moveX,taker.moveY=0,0
    taker.cooldown=0
    -- Dead-ball repositioning keeps players from standing on the ball.
    for _,p in ipairs(s.players) do
        if p~=taker then
            local dx,dy=p.x-b.x,p.y-b.y
            local d=sqrt(dx*dx+dy*dy)
            local clearance=p.r+b.r+3.0
            if d<clearance then
                if d<0.0001 then dx,dy,d=1,0,1 end
                p.x=clamp(b.x+dx/d*clearance,p.r,f.w-p.r)
                p.y=clamp(b.y+dy/d*clearance,p.r,f.h-p.r)
                p.vx,p.vy=0,0
            end
        end
    end
    s.phase="restart"
    s.phaseClock=0.72
    s.restartCount=s.restartCount+1
    s.setPiece={kind="restart",side=side,team=team,taker=taker}
    s.setPieceProtect=0
    s.setPieceTaker=nil
end
local function activateSetPiece(s)
    local spec=s.setPiece
    s.phase="play"
    if not spec then return end
    local b,f=s.ball,s.field
    local attack=spec.team==1 and 1 or -1
    local tx,ty
    if spec.kind=="kickoff" then
        tx,ty=b.x+attack*17,b.y+(spec.team==1 and -5 or 5)
    elseif spec.side=="top" then
        tx,ty=clamp(b.x+attack*12,12,f.w-12),f.h*0.43
    elseif spec.side=="bottom" then
        tx,ty=clamp(b.x+attack*12,12,f.w-12),f.h*0.57
    elseif spec.side=="left" then
        tx,ty=f.w*0.28,clamp(b.y,16,f.h-16)
    else
        tx,ty=f.w*0.72,clamp(b.y,16,f.h-16)
    end
    -- Set pieces are explicit, physical passes. A bad follow-up cannot
    -- instantly reset the ball to the same throw-in and loop forever.
    local kicked=Sim.kick(s,spec.taker,tx,ty,0.68,"pass")
    if kicked then
        s.setPieceTaker=spec.taker
        s.setPieceProtect=0.72
        s.lastTouch=spec.team
    end
    s.setPiece=nil
    s.aiTimer=0
end
local function outOfPlay(s)
    local b,f=s.ball,s.field
    local mouth=abs(b.y-f.h/2)<f.goalHalf-b.r*0.25
    if mouth and b.x>f.w+b.r then
        s.score[1]=s.score[1]+1
        resetPositions(s,2)
        return
    elseif mouth and b.x< -b.r then
        s.score[2]=s.score[2]+1
        resetPositions(s,1)
        return
    end
    if b.y< -b.r then prepareRestart(s,"top")
    elseif b.y>f.h+b.r then prepareRestart(s,"bottom")
    elseif b.x< -b.r then prepareRestart(s,"left")
    elseif b.x>f.w+b.r then prepareRestart(s,"right")
    end
end
function Sim.step(s,dt,input)
    input=input or {}
    if s.phase=="fulltime" or s.phase=="paused" then return end
    if s.phase=="kickoff" or s.phase=="restart" then
        s.phaseClock=s.phaseClock-dt
        if s.phaseClock<=0 then activateSetPiece(s) end
        return
    end
    s.elapsed=s.elapsed+dt
    if s.elapsed>=s.limit then
        s.elapsed=s.limit
        s.phase="fulltime"
        return
    end
    s.setPieceProtect=max(0,s.setPieceProtect-dt)
    if s.setPieceProtect==0 then s.setPieceTaker=nil end
    s.requestTimer=max(0,s.requestTimer-dt)
    if input.call then s.requestTimer=1.15 end
    s.aiTimer=s.aiTimer+dt
    if s.aiTimer>=0.10 then
        s.aiTimer=s.aiTimer-0.10
        AI.update(s)
    end
    local human=s.controlled
    human.moveX,human.moveY=input.x or 0,input.y or 0
    for _,p in ipairs(s.players) do moveDisc(s,p,dt) end
    for i=1,#s.players-1 do
        for j=i+1,#s.players do
            resolvePair(s.players[i],s.players[j],s.params.playerRestitution)
        end
    end
    local b=s.ball
    local decay=exp(-s.params.ballDrag*dt)
    b.vx,b.vy=b.vx*decay,b.vy*decay
    if b.vx*b.vx+b.vy*b.vy<s.params.ballStopSpeed^2 then
        b.vx,b.vy=0,0
    end
    b.x,b.y=b.x+b.vx*dt,b.y+b.vy*dt
    for _,p in ipairs(s.players) do
        local collided,speed=resolvePair(p,b,s.params.restitution)
        if collided and speed>1.5 and s.elapsed-s.lastKickTime>0.22 then
            s.lastTouch=p.team
        end
    end
    if input.kick then Sim.kick(s,human,nil,nil,input.kick) end
    local f=s.field
    for _,x in ipairs({0,f.w}) do
        for _,y in ipairs({f.h/2-f.goalHalf,f.h/2+f.goalHalf}) do
            collidePost(b,x,y,f.postRadius,s.params.wallBounce)
        end
    end
    outOfPlay(s)
end
return Sim
