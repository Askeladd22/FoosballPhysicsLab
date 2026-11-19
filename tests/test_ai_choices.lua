package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local Combinations=require("src.combinations")
local Settings=require("src.tactical_settings")
local function fixture()
    local s=Sim.new("GK",5)
    s.phase="play";s.setPiece=nil;s.lastTouch=1
    for _,p in ipairs(s.players) do
        p.x=p.team==1 and 8 or 108;p.y=8;p.vx,p.vy=0,0
    end
    s.ball.x,s.ball.y=50,35
    local p=s.players[2];p.x,p.y=47.4,35
    return s,p
end
local open,p=fixture()
open.players[3].x,open.players[3].y=55,48
assert(select(4,AI.chooseAction(open,p))=="advance","free carry never competes with short pass")
open.players[6].x,open.players[6].y=56,35
assert(select(4,AI.chooseAction(open,p))=="pass","new pressure did not interrupt carry for safe outlet")
local behind,q=fixture()
behind.players[3].x,behind.players[3].y=65,35
behind.players[6].x,behind.players[6].y=49.5,32.2
behind.players[7].x,behind.players[7].y=49.5,37.8
assert(AI.laneRisk(behind,50,35,65,35,1)==0,"pressure behind origin blocks forward lane")
assert(select(4,AI.chooseAction(behind,q))=="pass","clear pressure-release pass ignored")

local carry,c=fixture()
carry.ball.x,carry.ball.y=60,20;c.x,c.y=57.4,20
carry.players[6].x,carry.players[6].y=66,20
local x,y,_,action=AI.chooseAction(carry,c)
assert(action=="advance" and math.abs(y-20)>3,"carry repeated fixed forward/centre target into defender")
assert(x>=2 and x<=carry.field.w-2 and y>=3 and y<=carry.field.h-3)

local memory,passer=fixture()
local a,b=memory.players[3],memory.players[5]
a.x,a.y=65,35;b.x,b.y=65,48
assert(AI.passOption(memory,passer)==a)
AI.noteKick(memory,passer,"pass",{receiver=a})
memory.elapsed=1
assert(AI.passOption(memory,passer)==b,"recent stagnant pass repeated despite another safe outlet")
memory.players[6].x,memory.players[6].y=b.x,b.y
assert(AI.passOption(memory,passer)==a,"history vetoed the only safe pass")
memory.players[6].x,memory.players[6].y=108,8;memory.elapsed=10
assert(AI.passOption(memory,passer)==a,"pass memory never expired")
passer.aiIntent={action="pass",expires=12}
Sim.restart(memory)
assert(not next(memory.aiPassMemory) and not passer.aiIntent,"restart retained decision history")

local s=Sim.new("GK")
s.phase="play";s.setPiece=nil;s.lastTouch=1
for _,v in ipairs(s.players) do v.x=v.team==1 and 8 or 101;v.y=6 end
local runner,wall=s.players[9],s.players[3]
-- This scenario needs a mobile midfielder, not the default covering #6.
assert(Settings.setDuty(s,runner,"support"))
runner.x,runner.y=37.4,30;wall.x,wall.y=51,30;s.ball.x,s.ball.y=40,30
Combinations.onKick(s,runner,"pass",{receiver=wall})
assert(not s.combinations[1],"unpressured short pass forced automatic one-two")
s.players[13].x,s.players[13].y=44,35
Combinations.onKick(s,runner,"pass",{receiver=wall})
assert(s.combinations[1],"pressure plus open run did not permit one-two")
local combo=s.combinations[1]
combo.stage="return_ready";combo.readyAt=s.elapsed;combo.expires=3
s.ball.x,s.ball.y=wall.x-2.5,wall.y
s.players[13].x,s.players[13].y=s.ball.x+2,s.ball.y+3
assert(select(4,AI.chooseAction(s,wall))~="wait_return" and not s.combinations[1],
    "wall player waits for scripted return while challenged")

-- A screened outside lane produces a run inside instead of the same overlap.
local wide=Sim.new("GK")
wide.phase="play";wide.setPiece=nil;wide.lastTouch=1
for _,v in ipairs(wide.players) do v.x=v.team==1 and 8 or 101;v.y=4 end
local carrier,fb,cm=wide.players[3],wide.players[7],wide.players[9]
assert(Settings.setDuty(wide,cm,"attack"))
carrier.x,carrier.y=48,12;fb.x,fb.y=36,8;cm.x,cm.y=40,24
wide.ball.x,wide.ball.y=50.5,12
Combinations.update(wide)
assert(wide.supportActions[1],"no open support run")
Combinations.reset(wide)
wide.players[13].x,wide.players[13].y=58,6
wide.players[14].x,wide.players[14].y=64,6
Combinations.update(wide)
local run=assert(wide.supportActions[1],"screened overlap lost inside alternative")
assert(run.kind=="underlap" and run.y>carrier.y,"run ignored opponents screening wing")
print("PASS: contextual carry/pass, pressure behind ball, adaptive carry, pass memory, breakable combinations and inside run")
