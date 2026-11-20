-- FM24 terminology; original, bounded adapters for this ground-ball simulation.
local Roles=require("src.football_roles")
local Settings={}
local function clamp(v) return math.max(-1,math.min(1,v)) end
local function option(value,label) return {value=value,label=label} end
local levels={option(-1,"Molto meno"),option(-0.5,"Meno"),option(0,"Standard"),option(0.5,"Più"),option(1,"Molto più")}
local three={option(-1,"Meno"),option(0,"Standard"),option(1,"Più")}
local yesno={option(false,"No"),option(true,"Sì")}
local function row(id,label,options,default,section,hint,disabled)
    return {id=id,label=label,options=options,default=default,section=section,hint=hint,disabled=disabled}
end
Settings.teamInstructionList={
    row("mentality","Mentalità",{option(-1,"Molto difensiva"),option(-0.65,"Difensiva"),option(-0.4,"Prudente"),option(0,"Equilibrata"),option(0.3,"Positiva"),option(0.65,"Offensiva"),option(1,"Molto offensiva")},0,"Identità","Influenza compiti automatici, profondità e rischio."),
    row("width","Ampiezza",levels,0,"In possesso","Allarga o restringe le posizioni di appoggio."),
    row("passing","Passaggi diretti",levels,0,"In possesso","Preferenza per distanze maggiori o appoggi corti, entro la portata fisica."),
    row("tempo","Ritmo",levels,0,"In possesso","Modifica velocità di sostegno e priorità di rilascio della palla."),
    row("passIntoSpace","Passa negli spazi",yesno,false,"In possesso","Premia destinatari che attaccano spazio libero davanti alla palla."),
    row("focus","Sviluppo del gioco",{option("mixed","Misto"),option("left","A sinistra"),option("right","A destra"),option("centre","Al centro")},"mixed","In possesso","Premia le linee di passaggio nella zona scelta."),
    row("playOut","Costruisci dalla difesa",yesno,false,"In possesso","Difensori e portiere preferiscono appoggi corti."),
    row("finalThird","Ultimi metri",{option("mixed","Equilibrato"),option("work","Porta la palla in area"),option("shoot","Tira appena possibile"),option("early","Crossa prima")},"mixed","In possesso","Modifica priorità di tiro o traversone rasoterra."),
    row("dribbling","Dribbling",three,0,"In possesso","Aumenta o riduce la scelta di portare palla."),
    row("freedom","Libertà creativa",{option("disciplined","Più disciplinati"),option("balanced","Equilibrata"),option("expressive","Più creativi")},"balanced","In possesso","Libertà di movimento rispetto alla posizione assegnata."),
    row("overlap","Corse di sostegno",{option("none","Secondo il ruolo"),option("left","Sovrapponi a sinistra"),option("right","Sovrapponi a destra"),option("both","Sovrapponi sui due lati"),option("under_left","Sottoponi a sinistra"),option("under_right","Sottoponi a destra"),option("under_both","Sottoponi sui due lati")},"none","In possesso","Favorisce corse esterne o interne sul lato richiesto."),
    row("transitionLoss","Persa la palla",{option("balanced","Equilibrato"),option("counterpress","Contropressing"),option("regroup","Ripiega")},"balanced","Transizioni","Cambia l'aggressività della prima pressione dopo la perdita."),
    row("transitionWin","Recuperata la palla",{option("balanced","Equilibrato"),option("counter","Contropiede"),option("hold","Mantieni la posizione")},"balanced","Transizioni","Verticalizza oppure conserva gli appoggi dopo il recupero."),
    row("distribution","Distribuzione portiere",{option("mixed","Secondo il ruolo"),option("short","Difensori / corto"),option("long","In profondità"),option("flanks","Sulle fasce"),option("playmaker","Al regista"),option("target","Al fulcro del gioco")},"mixed","Transizioni","Sceglie il tipo di destinatario; tutti i lanci restano rasoterra."),
    row("defensiveLine","Linea difensiva",levels,0,"Non in possesso","Alza o abbassa la posizione di copertura."),
    row("engagement","Linea di pressione",three,0,"Non in possesso","Determina quanto avanti iniziare la pressione."),
    row("pressing","Intensità pressing",levels,0,"Non in possesso","Modifica la disponibilità a uscire sul portatore."),
    row("preventShortGK","Impedisci rinvio corto",yesno,false,"Non in possesso","Avvicina il primo pressatore al portiere avversario."),
    row("trap","Indirizza la pressione",{option("balanced","Equilibrata"),option("inside","Verso il centro"),option("outside","Verso l'esterno")},"balanced","Non in possesso","Cambia il lato di approccio del pressatore."),
    row("crossHeight","Altezza dei cross",{option("ground","Solo rasoterra")},"ground","Sistemi futuri","Cross alti e tesi richiedono altezza della palla e gioco aereo.",true),
    row("tackling","Aggressività contrasti",{option("physical","Contatto fisico")},"physical","Sistemi futuri","Entra deciso / resta in piedi richiedono contrasti, falli e cartellini.",true),
    row("keeperHands","Rilascio dalle mani",{option("ground","Palla a terra")},"ground","Sistemi futuri","Rotola / lancia richiedono presa e possesso del portiere.",true),
    row("timeWasting","Perdita di tempo",{option("none","Non modellata")},"none","Sistemi futuri","Manca una gestione arbitrale delle perdite di tempo.",true),
    row("setPieces","Cerca calci piazzati",{option("none","Non modellato")},"none","Sistemi futuri","Manca la scelta intenzionale di cercare falli o deviazioni.",true),
    row("crossDefence","Impedisci / invita cross",{option("none","Non modellato")},"none","Sistemi futuri","Serve un modello di difesa dei cross e delle traiettorie aeree.",true)
}
Settings.playerInstructionList={
    row("depth","Movimento verticale",{option("role","Secondo il ruolo"),option("forward","Vai più avanti"),option("hold","Mantieni posizione")},"role","Senza palla","L'allenatore indica se attaccare profondità o conservare la copertura."),
    row("width","Posizione laterale",{option("role","Secondo il ruolo"),option("wide","Stai più largo"),option("narrow","Stringi")},"role","Senza palla","Allarga o restringe l'appoggio rispetto alla corsia naturale."),
    row("roam","Libertà di movimento",{option("role","Secondo il ruolo"),option("yes","Muoviti liberamente"),option("no","Rispetta la posizione")},"role","Senza palla","Sceglie quanto seguire le opportunità fuori dalla zona iniziale."),
    row("channels","Muoviti negli spazi",yesno,false,"Senza palla","Aumenta gli inserimenti tra le linee."),
    row("pressing","Intensità pressing",three,0,"Non in possesso","Modifica la propensione individuale a uscire sul portatore."),
    row("markTighter","Marca più stretto",yesno,false,"Non in possesso","Riduce la distanza dal riferimento nella marcatura di zona."),
    row("markPosition","Marca una posizione",{option("none","Nessuna"),option("ST","Punta"),option("AMC","Trequartista"),option("MC","Centrocampista"),option("AML","Ala sinistra"),option("AMR","Ala destra")},"none","Non in possesso","Dà priorità a una posizione avversaria nella propria zona."),
    row("shooting","Frequenza tiri",three,0,"Con la palla","Modifica il punteggio delle occasioni di tiro raggiungibili."),
    row("dribbling","Dribbling",three,0,"Con la palla","Modifica la preferenza per un tocco in conduzione."),
    row("carryDirection","Direzione dribbling",{option("role","Secondo il ruolo"),option("mixed","Mista"),option("inside","Taglia dentro"),option("wide","Corri all'esterno")},"role","Con la palla","Favorisce corridoi interni o esterni liberi."),
    row("passing","Passaggi diretti",three,0,"Con la palla","Accorcia o allunga la distanza preferita del passaggio."),
    row("risk","Rischio passaggi",three,0,"Con la palla","Tollera più o meno rischio nelle linee di passaggio."),
    row("holdUp","Proteggi e aspetta",{option("role","Secondo il ruolo"),option("yes","Sì"),option("no","No")},"role","Con la palla","Favorisce appoggi e controllo sotto pressione; non aggancia la palla."),
    row("crossing","Frequenza cross",three,0,"Con la palla","Favorisce passaggi rasoterra dalle fasce verso l'area."),
    row("crossFrom","Origine cross",{option("mixed","Mista"),option("deep","Dalla trequarti"),option("byline","Dal fondo")},"mixed","Con la palla","Indica da quale zona cercare il traversone."),
    row("crossAim","Destinazione cross",{option("mixed","Mista"),option("near","Primo palo"),option("centre","Centro"),option("far","Secondo palo"),option("target","Fulcro del gioco")},"mixed","Con la palla","Premia destinatari nella zona scelta, senza creare traiettorie aeree."),
    row("tackling","Contrasti più / meno duri",{option("physical","Contatto fisico")},"physical","Sistemi futuri","Manca il sistema di contrasti e falli.",true),
    row("markPlayer","Marca un avversario preciso",{option("none","Non disponibile")},"none","Sistemi futuri","La marcatura attuale è di zona, con priorità di posizione.",true)
}
local byTeam,byPlayer={},{}
for _,r in ipairs(Settings.teamInstructionList) do byTeam[r.id]=r end
for _,r in ipairs(Settings.playerInstructionList) do byPlayer[r.id]=r end
local function defaults(list)
    local out={};for _,r in ipairs(list) do out[r.id]=r.default end;return out
