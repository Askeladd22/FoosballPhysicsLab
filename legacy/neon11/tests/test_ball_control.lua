package.path="./?.lua;./?/init.lua;"..package.path
local Control=require("src.ball_control")
local Sim=require("src.sim")
local function fixture()
    local p={x=20,y=20,vx=0,vy=0,moveX=0,moveY=0,r=1,team=1,protectInput=true}
    local b={x=21.5,y=20,vx=8,vy=0,r=0.5}
    return {phase="play",ball=b,controlled=p,players={p}},p,b
end
local function speed(b) return math.sqrt(b.vx*b.vx+b.vy*b.vy) end
local s,p,b=fixture()
local px,py,bx,by=p.x,p.y,b.x,b.y
Control.update(s,p,1/120)
assert(p.shielding and p.controlMoveScale<1)
assert(Control.contact(s,p,-18,0),"incoming ball was not cushioned")
assert(speed(b)<2 and b.vx>0,"ordinary first touch did not absorb the rebound")
assert(p.x==px and p.y==py and b.x==bx and b.y==by,"control teleported a body")
assert(p.moveX==0 and p.moveY==0,"control moved the player automatically")
local once=b.vx
assert(not Control.contact(s,p,-18,0) and b.vx==once,"repeated contact bypassed cooldown")
Control.update(s,p,0.3)
assert(p.controlCooldown==0 and p.controlFlash==0)
p.moveY=1;b.vx,b.vy=8,0
assert(Control.contact(s,p,-18,0) and b.vy>2,"direction did not orient the first touch")

local fast,fp,fb=fixture()
fb.vx=40
local before=fb.vx
assert(Control.contact(fast,fp,-70,0))
assert(before-fb.vx<=14.00001 and fb.vx>20,"fast shot was stopped with unbounded force")

local far,q,ball=fixture()
ball.x=ball.x+0.01
local vx,vy=ball.vx,ball.vy
assert(not Control.contact(far,q,-18,0) and ball.vx==vx and ball.vy==vy,"remote ball attracted")
ball.x=21.5;q.protectInput=false
assert(not Control.contact(far,q,-18,0),"unrequested control")
q.protectInput=true;far.phase="paused"
assert(not Control.contact(far,q,-18,0),"control applied during pause")

local contested,cp,cb=fixture()
contested.players[2]={team=2,x=cb.x+0.8,y=cb.y}
assert(not Control.contact(contested,cp,-18,0),"shield made ball-side challenge impossible")
contested.players[2].x=cp.x-2.5
assert(Control.contact(contested,cp,-18,0),"body between opponent and ball could not shield")
cp.protectInput=false;Control.update(contested,cp,1/120)
assert(not cp.shielding and cp.controlMoveScale==1,"release retained slow/protection stance")

-- Integration: same incoming ball, standard contact vs explicit Ctrl input.
local function approach(protect)
    local match=Sim.new()
    match.phase="play";match.setPiece=nil;match.aiTimer=-1000
    local human=match.controlled
    human.x,human.y=50,34
    for _,other in ipairs(match.players) do
        if other~=human then other.x,other.y=other.number*4,60 end
    end
    match.ball.x,match.ball.y=human.x+human.r+match.ball.r+0.02,34
    match.ball.vx,match.ball.vy=-16,0
    Sim.step(match,1/120,{protect=protect})
    return match,human
end
local normal=approach(false)
local controlled,human=approach(true)
assert((human.controlFlash or 0)>0,"simulation did not invoke first-touch contact")
assert(speed(controlled.ball)<speed(normal.ball),"physical first touch did not reduce rebound speed")
assert(controlled.controlled==human,"first touch changed controlled identity")
-- A real opponent contact still wins the last touch while Ctrl is held.
local challenged=Sim.new()
challenged.phase="play";challenged.setPiece=nil;challenged.aiTimer=-1000
local h,opponent=challenged.controlled,challenged.players[12]
for _,other in ipairs(challenged.players) do other.x,other.y=other.number*4,60 end
h.x,h.y=50,34
challenged.ball.x,challenged.ball.y=h.x+h.r+challenged.ball.r+0.02,34
opponent.x,opponent.y=challenged.ball.x+opponent.r+challenged.ball.r-0.20,34
challenged.ball.vx,challenged.ball.vy=-16,0
Sim.step(challenged,1/120,{protect=true})
assert(challenged.lastTouch==2,"Ctrl prevented a real opposing touch")
assert((h.controlFlash or 0)==0,"shield controlled a ball already contested on its far side")
print("PASS: contact-only first touch, oriented damping, bounded impulse, shield contest, release and real collision")
