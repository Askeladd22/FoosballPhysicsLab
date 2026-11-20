-- PAUL 31: show the whole real table only on request; the default must
-- prioritize pitch, physical ball and selected foot contact readability.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local abs=math.abs
local function near(a,b) return abs(a-b)<1e-7 end
local match=Model.new()
local original={match.ball.x,match.ball.y,match.score[1],match.score[2],
               match.rods[4].angle,match.rods[4].slide}
assert(ThreeD.viewMode=="gameplay","GAMEPLAY must be the default Foosball camera")
assert(ThreeD.sceneYaw==180,"retain requested horizontal 180-degree table yaw")
for _,win in ipairs({{900,650},{1280,850},{1650,895},{1920,1080}}) do
    local w,h=win[1],win[2]
    local top,vh=ThreeD.viewport(w,h)
    for _,side in ipairs({"front","back"}) do
        ThreeD.cameraSide=side
        ThreeD.setViewMode("showcase")
        local a=assert(ThreeD.project(100,-4,280,w,h))
        local b=assert(ThreeD.project(900,-4,280,w,h))
        local productWidth=abs(a-b)
        -- Existing product view must retain all four actual supports.
        for _,leg in ipairs({{0,0},{1000,0},{0,560},{1000,560}}) do
            local px,py=ThreeD.project(leg[1],-740,leg[2],w,h)
            assert(px and px>0 and px<w and py>top and py<top+vh,
                "SHOWCASE clipped an actual support leg")
        end
        ThreeD.setViewMode("gameplay")
        local c=assert(ThreeD.project(100,-4,280,w,h))
        local d=assert(ThreeD.project(900,-4,280,w,h))
        local playWidth=abs(c-d)
        assert(playWidth>=productWidth*1.40,
            ("GAMEPLAY did not substantially enlarge playfield: %.1f vs %.1f"):format(playWidth,productWidth))
        assert(playWidth>=w*0.23,"GAMEPLAY pitch too small")
        for _,p in ipairs({{40,-4,35},{960,-4,35},{40,-4,525},
                             {960,-4,525},{500,-4,280}}) do
            local px,py=ThreeD.project(p[1],p[2],p[3],w,h)
            assert(px and px>8 and px<w-8 and py>top+8 and py<top+vh-8,
                "GAMEPLAY cropped a goal-area/field point")
        end
        local selected=match.rods[match.selected]
        local markers=ThreeD.playerIndicators(match,w,h)
        assert(#markers.feet==#selected.offsets,"not all selected physical feet visible")
        for i,foot in ipairs(markers.feet) do
            local fx,fz=Model.foot(selected,i)
            local px,py=ThreeD.project(fx,ThreeD.ballHeight,fz,w,h)
            assert(near(foot.worldX,fx) and near(foot.worldZ,fz),
                "foot marker not tied to collision")
            assert(foot.x and near(foot.x,px) and near(foot.y,py),
                "foot marker detached from 3D camera")
        end
        local ball=ThreeD.ballIndicator(match,w,h)
        local px,py=ThreeD.project(match.ball.x,ThreeD.ballHeight+5,match.ball.y,w,h)
        assert(ball.x and near(ball.x,px) and near(ball.y,py) and
            near(ball.worldX,match.ball.x) and near(ball.worldZ,match.ball.y))
    end
end
assert(ThreeD.setViewMode("showcase")=="showcase")
assert(ThreeD.toggleViewMode()=="gameplay")
assert(ThreeD.toggleViewMode()=="showcase")
local ok=pcall(ThreeD.setViewMode,"nonsense")
assert(not ok,"invalid camera modes must be rejected")
ThreeD.resetCamera()
assert(ThreeD.viewMode=="gameplay" and math.abs(ThreeD.cameraDistance-0.90)<1e-7
       and ThreeD.cameraSide=="front","Home/reset must return to default gameplay")
assert(near(match.ball.x,original[1]) and near(match.ball.y,original[2])
    and match.score[1]==original[3] and match.score[2]==original[4]
    and near(match.rods[4].angle,original[5])
    and near(match.rods[4].slide,original[6]),
    "switching cameras altered a match state")
print("PASS: larger gameplay pitch, 4-leg showroom, HUD markers at real contacts, independent cameras")