end
local function valid(r,value)
    if not r or r.disabled then return false end
    for _,o in ipairs(r.options) do if o.value==value then return true end end
    return false
end
local legacy={GK="GK",DC="DF",DL="FB",DR="FB",WBL="FB",WBR="FB",DM="CM",MC="CM",ML="LM",MR="RM",AML="LM",AMR="RM",AMC="CM",ST="ST"}
local baseRole={GK="goalkeeper",DC="central_defender",DL="full_back",DR="full_back",WBL="wing_back",WBR="wing_back",DM="defensive_midfielder",MC="central_midfielder",ML="wide_midfielder",MR="wide_midfielder",AML="winger",AMR="winger",AMC="attacking_midfielder",ST="advanced_forward"}
Settings.positionList={"GK","DC","DL","DR","WBL","WBR","DM","MC","ML","MR","AML","AMR","AMC","ST"}
-- Coordinates are fractions of the field, viewed from the team's own goal.
-- All anchors stay in the own half for a legal kick-off; possession movement
-- is supplied by the role adapter, not by teleporting players.
local function slot(position,x,y) return {position=position,x=x,y=y} end
Settings.formations={
    {id="4-4-2",slots={slot("GK",.05,.5),slot("DC",.2,.34),slot("ML",.34,.17),slot("MR",.34,.83),slot("ST",.44,.39),slot("DC",.2,.66),slot("DL",.225,.11),slot("DR",.225,.89),slot("MC",.325,.37),slot("MC",.325,.63),slot("ST",.44,.61)}},
    {id="4-3-3",slots={slot("GK",.05,.5),slot("DC",.2,.34),slot("AML",.43,.15),slot("AMR",.43,.85),slot("ST",.46,.5),slot("DC",.2,.66),slot("DL",.225,.11),slot("DR",.225,.89),slot("DM",.28,.5),slot("MC",.36,.32),slot("MC",.36,.68)}},
    {id="4-2-3-1",slots={slot("GK",.05,.5),slot("DC",.2,.34),slot("AML",.42,.15),slot("AMR",.42,.85),slot("ST",.47,.5),slot("DC",.2,.66),slot("DL",.225,.11),slot("DR",.225,.89),slot("DM",.29,.36),slot("DM",.29,.64),slot("AMC",.4,.5)}},
    {id="3-5-2",slots={slot("GK",.05,.5),slot("DC",.19,.25),slot("WBL",.32,.1),slot("WBR",.32,.9),slot("ST",.45,.39),slot("DC",.18,.5),slot("DC",.19,.75),slot("MC",.36,.7),slot("DM",.27,.5),slot("MC",.36,.3),slot("ST",.45,.61)}},
    {id="5-2-3",slots={slot("GK",.05,.5),slot("DC",.18,.27),slot("AML",.43,.2),slot("AMR",.43,.8),slot("ST",.46,.5),slot("DC",.17,.5),slot("WBL",.27,.09),slot("WBR",.27,.91),slot("MC",.32,.37),slot("MC",.32,.63),slot("DC",.18,.73)}}
}
local function contains(list,value) for _,v in ipairs(list) do if v==value then return true end end return false end
local function invalidate(s,team)
    -- A tactical edit changes future decisions; ball, players and clock stay put.
    s.aiTimer=0
    for _,key in ipairs({"pressers","presserSince","combinations","supportActions","runTriggers"}) do
        s[key]=s[key] or {};s[key][team]=nil
    end
    for _,p in ipairs(s.players) do if p.team==team then p.aiIntent=nil end end
