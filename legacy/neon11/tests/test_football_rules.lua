-- Goal-line rules remain; touchlines are experimental rails without throw-ins.
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
    s.ball.x=side=="left" and -2 or s.field.w+2
    s.ball.y=8
    Sim.step(s,dt)
    return s
end
for _,side in ipairs({"left","right"}) do
    for team=1,2 do
        local s=restart(side,team)
        local spec=assert(s.setPiece)
        local defender=side=="left" and 1 or 2
        local expected=team==defender and "corner" or "goal_kick"
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
    end
end
for _,side in ipairs({"top","bottom"}) do
    local s=ready();s.lastTouch=2;s.ball.x=s.field.w/2
    s.ball.y=side=="top" and -2 or s.field.h+2
    s.ball.vy=side=="top" and -15 or 15
    Sim.step(s,dt)
    assert(s.phase=="play" and not s.setPiece and s.restartCount==0)
    assert(s.ball.y>=s.ball.r and s.ball.y<=s.field.h-s.ball.r)
end
local touch=ready();touch.lastTouch=1;touch.lastKickTime=0
local p=touch.players[12]
p.x,p.y=50,10
touch.ball.x,touch.ball.y=50+p.r+touch.ball.r-0.01,10
touch.ball.vx,touch.ball.vy=-0.2,0
Sim.step(touch,dt)
assert(touch.lastTouch==2,"soft deflection ignored")
touch.ball.x,touch.ball.y=-2,8
Sim.step(touch,dt)
assert(touch.setPiece and touch.setPiece.team==1,"endline awarded using stale touch")
local goal=ready()
goal.ball.x=goal.field.w+goal.ball.r+1
goal.ball.y=goal.field.h/2
Sim.step(goal,dt)
assert(goal.score[1]==1 and goal.phase=="kickoff")
print("PASS: 11v11 arena rails, corners, goal kicks, soft touches, goals")
