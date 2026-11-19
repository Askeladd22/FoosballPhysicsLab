-- Foosball Lab visual identity: tempered smoky glass + selective neon.
-- Presentation only. No collision, AI, scoring or input geometry is changed.
local Theme={}
Theme.glowEnabled=true
Theme.colors={
    background={0.012,0.022,0.039},
    chassis={0.037,0.055,0.080},
    chassisEdge={0.18,0.27,0.32},
    glass={0.032,0.125,0.153},
    glassDeep={0.018,0.073,0.102},
    panel={0.076,0.185,0.204},
    etched={0.24,0.72,0.76},
    human={0.21,0.82,0.99},
    away={1.0,0.36,0.39},
    cream={0.96,0.97,0.91},
    muted={0.53,0.68,0.71},
    metal={0.67,0.78,0.83},
    gold={1,0.75,0.36},
    shadow={0.004,0.013,0.024}
}
local c=Theme.colors
local function paint(lg,color,a)
    lg.setColor(color[1],color[2],color[3],a or 1)
end
Theme.paint=paint
local passes={{9,0.035},{5,0.085},{2.5,0.15}}
local function startGlow(lg)
    lg.setBlendMode("add","alphamultiply")
end
local function endGlow(lg)
    lg.setBlendMode("alpha","alphamultiply")
end
function Theme.glowLine(lg,x1,y1,x2,y2,color,width,brightness)
    width=width or 2
    brightness=brightness or 1
    if Theme.glowEnabled then
        startGlow(lg)
        for _,p in ipairs(passes) do
            paint(lg,color,p[2]*brightness)
            lg.setLineWidth(width+p[1])
            lg.line(x1,y1,x2,y2)
        end
        endGlow(lg)
    end
    paint(lg,color,0.70*brightness)
    lg.setLineWidth(width)
    lg.line(x1,y1,x2,y2)
end
function Theme.glowCircle(lg,x,y,r,color)
    if Theme.glowEnabled then
        startGlow(lg)
        for i=3,1,-1 do
            paint(lg,color,0.05+0.02*(4-i))
            lg.circle("fill",x,y,r+i*5)
        end
        endGlow(lg)
    end
    paint(lg,color)
    lg.circle("fill",x,y,r)
end
function Theme.glowFrame(lg,x,y,w,h,color)
    if Theme.glowEnabled then
        startGlow(lg)
        for i=3,1,-1 do
            paint(lg,color,0.035*i)
            lg.setLineWidth(2+i*3)
            lg.rectangle("line",x,y,w,h,10,10)
        end
        endGlow(lg)
    end
    paint(lg,color,0.73)
    lg.setLineWidth(1.5)
    lg.rectangle("line",x,y,w,h,10,10)
end
function Theme.drawBackdrop(lg,w,h)
    paint(lg,c.background)
    lg.rectangle("fill",0,0,w,h)
    paint(lg,c.human,0.018)
    for x=24,w,48 do
        lg.rectangle("fill",x,0,1,h)
    end
    paint(lg,c.away,0.014)
    for y=0,h,44 do lg.rectangle("fill",0,y,w,1) end
    paint(lg,c.etched,0.17)
    lg.setLineWidth(1)
    lg.line(28,112,math.max(28,w-28),112)
end
function Theme.drawGlassTable(lg,W,H,goalHalf)
    -- Chassis and inward bevel, within the 46-unit wooden-frame safe margin.
    paint(lg,c.shadow,0.72)
    lg.rectangle("fill",-45,-45,W+90,H+90,29,29)
    paint(lg,c.chassis)
    lg.rectangle("fill",-42,-42,W+84,H+84,26,26)
    paint(lg,c.chassisEdge,0.72)
    lg.setLineWidth(4)
    lg.rectangle("line",-40,-40,W+80,H+80,23,23)
    paint(lg,c.cream,0.09)
    lg.setLineWidth(1)
    lg.rectangle("line",-35,-35,W+70,H+70,19,19)
    paint(lg,c.glassDeep)
    lg.rectangle("fill",-15,-15,W+30,H+30,11,11)
    -- Semi-translucent tinted slab with restrained internal bands.
    paint(lg,c.glass)
    lg.rectangle("fill",0,0,W,H,3,3)
    paint(lg,c.panel,0.15)
    lg.polygon("fill",0,0,W*0.47,0,W*0.27,H,0,H)
    paint(lg,c.human,0.045)
    lg.polygon("fill",W*0.60,0,W*0.76,0,W*0.49,H,W*0.34,H)
    paint(lg,c.cream,0.036)
    lg.polygon("fill",W*0.79,0,W*0.83,0,W*0.66,H,W*0.62,H)
    paint(lg,c.shadow,0.14)
    for x=0,W-1,100 do lg.rectangle("fill",x,0,50,H) end
    -- Surface bevel: subtle offset makes the slab read as thick glass.
    paint(lg,c.cream,0.28)
    lg.setLineWidth(1.5)
    lg.line(0,0,W,0)
    lg.line(0,0,0,H)
    paint(lg,c.human,0.30)
    lg.line(0,H-2,W,H-2)
    lg.line(W-2,0,W-2,H)
    Theme.glowFrame(lg,1,1,W-2,H-2,c.etched)
    -- Etched pitch, secondary to the ball and the active foot.
    local line=c.etched
    Theme.glowLine(lg,W/2,5,W/2,H-5,line,1.35,0.49)
    if Theme.glowEnabled then
        paint(lg,line,0.25)
        lg.setLineWidth(3)
        lg.circle("line",W/2,H/2,88)
    end
    paint(lg,line,0.58)
    lg.setLineWidth(1.5)
    lg.circle("line",W/2,H/2,88)
    lg.circle("fill",W/2,H/2,3)
    for _,right in ipairs({false,true}) do
        local boxX=right and W-160 or 0
        local smallX=right and W-48 or 0
        paint(lg,line,0.54)
        lg.setLineWidth(1.6)
        lg.rectangle("line",boxX,H/2-160,160,320)
        lg.rectangle("line",smallX,H/2-95,48,190)
        local gx=right and W or -36
        paint(lg,c.shadow,0.8)
        lg.rectangle("fill",gx,H/2-goalHalf,36,goalHalf*2,3,3)
        paint(lg,c.human,right and 0.12 or 0.18)
        lg.rectangle("fill",gx,H/2-goalHalf,36,goalHalf*2)
        for i=0,7 do
            local y=H/2-goalHalf+i*goalHalf*2/7
            paint(lg,c.etched,0.18)
            lg.setLineWidth(1)
            lg.line(gx,y,gx+36,y)
        end
        Theme.glowLine(lg,gx,H/2-goalHalf,gx+36,H/2-goalHalf,c.etched,1.4,0.9)
        Theme.glowLine(lg,gx,H/2+goalHalf,gx+36,H/2+goalHalf,c.etched,1.4,0.9)
    end
    -- Under-glass corner screws, intentional without overpowering ball.
    for _,x in ipairs({-27,W+27}) do
        for _,y in ipairs({-27,H+27}) do
            paint(lg,c.shadow)
            lg.circle("fill",x,y,9)
            paint(lg,c.metal,0.52)
            lg.setLineWidth(1.4)
            lg.circle("line",x,y,7)
            lg.line(x-3,y+3,x+3,y-3)
        end
    end
end
return Theme
