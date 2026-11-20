-- Dedicated Foosball Lab screen-space layout. The table INCLUDING its
-- 46-unit wood rim must fit between a fixed HUD header and footer.
local Camera=require("camera")
local Layout={}
local W,H=1000,560
local FRAME=46
local HEADER=132
local FOOTER=146
function Layout.compute(w,h)
    local availableW=math.max(1,w-72)
    local availableH=math.max(1,h-HEADER-FOOTER)
    local minX,minY,maxX,maxY=Camera.bounds(-FRAME,-FRAME,W+FRAME,H+FRAME)
    local boardW,boardH=maxX-minX,maxY-minY
    local scale=math.min(availableW/boardW,availableH/boardH)
    scale=math.max(scale,0.05)
    -- Center the *projected* table rather than its unprojected world rectangle.
    local ox=(w-(minX+maxX)*scale)/2
    local oy=HEADER+(availableH-boardH*scale)/2-minY*scale
    return ox,oy,scale,w,h
end
function Layout.bounds(w,h)
    local ox,oy,scale=Layout.compute(w,h)
    local minX,minY,maxX,maxY=Camera.bounds(-FRAME,-FRAME,W+FRAME,H+FRAME)
    return {
        boardLeft=ox+minX*scale,
        boardRight=ox+maxX*scale,
        boardTop=oy+minY*scale,
        boardBottom=oy+maxY*scale,
        headerTextBottom=111,
        footerInfoStart=oy+(H+FRAME)*scale+17,
        footerInfoEnd=oy+(H+FRAME)*scale+84,
        helpLineTop=h-40
    }
end
return Layout
