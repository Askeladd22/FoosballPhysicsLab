-- FoosballPhysicsLab: this is the real Foosball application, not a loader.
-- For the frozen 11vs11 only: love . --legacy (or love legacy/neon11).
local function runFrozenNeon11(args)
    if type(args)~="table" then return false end
    for _,token in pairs(args) do
        if token=="--legacy" or token=="--neon11" then return true end
    end
    return false
end
if runFrozenNeon11(rawget(_G,"arg")) then
    package.path="legacy/neon11/?.lua;"..package.path
    require("legacy.neon11.main")
    return
end

local Model=require("model")
local Layout=require("layout")
local Theme=require("theme")
local MeshArt=require("mesh_art")
local lg=love.graphics
local match
local accumulator=0
local STEP=1/120
local debugDraw=false
local fonts={}
local colors=Theme.colors
local function paint(c,a)
    lg.setColor(c[1],c[2],c[3],a or 1)
end
local function text(value,x,y,font,color)
    lg.setFont(font)
    paint(color or colors.cream)
    lg.print(value,x,y)
end
local function transform()
    return Layout.compute(lg.getDimensions())
end
local function pitch()
    Theme.drawGlassTable(lg,Model.W,Model.H,Model.GOAL_HALF)
    MeshArt.drawTable(lg)
