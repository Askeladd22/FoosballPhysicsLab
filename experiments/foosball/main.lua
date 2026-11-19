local Model=require("model")
local lg=love.graphics
local match
local accumulator=0
local STEP=1/120
local debugDraw=false
local fonts={}
local colors={
    felt={0.045,0.23,0.19},line={0.49,0.77,0.67},
    rim={0.30,0.17,0.10},wood={0.48,0.30,0.16},
    human={0.22,0.74,0.94},away={0.99,0.43,0.30},
    cream={0.95,0.94,0.80},muted={0.59,0.69,0.68},
    metal={0.69,0.79,0.78},gold={0.98,0.77,0.36}
}
local function paint(c,a)
    lg.setColor(c[1],c[2],c[3],a or 1)
end
local function text(value,x,y,font,color)
    lg.setFont(font)
    paint(color or colors.cream)
    lg.print(value,x,y)
end
local function transform()
    local w,h=lg.getDimensions()
    local scale=math.min((w-128)/Model.W,(h-255)/Model.H)
    scale=math.max(scale,0.25)
    return (w-Model.W*scale)/2,115,scale,w,h
end
local function pitch()
    paint(colors.rim)
    lg.rectangle("fill",-46,-46,Model.W+92,Model.H+92,24,24)
    paint(colors.wood)
    lg.rectangle("line",-43,-43,Model.W+86,Model.H+86,22,22)
    paint(colors.felt)
    lg.rectangle("fill",0,0,Model.W,Model.H)
    paint(colors.line,0.22)
    for i=0,9 do
        if i%2==0 then lg.rectangle("fill",i*100,0,100,Model.H) end
    end
    paint(colors.line,0.58)
    lg.setLineWidth(2.2)
    lg.rectangle("line",3,3,Model.W-6,Model.H-6)
    lg.line(Model.W/2,0,Model.W/2,Model.H)
    lg.circle("line",Model.W/2,Model.H/2,88)
    lg.circle("fill",Model.W/2,Model.H/2,4)
    lg.rectangle("line",0,Model.H/2-160,160,320)
    lg.rectangle("line",Model.W-160,Model.H/2-160,160,320)
    lg.rectangle("line",0,Model.H/2-95,48,190)
    lg.rectangle("line",Model.W-48,Model.H/2-95,48,190)
    for _,edge in ipairs({-1,1}) do
        local gx=edge==-1 and -38 or Model.W
        paint(colors.metal,0.28)
        lg.rectangle("fill",gx,Model.H/2-Model.GOAL_HALF,38,Model.GOAL_HALF*2)
        paint(colors.cream,0.7)
        lg.rectangle("line",gx,Model.H/2-Model.GOAL_HALF,38,Model.GOAL_HALF*2)
        for i=0,5 do
            local y=Model.H/2-Model.GOAL_HALF+i*Model.GOAL_HALF*2/5
            paint(colors.cream,0.13)
            lg.line(gx,y,gx+38,y)
        end
    end
end
local function rods()
    local selected=match.rods[match.selected]
    for i,r in ipairs(match.rods) do
        local c=r.team==1 and colors.human or colors.away
        local current=r==selected
        if current then
            paint(colors.gold,0.12)
            lg.rectangle("fill",r.x-19,-13,38,Model.H+26)
        end
        paint(colors.metal,current and 0.9 or 0.46)
        lg.setLineWidth(current and 5 or 3)
        lg.line(r.x,-20,r.x,Model.H+23)
        paint(c,current and 0.95 or 0.7)
        lg.rectangle("fill",r.x-11,Model.H+14,22,36,5,5)
        if current then
            paint(colors.gold)
            lg.rectangle("fill",r.x-17,Model.H+43,34,13,6,6)
            lg.setFont(fonts.small)
            lg.print(tostring(i),r.x-5,-34)
        end
        for j=1,#r.offsets do
            local fx,fy=Model.foot(r,j)
            -- The body sits on the rod; the shoe sweeps horizontally as it rotates.
            paint({0,0,0},0.24)
            lg.rectangle("fill",r.x-12,fy-12,25,31,6,6)
            paint(c)
            lg.rectangle("fill",r.x-11,fy-17,22,34,5,5)
            paint(colors.cream,0.55)
            lg.rectangle("fill",r.x-5,fy-3,10,6,2,2)
            paint({0.06,0.13,0.14},0.5)
            lg.setLineWidth(4)
            lg.line(r.x,fy,fx,fy)
            paint(c)
            lg.circle("fill",fx,fy,Model.FOOT_RADIUS)
            paint(colors.cream,0.76)
            lg.circle("line",fx,fy,Model.FOOT_RADIUS)
            if debugDraw then
                paint(colors.gold,0.7)
                local dir=r.team==1 and 1 or -1
                lg.line(fx,fy,fx+dir*Model.FOOT_REACH*math.cos(r.angle)*r.omega*0.11,
                    fy+r.vy*0.11)
            end
        end
    end
