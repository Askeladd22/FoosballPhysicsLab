-- Dead-ball corner organisation. The live ball still travels on the ground;
-- this module arranges alternating near/far-post deliveries and defensive cover.
local Corners={}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end

function Corners.prepare(s,spec)
    if not spec or spec.kind~="corner" or spec.cornerPrepared then return end
    local f,b=s.field,s.ball
    local near=b.y<f.h/2 and -1 or 1
    local mid=f.h/2
    if not s.cornerSequence or s.restartCount==1 then s.cornerSequence={0,0} end
    s.cornerSequence[spec.team]=s.cornerSequence[spec.team]+1
    local farDelivery=s.cornerSequence[spec.team]%2==0
    spec.routine=farDelivery and "far_post" or "near_post"
    -- Keep the strikers in the box. The generic nearest-player restart often
    -- picked a striker, leaving nobody to attack one of the two posts.
    local wide,bestCost=nil,math.huge
    for _,p in ipairs(s.players) do
        if p.team==spec.team and p~=s.controlled and
            (p.role=="LM" or p.role=="RM" or p.role=="FB") then
            local cost=(p.x-b.x)^2+(p.y-b.y)^2
            if cost<bestCost then wide,bestCost=p,cost end
        end
    end
    if wide then spec.taker=wide end
    local function worldX(depth)
        return spec.side=="left" and depth or f.w-depth
    end
    -- Depth is distance from the attacked goal, y is relative to its centre.
    local attacking={
        [1]={f.w-6,0}, [4]={42,-12}, [5]={42,12},
        [3]={29,-17}, [2]={29,17},
        [6]={20,-7}, [7]={21,7},
        [8]={9,near*(mid-14)}, [10]={21,near*20},
        [9]={farDelivery and 5.5 or 8.5,near*4}, [11]={10.5,-near*5}
    }
    local defending={
        [1]={2.8,near*1.2}, [4]={farDelivery and 2.3 or 5.3,near*4}, [5]={7.3,-near*5},
        [3]={2.8,near*8.5}, [2]={8.7,-near*10},
        [6]={16.5,-8}, [7]={16.5,8},
        [8]={13,near*16}, [10]={24,near*17},
        [9]={32,-8}, [11]={40,8}
    }
    local receiver
    local priorities=farDelivery and {11,9,6,7,8,10,4,5,3,2} or {9,11,6,7,8,10,4,5,3,2}
    for _,number in ipairs(priorities) do
        for _,p in ipairs(s.players) do
            if p.team==spec.team and p~=spec.taker and p.number==number then
                receiver=p; break
            end
        end
        if receiver then break end
    end
    if not receiver then return end
    spec.cornerPrepared=true
    for _,p in ipairs(s.players) do
        p.vx,p.vy,p.moveX,p.moveY=0,0,0,0
        p.sprinting=false
        if p~=spec.taker then
            local slots=p.team==spec.team and attacking or defending
            local slot=slots[p.number]
            if slot then
                local depth,offset=slot[1],slot[2]
                if p==receiver then
                    depth=farDelivery and 10.5 or 8.5
                    offset=farDelivery and -near*5 or near*4
                end
                p.x=clamp(worldX(depth),p.r,f.w-p.r)
                p.y=clamp(mid+offset,p.r,f.h-p.r)
                p.targetX,p.targetY=p.x,p.y
                p.decision=p.team==spec.team and "corner_attack" or "corner_mark"
            end
        end
    end
    spec.receiver=receiver
    spec.targetX,spec.targetY=receiver.x,receiver.y
    local dx,dy=receiver.x-b.x,receiver.y-b.y
    local distance=math.sqrt(dx*dx+dy*dy)
    local gap=spec.taker.r+b.r+0.48
    spec.taker.x=b.x-dx/distance*gap
    spec.taker.y=b.y-dy/distance*gap
    spec.taker.targetX,spec.taker.targetY=spec.taker.x,spec.taker.y
    spec.taker.cooldown=0
    spec.taker.decision="corner_taker"
end

return Corners
