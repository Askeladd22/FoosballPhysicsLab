-- Headless LÖVE facade: render and route mouse/keyboard inputs for the standalone lab.
local drawing={}
local mouseCaptured=false
local currentFont
local glowCalls=0
local function noop(...) end
local graphics={}
for _,name in ipairs({"setDefaultFilter","setColor","print","rectangle","line","circle","polygon",
                      "setLineWidth","clear","push","pop","translate","scale"}) do
    graphics[name]=noop
end
function graphics.setBlendMode(mode,alphaMode)
    assert(mode=="alpha" or mode=="add","unsupported blend mode")
    if mode=="add" then glowCalls=glowCalls+1 end
end
function graphics.newFont(size)
    return {size=size,getWidth=function(self,s) return #s*(self.size*0.53) end}
end
function graphics.getDimensions() return 1280,850 end
function graphics.setFont(font) currentFont=font end
function graphics.getFont() return assert(currentFont) end
function graphics.print(s)
    drawing[#drawing+1]=tostring(s)
end
love={
    graphics=graphics,
    window={setTitle=noop},
    mouse={
        getRelativeMode=function() return mouseCaptured end,
        setRelativeMode=function(mode) mouseCaptured=mode end
    }
}
package.path="./experiments/foosball/?.lua;./?.lua;"..package.path
dofile("experiments/foosball/main.lua")
love.load()
love.update(1/60)
love.draw()
assert(#drawing>6,"game never rendered")
assert(glowCalls>0,"glass/neon rendering never used selective additive glow")
local foundTitle=false
for _,s in ipairs(drawing) do if s:find("FOOSBALL LAB",1,true) then foundTitle=true end end
assert(foundTitle,"lab HUD title missing")
local footHint=false
for _,s in ipairs(drawing) do
    if s:find("faccia di tiro",1,true) then footHint=true end
    assert(not s:find("→",1,true) and not s:find("←",1,true),
        "unsupported directional arrow glyph in text")
end
assert(footHint,"new strike-face explanation not visible")
local glassLabel=false
for _,s in ipairs(drawing) do
    if s:find("NEON GLASS",1,true) then glassLabel=true end
end
assert(glassLabel,"new glass-theme HUD label not found")
love.keypressed("g",nil,false)
local before=glowCalls
drawing={}
love.draw()
assert(glowCalls==before,"glow disable still drew additive light")
local glowOff=false
for _,s in ipairs(drawing) do if s:find("glow OFF",1,true) then glowOff=true end end
assert(glowOff,"toggle failed to show glow OFF")
love.keypressed("g",nil,false)
drawing={}
love.draw()
assert(glowCalls>before,"glow did not return on re-enable")
love.mousemoved(0,0,70,-55)
love.keypressed("1",nil,false)
love.keypressed("4",nil,false)
love.wheelmoved(0,-1)
love.mousepressed(0,0,1)
assert(love.mouse.getRelativeMode(),"mouse capture did not engage")
love.mousemoved(0,0,-60,20)
love.update(1/30)
drawing={}
love.draw()
assert(#drawing>6,"render failed after input")
love.keypressed("escape",nil,false)
assert(not love.mouse.getRelativeMode(),"escape did not release mouse")
love.mousepressed(0,0,1)
love.focus(false)
assert(not love.mouse.getRelativeMode(),"focus loss did not unlock mouse")
love.keypressed("r",nil,false)
love.draw()
print("PASS: foosball standalone LÖVE load/update/draw, mouse axes, rod selection and capture release")
