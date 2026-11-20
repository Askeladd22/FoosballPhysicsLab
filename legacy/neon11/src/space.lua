-- Shared spatial evidence for decisions and off-ball movement.
local Space={}
local sqrt,min=math.sqrt,math.min

function Space.clearance(s,team,x,y)
    local gap=math.huge
    for _,other in ipairs(s.players) do
        if other.team~=team then
            gap=min(gap,sqrt((other.x-x)^2+(other.y-y)^2))
        end
    end
    return gap
end

function Space.laneRisk(s,ax,ay,bx,by,team)
    local dx,dy=bx-ax,by-ay
    local lengthSquared=dx*dx+dy*dy
    if lengthSquared<1 then return math.huge end
    local risk=0
    for _,other in ipairs(s.players) do
        if other.team~=team then
            local t=((other.x-ax)*dx+(other.y-ay)*dy)/lengthSquared
            -- Pressure behind the passer is not an interception ahead of him.
            -- Receiver pressure is measured independently with clearance.
            if t>0 and t<=1 then
                local gap=sqrt((other.x-ax-t*dx)^2+(other.y-ay-t*dy)^2)
                if gap<4.5 then risk=risk+(4.5-gap)*3 end
            end
        end
    end
    return risk
end

return Space
