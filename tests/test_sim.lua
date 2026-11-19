-- Headless simulation regressions. Run: lua tests/test_sim.lua
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local dt=1/120
local function check(ok,msg)
    if not ok then error(msg or "assertion failed",2) end
end
local function tick(s,n,input)
    for i=1,n do Sim.step(s,dt,input or {x=0,y=0}) end
end

-- Kick-off roles, no initial overlap and unchanged player identity.
local s=Sim.new()
check(#s.players==10,"AC-6: 5v5 must spawn ten discs")
check(s.controlled==s.players[4],"AC-6: controlled player must stay blue #10")
check(s.players[1].role=="GK" and s.players[6].role=="GK","missing keepers")
check(s.setPiece.kind=="kickoff" and s.setPiece.team==1 and
      s.setPiece.taker==s.players[5],"AC-3: one kickoff taker")
local controlled=s.controlled
for _,p in ipairs(s.players) do
    if p~=s.setPiece.taker then
        local dx,dy=p.x-s.ball.x,p.y-s.ball.y
        check(dx*dx+dy*dy>(p.r+s.ball.r+1)^2,
              "AC-3: non-taker overlaps center spot")
    end
end
tick(s,100)
check(s.phase=="play" and s.totalKicks==1 and s.passAttempts==1,
      "AC-3: kickoff should be a controlled pass, exactly once")
check(s.lastTouch==1 and s.ball.vx>0,"AC-3: blue kickoff goes right")
check(s.controlled==controlled,"AC-6: control switched at kickoff")

-- Analog control must not be normalized to max acceleration.
local slow,fast=Sim.new(),Sim.new()
slow.phase,fast.phase="play","play"
slow.setPiece,fast.setPiece=nil,nil
Sim.step(slow,dt,{x=0.2,y=0})
Sim.step(fast,dt,{x=1,y=0})
check(slow.controlled.vx>0 and slow.controlled.vx<fast.controlled.vx*0.3,
      "AC-1: partial input was normalized")

-- Near the support anchor: brake rather than switching left/right at full speed.
local stable=Sim.new()
stable.phase="play"
local defender=stable.players[2]
defender.x,defender.y=22.2,35
defender.vx,defender.vy=0,0
AI.update(stable)
check(math.sqrt(defender.moveX^2+defender.moveY^2)<0.2,
      "AC-2: player must brake at anchor")
local hold=Sim.new()
hold.phase="play"
AI.update(hold)
local prev=hold.pressers[2]
check(prev~=nil,"AC-2: red presser not assigned")
local candidate=hold.players[8]
candidate.x,candidate.y=63,35
hold.elapsed=0.1
AI.update(hold)
check(hold.pressers[2]==prev,"AC-2: pressing assignment switched too early")

-- A free passing lane must create a real physical AI pass.
local pass=Sim.new()
pass.phase="play"
pass.setPiece=nil
pass.setPieceProtect=0
pass.lastTouch=1
pass.ball.x,pass.ball.y=50,35
pass.ball.vx,pass.ball.vy=0,0
local passer=pass.players[2]
passer.x,passer.y=47.4,35
passer.vx,passer.vy=0,0
local mate=pass.players[5]
mate.x,mate.y=75,35
for i=6,10 do
    pass.players[i].x=95+(i-6)*3
    pass.players[i].y=15+((i-6)%3)*18
end
AI.update(pass)
check(pass.aiPassAttempts==1 and pass.passAttempts==1,
      "AC-5: available teammate was not passed to")
check(pass.ball.vx>1,"AC-5: AI pass must physically move ball forward")

local request=Sim.new()
request.phase="play"
request.ball.x,request.ball.y=50,35
local reqPasser=request.players[2]
reqPasser.x,reqPasser.y=47.4,35
request.controlled.x,request.controlled.y=77,35
for i=6,10 do
    request.players[i].x=105
    request.players[i].y=8+(i-6)*13
end
request.requestTimer=1.15
local receiver=AI.passOption(request,reqPasser)
check(receiver==request.controlled,
      "AC-5: pass request should help selection when lane is clear")

-- All boundaries: one designated taker, inside-directed restart.
for _,side in ipairs({"top","bottom","left","right"}) do
    local r=Sim.new()
    r.phase="play"
    r.lastTouch=1
    r.setPiece=nil
    r.ball.vx,r.ball.vy=0,0
    r.ball.x,r.ball.y=60,35
    if side=="top" then r.ball.y=-3
    elseif side=="bottom" then r.ball.y=r.field.h+3
    elseif side=="left" then r.ball.x,r.ball.y=-3,15
    else r.ball.x,r.ball.y=r.field.w+3,15 end
    Sim.step(r,dt,{x=0,y=0})
    check(r.phase=="restart" and r.setPiece.kind=="restart" and
          r.setPiece.side==side and r.setPiece.team==2,
          "AC-4: incorrectly assigned restart for "..side)
    local taker=r.setPiece.taker
    check(taker~=nil and taker.team==2 and taker~=r.controlled,
          "AC-4: missing AI restart taker")
    local x,y=r.ball.x,r.ball.y
    tick(r,100)
    check(r.phase=="play" and r.totalKicks==1,
          "AC-4: exactly one restart kick for "..side)
    if side=="top" then
        check(r.ball.vy>0,"AC-4: upper throw must go toward field")
    elseif side=="bottom" then
        check(r.ball.vy<0,"AC-4: lower throw must go toward field")
    elseif side=="left" then
        check(r.ball.vx>0,"AC-4: left restart must go toward field")
    else
        check(r.ball.vx<0,"AC-4: right restart must go toward field")
    end
    tick(r,25)
    check(r.restartCount==1 and r.phase=="play",
          "AC-4: immediate repeated out-of-bounds "..side)
end

-- Goals, clocks, restarts, deterministic fixed-step simulation remain valid.
local goal=Sim.new()
goal.phase="play"
goal.ball.x,goal.ball.y=goal.field.w+goal.ball.r+1,goal.field.h/2
Sim.step(goal,dt,{x=0,y=0})
check(goal.score[1]==1 and goal.phase=="kickoff" and
      goal.setPiece.team==2,"AC-6: goal must give kickoff to conceding side")

local timed=Sim.new()
timed.phase="play"
timed.elapsed=timed.limit-dt/2
Sim.step(timed,dt,{x=0,y=0})
check(timed.phase=="fulltime","AC-6: fulltime trigger")
local a,b=Sim.new(),Sim.new()
tick(a,800,{x=0.7,y=-0.3})
tick(b,800,{x=0.7,y=-0.3})
check(math.abs(a.ball.x-b.ball.x)<1e-8 and
      math.abs(a.controlled.x-b.controlled.x)<1e-8,
      "AC-6: match physics must be deterministic")
Sim.restart(a)
check(a.score[1]==0 and a.score[2]==0 and a.elapsed==0 and
      a.controlled==a.players[4],"AC-6: restart state")

print("PASS: kickoff, analog steering, sticky press, real passes, four restarts, scoring, identity, deterministic match")
