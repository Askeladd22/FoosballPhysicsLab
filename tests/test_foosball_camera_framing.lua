-- PAUL 35B: lock the GAMEPLAY composition to the user's ACTUAL
-- 1271x874 three-quarter screenshot, rather than an assumed overhead view.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local abs=math.abs
local function near(a,b,tol) return abs(a-b)<(tol or 1e-6) end
local windows={{900,650},{1271,874},{1280,850},{1650,895},{1920,1080}}
local match=Model.new()
local before={match.ball.x,match.ball.y,match.score[1],match.score[2],
             match.selected,match.rods[4].angle,match.rods[4].slide}

ThreeD.resetSceneYaw()
ThreeD.resetCamera()
assert(ThreeD.viewMode=="gameplay" and
       ThreeD.currentFovDegrees()==35 and ThreeD.sceneYaw==180)
-- Literal point projections of the 3/4 GAMEPLAY camera in the supplied
-- screenshot (1271x874, front, yaw180, zoom100%). This catches returning
-- to a zenithal/centred framing even if ordinary "fits within HUD" tests pass.
local anchors={
    {500,-4,280,635.5,429.2}, -- field centre
    {0,-4,0,339.6,252.2},
    {1000,-4,0,994.9,312.3},
    {0,-4,560,199.9,570.8},
    {1000,-4,560,1038.1,670.0},
    {0,-4,280,278.2,392.2}, -- left goal
    {1000,-4,280,1013.8,468.3}, -- right goal
}
for _,p in ipairs(anchors) do
    local x,y=ThreeD.project(p[1],p[2],p[3],1271,874)
    assert(x and y and near(x,p[4],1.2) and near(y,p[5],1.2),
        ("GAMEPLAY camera no longer matches the user's photo at %.0f,%.0f: %.1f,%.1f")
          :format(p[1],p[3],x or -1,y or -1))
end
local leftX,leftY=ThreeD.project(0,-4,0,1271,874)
local rightX,rightY=ThreeD.project(1000,-4,0,1271,874)
assert(rightY-leftY>45 and rightX-leftX>600,
    "3/4 reference must keep a noticeable oblique long-edge perspective")

for _,screen in ipairs(windows) do
    local w,h=screen[1],screen[2]
    local top,vh=ThreeD.viewport(w,h)
    for _,side in ipairs({"front","back"}) do
        ThreeD.resetCamera()
        if side=="back" then ThreeD.flipCamera() end
        local fit=math.max(1,1.60/(w/vh))
        local eye=ThreeD.cameraBasis(w,h)
        local sign=side=="front" and -1 or 1
        assert(near(eye[1],500-100*fit) and
               near(eye[2],10+1060*fit) and
               near(eye[3],280+sign*780*fit),
            "GAMEPLAY must keep the photographed 3/4 eye location")
        local tilt=math.deg(math.atan(1060/780))
        assert(tilt>=52 and tilt<=56,
            "photo is oblique, not an overhead camera")
        for _,yaw in ipairs({0,180}) do
            ThreeD.setSceneYaw(yaw)
            for _,point in ipairs({{40,-4,35},{960,-4,35},
                                   {40,-4,525},{960,-4,525}}) do
                local x,y=ThreeD.project(point[1],point[2],point[3],w,h)
                assert(x and y and x>8 and x<w-8
                    and y>top+8 and y<top+vh-8,
                    "photo-style GAMEPLAY clips the physical field")
            end
            local marker=ThreeD.ballIndicator(match,w,h)
            local lift=Model.Ramps.heightAt(match.ball.x,match.ball.y,
                Model.W,Model.H,Model.GOAL_HALF,match.ball.r)
            local x,y=ThreeD.project(match.ball.x,ThreeD.ballHeight+5+lift,
                match.ball.y,w,h)
            assert(marker.x and near(marker.x,x) and near(marker.y,y),
                "3/4 camera detached the ball marker")
            for _,foot in ipairs(ThreeD.playerIndicators(match,w,h).feet) do
                local px,py=ThreeD.project(foot.worldX,
                    ThreeD.ballHeight,foot.worldZ,w,h)
                assert(foot.x and near(foot.x,px) and near(foot.y,py),
                    "3/4 camera detached a foot marker")
            end
            -- F4 is genuinely different: preserve full upright furniture
            -- and the same 35-degree FOV in SHOWCASE without touching physics.
            assert(ThreeD.setViewMode("showcase")=="showcase")
            assert(ThreeD.currentFovDegrees()==35)
            local showcaseEye=ThreeD.cameraBasis(w,h)
            assert(near(showcaseEye[1],500-1012.35*fit)
                and near(showcaseEye[2],-305+2119.05*fit),
                "SHOWCASE framing changed")
            for _,p in ipairs({{0,0},{1000,0},{0,560},{1000,560}}) do
                local lx,ly=ThreeD.project(p[1],-740,p[2],w,h)
                assert(lx and lx>0 and lx<w and ly>top and ly<top+vh,
                    "SHOWCASE lost an original 3D support leg")
            end
            assert(ThreeD.toggleViewMode()=="gameplay")
            assert(ThreeD.currentFovDegrees()==35)
        end
    end
end
ThreeD.resetSceneYaw()
ThreeD.resetCamera()
assert(ThreeD.sceneYaw==180 and ThreeD.cameraSide=="front" and
       ThreeD.cameraDistance==1 and ThreeD.viewMode=="gameplay")
assert(near(match.ball.x,before[1]) and near(match.ball.y,before[2]) and
       match.score[1]==before[3] and match.score[2]==before[4] and
       match.selected==before[5] and near(match.rods[4].angle,before[6]) and
       near(match.rods[4].slide,before[7]),
       "camera reference verification altered game state")
print("PASS: user's screenshot 3/4 camera anchors, goal/field/foot markers, reversible F4 and yaw")
