-- PAUL23: physical input-to-rod latency, impulse and no AI regression.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("model")
local dt=1/120
local s=M.new()
local r=s.rods[4]
assert(r.team==1)
local initAngle=r.angle
s:mouseMoved(90,70)
assert(r.angle==initAngle,"mouse callback must set targets, not teleport colliders")
local targetAngle,targetSlide=r.targetAngle,r.targetSlide
assert(targetAngle-initAngle>1.5 and targetSlide>45)
for i=1,12 do s:step(dt) end
assert(math.abs(r.angle-targetAngle)<0.12,
    "human rod should reach target within 100ms, not use a slow spring")
assert(math.abs(r.slide-targetSlide)<4,
    "human slide should catch up within 100ms")
assert(math.abs(r.omega)<=38+0.001 and math.abs(r.vy)<=1600+0.001,
    "human servo violated collision-safe velocity cap")
-- Make sure AI keeps separate, slower spring response.
s=M.new()
local human,ai=s.rods[4],s.rods[5]
s.aiClock=-100000 -- suppress tactic redecisions during this control comparison.
human.targetSlide=50
ai.targetSlide=50
for i=1,8 do s:step(dt) end
assert(human.slide>ai.slide+8,
    "AI must retain the original slower physical movement behaviour")
-- Actual mouse stroke is still a physical ball impact, not scripted velocity.
s=M.new()
local striker=s.rods[4]
for i=5,8 do s.rods[i].x=1500 end
s.aiClock=-100000
s.ball.x,s.ball.y=striker.x+38,M.H/2
s.ball.vx,s.ball.vy=0,0
s:mouseMoved(115,0)
local maxBallSpeed=0
for i=1,65 do
    s:step(dt)
    maxBallSpeed=math.max(maxBallSpeed,s.ball.vx)
end
assert(s.hits>0 and maxBallSpeed>35,"fast servo broke physical foot-ball impulse")
-- A series of small high-frequency mouse deltas is still a real gesture.
s=M.new()
s.clock=2
s.ball.x=430
s:mouseMoved(3,1)
assert(s.controlHoldUntil>s.clock,
    "AUTO switch lock did not detect small-but-intentional mouse gestures")
local selected=s.selected
s.clock=s.clock+0.06
assert(not s:autoUpdate() and s.selected==selected,
    "AUTO interrupted the middle of a mouse gesture")
-- Bumpers keep their physical stop behaviour even under a large swipe.
s=M.new()
r=s.rods[4]
for i=1,8 do s:mouseMoved(0,140) end
for i=1,60 do s:step(dt) end
assert(r.slide==r.travel and r.vy==0 and r.stopCount>=1,
    "high-response slide never touched mechanical end-stop")
print("PASS: low-latency mouse servo, bounded rod speed, AI inertia, physical hit and AUTO gesture hold")
