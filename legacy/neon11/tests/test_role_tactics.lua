package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Tactics=require("src.tactics")
local AI=require("src.ai")
local function player(s,team,number)
    for _,p in ipairs(s.players) do if p.team==team and p.number==number then return p end end
end
for team=1,2 do
    local s=Sim.new("RM")
    s.phase="play";s.setPiece=nil;s.lastTouch=team
    local attack=team==1 and 1 or -1
    local function world(x) return team==1 and x or 105-x end
    s.ball.x,s.ball.y=world(52),34
    s.controlled.x,s.controlled.y=world(10),60
    local holding,forward=player(s,team,6),player(s,team,7)
    local hx=Tactics.supportPoint(s,holding)
    local fx=Tactics.supportPoint(s,forward)
    assert((s.ball.x-hx)*attack>=9 and (fx-s.ball.x)*attack>=6,"midfield lacks depth stagger")
    -- An occupied outlet must move sideways/backwards, not erase the holder.
    s.controlled.x,s.controlled.y=world(34),23
    hx=Tactics.supportPoint(s,holding)
    assert((s.ball.x-hx)*attack>=9,"human avoidance moved holder ahead of ball")
    local crowded=Tactics.teamTargets(s,team)
    assert((s.ball.x-crowded[holding].x)*attack>=9,"spacing erased holding duty")
    s.controlled.x,s.controlled.y=world(10),60
    s.supportActions[team]={player=holding,x=world(70),y=22,expires=4}
    local targets=Tactics.teamTargets(s,team)
    assert((s.ball.x-targets[forward].x)*attack>=8.9,"second CM did not cover runner")
    s.supportActions={}
    local near,far
    for _,p in ipairs(s.players) do
        if p.team==team and p.role=="FB" then
            if p.homeY<34 then near=p else far=p end
        end
    end
    s.ball.y=14
    local nx=Tactics.supportPoint(s,near)
    local fbx,fby=Tactics.supportPoint(s,far)
    assert((nx-fbx)*attack>=6.9,"both fullbacks advanced equally")
    assert(math.abs(fby-34)<math.abs(far.homeY-34),"far fullback failed to narrow")

    -- Defending: two separate threats, a carrier handled by the presser,
    -- and a covering defender. Mirror the same situation for either team.
    s.lastTouch=3-team;s.ball.x,s.ball.y=world(45),34
    for _,p in ipairs(s.players) do
        p.x,p.y=p.homeX,p.homeY
        if p.team~=team then p.x,p.y=world(96),34 end
    end
    s.controlled.x,s.controlled.y=world(10),60
    local threatA,threatB=player(s,3-team,9),player(s,3-team,11)
    threatA.x,threatA.y=world(32),20
    threatB.x,threatB.y=world(34),48
    local carrier=player(s,3-team,7)
    carrier.x,carrier.y=s.ball.x,s.ball.y
    s.pressers[team]=forward
    targets=Tactics.teamTargets(s,team)
    local marked,cover,markerA={},false
    assert(not targets[s.controlled] and not targets[forward],"assigned human or presser")
    for p,t in pairs(targets) do
        if t.cover then cover=true;assert(not t.mark,"last cover abandoned its duty") end
        if t.mark then
            assert(not marked[t.mark],"two players marked same threat")
            marked[t.mark]=p
            assert(t.mark~=carrier,"duplicated pressure on carrier")
            assert((t.mark.x-t.x)*attack>=2.49,"marker is not goal-side")
            assert(math.abs(t.y-t.mark.y)<7,"marker left passing threat untracked")
            if t.mark==threatA then markerA=p end
        end
    end
    assert(cover and marked[threatA] and marked[threatB],"threat or cover missing")
    local oldX,oldY=markerA.x,markerA.y
    local mx,my=s.controlled.moveX,s.controlled.moveY
    AI.update(s)
    assert(markerA.decision=="mark_zone","AI ignored zonal assignment")
    assert(markerA.x==oldX and markerA.y==oldY,"marking teleported a player")
    assert(s.controlled.moveX==mx and s.controlled.moveY==my,"marking drove human input")
    threatA.x,threatA.y=world(85),5
    for _,t in pairs(Tactics.teamTargets(s,team)) do assert(t.mark~=threatA,"marker followed threat out of zone") end
    s.lastTouch=team
    for _,t in pairs(Tactics.teamTargets(s,team)) do assert(not t.mark,"mark survived possession recovery") end
end
print("PASS: mirrored midfield duties, overlap balance, unique zonal marking, cover, zone release and human control")
