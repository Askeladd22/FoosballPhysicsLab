-- Original neon football arena. Rendering never changes simulation state.
local View={}
local Camera=require("src.camera")
local FootballRoles=require("src.football_roles")
local Settings=require("src.tactical_settings")
local lg=love.graphics
local min,max,sqrt=math.min,math.max,math.sqrt
local fonts,ballTexture
local cyan={0.13,0.88,1}
local orange={1,0.46,0.18}
local ink={0.025,0.045,0.075}
local function tint(c,a) lg.setColor(c[1],c[2],c[3],a or 1) end
local function centered(str,x,y)
    lg.print(str,x-lg.getFont():getWidth(str)/2,y)
end
function View.load()
    fonts={
        score=lg.newFont(24),number=lg.newFont(11),numberSmall=lg.newFont(9),
        label=lg.newFont(13),small=lg.newFont(11),micro=lg.newFont(9)
    }
    local ok,tex=pcall(lg.newImage,"assets/etrusco_unico.png")
    if ok and tex then ballTexture=tex;ballTexture:setFilter("linear","linear") end
end
local function layout(f)
    local w,h=lg.getDimensions()
    return Camera.fit(f,w,h)
end
local function markingGeometry(f)
    lg.rectangle("line",0,0,f.w,f.h)
    lg.line(f.w/2,0,f.w/2,f.h)
    lg.circle("line",f.w/2,f.h/2,9.15)
    for _,side in ipairs({1,-1}) do
        local x=side==1 and 0 or f.w
        lg.rectangle("line",side==1 and 0 or f.w-16.5,f.h/2-20.16,16.5,40.32)
        lg.rectangle("line",side==1 and 0 or f.w-5.5,f.h/2-9.16,5.5,18.32)
        local cx=x+side*11
        for i=-20,19 do
            local a,b=i*0.0463,(i+1)*0.0463
            lg.line(cx+side*9.15*math.cos(a),f.h/2+9.15*math.sin(a),
                cx+side*9.15*math.cos(b),f.h/2+9.15*math.sin(b))
        end
        for _,edge in ipairs({0,f.h}) do
            local sy=edge==0 and 1 or -1
            for i=0,7 do
                local a,b=i*math.pi/16,(i+1)*math.pi/16
                lg.line(x+side*math.cos(a),edge+sy*math.sin(a),
                    x+side*math.cos(b),edge+sy*math.sin(b))
            end
        end
    end
end
local function drawNet(x,y,width,height,scale,color)
    tint(color,0.055);lg.rectangle("fill",x,y,width,height)
    tint(color,0.26);lg.setLineWidth(0.7/scale)
    for i=1,4 do lg.line(x+i*width/5,y,x+i*width/5,y+height) end
    for i=1,5 do lg.line(x,y+i*height/6,x+width,y+i*height/6) end
    tint(color,0.7);lg.setLineWidth(1.3/scale)
    lg.rectangle("line",x,y,width,height)
