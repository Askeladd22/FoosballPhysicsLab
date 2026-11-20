-- Regression: no visually detached player/foot marker when local Table Soccer sprites are active.
package.path="./?.lua;./?/init.lua;"..package.path
local shapes={}
local function noop() end
local g={}
for _,name in ipairs({"setDefaultFilter","setColor","print","line","circle","polygon",
   "setLineWidth","clear","push","pop","translate","scale","shear","setBlendMode"}) do
   g[name]=noop
end
g.rectangle=function(mode,x,y,w,h)
    if mode=="fill" and math.abs(w-20)<0.01 and math.abs(h-28)<0.01 then
        shapes[#shapes+1]={x=x,y=y}
    end
end
g.newFont=function(size) return {getWidth=function(_,text) return #text*size*.5 end} end
g.getDimensions=function() return 1280,850 end
g.setFont=noop
love={
  graphics=g,
  mouse={getRelativeMode=function() return true end,setRelativeMode=noop},
  window={setTitle=noop}
}
local Art=require("mesh_art")
dofile("main.lua")
love.load()
-- User uploaded model is private; simulated drawn rigs are enough to verify
-- that ALL 22 physical feet receive a connected collision-accurate shoe.
Art.drawRod=function() return true end
love.draw()
local Model=require("model")
local state=Model.new()
local count=0
for _,rod in ipairs(state.rods) do
    for i=1,#rod.offsets do
        local x,y=Model.footRect(rod,i)
        local matched=false
        for _,shape in ipairs(shapes) do
            if math.abs(shape.x-x)<0.01 and math.abs(shape.y-y)<0.01 then
                matched=true
                break
            end
        end
        assert(matched,"one Table Soccer modelled figure lacks its physical shoe")
        count=count+1
    end
end
assert(count==22,"incomplete 1-2-5-3 layout")
print("PASS: every Table Soccer sprite has a shoe at its precise physical collider")
