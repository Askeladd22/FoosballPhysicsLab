-- PAUL 19: regression reproduction from screenshot: completely unreachable
-- middle corridor between fixed-X midfield rods (430 and 570).
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("model")
local dt=1/120
local function nearly(a,b) return math.abs(a-b)<1e-7 end
local function dead()
    local s=M.new()
    s.ball.x,s.ball.y,s.ball.vx,s.ball.vy=500,M.H/2,0,0
    return s
end
local s=dead()
assert(not M.isBallReachable(s),"midfield corridor was incorrectly considered playable")
assert(M.isBallReachable((function()
    local v=M.new()
    v.ball.x,v.ball.y=v.rods[3].x+35,M.H/2
    return v
end)()),"midfield serve position must be physically reachable")
-- Initial neutral restart goes to human midfielder, not the same dead zone.
s.score[1],s.score[2]=2,3
for _=1,math.floor((M.DEAD_BALL_SECONDS-0.10)/dt) do s:step(dt) end
assert(s.deadBallCount==0 and s.ball.x==500,"dead ball reset before timeout")
assert(s.deadBallTimer>0,"no countdown while unreachable")
local previousClock=s.clock
for _=1,20 do s:step(dt) end
assert(s.deadBallCount==1,"unreachable ball was never recovered")
assert(s.deadBallLastTeam==1 and s.ball.x==465,"restart does not reach the cyan midfield rod")
assert(s.ball.y==M.H/2 and M.isBallReachable(s),"new serve is still unreachable")
assert(s.score[1]==2 and s.score[2]==3 and s.phase=="play","restart altered score or phase")
assert(s.clock>previousClock and nearly(s.deadBallTimer,0),"restart reset time incorrectly")
assert(s.deadBallNotice and s.deadBallNotice.team==1 and s.deadBallNotice.expires>s.clock)
for _=1,360 do s:step(dt) end
assert(s.deadBallCount==1,"stationary reachable ball triggered repeated re-serves")
-- Opponent gets a playable re-serve after a last human strike.
s=dead()
s.lastHit={team=1,kind="Attacco",clock=0}
for _=1,300 do
    s:step(dt)
    if s.deadBallCount>0 then break end
end
assert(s.deadBallCount==1 and s.deadBallLastTeam==2,"last contact did not award opposite team")
assert(s.ball.x==535 and M.isBallReachable(s),"red midfield serve remains out of contact")
-- Preserve trajectories: a travelling ball cannot be replaced mid-shot.
s=dead()
s.ball.vx=240
for _=1,70 do s:step(dt) end
assert(s.deadBallCount==0,"moving ball was incorrectly re-served")
-- A temporarily stationary but reachable ball is legitimate, not a dead ball.
s=M.new()
s.ball.x,s.ball.y=465,M.H/2
assert(M.isBallReachable(s))
for _=1,360 do s:step(dt) end
assert(s.deadBallCount==0,"reachable ball was removed from play")
-- Regression: movement ALONG the unreachable corridor must not evade
-- recovery just because the ball keeps bouncing vertically between cushions.
s=dead()
s.score[1],s.score[2]=1,2
s.ball.vy=185
for _=1,170 do s:step(dt) end
assert(s.deadBallCount==0 and s.deadBallTimer>1,
    "vertical ricochets incorrectly reset the unreachable-ball countdown")
for _=1,140 do s:step(dt) end
assert(s.deadBallCount==1 and s.ball.x==465,
    "unhittable bouncing ball was never recovered")
assert(s.score[1]==1 and s.score[2]==2 and s.phase=="play",
    "bouncing-ball recovery changed score or match phase")

-- Horizontal escape is genuine only after the ball RE-ENTERS a reachable
-- contact envelope. Its velocity alone must not erase a pending countdown.
s=dead()
for _=1,170 do s:step(dt) end
assert(s.deadBallTimer>1)
s.ball.vx=120
s:step(dt)
assert(s.deadBallTimer>1 and s.deadBallCount==0,
    "velocity alone reset the countdown before the ball became reachable")
local escaped=false
for _=1,100 do
    s:step(dt)
    if M.isBallReachable(s) then
        escaped=true
        assert(s.deadBallTimer==0 and s.deadBallCount==0,
            "horizontal pass kept stale countdown after reaching a playable zone")
        break
    end
end
assert(escaped,"horizontal shot could not escape unreachable corridor")
-- Empty-state reset cannot inherit a pending warning or last-hit metadata.
s=dead()
for _=1,90 do s:step(dt) end
s:reset()
assert(s.deadBallTimer==0 and s.deadBallCount==0 and not s.deadBallNotice)
print("PASS: unreachable corridor, vertical ricochet recovery, horizontal escape, score and no false dead balls")
