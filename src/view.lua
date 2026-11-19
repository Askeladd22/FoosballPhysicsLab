-- Match Lab v0.2.1 presentation: original Football-Manager-style classic 2D.
-- The camera changes only rendering; all physics remain in independent world units.
local View={}
local lg=love.graphics
local min,max,abs,sqrt=math.min,math.max,math.abs,math.sqrt
local fonts,ballTexture
local function centered(str,x,y)
    lg.print(str,x-lg.getFont():getWidth(str)/2,y)
end
function View.load()
    fonts={
        score=lg.newFont(20),
        number=lg.newFont(11),
        label=lg.newFont(13),
        small=lg.newFont(11)
    }
    local ok,tex=pcall(lg.newImage,"assets/etrusco_unico.png")
    if ok and tex then
        ballTexture=tex
        ballTexture:setFilter("linear","linear")
    end
end
local function layout(f)
    local w,h=lg.getDimensions()
    local top,bottom=100,76
    local scale=min((w-94)/f.w,(h-top-bottom)/f.h)
    local pitchW,pitchH=scale*f.w,scale*f.h
    local ox=(w-pitchW)/2
    local oy=top+(h-top-bottom-pitchH)/2
    return scale,ox,oy,w,h,pitchW,pitchH
end
local function drawNet(x,y,width,height,scale)
    lg.setColor(0.94,0.97,0.95,0.075)
    lg.rectangle("fill",x,y,width,height)
    lg.setColor(0.90,0.95,0.95,0.27)
    lg.setLineWidth(1.0/scale)
    lg.rectangle("line",x,y,width,height)
    for i=1,4 do
        local xx=x+i*width/5
        lg.line(xx,y,xx,y+height)
    end
    for i=1,8 do
        local yy=y+i*height/9
        lg.line(x,yy,x+width,yy)
    end
end
local function drawPitch(f,ox,oy,scale)
    lg.push()
    lg.translate(ox,oy)
    lg.scale(scale)
    lg.setColor(0.18,0.40,0.24)
    lg.rectangle("fill",-4,-4,f.w+8,f.h+8)
    lg.setColor(0.16,0.35,0.235)
    lg.rectangle("fill",0,0,f.w,f.h)
    for i=0,11 do
        if i%2==0 then
            lg.setColor(0.18,0.397,0.26,0.72)
            lg.rectangle("fill",i*f.w/12,0,f.w/12,f.h)
        end
    end
    -- Ground markings deliberately thin, as in a classic 2D match viewer.
    lg.setLineWidth(1.35/scale)
    lg.setColor(0.92,0.95,0.90,0.88)
    lg.rectangle("line",0,0,f.w,f.h)
    lg.line(f.w/2,0,f.w/2,f.h)
    lg.circle("line",f.w/2,f.h/2,9.15)
    lg.circle("fill",f.w/2,f.h/2,0.18)
    lg.rectangle("line",0,f.h/2-13.5,16,27)
    lg.rectangle("line",f.w-16,f.h/2-13.5,16,27)
    lg.rectangle("line",0,f.h/2-7.8,5.2,15.6)
    lg.rectangle("line",f.w-5.2,f.h/2-7.8,5.2,15.6)
    lg.circle("fill",11,f.h/2,0.17)
    lg.circle("fill",f.w-11,f.h/2,0.17)
    -- Semi-transparent mesh and accurate post highlights.
    drawNet(-4.4,f.h/2-f.goalHalf,4.4,2*f.goalHalf,scale)
    drawNet(f.w,f.h/2-f.goalHalf,4.4,2*f.goalHalf,scale)
    lg.setColor(0.96,0.94,0.82)
    for _,x in ipairs({0,f.w}) do
        for _,y in ipairs({f.h/2-f.goalHalf,f.h/2+f.goalHalf}) do
            lg.circle("fill",x,y,f.postRadius)
        end
    end
    lg.pop()
end
local function playerFacing(p)
    local speed=sqrt(p.vx*p.vx+p.vy*p.vy)
    if speed>0.35 then return p.vx/speed,p.vy/speed end
    return p.team==1 and 1 or -1,0
end
local function drawPlayer(p,s,scale,ox,oy,debug)
    local px,py=ox+p.x*scale,oy+p.y*scale
    local rr=p.r*scale
    lg.setColor(0.02,0.04,0.03,0.32)
    lg.circle("fill",px+1.4,py+2.5,rr+1.1)
    if p==s.controlled then
        lg.setColor(1,0.79,0.16,0.92)
        lg.setLineWidth(2.2)
        lg.circle("line",px,py,rr+4.2)
    end
    if p.team==1 then lg.setColor(0.105,0.45,0.91)
    else lg.setColor(0.82,0.22,0.245) end
    lg.circle("fill",px,py,rr)
    lg.setColor(0.97,0.98,0.97)
    lg.setLineWidth(1.2)
    lg.circle("line",px,py,rr)
    lg.setFont(fonts.number)
    local number=tostring(p.number)
    lg.setColor(1,1,1)
    centered(number,px,py-fonts.number:getHeight()/2)
    -- FM27-inspired feet indicate facing without a large direction arrow.
    local fx,fy=playerFacing(p)
    local tx,ty=-fy,fx
    local front=rr*0.78
    local separation=rr*0.23
    for _,sign in ipairs({-1,1}) do
        local footX=px+fx*front+tx*separation*sign
        local footY=py+fy*front+ty*separation*sign
        lg.setColor(0.02,0.045,0.035,0.85)
        lg.circle("fill",footX+0.5,footY+0.5,2.2)
        lg.setColor(0.96,0.95,0.89,0.9)
        lg.circle("fill",footX,footY,1.35)
    end
    if debug and p~=s.controlled then
        lg.setColor(1,1,1,0.23)
        lg.setLineWidth(1)
        lg.line(px,py,ox+(p.targetX or p.x)*scale,oy+(p.targetY or p.y)*scale)
    end
