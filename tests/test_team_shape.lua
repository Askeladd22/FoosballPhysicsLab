package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Tactics=require("src.tactics")
local AI=require("src.ai")
local function d(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
for _,team in ipairs({1,2}) do
    for _,ballY in ipairs({2,35,68}) do
        local s=Sim.new("GK")
        s.phase="play"; s.setPiece=nil; s.lastTouch=team
        s.ball.x,s.ball.y=60,ballY
        local defender=s.players[team==1 and 2 or 7]
        s.pressers[team]=defender -- defender vacates the back line to press
        local targets=Tactics.teamTargets(s,team)
        local guard=false
        assert(not targets[s.controlled],"human received an AI target")
        assert(not targets[defender],"presser was reassigned to support")
        for p,target in pairs(targets) do
            assert(target.x>=4 and target.x<=116 and target.y>=7 and target.y<=63)
            if target.cover then
                guard=true
                assert((team==1 and target.x<=44) or (team==2 and target.x>=76),
                    "no covering player behind the press")
            end
            for other,t in pairs(targets) do
                if other~=p and p.role~="GK" and other.role~="GK" then
                    assert(d(target,t)>=7.99,"AI outlets overlap near touchline")
                end
            end
            local again=Tactics.teamTargets(s,team)[p]
            assert(again.x==target.x and again.y==target.y,"non-deterministic assignment")
        end
        assert(guard,"missing replacement cover")
    end
end
local s=Sim.new("GK")
s.phase="play"; s.setPiece=nil; s.lastTouch=1
local receiver=s.players[3]
s.activePass={team=1,receiver=receiver,targetX=53,targetY=20,expires=2}
local targets=Tactics.teamTargets(s,1)
assert(not targets[receiver],"receiving player assigned a support outlet")
for p,t in pairs(targets) do
    if p.role~="GK" then
        assert(d(t,{x=53,y=20})>=7.99,"teammate occupies reception point")
    end
end
s.controlled.moveX,s.controlled.moveY=0.3,-0.2
AI.update(s)
assert(receiver.decision=="receive","receiving intent lost")
assert(s.controlled.moveX==0.3 and s.controlled.moveY==-0.2,"human input overwritten")
print("PASS: shared outlets, replacement cover, touchline spacing, receiver priority, human control")
