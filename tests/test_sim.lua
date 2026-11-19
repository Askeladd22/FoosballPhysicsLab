-- Headless checks for the world simulation. Run from repository root:
-- lua tests/test_sim.lua
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local dt=1/120
local function check(ok,msg)
    if not ok then error(msg or "check failed",2) end
end
local function tick(s,n,input)
    for _=1,n do Sim.step(s,dt,input or {x=0,y=0}) end
end
local s=Sim.new()
check(#s.players==10,"5v5 must spawn ten discs")
check(s.controlled~=nil and s.controlled.team==1,"human must belong to blue team")
local original=s.controlled
local num=s.controlled.number
tick(s,100)
check(s.phase=="play","kickoff countdown must transition to play")
check(s.controlled==original and s.controlled.number==num,"control must never switch")
check(s.players[1].role=="GK" and s.players[6].role=="GK","keepers missing")

local k=Sim.new()
k.phase="play"
local p=k.controlled
k.ball.x=p.x+p.r+k.ball.r+0.2
k.ball.y=p.y
check(Sim.kick(k,p,nil,nil,1),"contact kick should succeed")
check(k.ball.vx>0,"kick should impart velocity")
check(not Sim.kick(k,p,nil,nil,1),"cooldown must prevent double kicking")

local score=Sim.new()
score.phase="play"
score.ball.x=score.field.w+score.ball.r+1
score.ball.y=score.field.h/2
Sim.step(score,dt,{x=0,y=0})
check(score.score[1]==1 and score.phase=="kickoff","right goal must score for blue")

local other=Sim.new()
other.phase="play"
other.ball.x=other.field.w/2
other.ball.y=-other.ball.r-2
Sim.step(other,dt,{x=0,y=0})
check(other.phase=="restart","side exit should start play restart")

local timed=Sim.new()
timed.phase="play"
timed.elapsed=timed.limit-dt/2
Sim.step(timed,dt,{x=0,y=0})
check(timed.phase=="fulltime","clock should end match")

local a,b=Sim.new(),Sim.new()
local input={x=0.7,y=-0.3}
tick(a,800,input)
tick(b,800,input)
check(math.abs(a.ball.x-b.ball.x)<1e-8,"fixed step physics must be deterministic")
check(math.abs(a.controlled.x-b.controlled.x)<1e-8,"controlled disc determinism")
check(a.controlled==a.players[4],"player identity must remain stable")

Sim.restart(a)
check(a.score[1]==0 and a.score[2]==0 and a.elapsed==0,"restart must reset result")
print("PASS: roster, control, physics, scoring, restart, timer, determinism")
