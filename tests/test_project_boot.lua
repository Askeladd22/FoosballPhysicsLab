-- Foosball is now the real root controller; legacy lives in its own tree.
package.path="./?.lua;./?/init.lua;"..package.path
local oldLove,oldArg,oldPath=love,arg,package.path
local oldPreload=package.preload["legacy.neon11.main"]
local oldLoaded=package.loaded["legacy.neon11.main"]
love={graphics={}}
arg={[0]="."}
dofile("main.lua")
assert(type(love.load)=="function" and type(love.draw)=="function"
    and type(love.mousemoved)=="function","Foosball isn't the root game")
local normalLoad=love.load
-- Legacy opt-in must happen BEFORE Foosball callbacks are reinstalled.
local legacyCalls=0
package.preload["legacy.neon11.main"]=function()
    legacyCalls=legacyCalls+1
    return true
end
package.loaded["legacy.neon11.main"]=nil
love={graphics={}}
arg={[0]=".",[1]="--legacy"}
dofile("main.lua")
assert(legacyCalls==1 and love.load==nil,"--legacy was not routed before Foosball")
love={graphics={}}
arg={[0]=".",[1]="--neon11"}
package.loaded["legacy.neon11.main"]=nil
dofile("main.lua")
assert(legacyCalls==2,"--neon11 shortcut was not routed")
package.preload["legacy.neon11.main"]=oldPreload
package.loaded["legacy.neon11.main"]=oldLoaded
love,arg,package.path=oldLove,oldArg,oldPath
assert(normalLoad~=nil)
print("PASS: actual Foosball root controller and explicit frozen legacy routes")
