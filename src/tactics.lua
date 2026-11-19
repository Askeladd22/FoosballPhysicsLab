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
return Tactics
