-- Rendering only. World coordinates and physical scale never depend on pixels.
local View={}
local lg=love.graphics
local min,max=math.min,math.max
local fonts,ballTexture
local function textCentered(txt,x,y)
    lg.print(txt,x-lg.getFont():getWidth(txt)/2,y)
end
function View.load()
    fonts={
        hud=lg.newFont(21),
        number=lg.newFont(12),
        label=lg.newFont(13),
        small=lg.newFont(11)
    }
    local ok,image=pcall(lg.newImage,"assets/etrusco_unico.png")
    if ok then
        ballTexture=image
        ballTexture:setFilter("linear","linear")
    end
end
local function layout(f)
    local w,h=lg.getDimensions()
    local scale=min((w-88)/(f.w+9),(h-158)/(f.h+12))
    scale=max(2,scale)
    local ox=(w-f.w*scale)/2
    local oy=85+(h-156-f.h*scale)/2
    return scale,ox,oy,w,h
end
local function rectangle(x,y,w,h)
    lg.rectangle("line",x,y,w,h)
end
function View.draw(s,ui)
    local f=s.field
    local scale,ox,oy,w,h=layout(f)
    lg.clear(0.095,0.105,0.10,1)
    -- Stadium texture, quiet enough to keep the play readable.
    lg.setColor(0.17,0.15,0.125)
    lg.rectangle("fill",0,0,w,h)
    for i=0,17 do
        lg.setColor(i%2==0 and 0.22 or 0.25,0.215,0.175,0.36)
        lg.rectangle("fill",0,i*34+16,w,12)
    end
    lg.push()
    lg.translate(ox,oy)
    lg.scale(scale)
    lg.setColor(0.13,0.36,0.255)
    lg.rectangle("fill",0,0,f.w,f.h)
    local stripes=12
    for i=0,stripes-1 do
        if i%2==0 then
            lg.setColor(0.17,0.405,0.282,0.75)
            lg.rectangle("fill",i*f.w/stripes,0,f.w/stripes,f.h)
        end
    end
    lg.setLineWidth(1.7/scale)
    lg.setColor(0.88,0.91,0.82,0.89)
    rectangle(0,0,f.w,f.h)
    lg.line(f.w/2,0,f.w/2,f.h)
    lg.circle("line",f.w/2,f.h/2,9.2)
    lg.circle("fill",f.w/2,f.h/2,0.24)
    rectangle(0,f.h/2-13.5,16,27)
    rectangle(f.w-16,f.h/2-13.5,16,27)
    rectangle(0,f.h/2-7.8,5.0,15.6)
    rectangle(f.w-5.0,f.h/2-7.8,5.0,15.6)
    lg.setColor(0.83,0.87,0.83)
    rectangle(-3.8,f.h/2-f.goalHalf,3.8,2*f.goalHalf)
    rectangle(f.w,f.h/2-f.goalHalf,3.8,2*f.goalHalf)
    lg.setColor(1,0.9,0.62)
    for _,x in ipairs({0,f.w}) do
        for _,y in ipairs({f.h/2-f.goalHalf,f.h/2+f.goalHalf}) do
            lg.circle("fill",x,y,f.postRadius)
        end
    end
    lg.pop()
    -- Player circles are outlined and labelled in screen space, not world space.
    lg.setFont(fonts.number)
    for _,p in ipairs(s.players) do
        local px,py=ox+p.x*scale,oy+p.y*scale
        local rr=p.r*scale
        if p==s.controlled then
            lg.setLineWidth(2.5)
            lg.setColor(1,0.82,0.25,0.9)
            lg.circle("line",px,py,rr+6)
            lg.polygon("fill",px,py-rr-12,px-4,py-rr-20,px+4,py-rr-20)
        end
        if p.team==1 then lg.setColor(0.095,0.43,0.86)
        else lg.setColor(0.78,0.21,0.24) end
        lg.circle("fill",px,py,rr)
        lg.setColor(0.95,0.96,0.96,0.96)
        lg.setLineWidth(1.8)
        lg.circle("line",px,py,rr)
        local number=tostring(p.number)
        textCentered(number,px,py-fonts.number:getHeight()/2)
        if ui.debug and p~=s.controlled then
            lg.setLineWidth(1)
            lg.setColor(1,1,1,0.23)
            lg.line(px,py,ox+p.targetX*scale,oy+p.targetY*scale)
        end
    end
    local b=s.ball
    local bx,by=ox+b.x*scale,oy+b.y*scale
    lg.setColor(0,0,0,0.48)
    lg.circle("fill",bx+2,by+2,b.r*scale+3)
    lg.setColor(1,1,1,1)
    if ballTexture then
        local sx=b.r*2*scale/ballTexture:getWidth()
        lg.draw(ballTexture,bx,by,b.angle or 0,sx,sx,ballTexture:getWidth()/2,ballTexture:getHeight()/2)
    else
        lg.circle("fill",bx,by,b.r*scale)
        lg.setColor(0.1,0.12,0.1)
        lg.circle("line",bx,by,b.r*scale)
    end
    -- Score strip and sparse player-focused controls.
    lg.setColor(0.055,0.073,0.073,0.94)
    lg.rectangle("fill",w/2-205,9,410,47,9,9)
    lg.setColor(0.2,0.59,0.99)
    lg.rectangle("fill",w/2-205,9,78,47,9,9)
    lg.setColor(0.88,0.24,0.27)
    lg.rectangle("fill",w/2+127,9,78,47,9,9)
    lg.setFont(fonts.hud)
    lg.setColor(1,1,1)
    textCentered("BLU",w/2-165,18)
    textCentered("ROSSI",w/2+164,18)
    textCentered(string.format("%d  -  %d",s.score[1],s.score[2]),w/2,18)
    lg.setFont(fonts.label)
    lg.setColor(0.98,0.96,0.9)
    local minute=math.floor(s.elapsed/60)
    local second=math.floor(s.elapsed%60)
    textCentered(string.format("%02d:%02d",minute,second),w/2,60)
    if s.phase=="fulltime" then
        lg.setColor(0.02,0.03,0.03,0.78)
        lg.rectangle("fill",w/2-180,h/2-38,360,76,12,12)
        lg.setColor(1,1,1)
        lg.setFont(fonts.hud)
        textCentered("FINE PARTITA",w/2,h/2-12)
    elseif s.phase=="kickoff" then
        lg.setColor(1,1,1,0.93)
        textCentered("CALCIO D'INIZIO",w/2,oy-30)
    elseif s.phase=="restart" then
        lg.setColor(1,1,1,0.93)
        textCentered("RIPRESA DEL GIOCO",w/2,oy-30)
    elseif s.phase=="paused" then
        lg.setColor(1,1,1,0.9)
        textCentered("PAUSA",w/2,oy-30)
    end
    lg.setFont(fonts.label)
    lg.setColor(0.87,0.88,0.86)
    local controls="WASD: movimento  |  SPAZIO: calcio  |  E: chiama passaggio  |  C: tiro rapido/caricato  |  P: pausa  |  R: ricomincia  |  F1: debug"
    textCentered(controls,w/2,h-46)
    local mode=ui.mode=="charge" and "CARICATO" or "RAPIDO"
    local line=string.format("Tiro %s  |  Velocita %.1f (N/M)  |  Attrito palla %.2f (J/K)",mode,s.params.maxSpeed,s.params.ballDrag)
    lg.setColor(0.72,0.8,0.73)
    textCentered(line,w/2,h-26)
    if ui.mode=="charge" and ui.charging then
        lg.setColor(0.1,0.1,0.1,0.8)
        lg.rectangle("fill",w/2-60,h-76,120,8,4,4)
        lg.setColor(1,0.78,0.24)
        lg.rectangle("fill",w/2-60,h-76,120*(ui.charge/0.6),8,4,4)
    end
    if ui.debug then
        lg.setFont(fonts.small)
        lg.setColor(1,1,1,0.85)
        lg.print(string.format("Phase: %s   Ball: %.1f   Last touch: %d   Kicks: %d",s.phase,
            math.sqrt(b.vx*b.vx+b.vy*b.vy),s.lastTouch,s.totalKicks),14,17)
    end
end
return View
