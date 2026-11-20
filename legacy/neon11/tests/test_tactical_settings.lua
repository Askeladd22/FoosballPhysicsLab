-- Tactical edits must be valid, isolated and independent of live physics.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Settings=require("src.tactical_settings")
local Roles=require("src.football_roles")
local function check(ok,message) if not ok then error(message,2) end end
local function copy(source)
    local out={};for key,value in pairs(source) do out[key]=type(value)=="table" and copy(value) or value end
    return out
end
local function equal(a,b,label)
    if type(a)~="table" or type(b)~="table" then
        check(a==b,label or "values differ");return
    end
    for key,value in pairs(a) do equal(value,b[key],(label or "table").."."..tostring(key)) end
    for key in pairs(b) do check(a[key]~=nil,(label or "table").." unexpected key "..tostring(key)) end
end
local function contains(list,value)
    for _,item in ipairs(list) do if item==value then return true end end
    return false
end
local function byNumber(s,team,number)
    for _,p in ipairs(s.players) do if p.team==team and p.number==number then return p end end
    error("missing player")
end
local function configSnapshot(s,team)
    local snapshot={team=copy(s.teamTactics[team]),players={}}
    for _,p in ipairs(s.players) do if p.team==team then
        snapshot.players[#snapshot.players+1]={position=p.position,role=p.role,
            tacticalRole=p.tacticalRole,duty=p.duty,homeX=p.homeX,homeY=p.homeY,instructions=copy(p.instructions)}
    end end
    return snapshot
end
local function liveSnapshot(s)
    local snapshot={ball=copy(s.ball),score=copy(s.score),elapsed=s.elapsed,
        phase=s.phase,phaseClock=s.phaseClock,clockStarted=s.clockStarted,controlled=s.controlled,
        setPiece=s.setPiece,totalKicks=s.totalKicks,players={}}
    for _,p in ipairs(s.players) do snapshot.players[#snapshot.players+1]={
        ref=p,x=p.x,y=p.y,vx=p.vx,vy=p.vy,moveX=p.moveX,moveY=p.moveY,cooldown=p.cooldown} end
    return snapshot
end
local function unchanged(s,before)
    equal(s.ball,before.ball,"tactical edit changed live ball")
    equal(s.score,before.score,"tactical edit changed score")
    check(s.elapsed==before.elapsed and s.phase==before.phase and s.phaseClock==before.phaseClock
        and s.clockStarted==before.clockStarted,"tactical edit reset match state")
    check(s.controlled==before.controlled and s.setPiece==before.setPiece
        and s.totalKicks==before.totalKicks,"tactical edit changed control or restart")
    for index,prior in ipairs(before.players) do
        local p=s.players[index]
        check(p==prior.ref,"tactical edit replaced player object")
        for _,key in ipairs({"x","y","vx","vy","moveX","moveY","cooldown"}) do
            check(p[key]==prior[key],"tactical edit altered player physics: "..key)
        end
    end
end
local function edit(s,fn)
    local before=liveSnapshot(s);check(fn(),"valid tactical edit rejected");unchanged(s,before)
end

local s=Sim.new("RM")
check(s.teamTactics[1]~=s.teamTactics[2] and
    s.teamTactics[1].instructions~=s.teamTactics[2].instructions,"teams share settings")
for _,p in ipairs(s.players) do
    local role=Roles.get(p.tacticalRole)
    check(role and contains(role.positions,p.position) and contains(role.duties,p.duty),"invalid initial assignment")
    for _,row in ipairs(Settings.playerInstructionList) do check(p.instructions[row.id]==row.default,"wrong individual default") end
    for _,other in ipairs(s.players) do if other~=p then check(other.instructions~=p.instructions,"players share settings") end end
end
for team=1,2 do
    check(s.teamTactics[team].formation=="4-4-2","wrong starting formation")
    for _,row in ipairs(Settings.teamInstructionList) do
        check(s.teamTactics[team].instructions[row.id]==row.default,"wrong team default")
    end
    check(byNumber(s,team,6).duty=="defend" and byNumber(s,team,7).duty=="attack"
        and byNumber(s,team,9).tacticalRole=="deep_lying_forward","complementary initial duties missing")
end
s.phase,s.setPiece,s.elapsed,s.phaseClock,s.clockStarted="play",nil,137.5,.23,true
s.score={2,1};s.ball.x,s.ball.y,s.ball.vx,s.ball.vy=41,26,4,-2
for n,p in ipairs(s.players) do p.vx,p.vy,p.cooldown=n*.1,-n*.1,.07 end
local blue,amber=s.controlled,byNumber(s,2,s.controlled.number)
local otherConfig=configSnapshot(s,2)
edit(s,function() return Settings.setPosition(s,blue,"AMC") end)
edit(s,function() return Settings.setRole(s,blue,"shadow_striker") end)
check(blue.duty=="attack","new role did not replace incompatible prior duty")
edit(s,function() return Settings.setPosition(s,blue,"MC") end)
check(blue.tacticalRole=="central_midfielder" and contains(Roles.get(blue.tacticalRole).duties,blue.duty),
    "position change retained an incompatible role")
