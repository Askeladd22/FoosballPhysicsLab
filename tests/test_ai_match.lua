-- Football decisions are tested independently from rendering and human input.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local Tactics=require("src.tactics")
local function isolated()
    local s=Sim.new("GK")
    s.phase="play"; s.setPiece=nil; s.lastTouch=1
    for i,p in ipairs(s.players) do
        p.x=8+(i%10)*2; p.y=8+(i%2)*4
        p.vx,p.vy=0,0
    end
    return s
end

-- A keeper at the centre must not veto every shot at the whole goal mouth.
local shot=isolated()
shot.ball.x,shot.ball.y=85,34
local striker=shot.players[5]
striker.x,striker.y=82.4,34
shot.players[12].x,shot.players[12].y=102,34
shot.players[13].x,shot.players[13].y=94,8
AI.update(shot)
assert(shot.lastAction=="shot","central keeper vetoed all shot options")
assert(shot.ball.vx>0 and math.abs(shot.ball.vy)>0.01,"shot did not target an open side")
shot.aiTimer=-1000
for _,p in ipairs(shot.players) do p.moveX,p.moveY,p.vx,p.vy=0,0,0,0 end
for _=1,360 do
    Sim.step(shot,1/120)
    if shot.score[1]>0 or shot.phase~="play" then break end
end
assert(shot.score[1]==1,"physical corner shot missed the opening")

-- Approaching from ahead must route around the ball, not run through it.
local approach=isolated()
approach.ball.x,approach.ball.y=55,34
local runner=approach.players[5]
runner.x,runner.y=59,34
AI.update(approach)
assert(math.abs(runner.targetY-34)>2,"wrong-side approach drives straight through ball")
assert(approach.totalKicks==0,"AI kicked while facing away from target")
assert(approach.ball.x==55 and approach.ball.y==34,"AI teleported ball")
for _=1,360 do Sim.step(approach,1/120) end
assert(approach.totalKicks>0 and math.abs(approach.ball.x-55)>2,
    "wrong-side approach stalled at its waypoint instead of reaching the ball")

-- The ball carrier keeps pursuing a touch into free space instead of
-- immediately retreating to a formation slot after every forward clearance.
local carry=isolated()
carry.ball.x,carry.ball.y=60,34
local carrier=carry.players[5]
carrier.x,carrier.y=57.4,34
AI.update(carry)
assert(carry.lastAction=="advance","open space should allow a progressive touch")
assert(carrier.targetX>carry.ball.x,"carrier abandoned its own progressive touch")
assert(carry.controlled.moveX==0 and carry.controlled.moveY==0,"AI moved human")

-- Forward support runs are prepared behind the offside line; a player who
-- has already received an onside pass remains free to run beyond it.
local Offside=require("src.offside")
for _,team in ipairs({1,2}) do
    local s=Sim.new("GK")
    s.phase="play";s.setPiece=nil;s.lastTouch=team
    s.ball.x,s.ball.y=52.5,34
    for _,p in ipairs(s.players) do
        if p.team~=team then p.x=team==1 and 68 or 37 end
    end
    local targets=Tactics.teamTargets(s,team)
    local line=Offside.line(s,team)
    for _,target in pairs(targets) do
        assert(team==1 and target.x<=line or team==2 and target.x>=line,"support runs offside")
    end
end

print("PASS: goal-mouth shot selection, ball-side approach, continuing progressive touches")
