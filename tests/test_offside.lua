package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Offside=require("src.offside")
local dt=1/120
local function fixture(team)
    local s=Sim.new()
    s.phase="play";s.setPiece=nil;s.aiTimer=-10000
    local passer,receiver=s.players[2],s.players[4]
    local d1,d2=s.players[12],s.players[13]
    s.testRoster=s.players
    s.players={passer,receiver,d1,d2}
    for _,p in ipairs(s.players) do p.vx,p.vy,p.moveX,p.moveY=0,0,0,0 end
    passer.x,passer.y=57.4,34;receiver.x,receiver.y=90,34
    d1.x,d1.y=100,15;d2.x,d2.y=80,55
    s.ball.x,s.ball.y=60,34
    if team==2 then
        for _,p in ipairs(s.players) do p.team=3-p.team;p.x=s.field.w-p.x end
        s.ball.x=s.field.w-s.ball.x
    end
    return s,passer,receiver,d1,d2
end
local function receive(s,p)
    s.ball.x,s.ball.y=p.x+0.5,p.y
    s.ball.vx,s.ball.vy=0,0
    Sim.step(s,dt)
end
for team=1,2 do
    local s,p,r=fixture(team)
    assert(Sim.kick(s,p,r.x,r.y,0.7,"pass"))
    assert(s.phase=="play" and Offside.involved(s,r),"position alone must not stop play")
    r.x=team==1 and 48 or s.field.w-48 -- return into own half after pass
    local offenceX=r.x
    receive(s,r)
    assert(s.phase=="restart" and s.setPiece.kind=="offside")
    assert(s.setPiece.team==3-team and s.offsideCount[team]==1)
    assert(math.abs(s.ball.x-offenceX)<0.001,"free kick not at involvement point")
    for _=1,100 do Sim.step(s,dt) end
    assert(s.phase=="play" and s.totalKicks==2,"indirect restart not taken")
    -- No direct goal from the indirect free kick.
    s.ball.x=team==1 and -2 or s.field.w+2;s.ball.y=s.field.h/2
    Sim.step(s,dt)
    assert(s.score[1]==0 and s.score[2]==0 and s.setPiece.kind=="goal_kick")

    local legal,q,runner,_,second=fixture(team)
    runner.x=second.x
    assert(not Offside.inPosition(legal,runner),"level with defender is legal")
    assert(Sim.kick(legal,q,runner.x,runner.y,0.7,"pass"))
    runner.x=team==1 and 90 or legal.field.w-90
    receive(legal,runner)
    assert(legal.phase=="play" and legal.offsideCount[team]==0,"onside runner flagged after pass")

    local behind,_,mate=fixture(team)
    mate.x=team==1 and 40 or behind.field.w-40
    assert(not Offside.inPosition(behind,mate),"own half offside")
    mate.x=team==1 and 85 or behind.field.w-85
    behind.ball.x=team==1 and 90 or behind.field.w-90
    assert(not Offside.inPosition(behind,mate),"behind ball offside")
end
for _,kind in ipairs({"throw_in","corner","goal_kick"}) do
    local s,p,r=fixture(1)
    s.phase="restart";s.phaseClock=0
    s.setPiece={kind=kind,team=1,taker=p,targetX=90,targetY=34}
    Sim.step(s,dt)
    assert(not Offside.involved(s,r),"direct restart exemption missing: "..kind)
    receive(s,r)
    assert(s.phase=="play","exempt receiver penalised: "..kind)
end
-- A deflection/save preserves the original phase; a deliberate clearance resets it.
local s,p,r,d=fixture(1)
assert(Sim.kick(s,p,90,34,0.7,"pass"))
receive(s,d)
assert(Offside.involved(s,r),"opponent deflection cancelled offside")
receive(s,r)
assert(s.setPiece.kind=="offside")
local c,cp,cr,def=fixture(1)
assert(Sim.kick(c,cp,90,34,0.7,"pass"))
c.ball.x,c.ball.y=def.x-2.6,def.y
assert(Sim.kick(c,def,50,34,1,"clearance"))
assert(not Offside.involved(c,cr),"deliberate play did not reset phase")
local save,sp,sr,gk=fixture(1)
assert(Sim.kick(save,sp,105,34,1,"shot"))
save.ball.x,save.ball.y,save.ball.vx=97.4,34,20
gk.x,gk.y=100,34
assert(Sim.kick(save,gk,50,34,1,"clearance"))
assert(Offside.involved(save,sr),"deliberate save reset offside")
-- Human kicks are not tagged 'shot'; saves must depend on the trajectory.
local manual,mp,mr,mg=fixture(1)
assert(Sim.kick(manual,mp,105,34,1))
manual.ball.x,manual.ball.y,manual.ball.vx=97.4,34,20
mg.x,mg.y=100,34
assert(Sim.kick(manual,mg,50,34,1,"clearance"))
assert(Offside.involved(manual,mr),"save of manual shot reset offside")
-- Deflections can leave pending candidates for both teams at once.
local dual,dp,blue,redTouch,redRunner=fixture(1)
blue.x,blue.y=55,55
redTouch.x,redTouch.y=70,34;redRunner.x,redRunner.y=40,34
assert(Offside.inPosition(dual,redRunner))
assert(Sim.kick(dual,dp,90,34,0.7,"pass"))
receive(dual,redTouch)
assert(Offside.involved(dual,redRunner),"deflection failed to snapshot deflector's team")
receive(dual,redRunner)
assert(dual.setPiece.kind=="offside" and dual.offsideCount[2]==1)
-- A challenge near the ball counts even before the attacker touches it.
local contest,a,off,op=fixture(1)
assert(Sim.kick(contest,a,90,34,0.7,"pass"))
off.x,off.y=90,34;op.x,op.y=92,34
contest.ball.x,contest.ball.y=93,34;contest.ball.vx,contest.ball.vy=0,0
Sim.step(contest,dt,{x=1})
assert(contest.setPiece and contest.setPiece.kind=="offside","challenge not penalised")
contest.players=contest.testRoster
Sim.restart(contest)
assert(not contest.offside and contest.offsideCount[1]==0)
print("PASS: offside snapshots, both teams, equality/own half/behind ball, involvement, exemptions, deflections, saves and indirect restart")
