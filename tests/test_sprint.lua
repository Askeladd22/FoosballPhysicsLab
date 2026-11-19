package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local dt=1/120
local function run(x,y,sprint)
 local s=Sim.new()
 s.phase="play";s.setPiece=nil;s.aiTimer=-1000
 local p=s.controlled
 p.x,p.y=30,30
 for _,q in ipairs(s.players) do if q~=p then q.x,q.y=q.number*4,60 end end
 s.ball.x,s.ball.y=90,5
 for _=1,120 do Sim.step(s,dt,{x=x,y=y,sprint=sprint}) end
 return s,math.sqrt(p.vx^2+p.vy^2)
end
local normal,v=run(1,0,false)
local sprint,fast=run(1,0,true)
assert(fast>v*1.3 and fast<=sprint.params.maxSpeed*sprint.params.sprintMultiplier+1e-8)
local diagonal,diag=run(1,1,true)
assert(math.abs(diag-fast)<1e-7,"diagonal speed bonus")
for _,p in ipairs(sprint.players) do
 if p~=sprint.controlled then assert(not p.sprinting,"human shift boosted AI") end
end
Sim.step(sprint,dt,{x=1,sprint=false})
assert(not sprint.controlled.sprinting and sprint.controlled.vx<=sprint.params.maxSpeed+1e-8)
sprint.phase="paused";local x=sprint.controlled.x
Sim.step(sprint,dt,{x=1,sprint=true})
assert(sprint.controlled.x==x,"sprint moved during pause")
Sim.restart(sprint)
assert(not sprint.controlled.sprinting,"reset retained sprint")
local still=run(0,0,true)
assert(not still.controlled.sprinting,"stationary player sprinting")
print("PASS: sprint acceleration/speed, diagonal normalization, release, pause, reset, human-only")
