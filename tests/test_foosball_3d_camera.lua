-- PAUL 27: the visible 3D table must fit across real window sizes.
-- Camera side/zoom changes must not touch physics, scores or rod targets.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local function close(a,b) return math.abs(a-b)<1e-7 end
local windows={{900,650},{1280,850},{1650,895},{1920,1080}}
local rim={
    {-106,130,-66},{1106,130,-66},
    {-106,130,626},{1106,130,626}
}
local physical=Model.new()
local ballX,ballY=physical.ball.x,physical.ball.y
local score1,score2=physical.score[1],physical.score[2]
ThreeD.resetCamera()
ThreeD.setViewMode("showcase")
-- This legacy test checks the CAMERA direction relative to unrotated source
-- coordinates. The new default is a separate 180° MODEL rotation: test the
-- source reference here, while test_foosball_world_yaw.lua covers the actual
-- rotated game and its selection-marker projection.
ThreeD.setSceneYaw(0)
assert(ThreeD.cameraSide=="front" and close(ThreeD.cameraDistance,0.78))
assert(close(ThreeD.fovDegrees,35),"default upright view fov unexpectedly changed")
assert(close(ThreeD.gameplayFovDegrees,43),
    "closer camera must not distort GAMEPLAY perspective via a new FOV")
for _,window in ipairs(windows) do
    local w,h=window[1],window[2]
    local top,vh=ThreeD.viewport(w,h)
    for _,side in ipairs({"front","back"}) do
        ThreeD.cameraSide=side
        local basisEye=ThreeD.cameraBasis(w,h)
        local targetZ=280
        if side=="front" then
            assert(basisEye[3]<targetZ,
                "default camera should view from the requested opposite edge")
        else
            assert(basisEye[3]>targetZ,"reverse-side camera has not moved")
        end
        for _,p in ipairs(rim) do
            local x,y=ThreeD.project(p[1],p[2],p[3],w,h)
            assert(x and x>=16 and x<=w-16,
                ("camera clipped board horizontally at %dx%d %s: x=%.1f"):format(w,h,side,x or -1))
            assert(y>=top+16 and y<=top+vh-16,
                ("camera clipped the raised board rim at %dx%d %s: y=%.1f"):format(w,h,side,y))
        end
        local _,near=ThreeD.project(500,0,0,w,h)
        local _,far=ThreeD.project(500,0,560,w,h)
        assert((side=="front" and near>far) or (side=="back" and far>near),
            "perspective field depth order did not flip with camera side")
        local cx,cy=ThreeD.project(500,10,280,w,h)
        assert(cx and cx>0 and cx<w and cy>top and cy<top+vh)
    end
end
ThreeD.resetCamera()
local function width()
    local x1=assert(ThreeD.project(0,0,0,1650,895))
    local x2=assert(ThreeD.project(1000,0,0,1650,895))
    return math.abs(x1-x2)
end
local normalWidth=width()
assert(ThreeD.zoomCamera(0.24)>1.0)
assert(width()<normalWidth,"PageDown (zoom out) did not reduce table size")
assert(ThreeD.zoomCamera(-0.48)<1)
assert(width()>normalWidth,"PageUp (zoom in) did not enlarge table")
ThreeD.zoomCamera(-99)
assert(close(ThreeD.cameraDistance,0.70),"minimum camera distance not clamped")
ThreeD.zoomCamera(99)
assert(close(ThreeD.cameraDistance,1.8),"maximum camera distance not clamped")
assert(ThreeD.flipCamera()=="back")
ThreeD.resetCamera()
assert(ThreeD.cameraSide=="front" and close(ThreeD.cameraDistance,0.78),
    "Home did not reset camera to safe view")
assert(physical.ball.x==ballX and physical.ball.y==ballY and
    physical.score[1]==score1 and physical.score[2]==score2,
    "camera changes altered gameplay")
ThreeD.resetSceneYaw()
assert(ThreeD.sceneYaw==180,"world yaw default was not restored")
ThreeD.resetCamera() -- restore the production default GAMEPLAY camera
assert(ThreeD.viewMode=="gameplay")
print("PASS: opposite default view, full board visibility in 4 resolutions, reversible camera and zoom")
