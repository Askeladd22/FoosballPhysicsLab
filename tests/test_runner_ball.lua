package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Passing=require("src.passing")
local Combinations=require("src.combinations")
local function player(s,team,number)
    for _,p in ipairs(s.players) do if p.team==team and p.number==number then return p end end
end
local function fixture(role)
    local s=Sim.new(role or "GK")
    s.phase="play";s.setPiece=nil;s.lastTouch=1;s.elapsed=1
    for _,p in ipairs(s.players) do
        p.x,p.y=p.team==1 and 8 or 98,8
        p.vx,p.vy,p.moveX,p.moveY=0,0,0,0
    end
    local p=player(s,1,6)
    p.x,p.y=45,34;s.ball.x,s.ball.y=47.3,34
    s.ball.vx,s.ball.vy=0,0
    return s,p
end

-- The actual physics tick must let an on-ball runner play, not just relabel him.
for _,kind in ipairs({"support_run","one_two_run"}) do
    local s,p=fixture()
    if kind=="support_run" then
        s.supportActions[1]={player=p,x=70,y=34,expires=5,kind=kind}
    else
        s.combinations[1]={runner=p,wall=player(s,1,7),x=70,y=34,
            expires=5,stage="outbound"}
    end
    s.aiTimer=0.1
    local oldX=s.ball.x
    Sim.step(s,1/120,{})
    assert(s.pressers[1]==p,"on-ball runner was not elected to play")
    assert(s.totalKicks==1 and s.lastKicker==p and s.ball.x>oldX and s.ball.vx>0,
        "runner followed route while nobody physically played the ball")
    assert(not Combinations.runTarget(s,p),"off-ball route survived taking the ball")
end

local function launchOneTwo(s,p,wall)
    wall.x,wall.y=60,34
    local plan=assert(Passing.plan(s,p,wall))
    plan.oneTwo=true
    assert(Sim.kick(s,p,plan.aimX,plan.aimY,plan.power,"pass",plan))
    assert(s.combinations[1] and s.combinations[1].runner==p)
end
-- Do not treat the passer's brief residual proximity as a loose-ball recovery.
local outgoing,p=fixture()
launchOneTwo(outgoing,p,player(outgoing,1,7))
outgoing.aiTimer=0.1
for _=1,24 do Sim.step(outgoing,1/120,{}) end
assert(outgoing.combinations[1] and outgoing.combinations[1].runner==p,
    "valid outgoing one-two was cancelled while pass travelled away")
assert(p.decision=="one_two_run" and p.x>45 and outgoing.ball.x>50,
    "outgoing passer stopped his physical run")

-- An explicit human one-two remains an instruction to teammates, never steering.
local human=fixture("RM")
local controlled=human.controlled
controlled.x,controlled.y=45,34
player(human,1,6).x,player(human,1,6).y=8,8
launchOneTwo(human,controlled,player(human,1,7))
human.aiTimer=0.1
Sim.step(human,1/120,{x=0.3,y=-0.2})
assert(human.controlled==controlled and controlled.moveX==0.3 and controlled.moveY==-0.2)
assert(human.combinations[1] and human.combinations[1].runner==controlled,
    "human's requested one-two was cancelled by on-ball runner handling")

local displacements={}
for _,power in ipairs({0.32,0.45}) do
    local s,kicker=fixture()
    local startX=s.ball.x
    assert(Sim.kick(s,kicker,startX+10,s.ball.y,power,"advance"))
    local speed=s.params.kickSpeed*power
    assert(math.abs(s.ball.vx-speed)<1e-9,"carry power was clamped to passing power")
    s.aiTimer=-1000 -- Isolate the physical roll after the real kick.
    for _=1,240 do Sim.step(s,1/120,{}) end
    local travelled=s.ball.x-startX
    assert(math.abs(travelled-speed*Passing.travelFactor(s.params.ballDrag,2))<1e-8,
        "physical carry disagrees with planner travel prediction")
    displacements[power]=travelled
end
assert(displacements[0.32]<9 and displacements[0.45]>displacements[0.32]+2,
    "short carry still overshoots its evaluated nine-metre corridor")
for _,action in ipairs({"pass","shot",false}) do
    local s,kicker=fixture()
    assert(Sim.kick(s,kicker,s.ball.x+10,s.ball.y,0.32,action or nil))
    local expected=s.params.kickSpeed*0.45*(action=="pass" and s.params.passMultiplier or 1)
    assert(math.abs(s.ball.vx-expected)<1e-9,"carry change lowered ordinary input/pass/shot floor")
end
print("PASS: physical runner recovery, preserved outgoing/human one-twos, short carry travel and unchanged kick floors")
