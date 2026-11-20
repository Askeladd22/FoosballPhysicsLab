-- PAUL29 / SEED: a truly upright field, NOT a false 180° X/Z flip.
-- Camera is steep enough to clear the near frame (Y≈130) at every supported
-- viewport; the old shallow angle visually hid the playing field.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local sim=Model.new()
local function eq(a,b) return math.abs(a-b)<1e-6 end
local before={sim.ball.x,sim.ball.y,sim.ball.vx,sim.ball.vy}
assert(ThreeD.sceneYaw==180,"user-requested Y-axis 180° orientation was lost")
assert(ThreeD.fovDegrees<=36,"upright game camera must fill viewport without flat shearing")
for _,screen in ipairs({{900,650},{1280,850},{1650,895},{1920,1080}}) do
  local w,h=screen[1],screen[2]
  local top,vh=ThreeD.viewport(w,h)
  for _,side in ipairs({"front","back"}) do
    ThreeD.cameraSide=side
    local eye=ThreeD.cameraBasis(w,h)
    local elev=eye[2]-15
    local offset=math.abs(eye[3]-280)
    assert(elev>950 and math.deg(math.atan(elev/offset))>75,
        "camera still looks sideways into rail, hiding the field")
    -- Eye Z must be *inside* the raised side rails while projecting
    -- the pitch from above, not behind the near wooden wall.
    assert(eye[3]>-66 and eye[3]<626,
        "camera should look over the field rather than through near rail")
    for _,p in ipairs({{100,-4,80},{900,-4,80},
                         {100,-4,480},{900,-4,480},
                         {500,-4,280}}) do
       local x,y=ThreeD.project(p[1],p[2],p[3],w,h)
       assert(x and x>0 and x<w and y>top and y<top+vh,
          "physically upper playing field clipped outside viewport")
    end
  end
end
ThreeD.resetCamera()
assert(ThreeD.sceneYaw==180 and ThreeD.cameraSide=="front")
assert(eq(sim.ball.x,before[1]) and eq(sim.ball.y,before[2])
   and eq(sim.ball.vx,before[3]) and eq(sim.ball.vy,before[4]),
   "camera presentation touched authoritative ball physics")
print("PASS: true Y-up high camera, no near-rail sightline, complete playfield and physics unchanged")