end
local function member(s,p)
    for _,candidate in ipairs(s.players) do if candidate==p then return true end end
    return false
end
function Settings.setRole(s,p,id)
    local r=Roles.get(id)
    if not member(s,p) or not r or not contains(r.positions,p.position) then return false,"Ruolo incompatibile con la posizione" end
    p.tacticalRole=id
    if not contains(r.duties,p.duty) then p.duty=r.defaultDuty or r.duties[1] end
    invalidate(s,p.team);return true
end
function Settings.setDuty(s,p,duty)
    if not member(s,p) then return false,"Compito non disponibile" end
    local r=Roles.get(p.tacticalRole)
    if not r or not contains(r.duties,duty) then return false,"Compito non disponibile" end
    p.duty=duty;invalidate(s,p.team);return true
end
function Settings.setPosition(s,p,position)
    if not member(s,p) or not legacy[position] then return false,"Posizione sconosciuta" end
    if (p.role=="GK")~=(position=="GK") then return false,"Il portiere mantiene il suo posto" end
    p.position,p.role=position,legacy[position]
    if s.teamTactics and s.teamTactics[p.team] then s.teamTactics[p.team].custom=true end
    local r=Roles.get(p.tacticalRole)
    if not r or not contains(r.positions,position) then
        p.tacticalRole=baseRole[position];r=Roles.get(p.tacticalRole);p.duty=r.defaultDuty or r.duties[1]
    end
    -- Manual position changes also change the defensive anchor, never x/y.
    local depths={DC=.2,DL=.225,DR=.225,WBL=.28,WBR=.28,DM=.28,MC=.34,ML=.34,MR=.34,AML=.43,AMR=.43,AMC=.4,ST=.45}
    if position~="GK" then
        local y=({DL=.11,WBL=.1,ML=.17,AML=.17,DR=.89,WBR=.9,MR=.83,AMR=.83})[position]
        p.homeX=(p.team==1 and depths[position] or 1-depths[position])*s.field.w
        if y then p.homeY=(p.team==1 and y or 1-y)*s.field.h
        else p.homeY=math.max(.28*s.field.h,math.min(.72*s.field.h,p.homeY)) end
    end
    invalidate(s,p.team);return true