equal(configSnapshot(s,2),otherConfig,"opponent changed during individual edit")

-- Replanning one coach's side must not cancel the opponent's live action.
local amberCombination={phase="return",runner=amber}
local amberSupport={runner=amber,kind="overlap"}
local amberTrigger={at=11}
local amberIntent={kind="carry"}
s.pressers={[1]=blue,[2]=amber};s.presserSince={[1]=10,[2]=12}
s.combinations={[1]={phase="out"},[2]=amberCombination}
s.supportActions={[1]={kind="underlap"},[2]=amberSupport}
s.runTriggers={[1]={at=9},[2]=amberTrigger}
blue.aiIntent={kind="pass"};amber.aiIntent=amberIntent
edit(s,function() return Settings.setRole(s,blue,"box_to_box_midfielder") end)
check(s.pressers[2]==amber and s.presserSince[2]==12 and s.combinations[2]==amberCombination
    and s.supportActions[2]==amberSupport and s.runTriggers[2]==amberTrigger and amber.aiIntent==amberIntent,
    "own tactical change cancelled an opponent's active intention")
check(s.pressers[1]==nil and s.presserSince[1]==nil and s.combinations[1]==nil
    and s.supportActions[1]==nil and s.runTriggers[1]==nil and blue.aiIntent==nil,
    "own tactical change retained stale own intentions")

local beforeInvalid=liveSnapshot(s)
local savedBlue=configSnapshot(s,1)
for _,case in ipairs({
    function() return Settings.setRole(s,blue,"goalkeeper") end,
    function() return Settings.setRole(s,blue,"missing") end,
    function() return Settings.setDuty(s,blue,"cover") end,
    function() return Settings.setDuty(s,nil,"support") end,
    function() return Settings.setDuty(s,{},"support") end,
    function() return Settings.setRole(s,{},"central_midfielder") end,
    function() return Settings.setPosition(s,blue,"GK") end,
    function() return Settings.setPosition(s,byNumber(s,1,1),"ST") end,
    function() return Settings.setPosition(s,blue,"missing") end,
    function() return Settings.setFormation(s,1,"missing") end,
    function() return Settings.setFormation(s,3,"4-4-2") end,
    function() return Settings.setTeamInstruction(s,1,"passing",.23) end,
    function() return Settings.setTeamInstruction(s,1,"missing",true) end,
    function() return Settings.setPlayerInstruction(s,blue,"carryDirection","diagonal") end,
    function() return Settings.setPlayerInstruction(s,{},"pressing",1) end
}) do check(case()==false,"invalid tactical edit accepted") end
unchanged(s,beforeInvalid);equal(configSnapshot(s,1),savedBlue,"rejected edit mutated configuration")
for _,row in ipairs(Settings.teamInstructionList) do if row.disabled then
    check(Settings.setTeamInstruction(s,1,row.id,row.default)==false,"unimplemented team instruction accepted")
end end
for _,row in ipairs(Settings.playerInstructionList) do if row.disabled then
    check(Settings.setPlayerInstruction(s,blue,row.id,row.default)==false,"unimplemented player instruction accepted")
end end

-- Every catalog role can be assigned through a compatible public position API.
local reached={}
for _,role in ipairs(Roles.list) do
    local p=role.positions[1]=="GK" and byNumber(s,1,1) or blue
    edit(s,function() return Settings.setPosition(s,p,role.positions[1]) end)
    edit(s,function() return Settings.setRole(s,p,role.id) end)
    for _,duty in ipairs(role.duties) do
        edit(s,function() return Settings.setDuty(s,p,duty) end)
        local profile=Settings.profile(s,p)
        check(profile.roleId==role.id and profile.requestedDuty==duty,"assigned role did not reach profile")
        for _,field in ipairs(Roles.numericFields) do check(profile[field]>=-1 and profile[field]<=1,"unbounded profile") end
    end
    reached[role.id]=true
end
local count=0;for _ in pairs(reached) do count=count+1 end
check(count==45,"some catalog roles cannot be reached through settings")
equal(configSnapshot(s,2),otherConfig,"role browsing changed opponent configuration")

for _,formation in ipairs(Settings.formations) do
    for team=1,2 do
        local opponent=configSnapshot(s,3-team)
        edit(s,function() return Settings.setFormation(s,team,formation.id) end)
        local keepers=0
        for _,p in ipairs(s.players) do if p.team==team then
            if p.position=="GK" then keepers=keepers+1 end
            check(contains(Roles.get(p.tacticalRole).positions,p.position),"formation retained incompatible role")
            check(contains(Roles.get(p.tacticalRole).duties,p.duty),"formation retained incompatible duty")
            check(team==1 and p.homeX<=s.field.w/2 or team==2 and p.homeX>=s.field.w/2,"illegal kickoff anchor")
        end end
        check(keepers==1,"formation creates illegal goalkeeper count")
        equal(configSnapshot(s,3-team),opponent,"formation changed opponent")
    end