end
local function drawPitch(f,ox,oy,scale)
    lg.push();lg.translate(ox,oy);lg.scale(scale)
    lg.setColor(0.022,0.055,0.083);lg.rectangle("fill",-4.6,-2.5,f.w+9.2,f.h+5)
    lg.setColor(0.032,0.085,0.115);lg.rectangle("fill",0,0,f.w,f.h)
    for i=0,9 do
        if i%2==0 then
            lg.setColor(0.04,0.12,0.15,0.28)
            lg.rectangle("fill",i*f.w/10,0,f.w/10,f.h)
        end
    end
    tint(cyan,0.08);lg.setLineWidth(0.6/scale)
    for x=5,f.w-1,5 do lg.line(x,0,x,f.h) end
    for y=5,f.h-1,5 do lg.line(0,y,f.w,y) end
    -- Soft glow is drawn behind a fine, sharp core; no full-screen bloom.
    tint(cyan,0.09);lg.setLineWidth(5/scale);markingGeometry(f)
    lg.setColor(0.49,0.84,0.88,0.76);lg.setLineWidth(1.15/scale);markingGeometry(f)
    tint(cyan,0.85);lg.circle("fill",f.w/2,f.h/2,0.16)
    for _,x in ipairs({11,f.w-11}) do lg.circle("fill",x,f.h/2,0.16) end
    drawNet(-4.2,f.h/2-f.goalHalf,4.2,2*f.goalHalf,scale,cyan)
    drawNet(f.w,f.h/2-f.goalHalf,4.2,2*f.goalHalf,scale,orange)
    for _,x in ipairs({0,f.w}) do
        tint(x==0 and cyan or orange,0.95)
        for _,y in ipairs({f.h/2-f.goalHalf-f.postRadius,f.h/2+f.goalHalf+f.postRadius}) do
            lg.circle("fill",x,y,max(f.postRadius,1.5/scale))
        end
    end
    -- Sparse apron lights keep the arena legible without a noisy crowd texture.
    for i=0,20 do
        local x=i*f.w/20
        tint(i<10 and cyan or orange,0.45)
        lg.rectangle("fill",x-0.6,-1.6,1.2,0.18)
        lg.rectangle("fill",x-0.6,f.h+1.42,1.2,0.18)
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
    local rr=max(7,0.95*scale)
    local c=p.team==1 and cyan or orange
    local fx,fy=playerFacing(p)
    if p.sprinting and s.phase=="play" then
        for i=1,3 do
            local back=rr+2+i*4
            tint(c,0.3/i);lg.setLineWidth(1.6)
            lg.line(px-fx*back-fy*2,py-fy*back+fx*2,
                px-fx*(back+4)-fy*2,py-fy*(back+4)+fx*2)
        end
    end
    tint(c,0.055);lg.circle("fill",px,py,rr+4)
    lg.setColor(0.005,0.015,0.03,0.8);lg.circle("fill",px+1,py+2,rr+1)
    tint(c,0.2);lg.circle("fill",px,py,rr)
    tint(c,1);lg.setLineWidth(1.5);lg.circle("line",px,py,rr)
    if p.role=="GK" then
        lg.setColor(0.8,0.74,1,0.95)
        lg.setLineWidth(1);lg.circle("line",px,py,rr-2.1)
    end
    local numberFont=rr<8.5 and fonts.numberSmall or fonts.number
    lg.setFont(numberFont);lg.setColor(0.95,0.99,1)
    centered(tostring(p.number),px,py-numberFont:getHeight()/2)
    tint(c,0.95)
    lg.line(px+fx*(rr+1),py+fy*(rr+1),px+fx*(rr+3.5),py+fy*(rr+3.5))
    if p==s.controlled then
        local outer=rr+5.5
        lg.setColor(0.94,1,1,0.95);lg.setLineWidth(1.7)
        for _,dx in ipairs({-1,1}) do
            for _,dy in ipairs({-1,1}) do
                local xx,yy=px+dx*outer,py+dy*outer
                lg.line(xx-dx*4,yy,xx,yy,xx,yy-dy*4)
            end
        end
        lg.setFont(fonts.micro);tint(cyan,0.9)
        centered("TU",px,py-outer-13)
        if (p.controlFlash or 0)>0 or p.shielding then
            -- Contact feedback, not a possession ring: the ball remains free.
            tint(cyan,(p.controlFlash or 0)>0 and 0.9 or 0.35)
            lg.setLineWidth((p.controlFlash or 0)>0 and 2 or 1)
            lg.circle("line",px,py,rr+3)
        end
    end
    if debug and p~=s.controlled then
        tint(c,0.22);lg.setLineWidth(1)
        lg.line(px,py,ox+(p.targetX or p.x)*scale,oy+(p.targetY or p.y)*scale)
    end
