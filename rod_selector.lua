-- Pure-Lua contextual rod selector, no shooting or physical player automation.
-- The player always performs every slide/rotation via the mouse.
local S={}
local abs,min,max=math.abs,math.min,math.max
local function clamp(v,a,b) return max(a,min(b,v)) end
S.SWITCH_COOLDOWN=0.28
S.HYSTERESIS=32
S.GESTURE_HOLD=0.20
-- Separate small, continuous high-DPI mouse events from isolated pointer jitter.
S.MICRO_GESTURE_WINDOW=0.060
S.MICRO_GESTURE_DISTANCE=3
local W,H=1000,560
function S.cost(s,index)
    local r=s.rods[index]
    local b=s.ball
    local predictedX=clamp(b.x+b.vx*0.085,0,W)
    local predictedY=clamp(b.y+b.vy*0.065,0,H)
    local yError=math.huge
    for _,offset in ipairs(r.offsets) do
        local wanted=predictedY-H/2-offset
        local actual=H/2+offset+clamp(wanted,-r.travel,r.travel)
        yError=min(yError,abs(predictedY-actual))
    end
    -- Prediction + reachable lane. X dominates; Y nudges between close rods.
    return abs(predictedX-r.x)+yError*0.30
end
function S.best(s)
    local best,bestCost=1,math.huge
    for i=1,4 do
        local cost=S.cost(s,i)
        if cost<bestCost then best,bestCost=i,cost end
    end
    return best,bestCost
end
function S.update(s,force)
    if s.controlMode~="auto" or s.phase~="play" then return false end
    if not force then
        if s.clock<(s.controlHoldUntil or 0) then return false end
        if s.clock-(s.rodSwitchedAt or 0)<S.SWITCH_COOLDOWN then return false end
    end
    local target,cost=S.best(s)
    if target==s.selected then return false end
    local current=S.cost(s,s.selected)
    if not force and cost+S.HYSTERESIS>=current then return false end
    s.selected=target
    s.rodSwitchedAt=s.clock
    s.autoRodNotice={rod=target,expires=s.clock+0.75}
    return true
end
return S