end
local function rods()
    local selected=match.rods[match.selected]
    for i,r in ipairs(match.rods) do
        local c=r.team==1 and colors.human or colors.away
        local current=r==selected
        if current then
            -- A subtle selected rod 'light pipe'; no opaque gold column.
            paint(colors.gold,Theme.glowEnabled and 0.065 or 0.035)
            lg.rectangle("fill",r.x-15,-15,30,Model.H+30)
            Theme.glowLine(lg,r.x,-21,r.x,Model.H+25,colors.gold,1,0.36)
        end
        -- Through-table shaft and its fixed chassis guides.
        paint(colors.shadow,0.67)
        lg.setLineWidth(current and 7 or 5)
        lg.line(r.x+2,-24,r.x+2,Model.H+28)
        paint(colors.metal,current and 0.91 or 0.52)
        lg.setLineWidth(current and 4 or 3)
        lg.line(r.x,-24,r.x,Model.H+28)
        paint(colors.cream,current and 0.45 or 0.19)
        lg.setLineWidth(1)
        lg.line(r.x-1,-24,r.x-1,Model.H+28)
        for _,y in ipairs({-10,Model.H+10}) do
            paint(colors.shadow)
            lg.circle("fill",r.x,y,13)
            paint(colors.chassisEdge)
            lg.circle("line",r.x,y,12)
            paint(colors.metal,0.75)
            lg.circle("line",r.x,y,8)
            paint(c,current and 0.95 or 0.68)
            lg.rectangle("fill",r.x-4,y-8,8,16,3,3)
        end
        -- Bumper compression clearly indicates which side hit the mechanical stop.
        if r.stopPulse>0 or r.stopSide~=0 then
            local y=r.stopSide<0 and -10 or Model.H+10
            local pulse=r.stopPulse/0.22
            paint(colors.gold,0.25+0.5*pulse)
            lg.rectangle("fill",r.x-17,y-7,34,14,5,5)
            if current then
                paint(colors.gold,0.3*pulse)
                lg.circle("line",r.x,y,18+12*(1-pulse))
            end
        end
        -- Grip attached to the shaft, distinct from the fixed guide.
        paint(colors.chassisEdge)
        lg.rectangle("fill",r.x-11,Model.H+18,22,32,5,5)
        paint(c,current and 0.96 or 0.72)
        lg.rectangle("fill",r.x-9,Model.H+20,18,28,5,5)
        if current then
            paint(colors.gold,0.89)
            lg.rectangle("fill",r.x-17,Model.H+43,34,10,6,6)
            lg.setFont(fonts.small)
            lg.print(tostring(i),r.x-5,-34)
        end
        local modelled=MeshArt.drawRod(lg,r,i)
        for j=1,#r.offsets do
            local fx,fy=Model.foot(r,j)
            local left,top,fw,fh=Model.footRect(r,j)
            local bodyX,_,headX,headY=Model.figurePose(r,j)
            local direction=r.team==1 and 1 or -1
            local central=j==math.ceil(#r.offsets/2)
            -- If locally baked 3D figures exist, use them for the silhouette.
            -- The white striking edge/outline stays in exact 2D physics space.
            if not modelled then
            -- Socket stays on the real shaft; leg and body lean with the
            -- actual horizontal shoe projection, instead of looking detached.
            paint(colors.shadow,0.72)
            lg.polygon("fill",r.x-8+3,fy-13+3,r.x+10+3,fy-13+3,
                bodyX+11+3,fy+13+3,bodyX-9+3,fy+13+3)
            paint(c,0.90)
            lg.polygon("fill",r.x-9,fy-13,r.x+9,fy-13,
                bodyX+8,fy+11,bodyX-8,fy+11)
            paint(colors.cream,0.18)
            lg.setLineWidth(1.3)
            lg.line(r.x-6,fy-12,bodyX-6,fy+8)
            paint(colors.shadow)
            lg.setLineWidth(4)
            lg.line(bodyX,fy+6,fx,fy+6)
            paint(c)
            lg.circle("fill",headX,headY,7)
            paint(colors.cream,0.72)
            lg.circle("fill",headX-2,headY-2,2.2)
            paint(colors.shadow,0.72)
            lg.setLineWidth(1)
            lg.circle("line",headX,headY,7)
            -- Same rectangle as the collision geometry; NO circular toe.
            paint(colors.shadow,0.63)
            lg.rectangle("fill",left+2,top+3,fw,fh,3,3)
            paint(c)
            lg.rectangle("fill",left,top,fw,fh,3,3)
            paint(colors.cream,0.22)
            lg.rectangle("fill",left+2,top+2,3,fh-4,1,1)
            end -- legacy procedural figures, used when private model is absent
            -- White is the physical striking edge, gold only outlines the
            -- selected rod. It must remain visibly blue/red, not all yellow.
            if current then
                paint(colors.gold,0.91)
                lg.setLineWidth(2)
                lg.rectangle("line",left-1.5,top-1.5,fw+3,fh+3,3,3)
            end
            local front=direction==1 and left+fw or left
            if current then
                Theme.glowLine(lg,front,top+2,front,top+fh-2,colors.cream,3,0.85)
            else
                paint(colors.cream)
                lg.setLineWidth(3)
                lg.line(front,top+2,front,top+fh-2)
            end
            if current and central then
                -- Only ONE arrow on the active rod: repeated arrows on five
                -- figures read as spiky shoes in the screenshot.
                paint(colors.gold,0.85)
                local tip=front+direction*12
                lg.line(front,fy,tip,fy)
                lg.line(tip,fy,tip-direction*5,fy-5)
                lg.line(tip,fy,tip-direction*5,fy+5)
            end
            if debugDraw then
                paint(colors.gold,0.75)
                lg.setLineWidth(1)
                lg.rectangle("line",left,top,fw,fh)
                lg.line(r.x,fy,fx,fy)
                lg.line(fx,fy,fx+direction*Model.FOOT_REACH*math.cos(r.angle)*r.omega*0.11,
                    fy+r.vy*0.11)
            end
        end
    end
end
local function drawBall()
    local b=match.ball
    -- High contrast on every glass band. Warm white core is never transparent.
    paint(colors.shadow,0.70)
    lg.circle("fill",b.x+3,b.y+4,b.r+3)
    if Theme.glowEnabled then
        Theme.glowCircle(lg,b.x,b.y,b.r+1,colors.cream)
    else
        paint(colors.cream)
        lg.circle("fill",b.x,b.y,b.r+1)
    end
    paint(colors.shadow,0.73)
    lg.setLineWidth(1.4)
    lg.circle("line",b.x,b.y,b.r)
    paint(colors.chassis)
    lg.circle("fill",b.x,b.y,3.2)
    paint(colors.cream,0.8)
    lg.circle("fill",b.x-2,b.y-3,2.6)
    if match.deadBallTimer>0 then
        -- A warning ring, not a magnetic force or gameplay collision.
        paint(colors.gold,0.35+0.25*math.min(1,match.deadBallTimer/Model.DEAD_BALL_SECONDS))
        lg.setLineWidth(2)
        lg.circle("line",b.x,b.y,b.r+9)
    end
    local speed=math.sqrt(b.vx*b.vx+b.vy*b.vy)
    if Theme.glowEnabled and speed>140 then
        local factor=math.min(0.062,10/speed)
        Theme.glowLine(lg,b.x-b.vx*factor,b.y-b.vy*factor,
            b.x-b.vx*factor*0.34,b.y-b.vy*factor*0.34,colors.cream,1.2,0.35)
    end
    if debugDraw then
        paint(colors.gold,0.9)
        lg.setLineWidth(2)
        lg.line(b.x,b.y,b.x+b.vx*0.16,b.y+b.vy*0.16)
    end
end

local function hud(w,h)
    local r=match.rods[match.selected]
    text("FOOSBALL LAB",36,18,fonts.title,colors.cream)
    text("NEON GLASS  /  "..(MeshArt.active() and "TABLE SOCCER 2.5D" or "PROCEDURALE"),38,58,fonts.small,colors.human)
    text("SU/GIU: scorri l'asta    SINISTRA/DESTRA: ruota e colpisci",
        38,81,fonts.small,colors.muted)
    local score=tostring(match.score[1]).."  :  "..tostring(match.score[2])
    text(score,w-174,21,fonts.title,colors.cream)
    text("TU           IA",w-166,66,fonts.small,colors.muted)
    Theme.glowLine(lg,36,110,w-36,110,colors.etched,1,0.43)
    local bounds=Layout.bounds(w,h)
    local bottom=bounds.boardBottom+16
    local angle=math.floor(r.angle*180/math.pi+0.5)
    -- An optical glass HUD plate; no heavy panels or extra menus.
    paint(colors.chassis,0.74)
    lg.rectangle("fill",30,bottom-8,w-60,79,9,9)
    paint(colors.metal,0.28)
    lg.setLineWidth(1)
    lg.rectangle("line",30,bottom-8,w-60,79,9,9)
    Theme.glowLine(lg,39,bottom-6,170,bottom-6,colors.gold,1.5,0.48)
    text((match.controlMode=="auto" and "AUTO" or "MANUALE")..
        "  /  ASTA "..match.selected.."  /  "..r.kind.."  /  rotazione "..angle.." gradi",
        45,bottom,fonts.normal,colors.cream)
    if r.stopPulse>0 then text("FINE CORSA",w-175,bottom,fonts.small,colors.gold)
    elseif match.autoRodNotice and match.autoRodNotice.expires>match.clock then
        text("ASTA "..match.autoRodNotice.rod.." SELEZIONATA",w-220,bottom,fonts.small,colors.gold)
    end
    if match.deadBallNotice and match.deadBallNotice.expires>match.clock then
        local side=match.deadBallNotice.team==1 and "BLU" or "ROSSO"
        text("PALLA MORTA - RIMESSA "..side.." A CENTROCAMPO",
            45,bottom+27,fonts.small,colors.gold)
    elseif match.deadBallTimer>0 then
        local remain=math.max(0,Model.DEAD_BALL_SECONDS-match.deadBallTimer)
        text(string.format("PALLA IRRAGGIUNGIBILE - RIMESSA FRA %.1f s",remain),
            45,bottom+27,fonts.small,colors.gold)
    else
        text("Bordo BIANCO = faccia di tiro   /   BLU: destra   /   ROSSO: sinistra",
            45,bottom+27,fonts.small,colors.muted)
    end
    local captured=love.mouse.getRelativeMode()
    local help=captured and "MOUSE CATTURATO - ESC per sbloccare" or
        "Clic per bloccare il mouse e ruotare senza limiti"
    text(help,45,bottom+52,fonts.small,captured and colors.gold or colors.muted)
    text("TAB: AUTO/MANUALE   1-4/rotella: asta   V: 2.5D "..
        (MeshArt.loaded and (MeshArt.active() and "ON" or "OFF") or "N/D")..
        "   G: glow "..(Theme.glowEnabled and "ON" or "OFF").."   R: reset",
        39,h-38,fonts.small,colors.muted)
    if match.phase=="goal" or match.phase=="finished" then
        local message=match.phase=="finished" and
            (match.lastScorer==1 and "VITTORIA!  /  R: nuova partita" or "SCONFITTA!  /  R: riprova") or
            (match.lastScorer==1 and "GOL!" or "GOL DELL'IA!")
        local width=fonts.title:getWidth(message)
        paint(colors.shadow,0.94)
        lg.rectangle("fill",(w-width)/2-28,h/2-38,width+56,78,14,14)
        Theme.glowFrame(lg,(w-width)/2-28,h/2-38,width+56,78,colors.human)
        text(message,(w-width)/2,h/2-15,fonts.title,colors.cream)
    end
end

function love.load()
    lg.setDefaultFilter("linear","linear")
    fonts.title=lg.newFont(31)
    fonts.normal=lg.newFont(17)
    fonts.small=lg.newFont(14)
    match=Model.new()
    MeshArt.load()
    love.window.setTitle("FOOSBALL LAB | Neon Glass")
end
function love.update(dt)
    accumulator=accumulator+math.min(dt,0.08)
    local n=0
    while accumulator>=STEP and n<12 do
        match:step(STEP)
        accumulator=accumulator-STEP
        n=n+1
    end
    if n==12 then accumulator=0 end
end
function love.draw()
    local ox,oy,scale,w,h=transform()
    lg.clear(colors.background[1],colors.background[2],colors.background[3])
    Theme.drawBackdrop(lg,w,h)
    lg.push()
    lg.translate(ox,oy)
    lg.scale(scale)
    pitch()
    rods()
    drawBall()
    lg.pop()
    hud(w,h)
end
function love.mousemoved(_,_,dx,dy)
    if match then match:mouseMoved(dx,dy) end
end
function love.mousepressed(_,_,button)
    if button==1 then love.mouse.setRelativeMode(true) end
end
function love.wheelmoved(_,dy)
    if dy~=0 then match:selectRod((match.selected-1+(dy>0 and 1 or 3))%4+1) end
end
function love.keypressed(key,_,repeatKey)
    if repeatKey then return end
    local index=tonumber(key)
    if index and index>=1 and index<=4 then
        match:selectRod(index)
    elseif key=="escape" then
        love.mouse.setRelativeMode(false)
    elseif key=="m" then
        love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
    elseif key=="tab" then
        match:toggleAutoRod()
    elseif key=="c" then
        match:neutralRod()
    elseif key=="r" then
        match:reset()
    elseif key=="f1" then
        debugDraw=not debugDraw
    elseif key=="g" then
        Theme.glowEnabled=not Theme.glowEnabled
    elseif key=="v" then
        MeshArt.toggle()
    elseif key=="-" or key=="kp-" then
        match.mouseSensitivity.angle=math.max(0.007,match.mouseSensitivity.angle-0.002)
    elseif key=="=" or key=="+" or key=="kp+" then
        match.mouseSensitivity.angle=math.min(0.05,match.mouseSensitivity.angle+0.002)
    end
end
function love.focus(focused)
    if not focused then love.mouse.setRelativeMode(false) end
end