end
local function drawBall(s,scale,ox,oy,debug)
    local b=s.ball
    local bx,by=ox+b.x*scale,oy+b.y*scale
    local radius=max(3,b.r*scale*0.65)
    lg.setColor(0,0.01,0.025,0.7);lg.ellipse("fill",bx+2,by+3,radius*1.15,radius*0.8)
    lg.setColor(0.8,0.95,1,0.10);lg.circle("fill",bx,by,radius+4)
    lg.setColor(0.85,0.98,1,0.55);lg.setLineWidth(1);lg.circle("line",bx,by,radius+1.5)
    lg.setColor(1,1,1);lg.circle("fill",bx,by,radius)
    if ballTexture then
        local k=2*radius/ballTexture:getWidth()
        lg.draw(ballTexture,bx,by,0,k,k,ballTexture:getWidth()/2,ballTexture:getHeight()/2)
    end
    if debug then
        tint(orange,0.8);lg.line(bx,by,bx+b.vx*scale*0.18,by+b.vy*scale*0.18)
    end
end
local function drawHumanAim(s,scale,ox,oy)
    if s.phase~="play" then return end
    local p,b=s.controlled,s.ball
    local dx,dy=p.x-b.x,p.y-b.y
    if dx*dx+dy*dy>(p.r+b.r+3.5)^2 then return end
    local vx,vy=p.facingX or 1,p.facingY or 0
    local sx,sy=ox+b.x*scale,oy+b.y*scale
    local ex,ey=sx+vx*11*scale,sy+vy*11*scale
    tint(cyan,0.45);lg.setLineWidth(1.5)
    lg.line(sx,sy,ex,ey)
    lg.circle("line",ex,ey,3)
end
local function drawPassTarget(s,scale,ox,oy,debug)
    local pass=s.activePass
    if not pass or not pass.receiver or (pass.team~=1 and not debug) then return end
    local p=pass.receiver
    tint(cyan,0.65);lg.setLineWidth(1)
    lg.circle("line",ox+p.x*scale,oy+p.y*scale,max(7,0.95*scale)+8)
    if p==s.controlled or debug then
        local tx,ty=ox+pass.targetX*scale,oy+pass.targetY*scale
        lg.line(tx-6,ty,tx+6,ty);lg.line(tx,ty-6,tx,ty+6)
        lg.circle("line",tx,ty,3)
    end
end
local function scoreboard(s,w)
    local left=w/2-220
    tint(ink,0.98);lg.rectangle("fill",left,5,440,34,4,4)
    lg.setColor(0.17,0.28,0.36);lg.setLineWidth(1);lg.rectangle("line",left,5,440,34,4,4)
    tint(cyan);lg.rectangle("fill",left,5,3,34)
    tint(orange);lg.rectangle("fill",left+437,5,3,34)
    lg.setFont(fonts.small)
    tint(cyan);centered("CYAN",left+56,16)
    tint(orange);centered("ARANCIO",left+384,16)
    lg.setFont(fonts.score);lg.setColor(0.95,0.99,1)
    centered(tostring(s.score[1]),left+132,7)
    centered(tostring(s.score[2]),left+308,7)
    local remaining=max(0,math.ceil((s.limit or 300)-s.elapsed))
    lg.setFont(fonts.label);tint(cyan,0.95)
    centered(string.format("%02d:%02d",math.floor(remaining/60),remaining%60),w/2,7)
    lg.setFont(fonts.micro);lg.setColor(0.46,0.61,0.69)
    centered("TEMPO RIMASTO",w/2,24)
    if w>=1150 then
        lg.setFont(fonts.label);lg.setColor(0.79,0.9,0.96);lg.print("MATCH LAB",24,8)
        lg.setFont(fonts.micro);tint(cyan,0.65);lg.print("105 x 68 / 11 CONTRO 11",24,26)
        lg.setColor(0.46,0.61,0.69);lg.print("CONTROLLO INDIVIDUALE",w-183,17)
    end
end
local function status(s,w,h)
    local message
    if s.phase=="paused" then message="PAUSA"
    elseif s.phase=="fulltime" then message="FINE PARTITA"
    elseif s.phase=="kickoff" or s.phase=="restart" then
        local labels={kickoff="CALCIO D'INIZIO",goal_kick="RINVIO DAL FONDO",
            corner="CALCIO D'ANGOLO",throw_in="RIMESSA LATERALE",offside="FUORIGIOCO"}
        local spec=s.setPiece
        message=spec and labels[spec.kind] or "RIPRESA"
        if spec then message=message..(spec.team==1 and " / CYAN" or " / ARANCIO") end
        if spec and spec.taker==s.controlled then message=message.." / SPAZIO per battere" end
    end
    if message then
        lg.setFont(fonts.micro);lg.setColor(0.83,0.94,0.98)
        lg.print(message,w/2+12,h-49)
    end
