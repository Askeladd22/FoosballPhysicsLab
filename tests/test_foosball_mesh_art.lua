-- Optional 3D sprite renderer: all-or-nothing loads and safe fallback.
package.path="./?.lua;./?/init.lua;"..package.path
local Art=require("mesh_art")
local fake={images={},draws=0,colors=0,drawn={}}
love={graphics={
  newImage=function(path)
      fake.images[path]=(fake.images[path] or 0)+1
      return {path=path,setFilter=function() end}
  end,
  draw=function(image) fake.draws=fake.draws+1; fake.drawn[#fake.drawn+1]=image.path end,
  setColor=function() fake.colors=fake.colors+1 end
},filesystem={getInfo=function() return nil end}}
assert(not Art.load() and not Art.active(),"missing local renders must be optional")
assert(not Art.drawTable(love.graphics) and not Art.drawRod(love.graphics,{angle=0,x=100,slide=0},1))
local prefix="local_assets/"
love.filesystem.getInfo=function(path)
  if path:sub(1,#prefix)==prefix then return {type="file"} end
end
assert(Art.load() and Art.active(),"local original model images failed to load")
assert(Art.frameCount==9,"old nine-pose pack not detected")
assert(fake.images[prefix.."table.png"]==1,"table backdrop omitted")
assert(fake.images[prefix.."rods/blue_attack_04.png"]==1,"blue figure pose omitted")
assert(fake.images[prefix.."rods/red_goalkeeper_08.png"]==1,"red figure pose omitted")
local rod={x=430,slide=17,angle=0}
assert(Art.drawTable(love.graphics) and Art.drawRod(love.graphics,rod,3))
local draws=fake.draws
assert(draws>0)
rod.angle=0.14
assert(Art.drawRod(love.graphics,rod,3) and fake.draws==draws+1,
    "render should draw exactly ONE crisp model pose, not two ghost images")
assert(not Art.toggle() and not Art.active(),"V should disable mesh overlay")
assert(not Art.drawTable(love.graphics) and not Art.drawRod(love.graphics,rod,3))
assert(Art.toggle() and Art.active(),"V failed to restore original model")
-- Missing frame must never partially switch visuals.
love.filesystem.getInfo=function(path)
    if path:sub(1,#prefix)==prefix and path~=prefix.."rods/blue_goalkeeper_04.png"
    then return {type="file"} end
end
assert(not Art.load() and not Art.active(),"incomplete local pack must fall back safely")
-- Re-baked 25-frame private packs should automatically upgrade smoothness.
love.filesystem.getInfo=function(path)
    if path:sub(1,#prefix)==prefix then return {type="file"} end
end
assert(Art.load() and Art.frameCount==25 and Art.active(),
    "25-pose high-resolution asset pack not selected")
local before=fake.draws
rod.angle=0.12
assert(Art.drawRod(love.graphics,rod,3) and fake.draws==before+1)
assert(fake.images[prefix.."rods/red_goalkeeper_24.png"]==1,
    "high-resolution red rig frame not loaded")
print("PASS: optional mesh sprites, eight rigs, 9 poses, 2.5D toggle and fallback")
