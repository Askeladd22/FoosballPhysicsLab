-- PAUL phase 28: rigid 180-degree yaw must rotate the actual 3D WORLD
-- (table, eight rods, ball and selection marker), never the match physics.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local function same(a,b) return math.abs(a-b)<1e-6 end
assert(ThreeD.sceneYaw==180,"180-degree scene turn must be default")
local sample={
    {0,0,0,1000,0,560},
    {1000,130,560,0,130,0},
    {500,50,280,500,50,280},
    {100,15,50,900,15,510},
    {372,42,499,628,42,61},
}
for _,p in ipairs(sample) do
    local x,y,z=ThreeD.worldPoint(p[1],p[2],p[3])
    assert(same(x,p[4]) and same(y,p[5]) and same(z,p[6]),
        "incorrect 180-degree rigid yaw around board center")
end
local sim=Model.new()
local rods={}
for i,r in ipairs(sim.rods) do
    rods[i]={r.x,r.slide,r.angle,r.vy,r.omega}
end
local ball={sim.ball.x,sim.ball.y,sim.ball.vx,sim.ball.vy}
local wins={{900,650},{1280,850},{1650,895},{1920,1080}}
for _,size in ipairs(wins) do
    local w,h=size[1],size[2]
    for _,point in ipairs(sample) do
        ThreeD.setSceneYaw(180)
        local sx,sy=ThreeD.project(point[1],point[2],point[3],w,h)
        ThreeD.setSceneYaw(0)
        local mirrorX,mirrorY=ThreeD.project(
            point[4],point[5],point[6],w,h)
        assert(sx and mirrorX and same(sx,mirrorX) and same(sy,mirrorY),
            "CPU selection-marker projection does not match GPU world yaw")
    end
end
ThreeD.setSceneYaw(180)
for i,r in ipairs(sim.rods) do
    local p=rods[i]
    local x,y,z=ThreeD.worldPoint(r.x,ThreeD.axisHeight,280+r.slide)
    assert(same(x,1000-r.x) and same(y,ThreeD.axisHeight)
        and same(z,280-r.slide),"physical rod slide not mirrored in scene")
    assert(r.x==p[1] and r.slide==p[2] and r.angle==p[3]
        and r.vy==p[4] and r.omega==p[5],
        "rendering orientation modified a physical rod")
end
local bx,by,bz=ThreeD.worldPoint(sim.ball.x,10,sim.ball.y)
assert(same(bx,1000-sim.ball.x) and same(by,10)
    and same(bz,560-sim.ball.y),"physical ball not rotated with table")
assert(sim.ball.x==ball[1] and sim.ball.y==ball[2]
    and sim.ball.vx==ball[3] and sim.ball.vy==ball[4],
    "renderer rotation changed the simulated ball")
assert(ThreeD.toggleSceneYaw()==0)
assert(ThreeD.toggleSceneYaw()==180)
local ok=pcall(ThreeD.setSceneYaw,90)
assert(not ok,"unimplemented camera angles must be rejected")
assert(ThreeD.resetSceneYaw()==180)
print("PASS: real 180-degree board yaw, ball/rig/selection sync and unchanged physics")
