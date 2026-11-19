-- PAUL18 visual-only quality gate (does not replace native screenshot/UAT).
package.path="./?.lua;./?/init.lua;"..package.path
local Theme=require("experiments.foosball.theme")
local Model=require("experiments.foosball.model")
local c=Theme.colors
local function luminance(color)
    return color[1]*0.2126+color[2]*0.7152+color[3]*0.0722
end
for name,rgba in pairs(c) do
    assert(type(rgba)=="table" and #rgba==3,"palette entry "..name.." malformed")
    for _,channel in ipairs(rgba) do
        assert(channel>=0 and channel<=1,"color channel out of range in "..name)
    end
end
assert(luminance(c.cream)-luminance(c.glass)>0.62,
    "glass playfield does not sufficiently separate the ball")
assert(math.abs(luminance(c.human)-luminance(c.away))>0.1,
    "team colors are too similar in perceived brightness")
local calls={add=0,core=0,rectangle=0,circle=0}
local mode="alpha"
local g={}
function g.setBlendMode(x)
    assert(x=="add" or x=="alpha")
    if x=="add" then calls.add=calls.add+1 end
    mode=x
end
function g.setColor(r,gg,b,a)
    assert(r>=0 and gg>=0 and b>=0)
    assert((a or 1)>=0 and (a or 1)<=1)
end
function g.setLineWidth(w) assert(w>0) end
function g.line(...) calls.core=calls.core+1 end
function g.circle(...) calls.circle=calls.circle+1 end
function g.rectangle(...) calls.rectangle=calls.rectangle+1 end
function g.polygon(...) end
Theme.glowEnabled=true
Theme.drawGlassTable(g,1000,560,94)
Theme.glowCircle(g,740,280,10,c.cream)
assert(calls.add>0 and calls.core>5 and calls.rectangle>0 and calls.circle>0)
assert(mode=="alpha","theme left additive blend enabled and broke world rendering")
Theme.glowEnabled=false
calls.add,calls.core=0,0
Theme.drawGlassTable(g,1000,560,94)
Theme.glowCircle(g,740,280,10,c.cream)
assert(calls.add==0,"glow toggle did not disable emissive rendering")
assert(calls.core>5,"disabling glow removed crisp essential field geometry")
assert(mode=="alpha")
Theme.glowEnabled=true
-- Same physical model state before/after visual renderer calls.
local s=Model.new()
local x,y,vx,vy=s.ball.x,s.ball.y,s.ball.vx,s.ball.vy
Theme.drawGlassTable(g,Model.W,Model.H,Model.GOAL_HALF)
assert(s.ball.x==x and s.ball.y==y and s.ball.vx==vx and s.ball.vy==vy,
    "visual-only renderer mutated physics state")
print("PASS: neon palette contrast, additive light isolation, glow-off fallback and no physics mutation")
