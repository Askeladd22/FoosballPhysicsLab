-- Football touchlines and stronger AI passes.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local dt=1/120
local function near(a,b,epsilon)
    return math.abs(a-b)<(epsilon or 1e-8)
end
local function check(condition,message)
    if not condition then error(message,2) end
end

local function ready()
    local s=Sim.new(nil,5)
    s.phase="play"
    s.setPiece=nil
    s.aiTimer=-1000 -- avoid autonomous AI decisions during isolated tests
    return s
end

-- Rails rebound above/below without triggering a throw-in or a pause.
for _,edge in ipairs({"top","bottom"}) do
    local s=ready()
    s.lastTouch=1
    local b=s.ball
    b.x=60
    b.y=edge=="top" and -b.r-0.01 or s.field.h+b.r+0.01
    b.vy=edge=="top" and -10 or 10
    Sim.step(s,dt)
    check(s.phase=="play" and not s.setPiece and s.restartCount==0,
        "arena rail generated a throw-in")
    check(b.y>=b.r and b.y<=s.field.h-b.r,"ball escaped arena rail")
    check(edge=="top" and b.vy>0 or edge=="bottom" and b.vy<0,
        "arena rail failed to reverse direction")
end

-- A kick of the same base power must be boosted only when classified 'pass'.
local function isolatedKick(action)
    local s=ready()
    local p=s.players[2]
    local b=s.ball
    p.x,p.y=47.4,35
    p.vx,p.vy=0,0
    b.x,b.y=50,35
    b.vx,b.vy=0,0
    p.cooldown=0
    local ok=Sim.kick(s,p,80,35,0.70,action)
    check(ok,"AC-3: could not execute "..tostring(action))
    return b.vx,b.vy,s
end
local normal,_,manual=isolatedKick("kick")
local shot,_,shooter=isolatedKick("shot")
local pass,_,passer=isolatedKick("pass")
check(normal>0,"AC-3: baseline kick must produce positive velocity")
check(near(pass/normal,1.35),"AC-3: pass impulse was not increased by 35 percent")
check(near(shot,normal),"AC-3: shot power changed unintentionally")
check(passer.passAttempts==1 and passer.shotAttempts==0,
    "AC-3: pass tracking broken")
check(shooter.shotAttempts==1 and manual.passAttempts==0,
    "AC-3: shot tracking broken")

-- Scoring still works and has priority over the goal-line restart.
local score=ready()
score.ball.x=score.field.w+score.ball.r+2
score.ball.y=score.field.h/2
Sim.step(score,dt,{x=0,y=0})
check(score.score[1]==1 and score.phase=="kickoff",
      "AC-2: right goal failed when touchlines were disabled")
check(score.setPiece and score.setPiece.kind=="kickoff",
      "AC-2: conceding side did not get kickoff")

print("PASS: touchline bounce, 35 percent pass-only boost, shots unchanged, goals")