end
local function drawBall(s,scale,ox,oy,debug)
    local b=s.ball
    local bx,by=ox+b.x*scale,oy+b.y*scale
    local radius=b.r*scale
    -- Wider, darker shadow improves ball tracking even at low resolutions.
    lg.setColor(0.01,0.025,0.015,0.57)
    lg.ellipse("fill",bx+2.3,by+3.3,radius*1.22,radius*0.85)
    lg.setColor(1,1,1)
    if ballTexture then
        local k=2*radius/ballTexture:getWidth()
        lg.draw(ballTexture,bx,by,0,k,k,ballTexture:getWidth()/2,ballTexture:getHeight()/2)
    else
        lg.circle("fill",bx,by,radius)
        lg.setColor(0.13,0.16,0.12)
        lg.setLineWidth(1)
        lg.circle("line",bx,by,radius)
    end
    if debug then
        lg.setColor(1,0.8,0.22,0.8)
        lg.line(bx,by,bx+b.vx*scale*0.18,by+b.vy*scale*0.18)
    end
end
function View.draw(s,ui)
    local f=s.field
    local scale,ox,oy,w,h,pitchW,pitchH=layout(f)
    lg.clear(0.07,0.09,0.075,1)
    -- Clean, subtle sideline surrounds instead of the old striped brown fill.
    lg.setColor(0.145,0.16,0.14)
    lg.rectangle("fill",0,0,w,h)
    lg.setColor(0.12,0.14,0.12)
    for n=0,7 do
        lg.rectangle("fill",0,n*10,w,4)
        lg.rectangle("fill",0,h-n*10-4,w,4)
    end
    lg.setColor(0.07,0.09,0.07)
    lg.rectangle("fill",ox-14,oy-14,pitchW+28,pitchH+28)
    drawPitch(f,ox,oy,scale)
    for _,p in ipairs(s.players) do drawPlayer(p,s,scale,ox,oy,ui.debug) end
    drawBall(s,scale,ox,oy,ui.debug)
    -- Compact top scoreboard, not a management-heavy Football Manager HUD.
    local barY=10
    lg.setColor(0.055,0.075,0.075,0.93)
    lg.rectangle("fill",w/2-185,barY,370,47,7,7)
    lg.setColor(0.13,0.45,0.82)
    lg.rectangle("fill",w/2-185,barY,72,47,7,7)
    lg.setColor(0.77,0.18,0.23)
    lg.rectangle("fill",w/2+113,barY,72,47,7,7)
    lg.setColor(1,1,1)
    lg.setFont(fonts.label)
    centered("BLU",w/2-149,barY+14)
    centered("ROSSI",w/2+149,barY+14)
    lg.setFont(fonts.score)
    centered(string.format("%d  -  %d",s.score[1],s.score[2]),w/2,barY+10)
    lg.setFont(fonts.label)
    lg.setColor(0.93,0.93,0.88)
    centered(string.format("%02d:%02d",math.floor(s.elapsed/60),math.floor(s.elapsed%60)),w/2,64)
    if s.phase=="fulltime" then
        lg.setColor(0.025,0.035,0.03,0.78)
        lg.rectangle("fill",w/2-145,h/2-28,290,56,10,10)
        lg.setColor(1,1,1)
        lg.setFont(fonts.score)
        centered("FINE PARTITA",w/2,h/2-12)
    elseif s.phase=="paused" then
        lg.setColor(1,1,1,0.9)
        centered("PAUSA",w/2,oy-28)
    elseif s.phase=="kickoff" or s.phase=="restart" then
        lg.setColor(1,1,1,0.9)
        centered(s.phase=="kickoff" and "CALCIO D'INIZIO" or "RIMESSA",w/2,oy-28)
    end
    -- Slim match information and controls.
    lg.setColor(0.055,0.075,0.065,0.95)
    lg.rectangle("fill",0,h-67,w,67)
    lg.setColor(0.31,0.68,0.9)
    lg.rectangle("fill",0,h-67,7,67)
    lg.setFont(fonts.label)
    lg.setColor(0.96,0.97,0.95)
    lg.print("BLU  #10  |  Centrocampista",22,h-55)
    lg.setColor(0.80,0.84,0.8)
    centered(string.format("Passaggi: %d  |  Tiri: %d  |  Calci: %d",
        s.passAttempts or 0,s.shotAttempts or 0,s.totalKicks or 0),w/2,h-55)
    lg.setFont(fonts.small)
    lg.setColor(0.82,0.85,0.8)
    centered("WASD muovi  |  SPAZIO calcia  |  E chiama passaggio  |  C tipo tiro  |  P pausa  |  R riavvia  |  F1 debug",w/2,h-28)
    if ui.debug then
        lg.setFont(fonts.small)
        lg.setColor(1,1,1,0.88)
        lg.print(string.format("Fase: %s  •  Ultimo tocco: %d  •  Rimesse: %d  •  Ultima azione: %s",
            s.phase,s.lastTouch or 0,s.restartCount or 0,s.lastAction or ""),12,15)
    end
    if ui.mode=="charge" and ui.charging then
        lg.setColor(0.08,0.08,0.08,0.85)
        lg.rectangle("fill",w/2-56,h-81,112,7,3,3)
        lg.setColor(0.99,0.77,0.20)
        lg.rectangle("fill",w/2-56,h-81,112*(ui.charge/0.6),7,3,3)
    end
end
return View
