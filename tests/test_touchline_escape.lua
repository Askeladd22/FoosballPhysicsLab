-- Players must be able to approach a live ball at the line from outside.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
for _,edge in ipairs({-1,1}) do
    local s=Sim.new("GK")
    s.phase="play"; s.setPiece=nil; s.lastTouch=1
    for i,p in ipairs(s.players) do p.x=15+i*2; p.y=34 end
    local p=s.players[4]
    s.ball.x=75; s.ball.y=edge==-1 and 0.2 or s.field.h-0.2
    p.x=70; p.y=s.ball.y
    AI.update(s)
    assert(s.lastAction~="escape","AI still deliberately aims at an arena wall")
    assert(p.targetY<0 or p.targetY>s.field.h,"AI cannot approach from outside line: "..p.targetY.." "..p.decision)
end
print("PASS: touchline approaches use outside space without rail-escape kicks")