end

-- Personal instructions override role tendencies without mutating teammates.
s=Sim.new("RM");blue=s.controlled;amber=byNumber(s,2,blue.number)
check(Settings.setPosition(s,blue,"MC") and Settings.setDuty(s,blue,"support"))
local baseline=Settings.profile(s,blue)
local teamTwo=configSnapshot(s,2)
local teammate=byNumber(s,1,7);local mateInstructions=copy(teammate.instructions)
for _,row in ipairs(Settings.playerInstructionList) do if not row.disabled then
    for _,option in ipairs(row.options) do
        edit(s,function() return Settings.setPlayerInstruction(s,blue,row.id,option.value) end)
        check(blue.instructions[row.id]==option.value,"individual instruction not stored")
    end
    check(Settings.setPlayerInstruction(s,blue,row.id,row.default))
end end
for _,field in ipairs({"passing","pressing","dribbling","shooting","risk","crossing"}) do
    check(Settings.setPlayerInstruction(s,blue,field,1))
    check(Settings.profile(s,blue)[field]>baseline[field],"instruction did not alter "..field)
    check(Settings.setPlayerInstruction(s,blue,field,0))
end
check(Settings.setPlayerInstruction(s,blue,"depth","forward"))
local forward=Settings.profile(s,blue)
check(forward.depth>baseline.depth and forward.runs>baseline.runs and not forward.hold,"forward override ineffective")
check(Settings.setPlayerInstruction(s,blue,"depth","hold"))
check(Settings.profile(s,blue).hold and Settings.profile(s,blue).runs==-1,"hold override ineffective")
check(Settings.setPlayerInstruction(s,blue,"width","wide"))
check(Settings.profile(s,blue).width>baseline.width,"width override ineffective")
check(Settings.setPlayerInstruction(s,blue,"roam","yes"))
check(Settings.setPlayerInstruction(s,blue,"holdUp","yes"))
check(Settings.setPlayerInstruction(s,blue,"carryDirection","inside"))
local customized=Settings.profile(s,blue)
check(customized.roam and customized.holdUp and customized.carryDirection=="inside","boolean/direction overrides ineffective")
local stable=Settings.profile(s,blue);customized.risk=99
equal(Settings.profile(s,blue),stable,"profile mutation leaked")
equal(teammate.instructions,mateInstructions,"individual edit leaked to teammate")
equal(configSnapshot(s,2),teamTwo,"individual edit leaked to opposing team")

for _,row in ipairs(Settings.teamInstructionList) do if not row.disabled then
    for _,option in ipairs(row.options) do
        edit(s,function() return Settings.setTeamInstruction(s,1,row.id,option.value) end)
        check(s.teamTactics[1].instructions[row.id]==option.value,"team instruction not stored")
    end
    check(Settings.setTeamInstruction(s,1,row.id,row.default))
end end
equal(configSnapshot(s,2),teamTwo,"team edit leaked to opponent")
check(Settings.setDuty(s,blue,"automatic"))
for _,row in ipairs(Settings.teamInstructionList) do if row.id=="mentality" then
    for _,option in ipairs(row.options) do
        check(Settings.setTeamInstruction(s,1,"mentality",option.value))
        local expected=option.value<0 and "defend" or (option.value>.3 and "attack" or "support")
        check(Settings.profile(s,blue).duty==expected,"automatic duty mismatches mentality: "..option.label)
    end
end end

-- A player moved away from ST remains a valid restart participant; shirt #9
-- must not disappear from kickoff selection when their tactical position changes.
local nine=byNumber(s,1,9)
check(Settings.setPosition(s,nine,"AMC") and Settings.setRole(s,nine,"enganche"))
check(Settings.setFormation(s,2,"3-5-2"))
check(Settings.setTeamInstruction(s,2,"width",1))
local one,two=configSnapshot(s,1),configSnapshot(s,2)
local controlled=s.controlled
Sim.restart(s)
check(s.controlled==controlled and s.setPiece and s.setPiece.taker,"restart lost control or kickoff taker")
equal(configSnapshot(s,1),one,"restart discarded blue tactics")
equal(configSnapshot(s,2),two,"restart discarded amber tactics")
check(s.elapsed==0 and s.score[1]==0 and s.score[2]==0,"restart did not reset match counters")
local five=Sim.new("RM",5)
check(five.teamTactics==nil and Settings.profile(five,five.controlled)==nil,"five-a-side fixture gained tactical configuration")
check(Settings.setFormation(five,1,"4-4-2")==false,"eleven-a-side formation accepted for five-a-side fixture")
print("PASS: tactical validation, all 45 roles reachable, isolation, live-state preservation, automatic duties and retained restarts")
