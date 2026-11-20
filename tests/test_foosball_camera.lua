-- PAUL 24: reversible oblique camera, mathematically consistent layout.
package.path="./?.lua;./?/init.lua;"..package.path
local Camera=require("camera")
local Layout=require("layout")
local M=require("model")
assert(Camera.mode=="oblique")
local sample={{0,0},{1000,560},{430,280},{0,560},{1000,0},{745,125}}
for _,p in ipairs(sample) do
    local x,y=Camera.project(p[1],p[2])
    local worldX,worldY=Camera.unproject(x,y)
    assert(math.abs(worldX-p[1])<0.00001 and math.abs(worldY-p[2])<0.00001,
        "camera projection unproject round-trip changed physics coordinates")
end
local r=M.new()
local saved=r.ball.x
for _,size in ipairs({{1280,850},{900,650},{1920,1080}}) do
    for _,mode in ipairs({"oblique","topdown"}) do
        Camera.setMode(mode)
        local w,h=size[1],size[2]
        local ox,oy,scale=Layout.compute(w,h)
        local bounds=Layout.bounds(w,h)
        assert(scale>0 and bounds.boardLeft>=-1 and bounds.boardRight<=w+1,
            "table rim clipped horizontally")
        assert(bounds.boardTop>=111 and bounds.boardBottom<=h-140,
            "table rim overlaps HUD")
        local minX,minY,maxX,maxY=Camera.bounds(-46,-46,1046,606)
        assert(math.abs(bounds.boardLeft-(ox+minX*scale))<0.01)
        assert(math.abs(bounds.boardBottom-(oy+maxY*scale))<0.01)
    end
end
Camera.setMode("oblique")
assert(Camera.toggle()=="topdown")
local x,y=Camera.project(400,200)
assert(x==400 and y==200,"legacy top-down must be unaltered")
assert(Camera.toggle()=="oblique")
assert(r.ball.x==saved,"camera toggle changed simulation")
local lg={calls={}}
for _,name in ipairs({"translate","scale","shear"}) do
    lg[name]=function(...) lg.calls[#lg.calls+1]=name end
end
Camera.apply(lg)
assert(#lg.calls==4 and lg.calls[2]=="shear",
    "oblique camera transform does not include tilt/shear")
lg.calls={}
Camera.setMode("topdown")
Camera.apply(lg)
assert(#lg.calls==0,"top-down mode should not warp the world")
Camera.setMode("oblique")
print("PASS: oblique/topdown camera projection, reversible toggles, viewport bounds")
