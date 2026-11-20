-- Camera is *presentation only*. All game physics and mouse controls remain
-- in Model.W x Model.H ground coordinates; same transform covers ball and feet.
-- Oblique means affine 2.5D (not perspective-rigged realtime 3D).
local Camera={
    mode="oblique",
    width=1000,height=560,
    tilt=0.76,shear=-0.23
}
function Camera.setMode(mode)
    assert(mode=="oblique" or mode=="topdown","unsupported camera mode")
    Camera.mode=mode
end
function Camera.isOblique()
    return Camera.mode=="oblique"
end
function Camera.toggle()
    Camera.mode=Camera.mode=="oblique" and "topdown" or "oblique"
    return Camera.mode
end
function Camera.project(x,y)
    if Camera.mode=="topdown" then return x,y end
    local dx=x-Camera.width/2
    local dy=y-Camera.height/2
    return Camera.width/2+dx+Camera.shear*Camera.tilt*dy,
           Camera.height/2+Camera.tilt*dy
end
function Camera.unproject(x,y)
    if Camera.mode=="topdown" then return x,y end
    local dy=(y-Camera.height/2)/Camera.tilt
    return Camera.width/2+(x-Camera.width/2)-Camera.shear*Camera.tilt*dy,
           Camera.height/2+dy
end
function Camera.bounds(left,top,right,bottom)
    local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
    for _,p in ipairs({{left,top},{left,bottom},{right,top},{right,bottom}}) do
        local x,y=Camera.project(p[1],p[2])
        minX=math.min(minX,x)
        maxX=math.max(maxX,x)
        minY=math.min(minY,y)
        maxY=math.max(maxY,y)
    end
    return minX,minY,maxX,maxY
end
function Camera.apply(lg)
    if Camera.mode~="oblique" then return end
    lg.translate(Camera.width/2,Camera.height/2)
    lg.shear(Camera.shear,0)
    lg.scale(1,Camera.tilt)
    lg.translate(-Camera.width/2,-Camera.height/2)
end
return Camera
