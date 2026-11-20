-- Whole-pitch tactical camera. Rendering scale never changes field dimensions.
local Camera={}
function Camera.fit(field,width,height)
    local top,bottom=44,56
    -- The asymmetric apron leaves room for throwers below the touchline.
    -- Restart messages live in the HUD, so the header can remain compact.
    local scale=math.min((width-24)/(field.w+10),(height-top-bottom)/(field.h+7))
    local pitchWidth,pitchHeight=field.w*scale,field.h*scale
    return scale,(width-pitchWidth)/2,
        top+3*scale+(height-top-bottom-(field.h+7)*scale)/2,
        width,height,pitchWidth,pitchHeight
end
return Camera