end
local function hud(s,ui,w,h)
    tint(ink,0.98);lg.rectangle("fill",0,h-52,w,52)
    tint(cyan,0.3);lg.setLineWidth(1);lg.line(18,h-52,w-18,h-52)
    lg.setFont(fonts.small);lg.setColor(0.94,0.98,1)
    local role=s.controlled.role=="GK" and "PORTIERE" or "CENTROCAMPISTA"
    local assigned=FootballRoles.get(s.controlled.tacticalRole)
    if assigned then
        local profile=Settings.profile(s,s.controlled)
        role=assigned.name.." / "..FootballRoles.dutyLabels[profile.duty]
        if w<1100 then lg.setFont(fonts.micro) end
    end
    lg.print(string.format("TU / #%d  %s",s.controlled.number,role),22,h-49)
    local controlHint
    if s.phase=="play" then
        if (s.controlled.controlFlash or 0)>0 then controlHint="PRIMO CONTROLLO"
        elseif s.controlled.shielding then controlHint="PROTEZIONE"
        elseif s.controlled.protectInput then controlHint="CONTROLLO"
        elseif s.controlled.sprinting then controlHint="SCATTO" end
    end
    if controlHint then
        lg.setFont(fonts.micro);tint(cyan);lg.print(controlHint,w/2-116,h-47)
    end
    local feedback
    if s.actionFeedback and s.actionFeedback.expires>s.elapsed then feedback=s.actionFeedback.message end
    if not feedback and s.activePass and s.activePass.receiver==s.controlled then feedback="Passaggio per te: vai incontro"
    elseif not feedback and s.combinationFeedback and s.combinationFeedback.expires>s.elapsed and
        s.combinationFeedback.player==s.controlled then
        local kind=s.combinationFeedback.kind
        local labels={one_two_run="Uno-due: attacca lo spazio",one_two_return="Uno-due: torna incontro",
            one_two_complete="Uno-due completato"}
        feedback=labels[kind]
    elseif not feedback and s.requestTimer>0 then feedback="Richiesta inviata: cerca spazio"
    elseif not feedback and s.passFeedback and s.elapsed-s.passFeedback.at<1.8 then
        local e=s.passFeedback
        local labels={completed="ricevuto",intercepted="intercettato",missed="perso"}
        feedback=(e.team==1 and "CYAN" or "ARANCIO")..": passaggio "..labels[e.result]
        if e.number then feedback=feedback.." da #"..e.number end
    end
    local coach=s.coaches and s.coaches[s.controlled.team]
    if not feedback and coach and coach.changedAt and s.elapsed-coach.changedAt<5 then
        feedback="ALLENATORE: "..coach.label.."  [T]"
    end
    if feedback and s.phase=="play" then lg.setFont(fonts.small);tint(cyan,0.9);lg.print(feedback,w/2+12,h-49) end
    lg.setFont(fonts.micro)
    for team=1,2 do
        local st=s.passStats[team]
        tint(team==1 and cyan or orange,0.76)
        lg.print(string.format("%s  Ricevuti: %d/%d | Intercetti: %d | Persi: %d",
            team==1 and "CYAN" or "ARANCIO",st.completed,st.attempts,st.intercepted,st.missed),
            team==1 and 22 or w/2+12,h-35)
    end
    lg.setColor(0.49,0.63,0.71)
    centered("WASD muovi | SHIFT scatto | CTRL controlla/proteggi | SPAZIO passa | TIENI SPAZIO tira",w/2,h-24)
    centered("Q+SPAZIO uno-due | E chiama | F2 tattica "..
        (s.autoCoachEnabled and "AUTO" or "STABILE")..
        " | T rapporto | P pausa | R reset | F1 debug | F11 schermo",w/2,h-12)
    if ui.charging then
        lg.setColor(0.05,0.1,0.15);lg.rectangle("fill",w/2-60,h-68,120,4)
        local shooting=ui.charge>=0.18
        tint(shooting and orange or cyan)
        lg.rectangle("fill",w/2-60,h-68,120*min(1,ui.charge/0.75),4)
        lg.setFont(fonts.micro)
        centered(shooting and "TIRO / rilascia SPAZIO" or "PASSAGGIO",w/2,h-82)
    end
