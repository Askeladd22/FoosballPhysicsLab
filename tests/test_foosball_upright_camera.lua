-- PAUL 30 — A foosball TABLE requires visible downward legs, not just green pixels.
-- Compare real imported GLB geometry: field Y=-4, four supports down to Y=-740.
-- This test protects perspective of the FULL OBJECT in all normal window sizes.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local sim=Model.new()
local function eq(a,b) return math.abs(a-b)<1e-6 end
local ball={sim.ball.x,sim.ball.y,sim.ball.vx,sim.ball.vy}
assert(ThreeD.sceneYaw==180,"keep the user's 180-degree horizontal table orientation")
assert(ThreeD.fovDegrees==35,"calibrated full-object camera FOV changed")
assert(ThreeD.cameraSide=="front")
ThreeD.resetCamera()

for _,size in ipairs({{900,650},{1280,850},{1650,895},{1920,1080}}) do
    local w,h=size[1],size[2]
    local top,vh=ThreeD.viewport(w,h)
    for _,side in ipairs({"front","back"}) do
        ThreeD.cameraSide=side
        local eye=ThreeD.cameraBasis(w,h)
        local targetY=-305
        local elev=eye[2]-targetY
        local horizontal=math.sqrt((eye[1]-500)^2+(eye[3]-280)^2)
        local pitch=math.deg(math.atan(elev/horizontal))
        assert(pitch>39 and pitch<55,
            "camera became top-down or near-horizontal: table legs unreadable")
        assert(eye[2]>1000 and eye[2]<3000,"camera eye Y out of bounds")
        local fullRim={{-106,130,-66},{1106,130,-66},
                       {-106,130,626},{1106,130,626}}
        for _,pt in ipairs(fullRim) do
            local x,y=ThreeD.project(pt[1],pt[2],pt[3],w,h)
            assert(x and x>10 and x<w-10 and y>top+10 and y<top+vh-10,
                ("top rim clipped at %dx%d / %s"):format(w,h,side))
        end
        local fieldPoints={{75,-4,75},{925,-4,75},
                           {75,-4,485},{925,-4,485},{500,-4,280}}
        for _,p in ipairs(fieldPoints) do
            local x,y=ThreeD.project(p[1],p[2],p[3],w,h)
            assert(x and x>10 and x<w-10 and y>top+10 and y<top+vh-10,
                "playing field out of viewport")
        end
        local feet={{0,0},{0,560},{1000,0},{1000,560}}
        for _,pt in ipairs(feet) do
            local x,y=ThreeD.project(pt[1],-740,pt[2],w,h)
            local xx,fieldY=ThreeD.project(pt[1],-4,pt[2],w,h)
            assert(x and xx and x>10 and x<w-10 and
                y>top+10 and y<top+vh-10,
                ("one of FOUR actual legs is off-screen at %dx%d %s"):format(w,h,side))
            assert(y>fieldY+20,
                "leg bottom is not visually BELOW the tabletop in the 3D view")
        end
    end
end
ThreeD.resetCamera()
assert(ThreeD.sceneYaw==180 and ThreeD.cameraSide=="front")
assert(eq(sim.ball.x,ball[1]) and eq(sim.ball.y,ball[2]) and
    eq(sim.ball.vx,ball[3]) and eq(sim.ball.vy,ball[4]),
    "camera change altered physics")
print("PASS: actual 3D board four support FEET BELOW field in 4 viewports and 2 sides")
