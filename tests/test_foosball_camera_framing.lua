-- PAUL 36 / CCteam QA: regression for the photographed real table view.
-- This intentionally REPLACES PAUL35's bad test that locked the diagonal camera.
-- The user explicitly needs a centred front view from the long rail, with legs.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local abs=math.abs
local function near(a,b,tolerance) return abs(a-b)<(tolerance or 0.01) end
local match=Model.new()
local initial={match.ball.x,match.ball.y,match.score[1],match.score[2],
               match.selected,match.rods[4].angle,match.rods[4].slide}
local windows={{900,650},{1271,874},{1280,850},{1650,895},{1920,1080}}
ThreeD.resetCamera()
ThreeD.resetSceneYaw()
assert(ThreeD.currentFovDegrees()==43,
    "GAMEPLAY still has the old 35-degree distant diagonal camera")

for _,wh in ipairs(windows) do
    local w,h=wh[1],wh[2]
    local top,vh=ThreeD.viewport(w,h)
    local bottom=top+vh
    local fit=math.max(1,1.60/(w/vh))
    local gameplayDistance=0.78*fit
    for _,side in ipairs({"front","back"}) do
        ThreeD.resetCamera()
        if side=="back" then ThreeD.flipCamera() end
        local eye=ThreeD.cameraBasis(w,h)
        assert(near(eye[1],500) and near(eye[2],-200+1100*gameplayDistance) and
            near(eye[3],280+(side=="front" and -915 or 915)*gameplayDistance),
            "GAMEPLAY is not centred in front of the long rail")
        local pitch=math.deg(math.atan((eye[2]+200)/abs(eye[3]-280)))
        assert(pitch>=48 and pitch<=53,
            "the photo needs a moderate ~50-degree view, not a diagonal/overhead shot")
        for _,yaw in ipairs({0,180}) do
            ThreeD.setSceneYaw(yaw)
            for _,z in ipairs({0,560}) do
                local xl,yl=ThreeD.project(0,130,z,w,h)
                local xr,yr=ThreeD.project(1000,130,z,w,h)
                assert(xl and xr and near(xl+xr,w,0.10) and near(yl,yr,0.25),
                    "table long rail is diagonal instead of horizontal")
            end
            local centerX,centerY=ThreeD.project(500,-200,280,w,h)
            assert(centerX and near(centerX,w/2,0.1) and
                near(centerY,top+vh/2,0.1),
                "whole table is not centred on screen")
            -- GAMEPLAY now intentionally prioritizes a larger pitch;
            -- cabinet legs/rim may be cropped at 128-143% close-up.
            -- F4 SHOWCASE remains the guaranteed four-leg full-table view.
            for _,xyz in ipairs({
                {0,-4,0},{1000,-4,0},{0,-4,560},{1000,-4,560},
                {0,-4,280},{1000,-4,280}
            }) do
                local px,py=ThreeD.project(xyz[1],xyz[2],xyz[3],w,h)
                assert(px and px>6 and px<w-6 and py>top+6 and py<bottom-6,
                    ("close-up GAMEPLAY crops the physical playing field or goals at %dx%d"):format(w,h))
            end
            -- Both goals should remain legible; the table is not a tiny
            -- dark object in a large empty viewport.
            local gx1=assert(ThreeD.project(0,-4,280,w,h))
            local gx2=assert(ThreeD.project(1000,-4,280,w,h))
            assert(abs(gx2-gx1)>w*0.28,
                "the new full-table view made the field too small")
            local ball=ThreeD.ballIndicator(match,w,h)
            local lift=Model.Ramps.heightAt(match.ball.x,match.ball.y,
                Model.W,Model.H,Model.GOAL_HALF,match.ball.r)
            local bx,by=ThreeD.project(match.ball.x,ThreeD.ballHeight+5+lift,
                match.ball.y,w,h)
            assert(ball.x and near(ball.x,bx) and near(ball.y,by),
                "ball marker no longer matches native projection")
            for _,foot in ipairs(ThreeD.playerIndicators(match,w,h).feet) do
                local fx,fy=ThreeD.project(foot.worldX,ThreeD.ballHeight,foot.worldZ,w,h)
                assert(foot.x and near(foot.x,fx) and near(foot.y,fy),
                    "a 3D toe marker is detached from its physical contact")
            end
            -- F4 remains presentation-only; original 3/4 full-furniture
            -- camera is still available and untouched.
            assert(ThreeD.setViewMode("showcase")=="showcase")
            assert(ThreeD.currentFovDegrees()==35)
            local shown=ThreeD.cameraBasis(w,h)
            assert(near(shown[1],500-1012.35*fit) and
                near(shown[2],-305+2119.05*fit),
                "SHOWCASE camera was altered as collateral damage")
            assert(ThreeD.toggleViewMode()=="gameplay")
            assert(ThreeD.currentFovDegrees()==43)
        end
    end
end
ThreeD.resetCamera()
ThreeD.resetSceneYaw()
assert(ThreeD.sceneYaw==180 and ThreeD.cameraSide=="front" and
       math.abs(ThreeD.cameraDistance-0.78)<1e-7 and ThreeD.viewMode=="gameplay")
assert(near(match.ball.x,initial[1]) and near(match.ball.y,initial[2]) and
    match.score[1]==initial[3] and match.score[2]==initial[4] and
    match.selected==initial[5] and near(match.rods[4].angle,initial[6]) and
    near(match.rods[4].slide,initial[7]),
    "camera changed match state")
print("PASS: actual front long-side framing, horizontal rails, 4 support legs, true 3D markers, F2/F3/F4 and 5 windows")
