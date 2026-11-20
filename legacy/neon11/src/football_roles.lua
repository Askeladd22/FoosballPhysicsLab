-- FM24 role vocabulary with ORIGINAL FootballPhysicsLab behaviour coefficients.
-- Names/source keys are verified against the installed English/Italian LTCs.
-- Duty descriptions are evidence, not proof of a live engine compatibility table.
-- See docs/FM24-Role-Catalog.md; no Sports Interactive engine weights are copied.
local R={list={},byId={}}

R.dutyLabels={defend="Difesa",support="Supporto",attack="Attacco",
    automatic="Automatico",stopper="Marcatura",cover="Copertura"}
R.numericFields={"depth","width","pressing","passing","risk","dribbling",
    "shooting","runs","crossing"}
R.booleanFields={"roam","hold","playmaker","target","holdUp","gkRush"}

local function copy(source)
    local result={}
    for key,value in pairs(source) do
        result[key]=type(value)=="table" and copy(value) or value
    end
    return result
end
local function contains(list,value)
    for _,item in ipairs(list) do if item==value then return true end end
    return false
end
local function words(text)
    local result={}
    for item in text:gmatch("%S+") do result[#result+1]=item end
    return result
end
local function add(id,name,nameEn,sourceId,positions,duties,profile,dutyKeys,description,overrides)
    local base={carryDirection="mixed",rotation="none"}
    for _,field in ipairs(R.numericFields) do base[field]=0 end
    for _,field in ipairs(R.booleanFields) do base[field]=false end
    for field,value in pairs(profile) do base[field]=value end
    local role={id=id,name=name,nameEn=nameEn,sourceId=sourceId,
        sourceKey=268435456+sourceId,positions=words(positions),duties=words(duties),
        profile=base,dutyProfiles=overrides or {},description=description,
        provenance={names="installed_ltc_verified",duties="ltc_descriptions_not_runtime_verified",
            positions="fm24_taxonomy_not_runtime_verified",behaviour="original_adaptation",
            dutyKeys=dutyKeys or {},evidenceFile="docs/fm24-roles-evidence.json"}}
    role.defaultDuty=contains(role.duties,"support") and "support" or role.duties[1]
    assert(not R.byId[id],"duplicate football role: "..id)
    R.list[#R.list+1]=role
    R.byId[id]=role
end

add("goalkeeper","Portiere","Goalkeeper",297433,"GK","defend",
    {depth=-0.45,pressing=-0.9,passing=-0.05,risk=-0.6,dribbling=-1,
        shooting=-1,runs=-1,crossing=-1,hold=true},
    {268735533},"Protegge la porta e distribuisce senza abbandonare la propria zona.")
add("sweeper_keeper","Portiere-libero","Sweeper Keeper",297445,"GK","defend support attack",
    {depth=-0.1,pressing=-0.5,passing=0.35,risk=0.1,dribbling=-0.25,
        shooting=-1,runs=-0.8,crossing=-1,gkRush=true},
    {268735560,268800926,268735562},"Copre lo spazio davanti alla porta e avvia le ripartenze.",
    {attack={shooting=-1,crossing=-1}})
add("central_defender","Difensore centrale","Central Defender",297434,"DC","defend stopper cover",
    {depth=-0.05,pressing=-0.05,passing=-0.3,risk=-0.5,dribbling=-0.65,
        shooting=-0.9,runs=-0.65,crossing=-0.9,hold=true},
    {268735534,268735535,268735536},"Mantiene la linea, marca e interrompe le azioni avversarie.")
add("ball_playing_defender","Difensore che imposta","Ball Playing Defender",297448,"DC","defend stopper cover",
    {depth=-0.05,pressing=-0.05,passing=0.45,risk=0.55,dribbling=-0.1,
        shooting=-0.8,runs=-0.55,crossing=-0.85,hold=true},
    {268735566,268735567,268735568},"Difende la linea e cerca passaggi capaci di superare il pressing.")
add("no_nonsense_centre_back","Difensore senza fronzoli","No-Nonsense Centre-Back",468615,"DC","defend stopper cover",
    {depth=-0.08,pressing=0.1,passing=0.85,risk=-0.8,dribbling=-1,
        shooting=-1,runs=-0.9,crossing=-1,hold=true},
    {268904101,268904561,268904562},"Dà priorità all'intervento difensivo e alla liberazione della zona.")
add("no_nonsense_full_back","Terzino senza fronzoli","No-Nonsense Full-Back",466769,"DL DR","defend",
    {depth=-0.3,width=0.6,pressing=0.1,passing=0.7,risk=-0.8,
        dribbling=-0.9,shooting=-1,runs=-0.85,crossing=-0.1,hold=true},
    {268904095},"Protegge la fascia e gioca in modo semplice senza sovrapposizioni frequenti.")
add("wide_centre_back","Braccetto di difesa","Wide Centre-Back",540030,"DC","defend support attack",
    {depth=0.08,width=0.6,pressing=0.05,passing=-0.2,risk=-0.1,
        dribbling=0.25,shooting=-0.5,runs=0.3,crossing=0.35},
    {268975420,268975421,268975422},"Si allarga dalla difesa e accompagna il gioco nel corridoio laterale.",
    {defend={hold=true,runs=-0.45,dribbling=-0.3},attack={roam=true}})
add("libero","Libero che avanza","Libero",297447,"DC","defend support",
    {depth=0.1,width=-0.3,pressing=-0.2,passing=0.25,risk=0.35,
        dribbling=0.1,shooting=-0.5,runs=0.05,crossing=-0.9,rotation="libero"},
    {269032970},"In possesso sale dalla linea difensiva per offrire un appoggio in mediana.",
    {defend={risk=-0.1,dribbling=-0.25},support={risk=0.5,dribbling=0.3}})
R.byId.libero.provenance.duties="official_fm24_revision"
R.byId.libero.provenance.reference="https://store.steampowered.com/news/app/2252570/view/4165345869849416401"
add("full_back","Terzino","Full-Back",297435,"DL DR","defend support attack automatic",
    {depth=-0.05,width=0.7,pressing=0.1,passing=-0.2,risk=-0.2,
        dribbling=-0.1,shooting=-0.6,runs=0.05,crossing=0.5},
    {268735537,268800925,268735539,268904093},"Offre un appoggio laterale e sceglie quando sovrapporsi.",
    {defend={hold=true},attack={crossing=0.8,runs=0.65}})
add("wing_back","Terzino fluidificante","Wing-Back",297436,"DL DR WBL WBR","defend support attack automatic",
    {depth=0.1,width=0.85,pressing=0.2,passing=-0.05,risk=0,
        dribbling=0.4,shooting=-0.35,runs=0.4,crossing=0.7,carryDirection="wide"},
    {268735540,268800929,268735542,268904094},"Percorre la fascia e porta cross, recuperando poi la posizione.",
    {defend={runs=-0.2,dribbling=-0.15},attack={crossing=0.95}})
add("complete_wing_back","Esterno completo","Complete Wing-Back",355286,"DL DR WBL WBR","support attack",
    {depth=0.25,width=0.8,pressing=0.2,passing=-0.1,risk=0.3,
        dribbling=0.7,shooting=-0.1,runs=0.65,crossing=0.75,roam=true,carryDirection="wide"},
    {268817878,268817879},"Attacca la fascia con libertà, conduzioni e inserimenti continui.")
add("inverted_wing_back","Esterno invertito","Inverted Wing-Back",376495,"DL DR WBL WBR","defend support attack automatic",
    {depth=0.05,width=-0.65,pressing=0.2,passing=-0.3,risk=0.1,
        dribbling=0.25,shooting=-0.15,runs=0.1,crossing=-0.5,
        carryDirection="inside",rotation="invert_midfield"},
    {268875974,268875975,268875976,268904107},"Dalla fascia entra in mediana per collegare e sostenere il possesso.",
    {defend={hold=true,runs=-0.45},attack={roam=true,runs=0.7}})
add("inverted_full_back","Terzino invertito","Inverted Full-Back",596934,"DL DR","defend",
    {depth=-0.18,width=-0.65,pressing=-0.1,passing=-0.35,risk=-0.4,
        dribbling=-0.6,shooting=-0.9,runs=-0.7,crossing=-0.8,hold=true,
        carryDirection="inside",rotation="invert_defence"},
    {269020761},"In possesso si stringe come un centrale per proteggere la costruzione.")
add("defensive_midfielder","Centrocampista difensivo","Defensive Midfielder",297437,"DM","defend support",
    {depth=-0.1,pressing=0.2,passing=-0.35,risk=-0.35,
        dribbling=-0.4,shooting=-0.4,runs=-0.25,crossing=-0.65,hold=true},
    {268735543,268735544},"Scherma la difesa e ricicla il pallone verso i compagni.",
    {support={hold=false,runs=0.15,depth=0.05}})
add("deep_lying_playmaker","Regista arretrato","Deep Lying Playmaker",297449,"DM MC","defend support",
    {depth=-0.12,pressing=-0.15,passing=0.25,risk=0.65,
        dribbling=-0.5,shooting=-0.4,runs=-0.5,crossing=-0.6,hold=true,playmaker=true},
    {268735569,268904100},"Riceve davanti alla difesa e orienta il possesso con passaggi creativi.",
    {defend={depth=-0.4,runs=-0.8},support={passing=0.45,risk=0.75}})
add("ball_winning_midfielder","Incontrista","Ball Winning Midfielder",297450,"DM MC","defend support",
    {depth=-0.05,pressing=0.95,passing=-0.45,risk=-0.45,
        dribbling=-0.6,shooting=-0.4,runs=-0.1,crossing=-0.7},
    {268735571,268735572},"Esce sul portatore per recuperare il pallone e affidarlo ai compagni.",
    {support={depth=0.15,runs=0.2}})
add("anchor","Mediano incontrista","Anchor",540032,"DM","defend",
    {depth=-0.35,pressing=-0.55,passing=-0.65,risk=-0.8,
        dribbling=-0.85,shooting=-0.8,runs=-0.9,crossing=-0.9,hold=true},
    {268962267},"Rimane davanti ai centrali, chiude le linee e scarica il pallone.")
add("half_back","Centromediano Metodista","Half Back",355384,"DM","defend",
    {depth=-0.25,width=-0.2,pressing=-0.3,passing=-0.5,risk=-0.55,
        dribbling=-0.7,shooting=-0.9,runs=-0.8,crossing=-0.9,hold=true,rotation="half_back"},
    {268793860},"In possesso arretra nella linea difensiva per sostenere l'uscita del pallone.")
add("regista","Regista","Regista",355634,"DM","support",
    {depth=0.1,pressing=-0.2,passing=0.55,risk=0.9,
        dribbling=0.1,shooting=-0.1,runs=0.15,crossing=-0.5,roam=true,playmaker=true},
    {268793880},"Si libera nella zona arretrata e cerca soluzioni creative su tutto il campo.")
add("roaming_playmaker","Regista mobile","Roaming Playmaker",376566,"DM MC","support",
    {depth=0.2,pressing=0.1,passing=0.15,risk=0.65,
        dribbling=0.5,shooting=0.1,runs=0.65,crossing=-0.4,roam=true,playmaker=true},
    {268812780},"Segue lo sviluppo dell'azione, conduce e crea nuovi angoli di passaggio.")
add("segundo_volante","Secondo Mediano","Segundo Volante",438384,"DM","support attack",
    {depth=0.25,pressing=0.35,passing=-0.2,risk=0.15,
        dribbling=0.35,shooting=0.3,runs=0.75,crossing=-0.6},
    {268885722,268885723},"Parte dalla mediana e arriva in avanti con inserimenti ritardati.")
add("central_midfielder","Centrocampista centrale","Central Midfielder",297438,"MC","defend support attack automatic",
    {pressing=0.15,passing=-0.1,risk=0.05,dribbling=-0.05,
        shooting=-0.05,runs=0.05,crossing=-0.4},
    {268812945,268812946,268812947,268904097},"Collega i reparti adattando avanzamenti e copertura al compito assegnato.",
    {defend={hold=true},attack={runs=0.75,depth=0.45}})
add("box_to_box_midfielder","Centrocampista di quantità","Box To Box Midfielder",297451,"MC","support",
    {depth=0.18,pressing=0.35,passing=-0.2,risk=0.1,
        dribbling=0.25,shooting=0.2,runs=0.7,crossing=-0.4,roam=true},
    {268735573},"Accompagna l'attacco e rientra, collegando le due aree con corse continue.")
add("advanced_playmaker","Regista avanzato","Advanced Playmaker",297452,"MC AML AMR AMC","support attack",
    {depth=0.15,pressing=-0.15,passing=-0.15,risk=0.85,
        dribbling=0.25,shooting=-0.3,runs=0.1,crossing=-0.25,playmaker=true},
    {268800924,268800931},"Riceve tra le linee e privilegia l'ultimo passaggio.",
    {support={hold=true},attack={dribbling=0.65,runs=0.45}})
add("mezzala","Mezzala","Mezzala",438380,"MC","support attack",
    {depth=0.15,width=0.6,pressing=0.1,passing=-0.1,risk=0.35,
        dribbling=0.35,shooting=0.2,runs=0.65,crossing=0.15,roam=true},
    {268875968,268875969},"Si apre nel mezzo spazio e combina con fascia e attacco.")
add("carrilero","Carrilero","Carrilero",438382,"MC","support",
    {depth=-0.05,width=0.45,pressing=0.3,passing=-0.35,risk=-0.2,
        dribbling=-0.2,shooting=-0.45,runs=0.1,crossing=-0.1},
    {268875971},"Scivola lateralmente per collegare il centro alla fascia e mantenere equilibrio.")
add("wide_midfielder","Centrocampista laterale","Wide Midfielder",297439,"ML MR","defend support attack automatic",
    {width=0.7,pressing=0.2,passing=-0.05,risk=-0.15,
        dribbling=-0.2,shooting=-0.2,runs=0.1,crossing=0.4},
    {268735548,268735549,268735550,268904098},"Sostiene la fascia con passaggi e cross senza dipendere dal dribbling.",
    {defend={hold=true},attack={crossing=0.75}})
add("winger","Ala","Winger",297440,"ML MR AML AMR","support attack",
    {depth=0.1,width=0.9,pressing=0.05,passing=-0.15,risk=0.05,
        dribbling=0.8,shooting=-0.1,runs=0.35,crossing=0.9,carryDirection="wide"},
    {268735551,268735552},"Resta larga, affronta il difensore e cerca un cross o uno scarico.")
add("defensive_winger","Ala che pressa","Defensive Winger",297457,"ML MR","defend support",
    {depth=-0.15,width=0.75,pressing=0.95,passing=-0.2,risk=-0.2,
        dribbling=0.2,shooting=-0.45,runs=0.2,crossing=0.65,carryDirection="wide"},
    {268792471,268735584},"Pressa sulla fascia e riparte con un passaggio o un cross.")
R.byId.defensive_winger.provenance.duties="current_taxonomy_stale_attack_text_excluded"
add("wide_playmaker","Regista largo","Wide Playmaker",376664,"ML MR","support attack",
    {depth=0.05,width=-0.2,pressing=-0.2,passing=-0.15,risk=0.7,
        dribbling=0.15,shooting=-0.25,runs=0,crossing=-0.25,
        playmaker=true,carryDirection="inside"},
    {268812126,268812127},"Dalla fascia si accentra per dirigere il gioco e cercare filtranti.",
    {support={hold=true},attack={depth=0.4,runs=0.35}})
add("inverted_winger","Ala invertita","Inverted Winger",438378,"ML MR AML AMR","support attack",
    {depth=0.1,width=-0.35,pressing=0,passing=-0.15,risk=0.35,
        dribbling=0.7,shooting=0.1,runs=0.3,crossing=0.25,carryDirection="inside"},
    {268875972,268875973},"Conduce dalla fascia verso il centro per combinare e creare occasioni.")
add("attacking_midfielder","Centrocampista offensivo","Attacking Midfielder",297442,"AMC","support attack",
    {depth=0.25,pressing=0.05,passing=-0.2,risk=0.2,
        dribbling=0.15,shooting=0.2,runs=0.25,crossing=-0.4},
    {268904099,268735556},"Collega mediana e punte e può accompagnare l'azione dentro l'area.")
add("enganche","Rifinitore","Enganche",355331,"AMC","support",
    {depth=-0.15,pressing=-0.85,passing=-0.35,risk=0.85,
        dribbling=-0.65,shooting=-0.25,runs=-0.6,crossing=-0.6,hold=true,playmaker=true},
    {268904096},"Resta disponibile tra le linee per servire i compagni con pochi spostamenti.")
add("trequartista","Trequartista","Trequartista",297459,"AML AMR AMC ST","attack",
    {depth=0.15,pressing=-0.9,passing=-0.15,risk=0.65,
        dribbling=0.65,shooting=0.4,runs=0.35,crossing=-0.1,roam=true,playmaker=true},
    {268735588},"Cerca liberamente spazio per inventare e concludere, partecipando poco al pressing.")
add("shadow_striker","Attaccante di sostegno","Shadow Striker",355654,"AMC","attack",
    {depth=0.5,pressing=0.65,passing=-0.3,risk=0.1,
        dribbling=0.45,shooting=0.65,runs=0.85,crossing=-0.65},
    {268793861},"Attacca la profondità dalla trequarti e pressa la costruzione avversaria.")
add("inside_forward","Attaccante esterno","Inside Forward",297441,"AML AMR","support attack",
    {depth=0.2,width=-0.7,pressing=0,passing=-0.25,risk=0.2,
        dribbling=0.65,shooting=0.65,runs=0.65,crossing=-0.55,carryDirection="inside"},
    {268800923,268735554},"Taglia verso l'area dalla fascia e cerca una conclusione o un passaggio decisivo.")
add("raumdeuter","Trovaspazi","Raumdeuter",376559,"AML AMR","attack",
    {depth=0.3,width=-0.2,pressing=-0.65,passing=-0.3,risk=-0.1,
        dribbling=-0.4,shooting=0.75,runs=0.95,crossing=-0.15,roam=true,carryDirection="inside"},
    {268812060},"Si libera senza palla e compare negli spazi utili per finalizzare.")
add("wide_target_forward","Fulcro del gioco largo","Wide Target Forward",539146,"AML AMR","support attack",
    {depth=0.05,width=0.75,pressing=-0.25,passing=-0.55,risk=-0.25,
        dribbling=-0.65,shooting=0.25,runs=-0.2,crossing=-0.2,target=true,holdUp=true},
    {268962264,268962263},"Offre un riferimento sulla fascia per ricevere e servire chi si inserisce.")
add("deep_lying_forward","Seconda punta","Deep Lying Forward",297443,"ST","support attack",
    {depth=-0.5,pressing=-0.05,passing=-0.35,risk=0.3,
        dribbling=-0.2,shooting=0.1,runs=-0.15,crossing=-0.6,holdUp=true,rotation="drop_forward"},
    {268735557,268735558},"Viene incontro, protegge il pallone e collega i compagni all'attacco.",
    {attack={depth=-0.05,runs=0.4,shooting=0.5}})
add("advanced_forward","Centravanti","Advanced Forward",297444,"ST","attack",
    {depth=0.55,width=0.15,pressing=0.25,passing=0.1,risk=0.1,
        dribbling=0.5,shooting=0.7,runs=0.85,crossing=0.1},
    {268735559},"Guida l'attacco, corre alle spalle della difesa e cerca il gol.")
add("target_forward","Fulcro del gioco","Target Forward",538908,"ST","support attack",
    {depth=0.2,pressing=-0.2,passing=-0.55,risk=-0.4,
        dribbling=-0.8,shooting=0.35,runs=-0.25,crossing=-0.8,target=true,holdUp=true},
    {268962265,268962266},"È il riferimento centrale per ricevere, proteggere e appoggiare il pallone.",
    {attack={depth=0.55,shooting=0.75,runs=0.15}})
add("poacher","Uomo d'area","Poacher",297454,"ST","attack",
    {depth=0.6,pressing=-0.45,passing=-0.75,risk=-0.7,
        dribbling=-0.7,shooting=0.95,runs=0.7,crossing=-0.95},
    {268735578},"Rimane vicino alla porta avversaria e cerca lo smarcamento per concludere.")
add("complete_forward","Punta completa","Complete Forward",297455,"ST","support attack",
    {depth=0.2,width=0.15,pressing=0.1,passing=-0.05,risk=0.55,
        dribbling=0.65,shooting=0.6,runs=0.55,crossing=0.1,roam=true,holdUp=true},
    {268735579,268735580},"Alterna protezione, conduzione, creazione e attacco della profondità.")
add("pressing_forward","Attaccante che pressa","Pressing Forward",468617,"ST","defend support attack",
    {depth=0.15,pressing=1,passing=-0.2,risk=-0.1,
        dribbling=0.1,shooting=0.35,runs=0.55,crossing=-0.5},
    {268905959,268905960,268905961},"Disturba la costruzione, insegue palloni liberi e partecipa alla finalizzazione.",
    {defend={depth=-0.25,holdUp=true,shooting=-0.2},support={risk=0.3}})
add("false_nine","Falso 9","False Nine",355345,"ST","support",
    {depth=-0.65,pressing=-0.25,passing=-0.45,risk=0.8,
        dribbling=0.65,shooting=0.05,runs=-0.25,crossing=-0.65,
        roam=true,rotation="false_nine"},
    {268792412},"Arretra dalla prima linea, richiama un difensore e crea spazio per gli inserimenti.")

-- Generic duty changes and role-specific overrides are our simulation choices.
-- The latter are absolute values, applied AFTER the generic additive modifiers.
local dutyChanges={
    defend={depth=-0.2,risk=-0.1,dribbling=-0.1,shooting=-0.15,runs=-0.25,pressing=-0.05},
    support={},
    attack={depth=0.28,risk=0.12,dribbling=0.12,shooting=0.18,runs=0.32,pressing=0.03},
    stopper={depth=0.15,pressing=0.5,runs=-0.35,shooting=-0.2},
    cover={depth=-0.42,pressing=-0.3,runs=-0.4,shooting=-0.2}
}
local mentalityDuties={
    very_defensive="defend",defensive="defend",cautious="defend",
    balanced="support",positive="support",attacking="attack",very_attacking="attack",
    molto_difensiva="defend",difensiva="defend",prudente="defend",
    equilibrata="support",positiva="support",offensiva="attack",molto_offensiva="attack",
    defend="defend",support="support",attack="attack"
}
local function automaticDuty(mentality)
    if mentality==nil then return "support" end
    if type(mentality)=="number" then
        assert(mentality==mentality and mentality>=-1 and mentality<=1,
            "numeric mentality must be in [-1,1]")
        if mentality < -1/3 then return "defend" end
        if mentality > 1/3 then return "attack" end
        return "support"
    end
    assert(type(mentality)=="string","mentality must be a string or number")
    local key=mentality:lower():gsub("[%s%-]+","_")
    assert(mentalityDuties[key],"unknown mentality: "..mentality)
    return mentalityDuties[key]
end

-- Catalog entries are shared read-only definitions. resolve returns owned data.
function R.get(id) return R.byId[id] end
function R.forPosition(position)
    local result={}
    for _,role in ipairs(R.list) do
        if contains(role.positions,position) then result[#result+1]=role end
    end
    return result
end
function R.resolve(roleId,duty,mentality)
    local role=assert(R.get(roleId),"unknown football role: "..tostring(roleId))
    duty=duty or role.defaultDuty
    assert(contains(role.duties,duty),"unsupported duty for "..roleId..": "..tostring(duty))
    local effective=duty=="automatic" and automaticDuty(mentality) or duty
    local profile=copy(role.profile)
    for field,value in pairs(dutyChanges[effective]) do profile[field]=profile[field]+value end
    for field,value in pairs(role.dutyProfiles[effective] or {}) do profile[field]=value end
    for _,field in ipairs(R.numericFields) do
        profile[field]=math.max(-1,math.min(1,profile[field]))
    end
    profile.roleId,profile.duty,profile.requestedDuty=roleId,effective,duty
    return profile
end

return R
