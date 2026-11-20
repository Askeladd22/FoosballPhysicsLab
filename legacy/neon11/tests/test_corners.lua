package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Corners=require("src.corners")
local Passing=require("src.passing")
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end

for _,side in ipairs({"left","right"}) do
    for _,bottom in ipairs({false,true}) do
        local s=Sim.new("GK")
        local human=s.controlled
        local defending=side=="left" and 1 or 2
        s.phase="play";s.setPiece=nil;s.lastTouch=defending
        s.ball.x=side=="left" and -2 or s.field.w+2
        s.ball.y=bottom and s.field.h-2 or 2
        Sim.step(s,1/120)
        local spec=s.setPiece
        assert(spec and spec.kind=="corner")
        -- Calling twice is harmless; also tests the module independently
        -- while the simulation's integration is assembled.
        Corners.prepare(s,spec)
        assert(s.controlled==human,"corner changed controlled identity")
        assert(spec.receiver and spec.receiver.team==spec.team)
        assert(spec.receiver~=spec.taker and spec.receiver.role~="GK")
        local goalX=side=="left" and 0 or s.field.w
        assert(math.abs(spec.receiver.x-goalX)<12,"receiver not attacking the box")
        assert((spec.receiver.y-s.field.h/2)*(bottom and 1 or -1)>0,"no near-post receiver")
        local cover,farRunner=0,false
        for i,p in ipairs(s.players) do
            if p.team==defending then
                assert(distance(p,s.ball)>=9.15+p.r,"opponent encroaches on corner")
                if p.role=="GK" then
                    assert(math.abs(p.x-goalX)<4,"defending GK not set near goal")
                end
            elseif p~=spec.taker and p.role~="GK" and math.abs(p.x-goalX)>35 then
                cover=cover+1
            end
            if p.team==spec.team and p.role=="ST" and p~=spec.receiver and
                math.abs(p.x-goalX)<12 and
                (p.y-s.field.h/2)*(bottom and 1 or -1)<0 then farRunner=true end
            for j=i+1,#s.players do
                local q=s.players[j]
                assert(distance(p,q)>=p.r+q.r+0.1,"corner setup overlaps discs")
            end
        end
        assert(cover>=2,"corner leaves no rest defence")
        assert(farRunner,"corner has no far-post runner")
        local plan=Passing.plan(s,spec.taker,spec.receiver)
        assert(plan and Passing.canLaunch(s,spec.taker,plan),"corner delivery unreachable")
        assert(plan.power>0.68,"corner retained generic underpowered restart")
        -- Integrate the exact physical launch with no steering: it must reach
        -- the attacking target, not stop halfway from the quadrant to the box.
        local vx,vy=Passing.kickVelocity(s,spec.taker,plan.aimX,plan.aimY,plan.power,"pass")
        local factor=Passing.travelFactor(s.params.ballDrag,plan.flightTime)
        local x,y=s.ball.x+vx*factor,s.ball.y+vy*factor
        assert((x-plan.targetX)^2+(y-plan.targetY)^2<0.01,"corner misses physical target")
        s.phaseClock=0
        Sim.step(s,1/120)
        assert(s.phase=="play" and s.totalKicks==1,"corner launch failed")
        assert(s.activePass and s.activePass.receiver==spec.receiver,"corner did not launch toward designated runner")
        assert(not s.offside or not next(s.offside.candidates),"direct corner should be offside-exempt")
        s.aiTimer=-1000
        for _,p in ipairs(s.players) do p.moveX,p.moveY=0,0 end
        for _=1,math.ceil(plan.flightTime*120)+20 do
            Sim.step(s,1/120)
            if not s.activePass then break end
        end
        assert(s.passStats[spec.team].completed==1,
            "ground-plane corner failed to reach an attacking player physically")

        -- A repeated corner uses the far post, rather than resetting the
        -- exact same delivery/clearance loop forever. Both remain reachable.
        s.phase="play";s.lastTouch=defending;s.setPiece=nil
        s.ball.x=side=="left" and -2 or s.field.w+2
        s.ball.y=bottom and s.field.h-2 or 2
        s.ball.vx,s.ball.vy=0,0
        Sim.step(s,1/120)
        local second=s.setPiece
        assert(second.routine=="far_post" and second.receiver~=spec.receiver,
            "repeated corner did not vary its attacking target")
        local secondPlan=Passing.plan(s,second.taker,second.receiver)
        assert(secondPlan and Passing.canLaunch(s,second.taker,secondPlan))
        for i,p in ipairs(s.players) do
            for j=i+1,#s.players do
                assert(distance(p,s.players[j])>=p.r+s.players[j].r+0.1,"far-post setup overlaps")
            end
        end
        s.phaseClock=0;Sim.step(s,1/120);s.aiTimer=-1000
        for _,p in ipairs(s.players) do p.moveX,p.moveY=0,0 end
        for _=1,math.ceil(secondPlan.flightTime*120)+20 do
            Sim.step(s,1/120)
            if not s.activePass then break end
        end
        assert(s.passStats[spec.team].completed==2,"far-post delivery intercepted its own near-post runner")
        s.aiTimer=0.1
        Sim.step(s,1/120)
        for _,p in ipairs(s.players) do
            if p~=s.controlled then
                assert(not p.decision:find("corner_",1,true),"AI remained frozen in corner setup")
            end
        end
    end
end
print("PASS: four corner setups, box runners/marking/cover, clearance, targeted physical delivery")