end
function Settings.setFormation(s,team,id)
    local formation
    for _,f in ipairs(Settings.formations) do if f.id==id then formation=f end end
    local config=s.teamTactics and s.teamTactics[team]
    if not formation or not config then return false,"Modulo non disponibile" end
    local players={};for _,p in ipairs(s.players) do if p.team==team then players[#players+1]=p end end
    if #players~=11 then return false,"Il modulo richiede undici calciatori" end
    for i,p in ipairs(players) do
        local slot=formation.slots[i]
        p.position,p.role=slot.position,legacy[slot.position]
        p.homeX=(team==1 and slot.x or 1-slot.x)*s.field.w
        p.homeY=(team==1 and slot.y or 1-slot.y)*s.field.h
        local r=Roles.get(p.tacticalRole)
        if not r or not contains(r.positions,p.position) then
            p.tacticalRole=baseRole[p.position];r=Roles.get(p.tacticalRole);p.duty=r.defaultDuty or r.duties[1]
        end
        p.instructions=p.instructions or defaults(Settings.playerInstructionList)
    end
    config.formation=id;config.custom=false;invalidate(s,team);return true
end
function Settings.attach(s)
    if #s.players~=22 then return end
    s.teamTactics={}
    for team=1,2 do
        s.teamTactics[team]={formation="4-4-2",instructions=defaults(Settings.teamInstructionList)}
        assert(Settings.setFormation(s,team,"4-4-2"))
    end
    -- A covering midfielder and a runner are explicit defaults, not hidden
    -- rules tied to shirt numbers in the decision engine.
    for _,p in ipairs(s.players) do
        if p.number==6 then p.duty="defend"
        elseif p.number==7 then p.duty="attack"
        elseif p.number==9 then p.tacticalRole="deep_lying_forward";p.duty="support" end
    end
end
function Settings.setTeamInstruction(s,team,id,value)
    local config=s.teamTactics and s.teamTactics[team]
    if not config or not valid(byTeam[id],value) then return false,"Istruzione non disponibile" end
    config.instructions[id]=value;invalidate(s,team);return true
end
function Settings.setPlayerInstruction(s,p,id,value)
    if not member(s,p) or not p.instructions or not valid(byPlayer[id],value) then return false,"Istruzione non disponibile" end
    p.instructions[id]=value;invalidate(s,p.team);return true
end
function Settings.profile(s,p)
    local config=s.teamTactics and s.teamTactics[p.team]
    if not p.tacticalRole or not config then return nil end
    local t,i=config.instructions,p.instructions or {}
    local result=Roles.resolve(p.tacticalRole,p.duty,t.mentality)
    for _,key in ipairs({"width","passing","pressing","dribbling"}) do result[key]=clamp((result[key] or 0)+(t[key] or 0)*.45) end
    result.depth=clamp((result.depth or 0)+t.mentality*.2)
    result.risk=clamp((result.risk or 0)+t.mentality*.25)
    for _,key in ipairs({"tempo","defensiveLine","engagement","focus","transitionLoss","transitionWin","distribution","passIntoSpace","overlap","trap","preventShortGK"}) do result[key]=t[key] end
    result.mentality=t.mentality
    if t.playOut and (p.role=="GK" or p.role=="DF" or p.role=="FB") then
        result.passing=clamp(result.passing-.65)
        if p.role=="GK" and t.distribution=="mixed" then result.distribution="short" end
    end
    if t.finalThird=="work" then result.shooting=clamp(result.shooting-.65)
    elseif t.finalThird=="shoot" then result.shooting=clamp(result.shooting+.65)
    elseif t.finalThird=="early" then result.crossing=clamp(result.crossing+.65);result.crossFrom="deep" end
    if t.freedom=="disciplined" then result.roam=false
    elseif t.freedom=="expressive" and p.role~="GK" and p.role~="DF" then result.roam=true end
    for _,key in ipairs({"passing","pressing","dribbling","shooting","risk","crossing"}) do result[key]=clamp((result[key] or 0)+(i[key] or 0)*.65) end
    if i.depth=="forward" then result.depth=clamp(result.depth+.6);result.runs=clamp(result.runs+.6);result.hold=false
    elseif i.depth=="hold" then result.hold=true;result.runs=-1 end
    if i.width=="wide" then result.width=clamp(result.width+.7)
    elseif i.width=="narrow" then result.width=clamp(result.width-.7) end
    if i.roam=="yes" then result.roam=true elseif i.roam=="no" then result.roam=false end
    if i.channels then result.runs=clamp(result.runs+.5) end
    if i.holdUp=="yes" then result.holdUp=true elseif i.holdUp=="no" then result.holdUp=false end
    if i.carryDirection and i.carryDirection~="role" then result.carryDirection=i.carryDirection end
    result.markTighter=i.markTighter or false;result.markPosition=i.markPosition or "none"
    if i.crossFrom and i.crossFrom~="mixed" then result.crossFrom=i.crossFrom end
    result.crossFrom=result.crossFrom or "mixed";result.crossAim=i.crossAim or "mixed"
    return result
end
return Settings
