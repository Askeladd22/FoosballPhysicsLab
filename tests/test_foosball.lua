-- Pure-Lua checks for the independent foosball control/physics experiment.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("experiments.foosball.model")
local dt=1/120
local function nearly(x,y) return math.abs(x-y)<1e-7 end
local s=M.new()
assert(#s.rods==8 and s.selected==4)
for i,n in ipairs({1,2,5,3,1,2,5,3}) do
    assert(#s.rods[i].offsets==n,"wrong rod population")
end

-- AC-1: orthogonal mouse axes, only currently selected rod changed.
local r=s.rods[4]
local oldAngle=r.targetAngle
s:mouseMoved(0,45)
assert(r.targetSlide>0 and nearly(r.targetAngle,oldAngle),"vertical mouse rotated rod")
local oldSlide=r.targetSlide
s:mouseMoved(50,0)
assert(r.targetAngle>oldAngle and nearly(r.targetSlide,oldSlide),"horizontal mouse translated rod")
assert(nearly(s.rods[3].targetSlide,0) and nearly(s.rods[3].targetAngle,-0.7),"unselected rod moved")
assert(s:selectRod(2) and s.selected==2 and not s:selectRod(5))
s:mouseMoved(-50,-30)
assert(s.rods[2].targetAngle<-.7 and s.rods[2].targetSlide<0)
assert(nearly(r.targetSlide,oldSlide),"selection changed a different rod")
for _=1,20 do s:mouseMoved(140,140) end
assert(s.rods[2].targetAngle<=1.15 and s.rods[2].targetSlide<=s.rods[2].travel,"bounds exceeded")

-- AC-2: targets do not teleport to position; finite angular and linear velocity.
s=M.new()
r=s.rods[s.selected]
s:mouseMoved(55,40)
assert(r.angle~=r.targetAngle and r.slide~=r.targetSlide)
s:step(dt)
assert(r.angle>-0.7 and r.angle<r.targetAngle)
assert(r.slide>0 and r.slide<r.targetSlide)
for _=1,120 do s:step(dt) end
assert(math.abs(r.slide)<=r.travel and r.angle<=1.15,"unstable spring")

-- AC-2: a forward mouse stroke produces a PHYSICAL impact and forward travel.
s=M.new()
r=s.rods[4]
for i=5,8 do s.rods[i].x=1500 end -- remove AI interference in the contact lab.
s.aiClock=-100000
s.ball.x,s.ball.y=r.x+38,M.H/2
s.ball.vx,s.ball.vy=0,0
local startX=s.ball.x
s:mouseMoved(115,0)
local maxVelocity=0
for _=1,65 do
    s:step(dt)
    maxVelocity=math.max(maxVelocity,s.ball.vx)
end
assert(s.hits>=1 and maxVelocity>35,"mouse rotation never struck the physical ball")
assert(s.ball.x>startX,"forward swipe did not move ball forward")

-- AC-3: rails and goal mouth remain separate.
s=M.new()
s.ball.x,s.ball.y=500,4;s.ball.vy=-200
s:step(dt)
assert(s.ball.y>=s.ball.r and s.ball.vy>0,"upper wall did not rebound")
s=M.new()
s.ball.x,s.ball.y=M.W+s.ball.r+4,M.H/2
s:step(dt)
assert(s.score[1]==1 and s.phase=="goal","right goal not recorded")
s=M.new()
s.ball.x,s.ball.y=-s.ball.r-4,M.H/2
s:step(dt)
assert(s.score[2]==1,"left goal not recorded")
s=M.new()
s.ball.x,s.ball.y=-5,15;s.ball.vx=-200
s:step(dt)
assert(s.score[2]==0 and s.ball.vx>0,"closed sidewall was treated as a goal")
s=M.new()
for i=1,5 do
    s:goal(1)
    if i<5 then s:serve() end
end
assert(s.phase=="finished" and s.score[1]==5,"five goals did not end match")

-- AC-4: opponent rod moves with finite acceleration, not instantaneous teleport.
s=M.new()
s.ball.x,s.ball.y=650,105
for _=1,14 do s:step(dt) end
r=s.rods[5]
assert(r.targetSlide<0,"opponent keeper failed to track ball")
assert(r.slide<0 and r.slide>r.targetSlide-0.01,"AI rod teleported beyond target")

-- AC-5: identical mouse streams imply identical 120Hz simulation histories.
local function replay()
    local game=M.new()
    for i=1,180 do
        if i==75 then game:selectRod(3) end
        if i%11==0 then game:mouseMoved(i%5-2,i%7-3) end
        game:step(dt)
    end
    return {game.ball.x,game.ball.y,game.ball.vx,game.ball.vy,
        game.rods[3].slide,game.rods[4].angle,game.hits,game.score[1],game.score[2]}
end
local a,b=replay(),replay()
for i=1,#a do assert(nearly(a[i],b[i]),"nondeterministic play at index "..i) end
print("PASS: foosball mouse input axes, controlled rods, angular ball impulse, walls, goals, AI, determinism")

-- Mechanical travel reaches a cushion/guide stop, not an invisible clamp.
local stop=M.new()
local sr=stop.rods[4]
stop:mouseMoved(0,2000)
for _=1,270 do stop:step(dt) end
assert(sr.stopCount>=1 and sr.stopSide==1,"rod never contacts lower mechanical bumper")
assert(nearly(sr.slide,sr.travel) and nearly(sr.vy,0),"end-stop did not arrest slide")
local oldStops=sr.stopCount
for _=1,50 do stop:step(dt) end
assert(sr.stopCount==oldStops,"holding at bumper repeats collision every tick")
stop:mouseMoved(0,-2000)
for _=1,270 do stop:step(dt) end
assert(sr.stopSide==-1 and sr.stopCount==oldStops+1,"upper cushion end-stop missing")
-- The front striking face is flat and bounds the real collision volume.
local shape=M.new()
local foot=shape.rods[4]
local fx,fy=M.foot(foot,2)
local rx,ry,w,h=M.footRect(foot,2)
assert(nearly(fx,rx+w/2) and nearly(fy,ry+h/2),"visual collision does not match foot")
assert(w>0 and h>0 and h>w,"shoe must read as a flat vertical striking surface")
-- Deterministic normal impact at the actual front rectangle, no round-contact shortcut.
shape.ball.x,shape.ball.y=rx+w+shape.ball.r-0.5,fy
shape.ball.vx,shape.ball.vy=-240,0
shape:step(dt)
assert(shape.ball.vx>0 and shape.hits>0,"flat forward face cannot reflect incoming ball")
print("PASS: mechanical rod bumpers, flat visible foot collision")
