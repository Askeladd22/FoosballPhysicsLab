-- Physical end-to-end pass scenarios; run with Lua 5.4 or LuaJIT.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local Passing=require("src.passing")
local dt=1/120
local function check(ok,msg) if not ok then error(msg,2) end end
local function fixture(distance)
    local s=Sim.new("GK",5)
    s.phase="play"; s.setPiece=nil; s.lastTouch=1
    local p,r=s.players[2],s.players[3]
    s.controlled.x,s.controlled.y=4,65
    p.x,p.y=17.4,35
    r.x,r.y=20+distance,35
    s.ball.x,s.ball.y=20,35
    local roster=s.players
    s.players={p,r,s.controlled}
    return s,p,r,roster
end
local function launch(s,p,r)
    local plan=Passing.plan(s,p,r)
    check(plan,"AC-1: no feasible pass")
    local nx,ny=(plan.aimX-s.ball.x)/10,(plan.aimY-s.ball.y)/10
    p.x,p.y=s.ball.x-nx*2.6,s.ball.y-ny*2.6
    check(Passing.canLaunch(s,p,plan),"AC-1: aligned launch rejected")
    check(Sim.kick(s,p,plan.aimX,plan.aimY,plan.power,"pass",plan),"kick failed")
    return plan
end
local function stepUntilResolved(s)
    for _=1,480 do
        Sim.step(s,dt,{x=0,y=0})
        if not s.activePass then return end
    end
    error("pass never resolved")
end
local function balanced(s)
    for team=1,2 do
        local stats=s.passStats[team]
        local pending=s.activePass and s.activePass.team==team and 1 or 0
        check(stats.attempts==stats.completed+stats.intercepted+stats.missed+pending,
            "AC-3: pass outcome counted twice or lost")
    end
end

-- Actual Sim.step trajectories, not a duplicate of the planner's formula.
for _,distance in ipairs({8,12,20,30,40}) do
    for _,velocity in ipairs({{0,0},{12,0},{-10,5},{0,-10}}) do
        local s,p,r=fixture(distance)
        s.ball.vx,s.ball.vy=velocity[1],velocity[2]
        if distance==40 and velocity[1]==-10 then
            check(not Passing.plan(s,p,r),"AC-1: opposing momentum exceeds power budget")
        else
            local plan=launch(s,p,r)
            s.players={s.controlled} -- isolate free flight from physical contacts
            s.aiTimer=-1000
            for _=1,math.floor(plan.flightTime/dt+0.5) do Sim.step(s,dt) end
            local miss=math.sqrt((s.ball.x-plan.targetX)^2+(s.ball.y-plan.targetY)^2)
            check(miss<0.00001,"AC-1: physical flight missed target at "..distance)
            balanced(s)
        end
    end
end

local far,passer,receiver=fixture(40)
local mate,_,_,plan=AI.passOption(far,passer)
check(mate==receiver and plan.power>0.70,"AC-1: original 40-unit pass still underpowered")
AI.update(far)
check(far.activePass and far.activePass.receiver==receiver and far.passAttempts==1,
    "AC-1: AI did not execute the planned 40-unit pass")
stepUntilResolved(far)
check(far.passStats[1].completed==1,"AC-1: original 40-unit pass was not received")
far,passer,receiver=fixture(40)
far.params.ballDrag=4
check(not Passing.plan(far,passer,receiver),"AC-1: unreachable high-drag pass selected")
check(AI.passOption(far,passer)~=receiver,"AC-1: selection ignored reachability")
far.params.ballDrag=0.45
check(Passing.plan(far,passer,receiver),"AC-1: low-drag pass should be possible")

-- A bad contact angle must trigger approach, not an inaccurate kick.
local angle,ap,ar=fixture(30)
ap.x,ap.y=19,32.6
local aimed=Passing.plan(angle,ap,ar)
check(not Passing.canLaunch(angle,ap,aimed),"AC-1: sideways contact accepted")
AI.update(angle)
check(angle.totalKicks==0 and ap.decision=="approach_pass","AC-1: AI ignored launch check")

