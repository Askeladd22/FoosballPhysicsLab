package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local Passing=require("src.passing")
local Offside=require("src.offside")
local Combinations=require("src.combinations")
local Tactics=require("src.tactics")
local Settings=require("src.tactical_settings")
local dt=1/120
local function ready(role)
    local s=Sim.new(role or "GK")
    s.phase="play";s.setPiece=nil;s.lastTouch=1
    for i,p in ipairs(s.players) do
        p.x=p.team==1 and 8 or 101
        p.y=4+(i%10)*2
        p.vx,p.vy,p.moveX,p.moveY=0,0,0,0
    end
    return s
end

-- A request creates a forward run, followed by an actual second physical pass.
for _,humanRunner in ipairs({false,true}) do
    local s=ready(humanRunner and "RM" or "GK")
    local runner=humanRunner and s.controlled or s.players[9]
    local wall=s.players[3]
    runner.x,runner.y=37.4,30;wall.x,wall.y=53,30
    s.ball.x,s.ball.y=40,30
    local plan=assert(Passing.plan(s,runner,wall));plan.oneTwo=true
    assert(Sim.kick(s,runner,plan.aimX,plan.aimY,plan.power,"pass",plan))
    assert(s.combinations[1] and s.combinations[1].x>wall.x+2)
    local controlled=s.controlled
    local completed=false
    for _=1,720 do
        local input={}
        if humanRunner then
            local combo=s.combinations[1]
            local tx,ty=combo and combo.x or runner.x,combo and combo.y or runner.y
            if combo and combo.stage=="returning" then tx,ty=s.ball.x,s.ball.y end
            local dx,dy=tx-runner.x,ty-runner.y
            local length=math.sqrt(dx*dx+dy*dy)
            if length>0.3 then input.x,input.y=dx/math.max(1,length),dy/math.max(1,length) end
        end
        Sim.step(s,dt,input)
        assert(s.controlled==controlled,"combination switched player")
        if s.combinationFeedback and s.combinationFeedback.kind=="one_two_complete" then completed=true;break end
    end
    assert(completed,"one-two never completed its physical return; human="..tostring(humanRunner))
    assert(s.passStats[1].completed>=2,"one-two did not make two physical receptions")
end

-- Long user-requested combinations must target beyond the wall player.
local longer=ready("RM")
local human=longer.controlled
human.x,human.y=47.4,34;longer.ball.x,longer.ball.y=50,34
longer.players[5].x,longer.players[5].y=70,34
assert(Sim.pass(longer,human,true))
assert(longer.combinations[1].x>72,"one-two target cannot reach return side")
human.moveX,human.moveY=0,0
AI.update(longer)
assert(human.moveX==0 and human.moveY==0,"one-two moved human automatically")

-- A fullback overlaps a wide carrier; another defender remains as cover.
for team=1,2 do
    local s=ready("GK")
    s.lastTouch=team
    local wide=s.players[team==1 and 3 or 14]
    local fb=s.players[team==1 and 7 or 18]
    local attack=team==1 and 1 or -1
    wide.x,wide.y=team==1 and 48 or 57,12
    fb.x,fb.y=wide.x-attack*12,8;fb.homeY=8
    s.ball.x,s.ball.y=wide.x+attack*2.5,12
    if team==2 then
        for _,p in ipairs(s.players) do if p.team==1 then p.x=4 end end
    end
    Combinations.update(s)
    local run=assert(s.supportActions[team],"no wide overlap")
    assert(run.kind=="overlap" and run.player==fb)
    assert((run.x-wide.x)*attack>6 and run.y<wide.y)
    local x,y=fb.x,fb.y
    AI.update(s)
    assert(fb.decision=="overlap" and fb.moveX*attack>0,"fullback not steering forward")
    assert(fb.x==x and fb.y==y,"overlap teleported player")
    local cover=false
    for _,target in pairs(Tactics.teamTargets(s,team)) do
        if target.cover then cover=true;assert((target.x-s.ball.x)*attack<0) end
    end
    assert(cover,"overlap removed defensive cover")
    s.lastTouch=3-team;Combinations.update(s)
    assert(not s.supportActions[team],"overlap survived turnover")
end

-- Held possession offers another runner after the first opportunity expires.
local held=ready("RM")
-- Two eligible runners let the coordinator renew its invitation. The
-- default #6 now explicitly holds position and must not violate that duty.
assert(Settings.setDuty(held,held.players[9],"attack"))
held.controlled.x,held.controlled.y=50,34
held.ball.x,held.ball.y=52.5,34
held.players[9].x,held.players[9].y=40,27
held.players[10].x,held.players[10].y=39,43
Combinations.update(held)
local first=assert(held.supportActions[1]).player
held.elapsed=8.1;Combinations.update(held)
assert(held.supportActions[1] and held.supportActions[1].player~=first,"static carrier never received another support run")
AI.update(held)
assert(held.controlled.moveX==0 and held.controlled.moveY==0)
assert(not held.pressers[1] or held.pressers[1].decision~="approach_pass","teammate crowded human carrier")
local previous=held.players[8]
held.pressers[1]=previous
AI.update(held)
assert(not held.pressers[1] and Tactics.teamTargets(held,1)[previous],"suspended presser missing from team support")
held.lastTouch=2;held.setPieceProtect=1;held.pressers[1]=previous
Combinations.reset(held);AI.update(held)
assert(not held.pressers[1] and Tactics.teamTargets(held,1)[previous],"restart protection retained stale presser")
Combinations.reset(held)
assert(not next(held.combinations) and not next(held.supportActions))
print("PASS: physical AI/human one-twos, forward targets, mirrored overlaps/cover, turnover and renewed support")
