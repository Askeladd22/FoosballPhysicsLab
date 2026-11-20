-- Selection and gameplay tests for goalkeeper or outfield-controlled disc.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local dt=1/120
local function check(ok,msg) if not ok then error(msg,2) end end
local function tick(s,n,input)
    for _=1,n do Sim.step(s,dt,input or {x=0,y=0}) end
end
local default=Sim.new(nil,5)
check(default.controlled==default.players[4] and
      default.controlled.number==10 and default.controlled.role=="RM",
      "default human should remain blue midfielder #10")
local goal=Sim.new("GK",5)
local keeper=goal.players[1]
check(goal.controlled==keeper and keeper.number==1 and keeper.team==1,
      "goalkeeper must be blue #1")
check(goal.players[4]~=goal.controlled,
      "midfielder must become AI when human is in goal")
check(goal.setPiece.taker==goal.players[5],
      "GK must not be forced to take opening kickoff")
tick(goal,100)
check(goal.phase=="play" and goal.controlled==keeper,
      "selected goalkeeper must persist through kickoff")
local beforeX=keeper.x
Sim.step(goal,dt,{x=1,y=0})
check(keeper.x>beforeX,"WASD movement must apply to goalkeeper")
goal.ball.x,goal.ball.y=keeper.x+keeper.r+goal.ball.r+0.2,keeper.y
goal.ball.vx,goal.ball.vy=0,0
keeper.cooldown=0
check(Sim.kick(goal,keeper,nil,nil,1,"clearance"),
      "goalkeeper should be able to clear with the normal kick")
check(goal.ball.vx>0 and goal.lastTouch==1,
      "GK clearance must propel ball with physical impulse")
local sameKeeper=goal.controlled
Sim.restart(goal)
check(goal.controlled==sameKeeper and goal.controlled.role=="GK",
      "R/restart must preserve chosen GK role")
tick(goal,100)
check(goal.controlled==sameKeeper and goal.players[4]~=sameKeeper,
      "goalkeeper control changed during match")
local invalid=pcall(function() Sim.new("ST") end)
check(not invalid,"unsupported role silently accepted")
print("PASS: goalkeeper selection, movement, clearance, locked role, restart")
