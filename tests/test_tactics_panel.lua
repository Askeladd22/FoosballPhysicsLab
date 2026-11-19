-- Headless coach-report integration: real key, row and mouse handlers.
-- Rendering is mocked; the separate visual smoke test covers actual geometry.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Panel=require("src.tactics_panel")
local function check(ok,message) if not ok then error(message,2) end end
local shown,panelState,panelMatch
local keys,quitCalls,stepCalls,lastInput={},0,0,nil
local realStep,realDraw=Sim.step,Panel.draw
Sim.step=function(s,dt,input)
    stepCalls=stepCalls+1
    lastInput={};for key,value in pairs(input or {}) do lastInput[key]=value end
    return realStep(s,dt,input)
end
Panel.draw=function(state,s) panelState,panelMatch=state,s end
package.loaded["src.view"]={
    load=function() end,
    draw=function(s,ui) shown={match=s,ui=ui} end
}
love={
    window={setTitle=function() end,setMode=function() end,maximize=function() end,
        getFullscreen=function() return false end,setFullscreen=function() end},
    keyboard={isDown=function(...)
        for _,key in ipairs({...}) do if keys[key] then return true end end
        return false
    end},
    event={quit=function() quitCalls=quitCalls+1 end}
}
dofile("main.lua")
love.load();love.draw()
check(shown.ui.chooseRole,"prematch selection missing")
love.keypressed("t",nil,false);love.draw()
check(not shown.ui.tactics and shown.ui.chooseRole,"tactics opened before role selection")
love.keypressed("2",nil,false);love.draw()
local s,human=shown.match,shown.match.controlled
check(#s.players==22 and human.number==10,"controller did not start expected player")
s.phase,s.setPiece,s.clockStarted,s.elapsed="play",nil,true,24.5
s.score={2,1}
local function key(value) love.keypressed(value,nil,false);love.draw() end
local function selectRow(id)
    local rows=Panel.rows(panelState,s)
    local target
    for index,row in ipairs(rows) do if row.id==id then target=index end end
    check(target,"row missing: "..id)
    while panelState.selected>target do key("up") end
    while panelState.selected<target do key("down") end
end
local function copy(value)
    if type(value)~="table" then return value end
    local out={};for name,item in pairs(value) do out[name]=copy(item) end
    return out
end
local function equal(a,b,label)
    if type(a)~="table" or type(b)~="table" then check(a==b,label);return end
    for name,value in pairs(a) do equal(value,b[name],label.."."..tostring(name)) end
    for name in pairs(b) do check(a[name]~=nil,label.." unexpected field") end
end
local function configuration()
    local out={teams=copy(s.teamTactics),players={}}
    for _,p in ipairs(s.players) do out.players[#out.players+1]={position=p.position,
        role=p.role,tacticalRole=p.tacticalRole,duty=p.duty,homeX=p.homeX,homeY=p.homeY,
        instructions=copy(p.instructions)} end
    return out
end
local function physicsSnapshot()
    local out={elapsed=s.elapsed,phase=s.phase,controlled=s.controlled,
        score1=s.score[1],score2=s.score[2],ball={s.ball.x,s.ball.y,s.ball.vx,s.ball.vy},players={}}
    for _,p in ipairs(s.players) do out.players[#out.players+1]={p.x,p.y,p.vx,p.vy,p} end
    return out
end
local function unchanged(before)
    check(s.elapsed==before.elapsed and s.phase==before.phase,"panel altered clock or phase")
    check(s.controlled==before.controlled and s.score[1]==before.score1 and s.score[2]==before.score2,
        "panel reset control or score")
    check(s.ball.x==before.ball[1] and s.ball.y==before.ball[2]
        and s.ball.vx==before.ball[3] and s.ball.vy==before.ball[4],"panel moved the ball")
    for n,p in ipairs(s.players) do local prior=before.players[n]
        check(p==prior[5] and p.x==prior[1] and p.y==prior[2] and p.vx==prior[3] and p.vy==prior[4],
            "panel teleported or accelerated a player")
    end
end

-- Pending tap, one-two and call input must not fire on leaving the report.
keys.q=true;key("space");love.keyreleased("space");key("e")
local paused=physicsSnapshot();local priorSteps=stepCalls
key("t")
check(shown.ui.tactics and panelState and panelMatch==s and not shown.ui.charging,"T did not open/clear charging")
love.keypressed("t",nil,true);love.keypressed("escape",nil,true);love.draw()
check(shown.ui.tactics and quitCalls==0,"repeated T/Esc closed tactical panel")
keys={d=true,lshift=true}
for _=1,20 do love.update(.05) end
check(stepCalls==priorSteps,"simulation ran while tactical panel was open")
unchanged(paused)
key("escape")
check(not shown.ui.tactics and quitCalls==0,"Esc must close tactics without quitting")
keys={};love.update(1/120)
check(stepCalls==priorSteps+1 and lastInput and not lastInput.kick and not lastInput.pass
    and not lastInput.shot and not lastInput.oneTwo and not lastInput.call,"queued input leaked across tactical pause")

-- Opening during a charge and releasing Space inside cannot create a shot.
key("space");love.update(.05)
check(shown.ui.charging,"space did not begin charge")
key("t");love.keyreleased("space")
check(shown.ui.tactics and not shown.ui.charging,"panel did not cancel active charge")
paused=physicsSnapshot();priorSteps=stepCalls

-- All sections can be inspected; former editing keys must never change tactics.
local coachConfiguration=configuration()
key("]");key("]");key("]")
check(Panel.player(panelState,s)==human,"roster keyboard selection did not reach human")
for _,id in ipairs({"formation","position","role","duty"}) do
    selectRow(id)
    for _,pressed in ipairs({"left","right","return","kpenter"}) do key(pressed) end
    equal(configuration(),coachConfiguration,"read-only role report edited tactics")
end
check(Panel.change(panelState,s,1)==false,"direct report change handler must refuse edits")
equal(configuration(),coachConfiguration,"report change helper edited tactics")
check(s.controlled==human,"report navigation swapped controlled object")
key("tab")
check(panelState.tab==2 and not shown.ui.chooseRole,"panel TAB restarted role selection")
for _,row in ipairs(Panel.rows(panelState,s)) do
    selectRow(row.id);key("left");key("right");key("return")
end
equal(configuration(),coachConfiguration,"team report edited coach configuration")
key("2");selectRow("pressing");key("right")
check(panelState.team==2,"team selector did not change inspected side")
equal(configuration(),coachConfiguration,"opponent report edited coach configuration")
key("1");key("tab")
check(panelState.tab==3 and Panel.player(panelState,s)==human,"player instruction tab lost selection")
for _,row in ipairs(Panel.rows(panelState,s)) do
    selectRow(row.id);key("left");key("right");key("kpenter")
end
equal(configuration(),coachConfiguration,"player report edited coach configuration")
key("pageup");local selected=panelState.selected
love.wheelmoved(1,0)
check(panelState.selected==selected,"horizontal/zero wheel input changed selected row")
love.wheelmoved(0,-1)
check(panelState.selected>=selected,"mouse wheel did not navigate rows")
unchanged(paused)
check(stepCalls==priorSteps,"report navigation stepped simulation")

-- Synthetic hit rectangles isolate real mouse dispatch from rendered geometry.
-- Every part of a row selects only; values are owned by the coach.
panelState.hits={
    {kind="tab",index=1,x=30,y=0,w=20,h=20},
    {kind="team",x=60,y=0,w=20,h=20},
    {kind="player",index=5,x=90,y=0,w=20,h=20},
    {kind="row",index=1,x=0,y=30,w=200,h=30},
    {kind="close",x=0,y=0,w=20,h=20}
}
love.mousepressed(40,10,2)
check(panelState.tab==3,"secondary click edited panel")
love.mousepressed(40,10,1)
check(panelState.tab==1,"mouse tab selector failed")
love.mousepressed(70,10,1)
check(panelState.team==2,"mouse team selector failed")
love.mousepressed(100,10,1)
check(panelState.player==5 and Panel.player(panelState,s).number==9,"mouse player selector failed")
local originalFormation=s.teamTactics[2].formation
love.mousepressed(20,40,1)
check(panelState.selected==1 and s.teamTactics[2].formation==originalFormation,"row label click changed value")
love.mousepressed(190,40,1)
check(s.teamTactics[2].formation==originalFormation,"mouse value click edited coach formation")
love.mousepressed(120,40,1)
equal(configuration(),coachConfiguration,"mouse navigation edited coach configuration")
unchanged(paused)
love.mousepressed(10,10,1);love.draw()
check(not shown.ui.tactics and quitCalls==0,"mouse close did not resume safely")
love.update(1/120)
check(not lastInput.kick and not lastInput.pass and not lastInput.shot,"charge leaked after mouse close")

-- R resets match counters but retains the human object and tactical choices.
local beforeRestart=configuration()
key("r")
check(s.controlled==human,"controller restart replaced controlled player")
equal(configuration(),beforeRestart,"controller restart discarded coach setup")
check(s.elapsed==0 and s.score[1]==0 and s.score[2]==0,"R failed to reset match counters")
-- T is an overlay: closing it must retain a pause that existed beforehand.
key("p");check(s.phase=="paused","manual pause failed")
key("t");key("t");love.update(1/120)
check(s.phase=="paused" and s.elapsed==0,"tactical close undid existing pause")
key("escape")
check(quitCalls==1,"Esc outside panel no longer quits")
Sim.step,Panel.draw=realStep,realDraw
print("PASS: read-only coach report, keyboard/mouse navigation, pause/input clearing and retained restart")
