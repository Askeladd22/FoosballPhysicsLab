-- Catalog integrity and behaviour contracts, independent of Sim and LÖVE.
package.path="./?.lua;./?/init.lua;"..package.path
local Roles=require("src.football_roles")
local function check(ok,message) if not ok then error(message,2) end end
local function includes(list,value)
    for _,item in ipairs(list) do if item==value then return true end end
    return false
end
local function sameProfile(a,b)
    for _,field in ipairs(Roles.numericFields) do
        check(a[field]==b[field],"profile differs at "..field)
    end
    for _,field in ipairs(Roles.booleanFields) do
        check(a[field]==b[field],"profile differs at "..field)
    end
    check(a.rotation==b.rotation and a.carryDirection==b.carryDirection,
        "profile movement differs")
end
local positions={GK=true,DC=true,DL=true,DR=true,WBL=true,WBR=true,DM=true,
    MC=true,ML=true,MR=true,AML=true,AMR=true,AMC=true,ST=true}
local rotations={none=true,invert_defence=true,invert_midfield=true,libero=true,
    half_back=true,drop_forward=true,false_nine=true}
local directions={mixed=true,inside=true,wide=true}
local seen,sourceIds,names={},{},{}
check(#Roles.list==45,"FM24 catalog must contain 45 roles")
for _,role in ipairs(Roles.list) do
    check(type(role.id)=="string" and role.id:match("^[a-z_]+$") and not seen[role.id],
        "role IDs must be unique stable keys")
    seen[role.id]=true
    check(Roles.get(role.id)==role and Roles.byId[role.id]==role,"catalog lookup mismatch")
    check(type(role.name)=="string" and #role.name>0 and not names[role.name],
        "Italian names must be unique and nonempty")
    names[role.name]=true
    check(type(role.nameEn)=="string" and #role.nameEn>0,"missing English name")
    check(type(role.sourceId)=="number" and role.sourceId%1==0 and not sourceIds[role.sourceId],
        "source IDs must be unique integers")
    sourceIds[role.sourceId]=true
    check(role.sourceKey==268435456+role.sourceId,"LTC key/id relationship changed")
    check(role.provenance.names=="installed_ltc_verified","name provenance missing")
    check(role.provenance.behaviour=="original_adaptation","behaviour must not claim engine extraction")
    check(role.provenance.positions=="fm24_taxonomy_not_runtime_verified","positions confidence missing")
    check(#role.provenance.dutyKeys>0,"duty evidence missing")
    check(not role.locked or next(role.locked)==nil,"unverified FM instruction locks introduced")
    check(#role.positions>0 and #role.duties>0,"role compatibility empty")
    for _,position in ipairs(role.positions) do
        check(positions[position],"unknown position "..position)
        check(includes(Roles.forPosition(position),role),"role absent from position filter")
    end
    check(includes(role.duties,role.defaultDuty),"invalid default duty")
    for _,duty in ipairs(role.duties) do
        check(Roles.dutyLabels[duty],"missing Italian duty label")
        local a,b=Roles.resolve(role.id,duty),Roles.resolve(role.id,duty)
        check(a~=b and a~=role.profile,"resolve must return independent objects")
        check(a.roleId==role.id and a.requestedDuty==duty,"resolved identity lost")
        check(a.duty~="automatic" and Roles.dutyLabels[a.duty],"duty did not resolve")
        for _,field in ipairs(Roles.numericFields) do
            check(type(a[field])=="number" and a[field]>=-1 and a[field]<=1,
                role.id.." invalid coefficient "..field)
        end
        for _,field in ipairs(Roles.booleanFields) do
            check(type(a[field])=="boolean",role.id.." invalid flag "..field)
        end
        check(rotations[a.rotation] and directions[a.carryDirection],"invalid movement mode")
        sameProfile(a,b)
        a.depth,a.roam=987,not a.roam
        sameProfile(b,Roles.resolve(role.id,duty))
    end
    sameProfile(Roles.resolve(role.id),Roles.resolve(role.id,role.defaultDuty))
end
for position in pairs(positions) do
    local first,second=Roles.forPosition(position),Roles.forPosition(position)
    check(#first>0 and first~=second,"position filters must return fresh nonempty arrays")
    for _,role in ipairs(first) do
        check(includes(role.positions,position),"position filter contains incompatible role")
    end
    first[1]=nil
    check(#Roles.forPosition(position)==#second,"filter mutation damaged catalog")
end
check(Roles.get("missing")==nil and #Roles.forPosition("missing")==0,"unknown lookup must be empty")
check(not pcall(Roles.resolve,"missing"),"unknown role silently accepted")
check(not pcall(Roles.resolve,"goalkeeper","attack"),"invalid role duty silently accepted")
check(not pcall(Roles.resolve,"libero","attack"),"obsolete Libero attack duty returned")
check(not pcall(Roles.resolve,"full_back","automatic",2),"out-of-range mentality accepted")
check(not pcall(Roles.resolve,"full_back","automatic",0/0),"NaN mentality accepted")
check(not pcall(Roles.resolve,"full_back","automatic","typo"),"unknown mentality accepted")

local automaticCases={
    {-1,"defend"},{-0.5,"defend"},{-1/3,"support"},{0,"support"},{1/3,"support"},{0.5,"attack"},{1,"attack"},
    {"very defensive","defend"},{"defensive","defend"},{"cautious","defend"},
    {"balanced","support"},{"positive","support"},{"attacking","attack"},{"very-attacking","attack"},
    {"Molto difensiva","defend"},{"Prudente","defend"},{"Equilibrata","support"},
    {"Positiva","support"},{"Offensiva","attack"},{"Molto offensiva","attack"}
}
for _,role in ipairs(Roles.list) do
    if includes(role.duties,"automatic") then
        for _,case in ipairs(automaticCases) do
            local automatic=Roles.resolve(role.id,"automatic",case[1])
            check(automatic.duty==case[2] and automatic.requestedDuty=="automatic",
                "automatic duty identity wrong")
            sameProfile(automatic,Roles.resolve(role.id,case[2]))
        end
        sameProfile(Roles.resolve(role.id,"automatic"),Roles.resolve(role.id,"support"))
    end
end

local function profile(id,duty) return Roles.resolve(id,duty) end
local anchor,hunter=profile("anchor"),profile("ball_winning_midfielder","defend")
check(anchor.hold and not hunter.hold and hunter.pressing>anchor.pressing+1,
    "anchor and ball winner need distinct protection/pressing behaviour")
local winger,inside=profile("winger","support"),profile("inside_forward","support")
check(winger.width>inside.width and winger.crossing>inside.crossing and inside.shooting>winger.shooting,
    "winger and inside forward need different movement and decisions")
check(winger.carryDirection=="wide" and inside.carryDirection=="inside","wide carrying direction missing")
local falseNine,poacher=profile("false_nine"),profile("poacher")
check(falseNine.depth<poacher.depth and falseNine.risk>poacher.risk and poacher.shooting>falseNine.shooting,
    "false nine and poacher need different support and finishing behaviour")
check(profile("target_forward").target and profile("target_forward").holdUp,
    "target forward must provide a receiving reference")
check(profile("enganche").hold and not profile("enganche").roam and profile("trequartista").roam,
    "stationary and roaming creators conflated")
check(profile("goalkeeper").gkRush==false and profile("sweeper_keeper").gkRush==true,
    "keeper sweeping behaviour missing")
check(profile("inverted_full_back").rotation=="invert_defence"
    and profile("inverted_wing_back").rotation=="invert_midfield"
    and profile("libero").rotation=="libero"
    and profile("half_back").rotation=="half_back","modern role rotations lost")
local stopper,cover=profile("central_defender","stopper"),profile("central_defender","cover")
check(stopper.depth>cover.depth and stopper.pressing>cover.pressing,"stopper and cover are indistinguishable")
local cmDefend,cmAttack=profile("central_midfielder","defend"),profile("central_midfielder","attack")
check(cmAttack.depth>cmDefend.depth and cmAttack.runs>cmDefend.runs,"duty must alter advancement")
check(Roles.byId.libero.provenance.duties=="official_fm24_revision","Libero revision evidence missing")
print("PASS: 45 FM24 roles, provenance, positions, duties, independent profiles and distinct behaviours")
