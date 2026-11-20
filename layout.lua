-- Dedicated Foosball Lab screen-space layout. The table INCLUDING its
-- 46-unit wood rim must fit between a fixed HUD header and footer.
local Layout={}
local W,H=1000,560
local FRAME=46
local HEADER=132
local FOOTER=146
function Layout.compute(w,h)
    local availableW=math.max(1,w-72)
    local availableH=math.max(1,h-HEADER-FOOTER)
    local scale=math.min(availableW/(W+2*FRAME),availableH/(H+2*FRAME))
    -- LÖVE's window minimum is 900x650; below that keep layout finite.
    scale=math.max(scale,0.05)
    local ox=(w-W*scale)/2
    local oy=HEADER+FRAME*scale
    return ox,oy,scale,w,h
end
function Layout.bounds(w,h)
    local ox,oy,scale=Layout.compute(w,h)
    return {
        boardLeft=ox-FRAME*scale,
        boardRight=ox+(W+FRAME)*scale,
        boardTop=oy-FRAME*scale,
        boardBottom=oy+(H+FRAME)*scale,
        headerTextBottom=111,
        footerInfoStart=oy+(H+FRAME)*scale+17,
        footerInfoEnd=oy+(H+FRAME)*scale+84,
        helpLineTop=h-40
    }
end
return Layout