end
local function drawBall()
    local b=match.ball
    paint({0,0,0},0.34)
    lg.circle("fill",b.x+4,b.y+5,b.r+2)
    paint(colors.cream)
    lg.circle("fill",b.x,b.y,b.r)
    paint({0.09,0.17,0.16})
    lg.circle("line",b.x,b.y,b.r)
    lg.circle("fill",b.x,b.y,3.5)
    if debugDraw then
        paint(colors.gold,0.82)
        lg.setLineWidth(3)
        lg.line(b.x,b.y,b.x+b.vx*0.16,b.y+b.vy*0.16)
    end
end
local function hud(w,h)
    local r=match.rods[match.selected]
    text("FOOSBALL LAB",38,22,fonts.title,colors.cream)
    text("Mouse fisico: gesto verticale = scorrimento  |  gesto orizzontale = rotazione",40,65,fonts.normal,colors.muted)
    local score=tostring(match.score[1]).."  :  "..tostring(match.score[2])
    text(score,w-200,21,fonts.title,colors.gold)
    text("TU      IA",w-184,67,fonts.small,colors.muted)
    local _,boardY,scale=transform()
    local bottom=boardY+Model.H*scale+67
    local angle=math.floor(r.angle*180/math.pi+0.5)
    text("ASTA "..match.selected.."  •  "..r.kind.."   |   rotazione "..angle.."°",45,bottom,fonts.normal,colors.cream)
    local captured=love.mouse.getRelativeMode()
    local help=captured and "MOUSE CATTURATO • ESC per sbloccare" or
        "Muovi il mouse per giocare • clic per catturarlo e non fermarti ai bordi"
    text(help,45,bottom+31,fonts.small,captured and colors.gold or colors.muted)
    text("1-4 cambia asta  |  rotella cambia asta  |  C neutralizza  |  [-][+] sensibilità  |  R ricomincia  |  F1 debug",
        45,h-40,fonts.small,colors.muted)
    if match.phase=="goal" or match.phase=="finished" then
        local message=match.phase=="finished" and
            (match.lastScorer==1 and "VITTORIA! • R per una nuova partita" or "SCONFITTA! • R per riprovare") or
            (match.lastScorer==1 and "GOL!" or "SEGNA L'IA!")
        lg.setFont(fonts.title)
        local width=lg.getFont():getWidth(message)
        paint({0.04,0.09,0.09},0.91)
        lg.rectangle("fill",(w-width)/2-22,h/2-25,width+44,68,13,13)
        text(message,(w-width)/2,h/2-13,fonts.title,colors.gold)
    end
end
function love.load()
    lg.setDefaultFilter("linear","linear")
    fonts.title=lg.newFont(31)
    fonts.normal=lg.newFont(17)
    fonts.small=lg.newFont(14)
    match=Model.new()
    love.window.setTitle("FOOSBALL LAB — Mouse Rods")
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
    lg.clear(0.025,0.068,0.074)
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
    elseif key=="c" then
        match:neutralRod()
    elseif key=="r" then
        match:reset()
    elseif key=="f1" then
        debugDraw=not debugDraw
    elseif key=="-" or key=="kp-" then
        match.mouseSensitivity.angle=math.max(0.007,match.mouseSensitivity.angle-0.002)
    elseif key=="=" or key=="+" or key=="kp+" then
        match.mouseSensitivity.angle=math.min(0.05,match.mouseSensitivity.angle+0.002)
    end
end
function love.focus(focused)
    if not focused then love.mouse.setRelativeMode(false) end
end
