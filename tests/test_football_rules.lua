package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local dt=1/120
local function ready()
 local s=Sim.new()
 s.phase="play";s.setPiece=nil;s.aiTimer=-1000
 for i,p in ipairs(s.players) do p.x=15+(i%10)*7;p.y=25+math.floor(i/11)*15 end
 return s
end
local function restart(side,last)
 local s=ready();s.lastTouch=last
 s.ball.x=side=="left" and -2 or (side=="right" and s.field.w+2 or 50)
 s.ball.y=side=="top" and -2 or (side=="bottom" and s.field.h+2 or 8)
 Sim.step(s,dt)
 return s
end
for _,side in ipairs({"left","right","top","bottom"}) do
 for team=1,2 do
  local s=restart(side,team)
  local spec=s.setPiece
  local defender=side=="left" and 1 or 2
  local expected=(side=="top" or side=="bottom") and "throw_in" or
      (team==defender and "corner" or "goal_kick")
  assert(spec.kind==expected and spec.team==3-team,side.." assigned incorrectly")
  if expected=="corner" then
   assert(s.ball.x<1 or s.ball.x>s.field.w-1)
   assert(s.ball.y<1 or s.ball.y>s.field.h-1)
   for _,p in ipairs(s.players) do
    if p.team~=spec.team then
     assert((p.x-s.ball.x)^2+(p.y-s.ball.y)^2>9.15^2,"corner distance")
    end
   end
  end
  for _=1,100 do Sim.step(s,dt) end
  assert(s.phase=="play" and s.totalKicks==1,"AI failed to restart "..side)
  assert(s.ball.x>=-s.ball.r and s.ball.x<=s.field.w+s.ball.r)
  assert(s.ball.y>=-s.ball.r and s.ball.y<=s.field.h+s.ball.r)
 end
end
-- First boundary wins at a diagonal corner, not the last position's goal line.
local s=ready();s.lastTouch=1
s.ball.x=s.field.w;s.ball.y=-s.ball.r+0.01
s.ball.vx,s.ball.vy=200,-200
Sim.step(s,dt)
assert(s.setPiece.kind=="throw_in","diagonal exit ignored first crossed line")

-- Every real deflection changes last touch, even just after a kick.
local touch=ready();touch.lastTouch=1;touch.lastKickTime=0
local p=touch.players[12]
p.x,p.y=50,10
touch.ball.x,touch.ball.y=50+p.r+touch.ball.r-0.01,10
touch.ball.vx,touch.ball.vy=-0.2,0
Sim.step(touch,dt)
assert(touch.lastTouch==2,"soft deflection ignored")
touch.ball.x,touch.ball.y=50,-2
Sim.step(touch,dt)
assert(touch.setPiece.team==1,"throw awarded using stale touch")

-- Direct throw-ins cannot score either in the opposing or own goal.
for _,side in ipairs({"left","right"}) do
 local r=restart("top",2)
 for _=1,87 do Sim.step(r,dt) end
 assert(r.directRestart.kind=="throw_in")
 r.aiTimer=-1000
 r.ball.x=side=="left" and -2 or r.field.w+2;r.ball.y=r.field.h/2
 Sim.step(r,dt)
 assert(r.score[1]==0 and r.score[2]==0)
 assert(r.setPiece.kind==(side=="right" and "goal_kick" or "corner"))
end
-- A subsequent player's touch removes the direct-goal restriction.
local r=restart("top",2)
for _=1,87 do Sim.step(r,dt) end
r.aiTimer=-1000
local q=r.players[2]
q.x,q.y=50,10;r.ball.x,r.ball.y=52,10;r.ball.vx,r.ball.vy=0,0
q.cooldown=0
assert(Sim.kick(r,q,80,10,1))
assert(not r.directRestart)
r.ball.x,r.ball.y=r.field.w+2,r.field.h/2
Sim.step(r,dt)
assert(r.score[1]==1 and r.setPiece.team==2,"valid goal not awarded")
print("PASS: 11v11 throw-ins, corners, goal kicks, first crossing, soft touches, direct-goal restrictions")
