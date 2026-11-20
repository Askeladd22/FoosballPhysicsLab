-- PAUL 17: UI occupies safe bands at the minimum and reference sizes.
package.path="./?.lua;./?/init.lua;"..package.path
local Layout=require("layout")
local Model=require("model")
for _,window in ipairs({{1280,850},{1279,881},{900,650},{1024,768}}) do
    local w,h=window[1],window[2]
    local b=Layout.bounds(w,h)
    local ox,oy,s=Layout.compute(w,h)
    assert(s>0 and s<2, "invalid scale")
    assert(b.boardTop>=b.headerTextBottom+18,"wood rim overlaps header at "..w.."x"..h)
    assert(b.boardLeft>=25 and b.boardRight<=w-25,"wood rim cropped horizontally")
    assert(b.footerInfoStart>b.boardBottom,"footer text invades the table")
    assert(b.footerInfoEnd+8<b.helpLineTop,"footer text overlaps controls")
    assert(math.abs(oy-46*s-b.boardTop)<1e-7)
end
-- The articulated figure must lean with the ACTUAL shoe projection.
local s=Model.new()
local rod=s.rods[4]
local bx,fy,hx,hy=Model.figurePose(rod,2)
local fx=Model.foot(rod,2)
assert((bx-rod.x)*(fx-rod.x)>0,"figure silhouette does not lean toward shoe")
rod.angle=1.05
local rightBody,rightY,rightHead,rightHeadY=Model.figurePose(rod,2)
local rightFoot=Model.foot(rod,2)
assert(rightBody>rod.x and rightFoot>rod.x,"body did not follow forward rotation")
assert(rightHead>rod.x and hy==rightHeadY,"head and shoe pose incoherent")
local x,y,width,height=Model.footRect(rod,2)
assert(math.abs(x+width/2-rightFoot)<1e-7)
print("PASS: UI safe margins, proportional fit and articulated pose tied to physical foot")
