-- Deterministic, lightweight tactical AI for a five-a-side vertical slice.
-- All agents use the same collision, acceleration and kick constraints.
local AI={}
local sqrt,min,max,abs=math.sqrt,math.min,math.max,math.abs
local function clamp(v,a,b) return max(a,min(b,v)) end
local function length(x,y) return sqrt(x*x+y*y) end
local function toward(p,x,y,slow)
    p.targetX,p.targetY=x,y
    local dx,dy=x-p.x,y-p.y
    local d=length(dx,dy)
    if d<0.10 then p.moveX,p.moveY=0,0 return end
    local throttle=slow and clamp(d/3.5,0,1) or 1
    p.moveX,p.moveY=dx/d*throttle,dy/d*throttle
end
local function dist(a,b)
    return length(a.x-b.x,a.y-b.y)
end
local function openLane(s,ax,ay,bx,by,team)
    local dx,dy=bx-ax,by-ay
    local lsq=dx*dx+dy*dy
    if lsq<1 then return 0 end
    local danger=0
    for _,other in ipairs(s.players) do
        if other.team~=team then
            local t=clamp(((other.x-ax)*dx+(other.y-ay)*dy)/lsq,0,1)
            local ex,ey=ax+t*dx,ay+t*dy
            local dd=length(other.x-ex,other.y-ey)
            if dd<5 then danger=danger+(5-dd)*2.8 end
        end
    end
    return danger
end
local function bestPass(s,p)
    local b=s.ball
    local attack=p.team==1 and 1 or -1
    local best,bestScore=nil,-math.huge
    for _,mate in ipairs(s.players) do
        if mate.team==p.team and mate~=p then
            local dx,dy=mate.x-b.x,mate.y-b.y
            local d=length(dx,dy)
            if d>4 and d<50 then
                local forward=dx*attack
                local lane=openLane(s,b.x,b.y,mate.x,mate.y,p.team)
                local score=forward*0.45-d*0.11-lane
                if mate.role=="GK" then score=score-9 end
                if mate==s.controlled and s.requestTimer>0 then
                    score=score+11
                end
                if score>bestScore then
                    best,bestScore=mate,score
                end
            end
        end
    end
    return best,bestScore
end
local function findPressers(s)
    local chosen={}
    for team=1,2 do
        local best,distScore=nil,math.huge
        for _,p in ipairs(s.players) do
            if p.team==team then
                local d=dist(p,s.ball)
                local gkCost=p.role=="GK" and 33 or 0
                if p.role=="GK" and
                   ((team==1 and s.ball.x<16) or
                    (team==2 and s.ball.x>s.field.w-16)) then
                    gkCost=0
                end
                if d+gkCost<distScore then
                    best,distScore=p,d+gkCost
                end
            end
        end
        chosen[team]=best
    end
    return chosen
end
local function anchor(s,p)
    local b,f=s.ball,s.field
    local attack=p.team==1 and 1 or -1
    local offsetX=(b.x-f.w/2)*0.23
    local offsetY=(b.y-f.h/2)*0.23
    local side=p.team==1 and 1 or -1
    local x,y=p.homeX+offsetX,p.homeY+offsetY
    if p.role=="GK" then
        x=p.team==1 and 5 or f.w-5
        y=clamp(f.h/2+(b.y-f.h/2)*0.42,14,f.h-14)
    elseif p.role=="DF" then
        x=p.homeX+offsetX*0.60
        y=f.h/2+offsetY*0.92
    elseif p.role=="ST" then
        x=p.homeX+offsetX*1.3
        y=f.h/2+offsetY*0.7
    end
    if s.lastTouch==p.team then
        x=x+attack*3.3
    else
        x=x-attack*2.2
    end
    return clamp(x,3,f.w-3),clamp(y,4,f.h-4)
end
function AI.update(s)
    if s.phase~="play" then return end
    local b,f=s.ball,s.field
    local pressers=findPressers(s)
    for _,p in ipairs(s.players) do
        if p~=s.controlled then
            local team=p.team
            local attack=team==1 and 1 or -1
            local d=dist(p,b)
            if p==pressers[team] then
                local px=b.x+b.vx*0.11-attack*1.5
                local py=b.y+b.vy*0.11
                toward(p,clamp(px,2,f.w-2),clamp(py,2,f.h-2),false)
                p.decision="press"
                if d < p.r+b.r+1.05 and p.cooldown<=0 then
                    local distanceToGoal=attack==1 and f.w-b.x or b.x
                    local mate,score=bestPass(s,p)
                    if distanceToGoal<28 and
                       openLane(s,b.x,b.y,attack==1 and f.w or 0,f.h/2,team)<8 then
                        if s.kick(p,attack==1 and f.w+4 or -4,f.h/2,1.0) then
                            p.decision="shoot"
                        end
                    elseif mate and score>-4 then
                        if s.kick(p,mate.x+mate.vx*0.22,mate.y+mate.vy*0.22,0.78) then
                            p.decision="pass"
                        end
                    else
                        if s.kick(p,b.x+attack*17,f.h/2,0.62) then
                            p.decision="advance"
                        end
                    end
                end
            else
                local x,y=anchor(s,p)
                if p.role=="GK" and d<8 then
                    x,y=b.x,b.y
                end
                toward(p,x,y,true)
                p.decision=p.role=="GK" and "goalkeeper" or
                    (s.lastTouch==team and "support" or "cover")
            end
        end
    end
end
return AI
