-- Contextual AUTO vs sticky manual selection. All rod impulses still come from mouse.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("model")
local Selector=require("rod_selector")
local s=M.new()
local dt=1/120
assert(s.selected==4 and s.controlMode=="auto","Foosball should default to AUTO attack")
local function setball(x,y,vx,vy)
    s.ball.x,s.ball.y=x,y or 280
    s.ball.vx,s.ball.vy=vx or 0,vy or 0
end
-- Ball crosses into midfield control zone; not before cooldown.
setball(440)
s.clock=0.10
assert(not s:autoUpdate() and s.selected==4,"startup cooldown failed")
s.clock=0.32
assert(s:autoUpdate() and s.selected==3,"AUTO did not choose midfield")
assert(not s:autoUpdate(),"same-frame repeated selection")
-- Hysteresis: a boundary position should not thrash back and forth.
s.clock=1.0
setball(570)
assert(s.selected==3 and not s:autoUpdate(),"hysteresis boundary thrash")
-- A clear attacker location must win when ball enters the right zone.
setball(745)
assert(s:autoUpdate() and s.selected==4,"AUTO failed to return to attack")
-- Deliberate mouse gestures must not hand control to another rod mid-stroke.
setball(195)
s:mouseMoved(36,5)
assert(s.controlHoldUntil>s.clock)
s.clock=s.clock+0.08
assert(not s:autoUpdate() and s.selected==4,"swipe lost control")
s.clock=s.controlHoldUntil+0.3
assert(s:autoUpdate() and s.selected==2,"selector did not resume after swipe")
-- Manual: one key/wheel selection stays in place even if ball travels.
assert(s:selectRod(1) and s.controlMode=="manual" and s.selected==1)
setball(730)
s.clock=s.clock+2
for _=1,5 do assert(not s:autoUpdate() and s.selected==1) end
assert(s:toggleAutoRod()=="auto" and s.selected==4,
    "TAB should restore context-aware selection immediately")
assert(s:toggleAutoRod()=="manual" and s.selected==4)
assert(s:selectRod(3) and s.selected==3)
assert(s:toggleAutoRod()=="auto")
-- No switching during goals/replays, and no control of opponent rods.
s.phase="goal"
setball(80)
s.clock=s.clock+2
assert(not s:autoUpdate(),"selection changed during goal")
s.phase="play"
s:reset()
assert(s.controlMode=="auto" and s.selected==4,"reset must restore intuitive AUTO")
for _,x in ipairs({5,80,180,288,430,570,710,880,995}) do
    setball(x)
    local target,cost=Selector.best(s)
    assert(target>=1 and target<=4 and cost>=0 and cost<3000,"invalid rod prediction")
end
print("PASS: default AUTO, midfield/attack switches, hysteresis, swipe lock, manual mode and reset")
