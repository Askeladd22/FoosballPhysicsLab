-- Read-only report of the AI coach's decisions. No tactical setter is exposed.
local Settings=require("src.tactical_settings")
local Roles=require("src.football_roles")
local Panel={}
local positions={GK="Portiere",DC="Difensore centrale",DL="Terzino sinistro",DR="Terzino destro",WBL="Esterno sinistro",WBR="Esterno destro",DM="Mediano",MC="Centrocampista centrale",ML="Esterno di centrocampo SX",MR="Esterno di centrocampo DX",AML="Ala sinistra",AMR="Ala destra",AMC="Trequartista",ST="Punta"}
local tabs={"ASSETTO", "SQUADRA", "CALCIATORE"}
local function opt(value,label) return {value=value,label=label} end
function Panel.new() return {team=1,player=1,tab=1,selected=1,scroll=0,message="",hits={}} end
local function roster(s,team)
    local out={};for _,p in ipairs(s.players) do if p.team==team then out[#out+1]=p end end
    return out
end
function Panel.player(state,s)
    local players=roster(s,state.team)
    state.player=math.max(1,math.min(#players,state.player))
    return players[state.player]
end
function Panel.rows(state,s)
    local p=Panel.player(state,s)
    if state.tab==2 then return Settings.teamInstructionList end
    if state.tab==3 then return Settings.playerInstructionList end
    local formations={};for _,f in ipairs(Settings.formations) do formations[#formations+1]=opt(f.id,f.id) end
    local available={};for _,position in ipairs(Settings.positionList) do
        if (p.role=="GK")== (position=="GK") then available[#available+1]=opt(position,positions[position]) end
    end
    local roles={};for _,r in ipairs(Roles.forPosition(p.position)) do roles[#roles+1]=opt(r.id,r.name) end
    local duties={};for _,duty in ipairs(Roles.get(p.tacticalRole).duties) do duties[#duties+1]=opt(duty,Roles.dutyLabels[duty]) end
    return {
        {id="formation",label="Modulo della squadra",section="Organizzazione",options=formations,hint="L'allenatore IA sceglie modulo e istruzioni in base all'andamento della partita."},
        {id="position",label="Posizione del calciatore",section="Assegnazione",options=available,hint="Posizione assegnata dall'allenatore IA. Tu resti sempre al controllo dello stesso calciatore."},
        {id="role",label="Ruolo",section="Assegnazione",options=roles,hint=Roles.get(p.tacticalRole).description},
        {id="duty",label="Compito",section="Assegnazione",options=duties,hint="Il compito modifica profondità, copertura e inserimenti. Automatico segue la mentalità della squadra."}
    }
end
function Panel.value(state,s,row)
    local p=Panel.player(state,s)
    if state.tab==2 then return s.teamTactics[state.team].instructions[row.id] end
    if state.tab==3 then return p.instructions[row.id] end
    if row.id=="formation" then return s.teamTactics[state.team].formation end
    if row.id=="position" then return p.position end
    if row.id=="role" then return p.tacticalRole end
    return p.duty
end
function Panel.change(state,s,direction)
    -- Keep this entry point explicitly non-mutating for all input paths.
    return false
end
local function selectTab(state,tab)
    state.tab=tab;state.selected=1;state.scroll=0;state.message=""
end
function Panel.keypressed(state,s,key)
    if key=="tab" then selectTab(state,state.tab%3+1)
    elseif key=="1" or key=="2" then state.team=tonumber(key);state.message=""
    elseif key=="up" then state.selected=math.max(1,state.selected-1)
    elseif key=="down" then state.selected=math.min(#Panel.rows(state,s),state.selected+1)
    elseif key=="[" then state.player=(state.player-2)%11+1
    elseif key=="]" then state.player=state.player%11+1
    elseif key=="pageup" then state.selected=math.max(1,state.selected-5)
    elseif key=="pagedown" then state.selected=math.min(#Panel.rows(state,s),state.selected+5) end
end
function Panel.mousepressed(state,s,x,y,button)
    if button~=1 then return end
    for _,hit in ipairs(state.hits) do
        if x>=hit.x and x<=hit.x+hit.w and y>=hit.y and y<=hit.y+hit.h then
            if hit.kind=="close" then return "close"
            elseif hit.kind=="tab" then selectTab(state,hit.index)
            elseif hit.kind=="team" then state.team=3-state.team
            elseif hit.kind=="player" then state.player=hit.index;state.message=""
            elseif hit.kind=="row" then
                state.selected=hit.index
            end
            return
        end
    end
end
function Panel.wheelmoved(state,s,dy)
    if dy==0 then return end
    state.selected=math.max(1,math.min(#Panel.rows(state,s),state.selected-(dy>0 and 1 or -1)*2))
end
local fonts
function Panel.draw(state,s)
    local lg=love.graphics
    if not fonts then fonts={title=lg.newFont(22),body=lg.newFont(14),small=lg.newFont(11),number=lg.newFont(16)} end
    local w,h=lg.getDimensions();local x,y=24,24;local pw,ph=w-48,h-48
    local accent=state.team==1 and {0.18,.9,1} or {1,.5,.22}
    local function color(c,a) lg.setColor(c[1],c[2],c[3],a or 1) end
    local function text(str,tx,ty,font,c) lg.setFont(font or fonts.body);color(c or {.83,.91,.96});lg.print(str,tx,ty) end
    local function fit(str,tx,ty,width,font,c)
        lg.setFont(font);color(c or {.83,.91,.96})
        local scale=math.min(1,width/math.max(1,font:getWidth(str)))
        lg.print(str,tx,ty,0,scale,1)
    end
    state.hits={}
    local function hit(kind,index,hx,hy,hw,hh) state.hits[#state.hits+1]={kind=kind,index=index,x=hx,y=hy,w=hw,h=hh} end
    lg.push("all");lg.origin();lg.setColor(.008,.018,.035,.92);lg.rectangle("fill",0,0,w,h)
    lg.setColor(.018,.038,.064,.99);lg.rectangle("fill",x,y,pw,ph,10)
    color(accent,.55);lg.setLineWidth(1);lg.rectangle("line",x,y,pw,ph,10)
    text("ALLENATORE IA",x+22,y+17,fonts.title)
    text("PARTITA IN PAUSA  /  DECISIONI AUTOMATICHE",x+23,y+46,fonts.small,accent)
    text("T / ESC   RIPRENDI",x+pw-170,y+26,fonts.small,accent);hit("close",0,x+pw-183,y+10,170,48)
    local top=y+80;local left=x+18;local lw=210;local rx=left+lw+22;local rw=pw-lw-58
    color(accent,.1);lg.rectangle("fill",left,top,lw,34,4)
    text(state.team==1 and "CYAN  /  SQUADRA 1" or "AMBER  /  SQUADRA 2",left+10,top+9,fonts.small,accent)
    hit("team",0,left,top,lw,34)
    for n,label in ipairs(tabs) do
        local tx=rx+(n-1)*rw/3
        if state.tab==n then color(accent,.15);lg.rectangle("fill",tx,top,rw/3-5,34,4) end
        text(label,tx+9,top+9,fonts.small,state.tab==n and accent or {.5,.63,.72})
        hit("tab",n,tx,top,rw/3-5,34)
    end
    local bodyY=top+48;local footerY=y+ph-65;local rosterHeight=math.min(32,(footerY-bodyY-22)/11)
    for i,p in ipairs(roster(s,state.team)) do
        local py=bodyY+(i-1)*rosterHeight
        if i==state.player then color(accent,.12);lg.rectangle("fill",left,py,lw,rosterHeight-2,4) end
        text(string.format("%02d",p.number),left+8,py+1,fonts.body,i==state.player and accent or {.65,.76,.82})
        local marker=p==s.controlled and "  • TU" or ""
        text(p.position..marker,left+41,py+2,fonts.small)
        fit(Roles.get(p.tacticalRole).name,left+8,py+17,lw-16,fonts.small,{.5,.65,.73})
        hit("player",i,left,py,lw,rosterHeight)
    end
    text("[ / ]  seleziona calciatore",left,bodyY+11*rosterHeight+7,fonts.small,{.45,.6,.69})
    local coach=s.coaches and s.coaches[state.team]
    text(coach and coach.label or "Equilibrio iniziale",rx+12,bodyY,fonts.body,accent)
    lg.setFont(fonts.small);color({.55,.7,.79})
    lg.printf(coach and coach.reason or "L'allenatore osserva lo sviluppo della partita.",rx+12,bodyY+20,rw-24,"left")
    bodyY=bodyY+54
    local rows=Panel.rows(state,s);state.selected=math.max(1,math.min(#rows,state.selected))
    local rowHeight=49;local visible=math.max(1,math.floor((footerY-bodyY-12)/rowHeight))
    if state.selected<=state.scroll then state.scroll=state.selected-1 end
    if state.selected>state.scroll+visible then state.scroll=state.selected-visible end
    state.scroll=math.max(0,math.min(math.max(0,#rows-visible),state.scroll))
    for j=1,visible do
        local index=state.scroll+j;local row=rows[index];if not row then break end
        local ry=bodyY+(j-1)*rowHeight;local selected=index==state.selected
        lg.setColor(.04,.08,.115,selected and 1 or .5);lg.rectangle("fill",rx,ry,rw,rowHeight-5,4)
        if selected then color(accent,.8);lg.rectangle("fill",rx,ry,3,rowHeight-5) end
        local foreground=row.disabled and {.4,.49,.55} or {.82,.9,.95}
        text(row.section:upper(),rx+12,ry+5,fonts.small,{.4,.56,.65})
        fit(row.label,rx+12,ry+21,rw*.45-18,fonts.body,foreground)
        local label=""
        local value=Panel.value(state,s,row)
        for _,o in ipairs(row.options) do if o.value==value then label=o.label end end
        if state.tab==1 and row.id=="formation" and s.teamTactics[state.team].custom then label=label.." (modificato)" end
        fit(label,rx+rw*.47,ry+21,rw*.51-8,fonts.body,row.disabled and foreground or accent)
        hit("row",index,rx,ry,rw,rowHeight-5)
    end
    if #rows>visible then text(string.format("%d / %d   SU / GIU",state.selected,#rows),rx+rw-150,footerY-15,fonts.small,{.45,.6,.69}) end
    if state.tab==1 then
        local p=Panel.player(state,s);local profile=Settings.profile(s,p);local start=bodyY+4*rowHeight+12
        text("TENDENZE CON LE ISTRUZIONI ATTUALI",rx+12,start,fonts.small,{.5,.66,.75})
        local indicators={{"Profondità","depth"},{"Pressing","pressing"},{"Passaggi diretti","passing"},{"Dribbling","dribbling"},{"Tiri","shooting"},{"Inserimenti","runs"}}
        for n,v in ipairs(indicators) do
            local col=(n-1)%3;local line=math.floor((n-1)/3);local bx=rx+12+col*rw/3;local by=start+24+line*40
            if by+26<footerY then
                text(v[1],bx,by,fonts.small,{.6,.72,.8})
                lg.setColor(.09,.16,.2);lg.rectangle("fill",bx,by+18,rw/3-26,3)
                color(accent,.8);lg.rectangle("fill",bx,by+18,(rw/3-26)*((profile[v[2]] or 0)+1)/2,3)
            end
        end
    end
    color(accent,.15);lg.line(left,footerY-6,x+pw-18,footerY-6)
    local hint=state.message~="" and state.message or rows[state.selected].hint
    lg.setFont(fonts.small);color({.64,.77,.84});lg.printf(hint,left,footerY+3,pw-40,"left")
    text("SOLA LETTURA   TAB sezione   SU/GIU voce   1/2 squadra   rotella/clic naviga",left,y+ph-21,fonts.small,{.4,.58,.68})
    lg.pop()
end
return Panel