end
function View.draw(s,ui)
    local f=s.field
    local scale,ox,oy,w,h,pw,ph=layout(f)
    lg.clear(0.012,0.023,0.041,1)
    -- Geometric frame around the arena, with restrained team-side lighting.
    tint(cyan,0.1);lg.setLineWidth(1)
    lg.line(ox-34,oy+ph*0.22,ox-34,oy+ph*0.78)
    tint(orange,0.1);lg.line(ox+pw+34,oy+ph*0.22,ox+pw+34,oy+ph*0.78)
    drawPitch(f,ox,oy,scale)
    if ui.debug and s.offside and s.offside.line then
        tint(orange,0.5);lg.setLineWidth(1)
        local x=ox+s.offside.line*scale
        for y=oy,oy+ph-7,14 do lg.line(x,y,x,min(y+7,oy+ph)) end
    end
    for _,p in ipairs(s.players) do drawPlayer(p,s,scale,ox,oy,ui.debug) end
    drawHumanAim(s,scale,ox,oy)
    drawPassTarget(s,scale,ox,oy,ui.debug)
    drawBall(s,scale,ox,oy,ui.debug)
    scoreboard(s,w);hud(s,ui,w,h);status(s,w,h)
    if ui.debug then
        lg.setFont(fonts.micro);lg.setColor(0.68,0.8,0.86)
        local offside=s.offsideCount or {0,0}
        lg.print(string.format("%s / tocchi %d / riprese %d / fuorigioco %d:%d",
            s.phase,s.lastTouch or 0,s.restartCount or 0,offside[1],offside[2]),18,h-79)
    end
    if s.phase=="fulltime" then
        tint(ink,0.96);lg.rectangle("fill",w/2-170,h/2-43,340,86,4,4)
        tint(cyan,0.55);lg.setLineWidth(1);lg.rectangle("line",w/2-170,h/2-43,340,86,4,4)
        lg.setFont(fonts.label);lg.setColor(0.87,0.95,0.99);centered("FINE PARTITA",w/2,h/2-27)
        lg.setFont(fonts.score);centered(string.format("%d  :  %d",s.score[1],s.score[2]),w/2,h/2-4)
    end
    if ui.chooseRole then
        lg.setColor(0.005,0.012,0.025,0.87);lg.rectangle("fill",0,0,w,h)
        local bw=min(480,w-48);local bx=(w-bw)/2
        tint(ink,0.98);lg.rectangle("fill",bx,h/2-142,bw,284,5,5)
        tint(cyan,0.7);lg.setLineWidth(1);lg.rectangle("line",bx,h/2-142,bw,284,5,5)
        lg.setFont(fonts.small);tint(cyan);centered("UN GIOCATORE. UNA SQUADRA.",w/2,h/2-117)
        lg.setFont(fonts.score);lg.setColor(0.92,0.98,1);centered("SCEGLI CHI CONTROLLARE",w/2,h/2-86)
        lg.setFont(fonts.label);tint(cyan,0.95);centered("1  PORTIERE  /  #1",w/2,h/2-31)
        lg.setColor(0.88,0.94,0.98);centered("2  CENTROCAMPISTA  /  #10",w/2,h/2+7)
        lg.setFont(fonts.small);lg.setColor(0.51,0.67,0.76)
        centered("11 contro 11 / 5 minuti / controllo fisso",w/2,h/2+65)
        centered("L'allenatore IA decide ruoli e istruzioni.",w/2,h/2+88)
    end
end
return View
