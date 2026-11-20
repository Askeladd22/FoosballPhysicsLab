-- PAUL 34: real anti-dead-zone low slopes, no scripted impulses.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("model")
local R=require("ramps")
local W,H,G=M.W,M.H,M.GOAL_HALF
local dt=1/120
local function near(a,b,tol) return math.abs(a-b)<(tol or 1e-7) end
local function newBall(x,y)
    local s=M.new()
    s.ball.x,s.ball.y=x,y
    s.ball.vx,s.ball.vy=0,0
    s.aiClock=-100000 -- avoid AI player contact during isolated floor checks
    return s
end
local function step(s,n)
    for _=1,n do s:step(dt) end
end

assert(R.DEPTH>0 and R.DEPTH<60 and R.HEIGHT>0)
local sections=R.sections(W,H,G,M.BALL_RADIUS)
assert(#sections==6,"expected 2 long ramps + 4 goal-side segments")
for _,v in ipairs(sections) do
    assert(v.x1>v.x0 and v.y1>v.y0,"invalid ramp footprint")
    if v.edge=="left" or v.edge=="right" then
        assert(v.y1<=H/2-G-M.BALL_RADIUS or v.y0>=H/2+G+M.BALL_RADIUS,
            "short-end ramp blocks the goal mouth")
    end
end

-- The ball should wake from rest (two microsteps/sim) and roll INWARD.
local s=newBall(500,12)
local x,y=s.ball.x,s.ball.y
step(s,120)
assert(near(s.ball.x,x,0.01) and s.ball.y>y+15,
    "top rail did not roll a stationary ball into play")
assert(s.deadBallCount==0,"side ramp caused an unwanted dead-ball restart")

s=newBall(500,H-12)
step(s,120)
assert(s.ball.y<H-27 and near(s.ball.x,500,0.01),
    "bottom rail did not return a stationary ball into play")

-- End-wall pads near each goal are outside the actual goal opening.
s=newBall(12,128)
step(s,120)
assert(s.ball.x>27 and near(s.ball.y,128,0.01),
    "left goal-side ramp did not move a ball away from the end wall")
s=newBall(W-12,H-128)
step(s,120)
assert(s.ball.x<W-27 and near(s.ball.y,H-128,0.01),
    "right goal-side ramp did not move a ball inward")

-- Four corners: ramp heights/accelerations combine on both axes.
for _,point in ipairs({
    {16,16,1,1},{W-16,16,-1,1},
    {16,H-16,1,-1},{W-16,H-16,-1,-1}
}) do
    local px,py,sx,sy=point[1],point[2],point[3],point[4]
    local b={x=px,y=py,r=M.BALL_RADIUS}
    local ax,ay=R.acceleration(b,W,H,G)
    assert(ax*sx>0 and ay*sy>0,"corner lacks diagonal recovery")
    local cornerHeight=R.heightAt(px,py,W,H,G,b.r)
    local longSideOnly=R.heightAt(W/2,py,W,H,G,b.r)
    local shortEndOnly=R.heightAt(px,H/2-G-b.r-R.GOAL_TAPER-20,
        W,H,G,b.r)
    assert(cornerHeight>longSideOnly+0.2 and cornerHeight>shortEndOnly+0.2,
        "corner is not raised above each individual side slope")
    s=newBall(px,py)
    step(s,90)
    assert((s.ball.x-px)*sx>9 and (s.ball.y-py)*sy>9,
        "corner slope left a stationary ball trapped")
    assert(s.score[1]==0 and s.score[2]==0 and s.deadBallCount==0,
        "corner recovery awarded an artificial goal or neutral serve")
end

-- The centre and both goal channels stay flat/neutral, including goal-line.
for _,p in ipairs({{500,H/2},{16,H/2},{W-16,H/2},
    {W+12,H/2},{-12,H/2},{400,H/2}}) do
    local ax,ay=R.acceleration({x=p[1],y=p[2],r=M.BALL_RADIUS},W,H,G)
    assert(ax==0 and ay==0 and R.heightAt(p[1],p[2],W,H,G,M.BALL_RADIUS)==0,
        "ramp physics obstructed the centre or goal channel")
end
s=newBall(500,H/2)
step(s,90)
assert(near(s.ball.x,500) and near(s.ball.y,H/2),
    "flat central area injected movement into a stationary ball")
-- Goals in both directions remain awarded as before.
s=newBall(W+M.BALL_RADIUS+4,H/2)
s:step(dt)
assert(s.score[1]==1 and s.phase=="goal","right goal blocked by ramp")
s=newBall(-M.BALL_RADIUS-4,H/2)
s:step(dt)
assert(s.score[2]==1 and s.phase=="goal","left goal blocked by ramp")

-- Native 3D vertices are a single coherent, finite, elevated floor profile,
-- with NO quads or vertices obstructing either goal opening.
local verts=R.meshVertices(W,H,G,M.BALL_RADIUS,7.2)
assert(#verts>100 and #verts%3==0,"missing ramp triangle mesh")
local elevated=false
for _,v in ipairs(verts) do
    assert(#v==10 and v[2]>=7.2 and v[2]<=7.2+2*R.HEIGHT+1e-5,
        "invalid GPU ramp height or vertex format")
    assert(v[4]==v[4] and v[5]>0 and v[6]==v[6],
        "invalid ramp normal")
    if v[2]>7.2+0.1 then elevated=true end
    if (v[1]<=R.DEPTH or v[1]>=W-R.DEPTH) and
       v[3]>H/2-G-M.BALL_RADIUS and v[3]<H/2+G+M.BALL_RADIUS then
        error("3D ramp geometry crosses a goal mouth")
    end
end
assert(elevated,"3D ramps are a flat overlay, not a real tilted surface")

-- Determinism under the unchanged fixed 120Hz outer simulation.
local function snapshot()
    local state=newBall(13,14)
    step(state,108)
    return {state.ball.x,state.ball.y,state.ball.vx,state.ball.vy,
            state.hits,state.deadBallCount}
end
local a,b=snapshot(),snapshot()
for i=1,#a do assert(near(a[i],b[i]),"ramp simulation not deterministic") end
print("PASS: side/end ramps, all corners, neutral goal channels, true 3D slope and determinism")
