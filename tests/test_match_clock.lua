package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local dt=1/120
local s=Sim.new("GK")
assert(s.limit==300)
Sim.step(s,dt)
assert(s.elapsed==0,"prematch countdown counted")
s.phase="play";s.setPiece=nil
Sim.step(s,dt)
assert(s.elapsed>0 and s.clockStarted)
s.lastTouch=2;s.ball.x=-2;s.ball.y=5
Sim.step(s,dt)
assert(s.setPiece.kind=="goal_kick")
local before=s.elapsed
for _=1,240 do Sim.step(s,dt) end
assert(s.phase=="restart" and s.elapsed>before+1.99,"dead ball stopped match clock")
s.phase="paused";before=s.elapsed
for _=1,120 do Sim.step(s,dt) end
assert(s.elapsed==before,"pause advanced clock")
s.phase="restart";s.elapsed=299.999
Sim.step(s,dt,{kick=1})
assert(s.phase=="fulltime" and s.elapsed==300 and not s.setPiece)
s.cornerSequence={2,3}
Sim.restart(s)
assert(s.elapsed==0 and not s.clockStarted and s.limit==300)
assert(not s.cornerSequence,"restart retained previous match corner sequence")
print("PASS: five-minute timer, initial countdown, dead balls, pause, final whistle, reset")
