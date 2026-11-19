-- Phase 14 gameplay recovery: input agency, scale, buffered failure, tactics A/B.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local dt=1/120
local function ready(role,size)
    local s=Sim.new(role or "RM",size)
    s.phase="play";s.setPiece=nil;s.aiTimer=-1000;s.lastTouch=1
    for _,p in ipairs(s.players) do
        p.x,p.y=p.team==1 and 10 or 100,5
        p.vx,p.vy,p.cooldown=0,0,0
    end
    s.ball.x,s.ball.y=50,34;s.ball.vx,s.ball.vy=0,0
    local h=s.controlled;h.x,h.y=47.4,34
    return s
end
local s=ready()
assert(s.ball.r==0.62 and s.controlled.r==1.10)
assert((s.ball.r/s.field.goalHalf)<0.19,"ball diameter too large versus goal width")
local legacy=ready("RM",5)
assert(legacy.ball.r==0.83 and legacy.controlled.r==1.32)
local right=s.players[5];right.x,right.y=70,34
local up=s.players[3];up.x,up.y=51,22
assert(Sim.pass(s,s.controlled,false,0,-1))
assert(s.activePass and s.activePass.receiver==up,"up aim ignored")
s=ready();s.players[5].x,s.players[5].y=70,34;s.players[3].x,s.players[3].y=51,22
assert(Sim.pass(s,s.controlled,false,1,0))
assert(s.activePass and s.activePass.receiver==s.players[5],"right aim ignored")
s=ready()
assert(Sim.pass(s,s.controlled,false,1,0))
assert(s.activePass and s.activePass.receiver==nil,"unrequested teammate")
assert(s.ball.vx>0 and math.abs(s.ball.vy)<s.ball.vx,"space pass ignored aim")
s=ready();s.controlled.x=43
Sim.step(s,dt,{pass=true,x=1,y=0})
assert(s.pendingHumanPass and s.actionFeedback and s.actionFeedback.message,"failed pass was silent")
s.controlled.x=47.4
Sim.step(s,dt,{})
assert(not s.pendingHumanPass and s.passAttempts==1,"brief pass buffer did not execute")
s=ready();s.controlled.x=40
Sim.step(s,dt,{pass=true,x=1,y=0})
Sim.restart(s)
assert(not s.pendingHumanPass and not s.actionFeedback,"restart leaked pending kick")
local stable=Sim.new("GK")
assert(stable.autoCoachEnabled==false)
stable.phase="play";stable.setPiece=nil;stable.aiTimer=-1000
for _=1,3100 do Sim.step(stable,dt,{}) end
assert(stable.coaches[1].changes==0,"coach modified tactics in stable mode")
print("PASS: recovery radii, player-directed aim, input buffer, stable coach")
