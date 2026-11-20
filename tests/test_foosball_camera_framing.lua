-- PAUL 35: the 3D gameplay camera must privilege physical contacts
-- over the whole furniture display, independently of window and world yaw.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local abs,sqrt=math.abs,math.sqrt
local function near(a,b,tol) return abs(a-b)<(tol or 1e-6) end
local windows={{900,650},{1271,874},{1280,850},{1650,895},{1920,1080}}
local s=Model.new()
local initial={s.ball.x,s.ball.y,s.score[1],s.score[2],s.selected}
ThreeD.resetSceneYaw()
ThreeD.resetCamera()
assert(ThreeD.currentFovDegrees()==33,
    "GAMEPLAY must use its dedicated field-readable 33-degree FOV")
assert(ThreeD.fovDegrees==35,
    "do not silently alter the showroom camera FOV")

for _,wh in ipairs(windows) do
    local w,h=wh[1],wh[2]
    local top,vh=ThreeD.viewport(w,h)
    for _,side in ipairs({"front","back"}) do
        ThreeD.resetCamera()
        if side=="back" then assert(ThreeD.flipCamera()=="back") end
        ThreeD.setViewMode("showcase")
        assert(ThreeD.currentFovDegrees()==35)
        local showEye=ThreeD.cameraBasis(w,h)
        local fit=math.max(1,1.60/(w/vh))
        assert(near(showEye[1],500-1012.35*fit) and
               near(showEye[2],-305+2119.05*fit),
               "SHOWCASE must retain its previously verified eye/target")
        for _,yaw in ipairs({0,180}) do
            ThreeD.setSceneYaw(yaw)
            -- The four actual support legs are a showroom feature.
            for _,leg in ipairs({{0,0},{1000,0},{0,560},{1000,560}}) do
                local px,py=ThreeD.project(leg[1],-740,leg[2],w,h)
                assert(px and px>0 and px<w and py>top and py<top+vh,
                    "SHOWCASE crop of original 3D support legs")
            end
            ThreeD.setViewMode("gameplay")
            assert(ThreeD.currentFovDegrees()==33)
            local eye=ThreeD.cameraBasis(w,h)
            local dz=abs(eye[3]-280)
            local dy=eye[2]-10
            assert(near(eye[1],500) and dy/dz>2.4,
                "GAMEPLAY camera not symmetric or elevated enough")
            local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
            for _,x in ipairs({0,1000}) do
                for _,z in ipairs({0,560}) do
                    local px,py=ThreeD.project(x,-4,z,w,h)
                    assert(px and py,"GAMEPLAY failed to project a field corner")
                    minX,maxX=math.min(minX,px),math.max(maxX,px)
                    minY,maxY=math.min(minY,py),math.max(maxY,py)
                end
            end
            assert(minX>32 and maxX<w-32 and minY>top+30 and
                maxY<top+vh-30,
                "GAMEPLAY clips field near HUD/rails at "..w.."x"..h)
            assert(maxY-minY>=vh*0.67,
                "3D foosball field is still vertically compressed")
            assert(maxX-minX>=w*0.52,
                "3D foosball field is still too small horizontally")
            for _,z in ipairs({20,280,540}) do
                local left=assert(ThreeD.project(50,-4,z,w,h))
                local right=assert(ThreeD.project(950,-4,z,w,h))
                assert(near(left+right,w,0.1),
                    "goal lines should be symmetric in GAMEPLAY")
            end
            local marker=ThreeD.ballIndicator(s,w,h)
            local lift=Model.Ramps.heightAt(s.ball.x,s.ball.y,Model.W,
                Model.H,Model.GOAL_HALF,s.ball.r)
            local bx,by=ThreeD.project(s.ball.x,ThreeD.ballHeight+5+lift,
                s.ball.y,w,h)
            assert(marker.x and near(marker.x,bx) and near(marker.y,by),
                "new preset detached real ball tracking from GPU projection")
            for _,foot in ipairs(ThreeD.playerIndicators(s,w,h).feet) do
                local fx,fz=foot.worldX,foot.worldZ
                local px,py=ThreeD.project(fx,ThreeD.ballHeight,fz,w,h)
                assert(foot.x and near(foot.x,px) and near(foot.y,py),
                    "new preset detached physical foot contact markers")
            end
            ThreeD.setViewMode("showcase")
        end
    end
end
ThreeD.resetSceneYaw()
ThreeD.resetCamera()
assert(ThreeD.viewMode=="gameplay" and ThreeD.currentFovDegrees()==33 and
       ThreeD.sceneYaw==180 and ThreeD.cameraDistance==1 and
       ThreeD.cameraSide=="front","Home must recover the new default camera")
assert(near(s.ball.x,initial[1]) and near(s.ball.y,initial[2]) and
       s.score[1]==initial[3] and s.score[2]==initial[4] and
       s.selected==initial[5],"camera and zoom mutated the physical game")
print("PASS: 70-degree symmetric GAMEPLAY, field occupation/HUD, marker projection, preserved SHOWCASE and yaw")
