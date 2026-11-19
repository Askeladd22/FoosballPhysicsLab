-- Game-design regressions for five-a-side support and back-passing.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local Tactics=require("src.tactics")
local sqrt,abs=math.sqrt,math.abs
local function check(ok,msg) if not ok then error(msg,2) end end
local function d(x,y,u,v) return sqrt((x-u)^2+(y-v)^2) end

-- Wide midfielders, an outlet behind the ball and a striker ahead.
local s=Sim.new()
s.phase="play"; s.lastTouch=1; s.ball.x,s.ball.y=60,35
local lm,rm,df,st=s.players[3],s.players[4],s.players[2],s.players[5]
local lx,ly=Tactics.supportPoint(s,lm)
local rx,ry=Tactics.supportPoint(s,rm)
local bx,by=Tactics.supportPoint(s,df)
local fx,fy=Tactics.supportPoint(s,st)
check(ly<s.ball.y-10 and ry>s.ball.y+10,
      "AC-1: midfielders must offer opposite flank options")
check(abs(ly-ry)>18,"AC-1: midfielders clustered")
check(bx<s.ball.x-10 and fx>s.ball.x+10,
      "AC-1: rear outlet and advanced support must coexist")
check(lx>=4 and rx<=s.field.w-4 and by>=7 and fy<=s.field.h-7,
      "AC-1: support targets must remain on the pitch")

-- If human occupies a colleague's passing lane, that colleague rotates.
local rotated=Sim.new()
rotated.phase="play"; rotated.lastTouch=1
rotated.ball.x,rotated.ball.y=66,35
local midfielder=rotated.players[3]
local hx,hy=Tactics.supportPoint(rotated,midfielder)
rotated.controlled.x,rotated.controlled.y=hx,hy
local nx,ny=Tactics.supportPoint(rotated,midfielder)
check(d(nx,ny,hx,hy)>8,"AC-2: lane occupation did not trigger rotation")
check(d(nx,ny,rotated.controlled.x,rotated.controlled.y)>=9.5,
      "AC-2: occupied target is still too close to human")
local nx2,ny2=Tactics.supportPoint(rotated,midfielder)
check(nx==nx2 and ny==ny2,"AC-2: rotation was non-deterministic")

-- Defensive shape keeps a protector behind the ball; press is still assigned.
local defend=Sim.new()
defend.phase="play"; defend.lastTouch=1
defend.ball.x,defend.ball.y=62,35
local redDef=defend.players[7]
local dx,dy,phase=Tactics.supportPoint(defend,redDef)
check(phase=="defend" and dx>defend.ball.x+10,
      "AC-3: defending side has no back-line coverage")
AI.update(defend)
check(defend.pressers[2]~=nil,"AC-3: nobody presses for defending side")
check(redDef.targetX~=nil and redDef.targetY~=nil,
      "AC-3: defender lacks movement target")

-- Forward runner is tightly screened; safe backward outlet must be selected.
local pressure=Sim.new()
pressure.phase="play"; pressure.lastTouch=1
pressure.ball.x,pressure.ball.y=70,35
local passer=pressure.players[2]
passer.x,passer.y=67.4,35
pressure.players[3].x,pressure.players[3].y=55,18
pressure.controlled.x,pressure.controlled.y=55,51
pressure.players[5].x,pressure.players[5].y=90,35
local red={{78,35},{83,35},{89,35},{95,35},{106,35}}
for i=6,10 do
    pressure.players[i].x,pressure.players[i].y=red[i-5][1],red[i-5][2]
end
local recipient=AI.passOption(pressure,passer)
check(recipient and recipient.x<pressure.ball.x,
      "AC-4: a safe back-pass should beat a marked forward outlet")

-- A call for the ball influences selection only if the lane is safe.
local called=Sim.new()
called.phase="play"; called.lastTouch=1
called.ball.x,called.ball.y=70,35
local deliverer=called.players[2]
deliverer.x,deliverer.y=67.4,35
called.controlled.x,called.controlled.y=87,35
called.players[3].x,called.players[3].y=52,17
called.players[5].x,called.players[5].y=92,52
for i=6,10 do
    called.players[i].x=110
    called.players[i].y=6+(i-6)*14
end
called.requestTimer=1.15
local choice=AI.passOption(called,deliverer)
check(choice==called.controlled,"AC-5: a clear requested pass can be favored")
called.players[6].x,called.players[6].y=78,35
choice=AI.passOption(called,deliverer)
check(choice~=called.controlled,"AC-5: a marked call must not force a pass")

-- No player swap or accidental human steering via team tactics.
local goal=Sim.new("GK")
goal.phase="play"; goal.lastTouch=1
local keeper=goal.controlled
keeper.moveX,keeper.moveY=0.25,0.1
AI.update(goal)
check(goal.controlled==keeper and keeper.moveX==0.25 and keeper.moveY==0.1,
      "AC-6: AI has overwritten goalkeeper input")
print("PASS: tactical lanes, rotation, defensive cover, backpass, request safety, locked goalkeeper")
