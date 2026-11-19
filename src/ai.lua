-- Match Lab v0.2.1: autonomous football with stable steering and physical passing.
local AI={}
local Tactics=require("src.tactics")
local Passing=require("src.passing")
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
local function toward(s,p,x,y)
    local dx,dy=x-p.x,y-p.y
    local d=length(dx,dy)
    p.targetX,p.targetY=x,y
    local speed=min(s.params.maxSpeed*0.86,d*2.25)
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
local function laneRisk(s,ax,ay,bx,by,team)
    local dx,dy=bx-ax,by-ay
    local lsq=dx*dx+dy*dy
    if lsq<1 then return math.huge end
    local danger=0
    for _,other in ipairs(s.players) do
        if other.team~=team then
            local t=clamp(((other.x-ax)*dx+(other.y-ay)*dy)/lsq,0,1)
            local px,py=ax+t*dx,ay+t*dy
            local gap=length(other.x-px,other.y-py)
            if gap<4.5 then danger=danger+(4.5-gap)*3 end
        end
    end
    return danger
end
local function passOption(s,p)
    local b=s.ball
    local attack=p.team==1 and 1 or -1
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
        if mate.team==p.team and mate~=p then
            local plan=Passing.plan(s,p,mate)
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
                if mate.role=="GK" then score=score-4 end
                if pressured and forward<0 and risk<5 then
                    score=score+3
                end
                if mate==s.controlled and s.requestTimer>0 and
                   risk<5 and receiverGap>5 then
                    score=score+9
                end
                if leadY<9 or leadY>s.field.h-9 then score=score-4 end
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
        if s.setPieceProtect>0 and s.lastTouch~=team then
            chosen[team]=nil
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
                    if cost<bestCost then best,bestCost=p,cost end
                    if p==previous then previousCost=cost end
                end
            end
            local held=s.elapsed-(s.presserSince[team] or -100)
            if previous and previousCost<math.huge and
               (held<0.7 or previousCost<bestCost+2.8) then
                best=previous
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
local function safeForward(s,team)
    local b=s.ball
    local attack=team==1 and 1 or -1
    local x=clamp(b.x+attack*19,9,s.field.w-9)
    -- Near touch lines, even a failed pass should move into playable space.
    local y=clamp(b.y+(s.field.h/2-b.y)*0.55,12,s.field.h-12)
    return x,y
end
local function chooseAction(s,p)
    local b,f=s.ball,s.field
    local attack=p.team==1 and 1 or -1
    local goalX=attack==1 and f.w+2 or -2
    local distanceToGoal=abs(goalX-b.x)
    if distanceToGoal<25 and
       laneRisk(s,b.x,b.y,goalX,f.h/2,p.team)<8 then
        return goalX,f.h/2,1.0,"shot"
    end
    local mate,score,risk,plan=passOption(s,p)
    if mate and score>-7 and risk<9 then
        return plan.aimX,plan.aimY,plan.power,"pass",plan
    end
    local tx,ty=safeForward(s,p.team)
    return tx,ty,0.55,"advance"
end
function AI.update(s)
    if s.phase~="play" then return end
    local b,f=s.ball,s.field
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
            if pass and pass.receiver and pass.team==p.team then
                if p==pass.receiver then
                    local x,y=Passing.receivePoint(s,p)
                    toward(s,p,x,y)
                    p.decision="receive"
                else
                    local x,y=support(p)
                    toward(s,p,x,y)
                    p.decision="support"
                end
            elseif p==s.setPieceTaker and s.setPieceProtect>0 then
                local x,y=support(p)
                toward(s,p,x,y)
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
                if d<=p.r+b.r+0.95 and face>0.59 and p.cooldown<=0
                    and (not plan or Passing.canLaunch(s,p,plan)) then
                    if s.kick(p,tx,ty,power,action,plan) then
                        local x,y=support(p)
                        toward(s,p,x,y)
                        p.decision=action
                        if action=="pass" then
                            s.aiPassAttempts=(s.aiPassAttempts or 0)+1
                        end
                    end
                else
                    local reach=p.r+b.r+0.38
                    local bx=b.x+b.vx*0.12
                    local by=b.y+b.vy*0.12
                    local cx=clamp(bx-ux*reach,p.r+0.2,f.w-p.r-0.2)
                    local cy=clamp(by-uy*reach,p.r+0.2,f.h-p.r-0.2)
                    toward(s,p,cx,cy)
                    p.decision="approach_"..action
                end
            else
                local x,y=support(p)
                toward(s,p,x,y)
                p.decision=p.role=="GK" and "goalkeeper" or
                    (s.lastTouch==p.team and "support" or "cover")
            end
        end
    end
end
-- Pure functions exposed for tactical regression scenarios.
AI.passOption=passOption
AI.laneRisk=laneRisk
return AI