-- Actual stationary and running AI receivers complete passes using only forces.
for _,velocity in ipairs({{0,0},{0,6},{-4,3}}) do
    local s,p,r=fixture(25)
    r.vx,r.vy=velocity[1],velocity[2]
    launch(s,p,r)
    local bx,by=s.ball.x,s.ball.y
    AI.update(s)
    check(r.decision=="receive" and p.decision=="support","AC-2: missing receive/support roles")
    check(s.ball.x==bx and s.ball.y==by,"AC-2: AI moved ball without physics")
    stepUntilResolved(s)
    check(s.passStats[1].completed==1,"AC-2: AI receiver failed to meet pass")
    check(s.passFeedback.number==r.number,"AC-2: wrong receiver made contact")
    balanced(s)
end

-- The opposite attacking direction uses the same physical reception behavior.
local mirrored,mp,mr=fixture(25)
mp.team,mr.team=2,2
mp.x,mr.x=102.6,75
mirrored.ball.x=100
mirrored.lastTouch=2
launch(mirrored,mp,mr)
stepUntilResolved(mirrored)
check(mirrored.passStats[2].completed==1 and mirrored.passStats[1].attempts==0,
    "AC-2: red team reception or accounting failed")
balanced(mirrored)

-- The human can receive physically, but neither AI input nor role is replaced.
local human,hp=fixture(20)
local hr=human.controlled
hr.x,hr.y=40,35
human.players={hp,hr}
launch(human,hp,hr)
hr.moveX,hr.moveY=0.25,-0.5
AI.update(human)
check(hr.moveX==0.25 and hr.moveY==-0.5,"AC-2: human steering overwritten")
stepUntilResolved(human)
check(human.passStats[1].completed==1 and human.controlled==hr,"AC-2: human reception failed")

-- An opposing physical touch immediately intercepts, even during old touch grace.
local intercepted,ip,ir=fixture(25)
local opponent=Sim.new(nil,5).players[7]
opponent.x,opponent.y=23,35
intercepted.players[#intercepted.players+1]=opponent
launch(intercepted,ip,ir)
intercepted.aiTimer=-1000
stepUntilResolved(intercepted)
check(intercepted.elapsed<0.22,"interception fixture was not immediate")
check(intercepted.passStats[1].intercepted==1 and intercepted.lastTouch==2,
    "AC-2: early interception not resolved")
for _=1,30 do Sim.step(intercepted,dt) end
check(intercepted.passStats[1].intercepted==1,"AC-3: interception counted repeatedly")
balanced(intercepted)

-- Successful one-touch kick also resolves the previous pass, once.
local touch,tp,tr=fixture(12)
launch(touch,tp,tr)
tr.x,tr.y=touch.ball.x+2.5,touch.ball.y
check(Sim.kick(touch,tr,nil,nil,1,"shot"),"one-touch kick failed")
check(touch.passStats[1].completed==1 and not touch.activePass,"AC-3: one-touch reception lost")
balanced(touch)

for _,ending in ipairs({"timeout","out","goal","fulltime"}) do
    local s,p,r,roster=fixture(20)
    s.players=roster
    launch(s,p,r)
    s.aiTimer=-1000
    if ending=="timeout" then s.activePass.expires=s.elapsed+dt/2
    elseif ending=="out" then s.ball.x,s.ball.y=-2,10
    elseif ending=="goal" then s.ball.x,s.ball.y=122,35
    else s.elapsed=s.limit-dt/2 end
    Sim.step(s,dt)
    check(not s.activePass and s.passStats[1].missed==1,"AC-2: stale pass after "..ending)
    check(s.passFeedback.reason==ending,"AC-3: wrong reason for "..ending)
    balanced(s)
end

local paused,pp,pr,roster=fixture(20)
paused.players=roster
launch(paused,pp,pr)
paused.phase="paused"
for _=1,400 do Sim.step(paused,dt) end
check(paused.activePass and paused.passStats[1].missed==0,"pause expired the pass")
Sim.restart(paused)
check(not paused.activePass and not paused.passFeedback and paused.passAttempts==0,
    "AC-3: restart retained pass state")
check(paused.passStats[1].attempts==0 and paused.passStats[2].attempts==0,
    "AC-3: restart retained statistics")
print("PASS: pass flight at 5 distances/4 velocities, drag, angles, moving receivers, human control, outcomes and reset")
