-- Match Lab v0.2.1: autonomous football with stable steering and physical passing.
local AI={}
local Tactics=require("src.tactics")
local Passing=require("src.passing")
local Offside=require("src.offside")
local Combinations=require("src.combinations")
local Space=require("src.space")
local Settings=require("src.tactical_settings")
local sqrt,min,max,abs=math.sqrt,math.min,math.max,math.abs
local function clamp(v,a,b) return max(a,min(b,v)) end
local function length(x,y) return sqrt(x*x+y*y) end
local function dist(a,b) return length(a.x-b.x,a.y-b.y) end
local function norm(x,y)
    local d=length(x,y)
    if d<0.000001 then return 0,0 end
    return x/d,y/d
end
-- Velocity control includes braking, unlike a full-strength direction chase.
-- Returning analog input (0..1) is important: sim.lua must not normalize it.
local function toward(s,p,x,y,steady)
    if steady then
        local ox,oy=p.supportX,p.supportY
        if ox and oy and length(x-ox,y-oy)<1.75 and length(p.x-ox,p.y-oy)<8 then
            x,y=ox,oy
        end
        p.supportX,p.supportY=x,y
    else
        p.supportX,p.supportY=nil,nil
    end
    local dx,dy=x-p.x,y-p.y
    local d=length(dx,dy)
    p.targetX,p.targetY=x,y
    local q=Settings.profile(s,p)
    local pace=q and clamp(1+(q.tempo or 0)*0.14,0.75,1.2) or 1
    local speed=min(s.params.maxSpeed*0.86*pace,d*2.25*pace)
    local ux,uy=norm(dx,dy)
    local vx,vy=ux*speed,uy*speed
    local gain=10.5
    local ax=(vx-p.vx)*gain+s.params.playerDrag*p.vx
    local ay=(vy-p.vy)*gain+s.params.playerDrag*p.vy
    local controlX,controlY=ax/s.params.acceleration,ay/s.params.acceleration
    local magnitude=length(controlX,controlY)
    if magnitude>1 then
        controlX,controlY=controlX/magnitude,controlY/magnitude
    end
    p.moveX,p.moveY=controlX,controlY
end
local laneRisk=Space.laneRisk
function AI.reset(s)
    s.aiPassMemory={}
    s.aiTransition=nil
    for _,p in ipairs(s.players) do p.aiIntent=nil;p.aiScores=nil;p.supportX=nil;p.supportY=nil end
