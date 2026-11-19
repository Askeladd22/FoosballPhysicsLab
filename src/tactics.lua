-- Tactical support for a five-a-side match, adapted from user-supplied HaxBall
-- positioning/off-ball principles. Entirely independent from love.graphics.
-- The team uses role-based starting positions, but rotates into space in play.
local Tactics={}
local abs,min,max,sqrt=math.abs,math.min,math.max,math.sqrt
local function clamp(x,a,b) return max(a,min(b,x)) end
local function distance(x,y,u,v)
    local dx,dy=x-u,y-v
    return sqrt(dx*dx+dy*dy)
end
function Tactics.phase(s,team)
    if s.lastTouch==team then return "attack" end
    if s.lastTouch==3-team then return "defend" end
    return "neutral"
end
-- A formation anchor is not an immutable position: it follows the ball while
-- keeping a defender behind it and midfielders in distinct passing lanes.
function Tactics.supportPoint(s,p)
    local b,f=s.ball,s.field
    local attack=p.team==1 and 1 or -1
    local phase=Tactics.phase(s,p.team)
    local mid=f.h/2
    local x,y=p.homeX,p.homeY
    if p.role=="GK" then
        x=p.team==1 and 5.3 or f.w-5.3
        y=clamp(mid+(b.y-mid)*0.34,14,f.h-14)
    elseif phase=="attack" then
        if p.role=="DF" then
            x=p.homeX*0.48+(b.x-attack*18)*0.52
            y=mid+(b.y-mid)*0.38
        elseif p.role=="LM" then
            x=b.x-attack*7
            y=b.y-15
        elseif p.role=="RM" then
            x=b.x-attack*7
            y=b.y+15
        elseif p.role=="ST" then
            x=b.x+attack*17
            y=b.y+(mid-b.y)*0.45
        end
    elseif phase=="defend" then
        if p.role=="DF" then
            x=b.x-attack*17
            y=mid+(b.y-mid)*0.43
        elseif p.role=="LM" then
            x=b.x-attack*10
            y=b.y-13
        elseif p.role=="RM" then
            x=b.x-attack*10
            y=b.y+13
        elseif p.role=="ST" then
            x=b.x+attack*7
            y=b.y+(mid-b.y)*0.35
        end
    else
        local dx=(b.x-f.w/2)*0.17
        local dy=(b.y-mid)*0.16
        x=p.homeX+dx-attack*1.8
        y=p.homeY+dy
    end

    x,y=clamp(x,4,f.w-4),clamp(y,7,f.h-7)

    -- The human can occupy any lane. AI must yield and rotate instead of
    -- chasing its fixed role slot or forcing the human out of position.
    local human=s.controlled
    if human and human.team==p.team and human~=p and p.role~="GK" then
        if distance(x,y,human.x,human.y)<9.5 then
            local options={
                {clamp(b.x-attack*15,5,f.w-5),clamp(b.y-14,8,f.h-8)},
                {clamp(b.x-attack*15,5,f.w-5),clamp(b.y+14,8,f.h-8)},
                {clamp(b.x+attack*6,5,f.w-5),clamp(mid+(b.y-mid)*0.2,8,f.h-8)}
            }
            local bestX,bestY,bestScore=x,y,-math.huge
            for _,option in ipairs(options) do
                local ox,oy=option[1],option[2]
                local separation=distance(ox,oy,human.x,human.y)
                local score=min(separation,24)-distance(ox,oy,x,y)*0.13
                if separation>=9.5 and score>bestScore then
                    bestX,bestY,bestScore=ox,oy,score
                end
            end
            if bestScore>-math.huge then x,y=bestX,bestY end
        end
    end
    return x,y,phase
end
-- Coordinate a team's off-ball destinations once per AI decision. These are
-- steering targets, never player teleports or an assignment for the human.
function Tactics.teamTargets(s,team)
    local targets,reserved,candidates={},{},{}
    local human=s.controlled
    if human.team==team then reserved[#reserved+1]={human.x,human.y} end
    local pass=s.activePass
    local receiver=pass and pass.team==team and pass.receiver
    if receiver then
        reserved[#reserved+1]={receiver.x,receiver.y}
        reserved[#reserved+1]={pass.targetX,pass.targetY}
    end
    -- While receiving, the original presser also returns to team support.
    local presser=not receiver and s.pressers[team] or nil
    for _,p in ipairs(s.players) do
        if p.team==team and p~=human and p~=receiver and p~=presser then
            candidates[#candidates+1]=p
        end
    end
    local guard
    for _,p in ipairs(candidates) do
        if p.role~="GK" and (not guard or
            (team==1 and p.x<guard.x) or (team==2 and p.x>guard.x)) then
            guard=p
        end
    end
    -- Reserve the covering player first, then assign distinct nearby outlets.
    table.sort(candidates,function(a,b)
        if a==guard then return b~=guard end
        if b==guard then return false end
        return a.number<b.number
    end)
    for _,p in ipairs(candidates) do
        local x,y=Tactics.supportPoint(s,p)
        local cover=p==guard
        if cover then
            if team==1 then x=min(x,clamp(s.ball.x-16,4,s.field.w-4))
            else x=max(x,clamp(s.ball.x+16,4,s.field.w-4)) end
        end
        if p.role~="GK" then
            local bestX,bestY,bestScore=x,y,-math.huge
            for ix=-2,2 do
                for iy=-3,3 do
                    local tx=clamp(x+ix*8,4,s.field.w-4)
                    local ty=clamp(y+iy*8,7,s.field.h-7)
                    if cover then
                        if team==1 then tx=min(tx,x) else tx=max(tx,x) end
                    end
                    local gap=math.huge
                    for _,point in ipairs(reserved) do
                        gap=min(gap,distance(tx,ty,point[1],point[2]))
                    end
                    local score=-distance(tx,ty,x,y)-max(0,8-gap)*100
                    if score>bestScore then bestX,bestY,bestScore=tx,ty,score end
                end
            end
            x,y=bestX,bestY
        end
        targets[p]={x=x,y=y,cover=cover}
        reserved[#reserved+1]={x,y}
    end
    return targets
end
return Tactics
