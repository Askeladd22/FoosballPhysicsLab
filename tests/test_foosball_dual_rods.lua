-- PAUL 37: one physical mouse controls defence (2) and attack (4)
-- simultaneously without stealing AUTO, teleporting or touching opponent AI.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("model")
local ThreeD=require("renderer3d")
local dt=1/120
local function near(a,b,tol) return math.abs(a-b)<(tol or 0.01) end
local s=M.new()
assert(s.controlMode=="auto" and s.selected==4)
assert(#M.DUAL_RODS==2 and M.DUAL_RODS[1]==2 and M.DUAL_RODS[2]==4)
assert(s:isRodControlled(4) and not s:isRodControlled(2))
local r2,r4=s.rods[2],s.rods[4]
local untouched={s.rods[1].targetSlide,s.rods[3].targetAngle,
                 s.rods[5].targetSlide,s.rods[8].targetAngle,
                 s.ball.x,s.ball.y,s.score[1],s.score[2]}
assert(s:toggleDualRod()=="dual" and s.selected==4)
assert(s:isRodControlled(2) and s:isRodControlled(4)
    and not s:isRodControlled(1) and not s:isRodControlled(3)
    and not s:isRodControlled(5))
local x2,x4=r2.angle,r4.angle
s.clock=4
s.ball.x=185
assert(not s:autoUpdate() and s.selected==4,
    "contextual AUTO must not steal a rod in dual mode")
-- One mouse packet must set two independent physical targets.
s:mouseMoved(40,70)
assert(near(r2.targetSlide,58.1) and near(r4.targetSlide,58.1),
    "mouse Y did not simultaneously target both rods")
assert(r2.targetAngle>x2 and r4.targetAngle>x4,
    "mouse X did not rotate defence and attack together")
assert(near(r2.angle,x2) and near(r4.angle,x4),
    "mouse events must never teleport rod collision geometry")
assert(s.rods[1].targetSlide==untouched[1] and
    s.rods[3].targetAngle==untouched[2] and
    s.rods[5].targetSlide==untouched[3] and
    s.rods[8].targetAngle==untouched[4],
    "dual mouse input touched goalkeeper/midfield/opponent")
assert(near(s.ball.y,untouched[6]) and
    s.score[1]==untouched[7] and s.score[2]==untouched[8],
    "entering dual mode modified scoring or ball position")
s.aiClock=-100000
for _=1,12 do s:step(dt) end
assert(r2.slide>34 and r4.slide>34 and
    math.abs(r2.angle-x2)>0.3 and math.abs(r4.angle-x4)>0.3,
    "both controlled rods must move through the physical 120Hz servos")
assert(math.abs(r2.vy)<=1600.01 and math.abs(r4.vy)<=1600.01 and
    math.abs(r2.omega)<=38.01 and math.abs(r4.omega)<=38.01,
    "dual mode violated servo speed caps")
-- Both shafts have their own clamps; the defence can travel farther than
-- attack, and neither one inherits its partner's stop events.
for _=1,6 do s:mouseMoved(0,140) end
for _=1,90 do s:step(dt) end
assert(near(r2.slide,r2.travel) and near(r4.slide,r4.travel)
       and r2.travel~=r4.travel and r2.stopCount>=1 and r4.stopCount>=1,
    "dual mode merged mechanical stop or travel limits")
r2.targetAngle,r4.targetAngle=0.8,-0.5
s:neutralRod()
assert(r2.targetAngle==0 and r4.targetAngle==0,
    "C must neutralize both physical rods in dual mode")
local defenceMarkers=ThreeD.playerIndicators(s,1277,878,2)
local attackMarkers=ThreeD.playerIndicators(s,1277,878,4)
assert(#defenceMarkers.feet==2 and #attackMarkers.feet==3)
for _,entry in ipairs({{defenceMarkers,2},{attackMarkers,4}}) do
    for i,foot in ipairs(entry[1].feet) do
        local fx,fy=M.foot(s.rods[entry[2]],i)
        local px,py=ThreeD.project(fx,ThreeD.ballHeight,fy,1277,878)
        assert(near(foot.worldX,fx) and near(foot.worldZ,fy)
            and near(foot.x,px) and near(foot.y,py),
            "3D dual highlight does not track the physical striking foot")
    end
end
-- D restores previous AUTO mode, not stale targets or a permanent lock.
assert(s:toggleDualRod()=="auto")
assert(s.selected==2 and s:isRodControlled(2) and not s:isRodControlled(4),
    "D failed to restore contextual AUTO near defence")
assert(s:selectRod(1) and s.controlMode=="manual")
assert(s:toggleDualRod()=="dual")
assert(s:toggleDualRod()=="manual" and s.selected==1,
    "D must restore previous manual slot, not hardcoded attack")
assert(s:toggleDualRod()=="dual")
assert(s:selectRod(3) and s.controlMode=="manual"
       and s.selected==3 and not s:isRodControlled(2),
    "number/scroll selection must exit dual mode into manual")
assert(s:toggleDualRod()=="dual")
assert(s:toggleAutoRod()=="auto" and s.controlMode=="auto",
    "TAB must leave dual mode for contextual AUTO")
s:reset()
assert(s.controlMode=="auto" and not s.dualPreviousMode and
    not s.dualPreviousSelected and not s:isRodControlled(2),
    "reset leaked dual mode or the previous slot")
-- A dual controlled attack shot is still a foot collision, no scripted goal.
s=M.new()
s.aiClock=-100000
for i=5,8 do s.rods[i].x=1500 end
s.ball.x,s.ball.y=s.rods[4].x+38,M.H/2
s.ball.vx,s.ball.vy=0,0
assert(s:toggleDualRod()=="dual")
s:mouseMoved(115,0)
local fastest=0
for _=1,65 do
    s:step(dt)
    fastest=math.max(fastest,s.ball.vx)
end
assert(s.hits>0 and fastest>35 and s.lastHit and s.lastHit.team==1,
    "dual attack did not produce a real ball-foot impact")
print("PASS: D dual defence/attack input, physical limits, F2/3D markers, AUTO/manual/reset, real collision")
