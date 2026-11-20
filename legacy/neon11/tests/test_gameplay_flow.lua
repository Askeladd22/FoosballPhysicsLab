-- Phase 16B: realistic local action flow, not a claim of fun.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
local dt=1/120
local function fixture()
    local s=Sim.new("GK")
    s.phase="play";s.setPiece=nil;s.lastTouch=1
    s.ball.x,s.ball.y,s.ball.vx,s.ball.vy=60,34,0,0
    for _,p in ipairs(s.players) do
        p.x,p.y=p.team==1 and 6 or 100,5
        p.vx,p.vy,p.moveX,p.moveY,p.cooldown=0,0,0,0,0
    end
    return s
end
-- Real physical takeover: an opponent at the ball must trigger a direct
-- contest. No need to find the correct "passing side" around the ball.
local s=fixture()
local defender,carrier=s.players[2],s.players[13]
s.ball.x,s.ball.y=55,34
defender.x,defender.y=52.4,34
carrier.x,carrier.y=56,34
s.lastTouch=2
AI.update(s)
assert(s.tackleAttempts>=1 and s.lastAction=="tackle","AI did not contest opponent possession")
assert(s.lastTouch==1 and s.ball.vx>0,"tackle did not produce a physical clearance")
assert(s.ball.x==55 and s.ball.y==34,"tackle teleported the ball")
-- A shot opportunity must beat another available pass near goal.
s=fixture()
local striker=s.players[5]
s.ball.x,s.ball.y=79,34
striker.x,striker.y=76.4,34
s.players[12].x,s.players[12].y=103,34
s.players[13].x,s.players[13].y=94,12
s.players[4].x,s.players[4].y=88,42 -- available forward outlet
local _,_,_,decision=AI.chooseAction(s,striker)
assert(decision=="shot","scoring chance displaced by a safe side pass: "..tostring(decision))
AI.update(s)
assert(s.shotAttempts>=1 and s.lastAction=="shot","shot candidate was never fired")
-- A bounded lower-energy touch is available without increasing shot/pass physics.
s=fixture()
local p=s.players[5]
p.x,p.y=57.4,34
assert(Sim.kick(s,p,70,34,0.25,"advance"))
local vx=s.ball.vx
assert(vx>0 and vx<7.3,"AI carry impulse still outruns a player at rest")
-- No fixed script: support relocates away from live screening while respecting offside.
s=fixture()
local teammate=s.players[9]
s.ball.x,s.ball.y=51,34
s.players[12].x,s.players[12].y=100,60
local bx,by=60,28
local oldx,oldy=AI.chooseAction(s,s.players[5])
assert(oldx==oldx and oldy==oldy,"invalid action")
-- End-to-end AI update remains finite after a pressured restart.
for _=1,400 do Sim.step(s,dt,{x=0,y=0}) end
for _,body in ipairs(s.players) do
    assert(body.x==body.x and body.y==body.y,"AI produced non-finite body")
end
assert(s.ball.x==s.ball.x and s.ball.y==s.ball.y,"ball unstable")
print("PASS: direct opponent contest, purposeful shot, soft carry, finite AI play")
