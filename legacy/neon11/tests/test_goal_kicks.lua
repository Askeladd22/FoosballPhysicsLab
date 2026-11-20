package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
for _,side in ipairs({"left","right"}) do
    local defender=side=="left" and 1 or 2
    for _,role in ipairs({"GK","RM"}) do
        local s=Sim.new(role,5)
        s.phase="play"; s.setPiece=nil; s.lastTouch=3-defender
        s.ball.x=side=="left" and -2 or 122; s.ball.y=10
        Sim.step(s,1/120)
        local spec=s.setPiece
        assert(spec.kind=="goal_kick" and spec.team==defender)
        assert(spec.taker.role=="GK" and spec.taker.team==defender)
        assert(math.abs(s.ball.y-35)<=7.8,"ball outside goal area")
        for _,p in ipairs(s.players) do
            if p.team~=defender then assert(side=="left" and p.x>=19 or side=="right" and p.x<=101) end
        end
        for _=1,100 do Sim.step(s,1/120) end
        if spec.taker==s.controlled then
            assert(s.phase=="restart" and s.totalKicks==0,"human keeper was auto-kicked")
            Sim.step(s,1/120,{kick=1})
        end
        assert(s.phase=="play" and s.totalKicks==1,"goal kick not taken exactly once")
        assert(side=="left" and s.ball.vx>0 or side=="right" and s.ball.vx<0)
        assert(s.controlled.role==role)
    end
    local s=Sim.new(nil,5); s.phase="play"; s.setPiece=nil; s.lastTouch=defender
    s.ball.x=side=="left" and -2 or 122; s.ball.y=10
    Sim.step(s,1/120)
    assert(s.setPiece.kind=="corner" and s.setPiece.team==3-defender,
        "defender touch incorrectly awarded goal kick")
end
print("PASS: goal kicks, keeper selection, opponent clearance, manual GK and mirrored exits")