end
function AI.noteKick(s,p,action,plan)
    s.aiPassMemory=s.aiPassMemory or {}
    s.aiPassMemory[3-p.team]=nil
    if action~="pass" or not plan or not plan.receiver then return end
    local history=s.aiPassMemory[p.team] or {}
    history[#history+1]={from=p,to=plan.receiver,x=s.ball.x,y=s.ball.y,at=s.elapsed}
    if #history>6 then table.remove(history,1) end
    s.aiPassMemory[p.team]=history
end
local function passOption(s,p)
    local b=s.ball
    local attack=p.team==1 and 1 or -1
    local q=Settings.profile(s,p)
    local best,bestScore,bestRisk,bestPlan=nil,-math.huge,math.huge,nil
    local closestToBall=math.huge
    for _,enemy in ipairs(s.players) do
        if enemy.team~=p.team then
            local d=dist(enemy,b)
            if d<closestToBall then closestToBall=d end
        end
    end
    local pressured=closestToBall<10
    for _,mate in ipairs(s.players) do
        if mate.team==p.team and mate~=p and not Offside.inPosition(s,mate) then
            local recipient=mate
            local mq=Settings.profile(s,mate)
            if q and q.passIntoSpace and ((mq and (mq.runs or 0)>0) or mate.role=="ST") then
                recipient={x=clamp(mate.x+attack*3,mate.r,s.field.w-mate.r),y=mate.y,
                    vx=mate.vx,vy=mate.vy,r=mate.r}
            end
            local plan=Passing.plan(s,p,recipient)
            if plan then plan.receiver=mate end
            if plan then
                local leadX,leadY=plan.targetX,plan.targetY
                local dx,dy=leadX-b.x,leadY-b.y
                local d=length(dx,dy)
                local risk=laneRisk(s,b.x,b.y,leadX,leadY,p.team)
                local receiverGap=math.huge
                for _,enemy in ipairs(s.players) do
                    if enemy.team~=p.team then
                        receiverGap=min(receiverGap,
                            length(enemy.x-leadX,enemy.y-leadY))
                    end
                end
                -- Progress is valuable, but an open back-pass must beat a
                -- marked forward lane. Avoid receivers being immediately tackled.
                local forward=dx*attack
                local receiverPenalty=max(0,8-receiverGap)*1.8
                local score=5+forward*0.24-d*0.13
                    -risk*1.35-receiverPenalty
                if q then
                    score=score+(q.passing or 0)*(d-18)*0.32+(q.risk or 0)*risk*0.45
                    if q.passIntoSpace and forward>4 and receiverGap>6 then score=score+2 end
                    if mq and mq.playmaker then score=score+1.4 end
                    if q.focus=="left" then score=score+(s.field.h/2-leadY)*attack*0.15
                    elseif q.focus=="right" then score=score+(leadY-s.field.h/2)*attack*0.15
                    elseif q.focus=="centre" then score=score-abs(leadY-s.field.h/2)*0.15 end
                    if p.role=="GK" then
                        local mode=q.distribution
                        if mode=="short" then score=score-d*0.3+(mate.role=="DF" and 3 or 0)
                        elseif mode=="long" then score=score+d*0.25+max(0,forward)*0.1
                        elseif mode=="flanks" then score=score+abs(leadY-s.field.h/2)*0.28
                        elseif mode=="playmaker" then score=score+(mq and mq.playmaker and 9 or -2)
                        elseif mode=="target" then score=score+(mq and mq.target and 9 or -2) end
                    end
                    local deep=p.team==1 and b.x or s.field.w-b.x
                    local wide=abs(b.y-s.field.h/2)>s.field.h*0.22
                    local delivery=wide and deep>s.field.w*0.55 and
                        (leadX-b.x)*attack>-12 and abs(leadY-s.field.h/2)<s.field.h*0.27
                    if delivery then
                        score=score+(q.crossing or 0)*5
                        if q.crossFrom=="deep" then score=score+(deep<s.field.w-18 and 3 or -2)
                        elseif q.crossFrom=="byline" then score=score+(deep>s.field.w-18 and 3 or -4) end
                        local side=b.y<s.field.h/2 and -1 or 1
                        if q.crossAim=="near" then score=score+(leadY-s.field.h/2)*side*0.25
                        elseif q.crossAim=="far" then score=score-(leadY-s.field.h/2)*side*0.25
                        elseif q.crossAim=="centre" then score=score-abs(leadY-s.field.h/2)*0.25
                        elseif q.crossAim=="target" then score=score+(mq and mq.target and 7 or -2) end
                    end
                    if s.aiTransition and s.elapsed-s.aiTransition.at<3 then
                        if q.transitionWin=="counter" then score=score+forward*0.14
                        elseif q.transitionWin=="hold" then score=score-forward*0.1 end
                    end
                end
                if mate.role=="GK" then score=score-4 end
                if pressured and forward<0 and risk<5 then
                    score=score+3
                end
                if mate==s.controlled and s.requestTimer>0 and
                   risk<5 and receiverGap>5 then
                    score=score+9
                end
                if leadY<9 or leadY>s.field.h-9 then score=score-4 end
                for _,recent in ipairs((s.aiPassMemory or {})[p.team] or {}) do
                    local age=s.elapsed-recent.at
                    local stagnant=length(b.x-recent.x,b.y-recent.y)<12
                    if age<8 and stagnant then
                        if recent.from==mate and recent.to==p then score=score-4*(1-age/8) end
                        if recent.from==p and recent.to==mate then score=score-3*(1-age/8) end
                    end
                end
                if score>bestScore then
                    best,bestScore,bestRisk=mate,score,risk
                    bestPlan=plan
                end
            end
        end
    end
    return best,bestScore,bestRisk,bestPlan
end
-- Only the genuinely closest appropriate player presses; sticky assignment
-- prevents alternating pressers every 100 ms when distances are comparable.
local function pressers(s)
    local chosen={}
    local b=s.ball
    for team=1,2 do
        local humanCarrier=s.controlled.team==team and s.lastTouch==team and
            dist(s.controlled,b)<s.controlled.r+b.r+1.5
        if humanCarrier or (s.setPieceProtect>0 and s.lastTouch~=team) then
            chosen[team]=nil
            s.pressers[team]=nil
        else
            local best,bestCost=nil,math.huge
            local previous=s.pressers[team]
            local previousCost=math.huge
            for _,p in ipairs(s.players) do
                if p.team==team and p~=s.controlled and
                   p~=s.setPieceTaker then
                    local d=dist(p,b)
                    local keeper=(p.role=="GK") and
                        ((team==1 and b.x>19) or
                         (team==2 and b.x<s.field.w-19))
                    local cost=d+(keeper and 30 or 0)
                    local q=Settings.profile(s,p)
                    if q and s.lastTouch==3-team then
                        cost=d/(1+(q.pressing or 0)*0.3)+(keeper and (q.gkRush and 18 or 30) or 0)
                        if q.hold and d>7 then cost=cost+4 end
                        if q.preventShortGK and ((team==1 and b.x>s.field.w-18) or
                            (team==2 and b.x<18)) and p.role=="ST" then cost=cost-5 end
                    end
                    if cost<bestCost then best,bestCost=p,cost end
                    if p==previous then previousCost=cost end
                end
            end
            local held=s.elapsed-(s.presserSince[team] or -100)
            local preferred=best and Settings.profile(s,best)
            local pressing=preferred and preferred.pressing or 0
            if previous and previousCost<math.huge and
               (held<0.7*(1-pressing*0.5) or previousCost<bestCost+2.8*(1-pressing*0.5)) then
                best=previous
            end
            local combo=s.combinations and s.combinations[team]
            if combo and combo.stage=="return_ready" and combo.wall~=s.controlled and
                dist(combo.wall,b)<7 then best=combo.wall end
            local q=best and Settings.profile(s,best)
            if q and s.lastTouch==3-team and dist(best,b)>7 then
                local depth=team==1 and b.x or s.field.w-b.x
                local line=s.field.w*0.72+(q.engagement or 0)*24+(q.pressing or 0)*7
                if s.aiTransition and s.elapsed-s.aiTransition.at<3 then
                    if q.transitionLoss=="counterpress" then line=line+22
                    elseif q.transitionLoss=="regroup" then line=line-18 end
                end
                if not q.preventShortGK and depth>line then best=nil end
            end
            if best~=s.pressers[team] then
                s.presserSince[team]=s.elapsed
                s.pressers[team]=best
            end
            chosen[team]=best
        end
    end
    return chosen
end
local function carryOption(s,p)
    local b=s.ball
    local attack=p.team==1 and 1 or -1
    local q=Settings.profile(s,p)
    local best
    for _,angle in ipairs({0,-0.6,0.6,-1.15,1.15,-1.7,1.7}) do
        local tx=clamp(b.x+attack*9*math.cos(angle),2,s.field.w-2)
        local ty=clamp(b.y+9*math.sin(angle),3,s.field.h-3)
        local d=length(tx-b.x,ty-b.y)
        if d>3 then
            local risk=laneRisk(s,b.x,b.y,tx,ty,p.team)
            local freedom=clamp((Space.clearance(s,p.team,tx,ty)-2.5)/10,0,1)
            local corridor=1-clamp(risk/10,0,1)
            local progress=clamp(((tx-b.x)*attack+3)/12,0,1)
            local value=freedom*0.4+corridor*0.4+progress*0.2
            if q and q.carryDirection~="mixed" then
                local inward=(abs(b.y-s.field.h/2)-abs(ty-s.field.h/2))/9
                if q.carryDirection=="inside" then value=value+inward*0.18
                elseif q.carryDirection=="wide" then value=value-inward*0.18 end
            end
            if not best or value>best.value then best={x=tx,y=ty,value=value,risk=risk} end
        end
    end
    return best
end
-- Shots have narrower interception corridors than passes: an opponent near
-- one post must not close the whole goal. Choose an actual point inside it.
local function shotOption(s,p)
    local b,f=s.ball,s.field
    local attack=p.team==1 and 1 or -1
    local goalX=attack==1 and f.w+b.r+0.1 or -b.r-0.1
    local distance=length(goalX-b.x,f.h/2-b.y)
    local power=1.15
    local range=s.params.kickSpeed*power*Passing.travelFactor(s.params.ballDrag,8)
    if distance>min(28,range-0.5) then return end
    local inset=max(0,f.goalHalf-b.r-0.1)
    local bestY,bestRisk=nil,math.huge
    for _,offset in ipairs({-inset,inset,0}) do
        local ty=f.h/2+offset
        local dx,dy=goalX-b.x,ty-b.y
        local lsq=dx*dx+dy*dy
        local risk=0
        for _,other in ipairs(s.players) do
            if other.team~=p.team then
                local t=((other.x-b.x)*dx+(other.y-b.y)*dy)/lsq
                if t>0 and t<1 then
                    local gap=length(other.x-b.x-t*dx,other.y-b.y-t*dy)
                    risk=risk+max(0,other.r+b.r+0.25-gap)*4
                end
            end
        end
        if risk<bestRisk then bestY,bestRisk=ty,risk end
    end
    if bestRisk>7 then return end
    -- Invert the existing contact/aim blend so the physical launch heads at
    -- the chosen gap, rather than collapsing every corner aim toward centre.
    local ux,uy=norm(goalX-b.x,bestY-b.y)
    local nx,ny=norm(b.x-p.x,b.y-p.y)
    local dot=ux*nx+uy*ny
    local discriminant=0.48^2-0.52^2*(1-dot*dot)
    if dot>0.6 and discriminant>=0 then
        local q=0.52*dot+sqrt(discriminant)
        return b.x+(q*ux-0.52*nx)*20,b.y+(q*uy-0.52*ny)*20,power,bestRisk,distance
    end
    return goalX,bestY,power,bestRisk,distance
end
local function chooseAction(s,p)
    local b,f=s.ball,s.field
    local pressureGap=Space.clearance(s,p.team,b.x,b.y)
    local pressure=1-clamp((pressureGap-3)/9,0,1)
    local q=Settings.profile(s,p)
    local returnPlan=Combinations.returnPlan(s,p)
    if returnPlan and laneRisk(s,b.x,b.y,returnPlan.targetX,returnPlan.targetY,p.team)<5 then
        return returnPlan.aimX,returnPlan.aimY,returnPlan.power,"pass",returnPlan
    end
    local combo=s.combinations and s.combinations[p.team]
    if combo and combo.wall==p and combo.stage=="return_ready" and s.elapsed<combo.expires then
        if pressureGap>5 and not Offside.inPosition(s,combo.runner) and
            laneRisk(s,b.x,b.y,combo.x,combo.y,p.team)<5 then
            return combo.x,combo.y,0,"wait_return"
        end
        s.combinations[p.team]=nil
    end
    local options={}
    local shotX,shotY,shotPower,shotRisk,goalDistance=shotOption(s,p)
    if shotX then options[#options+1]={x=shotX,y=shotY,power=shotPower,action="shot",
        score=0.62+0.28*(1-clamp(goalDistance/28,0,1))-0.15*clamp(shotRisk/7,0,1)
            +(q and (q.shooting or 0)*0.2 or 0)} end
    local mate,score,risk,plan=passOption(s,p)
    if mate and score>-7 and risk<9+(q and (q.risk or 0)*2 or 0) then
        local utility=0.32+0.36*clamp((score+8)/22,0,1)+0.18*pressure
        local progress=(plan.targetX-b.x)*(p.team==1 and 1 or -1)
        utility=utility+0.14*clamp(progress/25,0,1)
        if mate==s.controlled and s.requestTimer>0 then utility=utility+0.12 end
        if q then utility=utility+(q.tempo or 0)*0.07+(q.holdUp and pressure*0.08 or 0) end
        options[#options+1]={x=plan.aimX,y=plan.aimY,power=plan.power,action="pass",plan=plan,score=utility}
    end
    local carry=carryOption(s,p)
    if carry then
        local utility=0.28+0.40*carry.value-0.25*pressure
        if p.role=="GK" then utility=utility-0.3 end
        if q then utility=utility+(q.dribbling or 0)*0.2-(q.holdUp and 0.12 or 0)
            -(q.tempo or 0)*0.04 end
        options[#options+1]={x=carry.x,y=carry.y,power=0.32,action="advance",score=utility}
    end
    local best,bestValue=nil,-math.huge
    p.aiScores={}
    for _,option in ipairs(options) do
        p.aiScores[option.action]=option.score
        local previous=p.aiIntent
        local bonus=previous and s.elapsed<previous.expires and previous.action==option.action and
            (not option.plan or option.plan.receiver==previous.receiver) and 0.055 or 0
        if option.score+bonus>bestValue then best,bestValue=option,option.score+bonus end
    end
    if not best then return b.x,b.y,0,"wait_return" end
    if not p.aiIntent or p.aiIntent.action~=best.action or
        p.aiIntent.receiver~=(best.plan and best.plan.receiver) or s.elapsed>=p.aiIntent.expires then
        p.aiIntent={action=best.action,receiver=best.plan and best.plan.receiver,expires=s.elapsed+0.45}
    end
    return best.x,best.y,best.power,best.action,best.plan
end
function AI.update(s)
    if s.phase~="play" then return end
    local b,f=s.ball,s.field
    if not s.aiTransition or s.aiTransition.team~=s.lastTouch then
        s.aiTransition={team=s.lastTouch,at=s.elapsed}
    end
    for _,p in ipairs(s.players) do
        if p~=s.controlled and Combinations.runTarget(s,p) and dist(p,b)<=p.r+b.r+0.95 then
            local pass=s.activePass
            local freshKick=s.lastKicker==p and s.elapsed-s.lastKickTime<0.12
            local outgoing=pass and pass.passer==p and
                (b.vx-p.vx)*(b.x-p.x)+(b.vy-p.vy)*(b.y-p.y)>0
            if not freshKick and not outgoing then
                -- A loose ball reaching the runner takes precedence over his
                -- off-ball route. Re-elect the presser after releasing it.
                local combo=s.combinations and s.combinations[p.team]
                local run=s.supportActions and s.supportActions[p.team]
                if combo and combo.runner==p then s.combinations[p.team]=nil end
                if run and run.player==p then s.supportActions[p.team]=nil end
            end
        end
    end
    local chosen=pressers(s)
    local teamTargets={Tactics.teamTargets(s,1),Tactics.teamTargets(s,2)}
    local function support(p)
        local target=teamTargets[p.team][p]
        if target then return target.x,target.y end
        return Tactics.supportPoint(s,p)
    end
    for _,p in ipairs(s.players) do
        if p~=s.controlled then
            local pass=s.activePass
            local runX,runY,runKind=Combinations.runTarget(s,p)
            if runX and not (pass and pass.receiver==p) then
                toward(s,p,runX,runY)
                p.decision=runKind
            elseif pass and pass.receiver and pass.team==p.team then
                if p==pass.receiver then
                    local x,y=Passing.receivePoint(s,p)
                    toward(s,p,x,y)
                    p.decision="receive"
                else
                    local x,y=support(p)
                    toward(s,p,x,y,true)
                    p.decision="support"
                end
            elseif p==s.setPieceTaker and s.setPieceProtect>0 then
                local x,y=support(p)
                toward(s,p,x,y,true)
                p.decision="recover"
            elseif p==chosen[p.team] then
                local tx,ty,power,action,plan=chooseAction(s,p)
                local ux,uy=norm(tx-b.x,ty-b.y)
                local dx,dy=b.x-p.x,b.y-p.y
                local d=length(dx,dy)
                local nx,ny=norm(dx,dy)
                local face=ux*nx+uy*ny
                -- A player must approach the correct side of the ball.
                -- Never change the ball's direction without contact.
                if action~="wait_return" and d<=p.r+b.r+0.95 and face>0.59 and p.cooldown<=0
                    and (not plan or Passing.canLaunch(s,p,plan)) then
                    if s.kick(p,tx,ty,power,action,plan) then
                        if action=="advance" then
                            -- Follow a physical touch into space. Previously
                            -- the carrier immediately retreated to support.
                            toward(s,p,b.x+ux*5,b.y+uy*5)
                        else
                            local x,y=support(p)
                            toward(s,p,x,y)
                        end
                        p.decision=action
                        if action=="pass" then
                            s.aiPassAttempts=(s.aiPassAttempts or 0)+1
                        end
                    end
                else
                    local reach=p.r+b.r+0.38
                    local bx=b.x+b.vx*0.12
                    local by=b.y+b.vy*0.12
                    local cx=clamp(bx-ux*reach,-3.5,f.w+3.5)
                    local cy=clamp(by-uy*reach,-3.5,f.h+3.5)
                    local q=Settings.profile(s,p)
                    if q and s.lastTouch==3-p.team and q.trap~="balanced" and d>reach*1.4 then
                        local side=b.y<f.h/2 and -1 or 1
                        if q.trap=="inside" then cy=by+side*reach
                        elseif q.trap=="outside" then cy=by-side*reach end
                    end
                    if face<0.35 and d<reach*3 then
                        -- Advance around the ball by a quarter turn from the
                        -- current radial position. A fixed tangent waypoint
                        -- can strand both pressers permanently on one side.
                        local turn=nx*uy-ny*ux>=0 and 1 or -1
                        local rx,ry=-nx,-ny
                        local nextX=(rx-ry*turn)*0.70710678118
                        local nextY=(ry+rx*turn)*0.70710678118
                        cx=clamp(bx+nextX*(reach+0.9),-3.5,f.w+3.5)
                        cy=clamp(by+nextY*(reach+0.9),-3.5,f.h+3.5)
                    end
                    toward(s,p,cx,cy)
                    p.decision="approach_"..action
                end
            else
                local x,y=support(p)
                toward(s,p,x,y,true)
                local target=teamTargets[p.team][p]
                p.decision=p.role=="GK" and "goalkeeper" or
                    (target and target.mark and "mark_zone") or
                    (s.lastTouch==p.team and "support" or "cover")
            end
        end
    end
end
-- Pure functions exposed for tactical regression scenarios.
AI.passOption=passOption
AI.laneRisk=laneRisk
AI.chooseAction=chooseAction
return AI
