-- Root application dispatch: Foosball native, 11vs11 explicit --legacy and old headless mocks.
package.path="./?.lua;./?/init.lua;"..package.path
local originalLove,originalArg,originalPath=love,arg,package.path
local original={}
for _,name in ipairs({"experiments.foosball.main","legacy.neon11.main"}) do
    original[name]={preload=package.preload[name],loaded=package.loaded[name]}
end
local chosen={}
package.preload["experiments.foosball.main"]=function()
    chosen[#chosen+1]="foosball"
    return true
end
package.preload["legacy.neon11.main"]=function()
    chosen[#chosen+1]="legacy"
    return true
end
local function check(simulatedLove,arguments,expected)
    love,arg=simulatedLove,arguments
    package.loaded["experiments.foosball.main"]=nil
    package.loaded["legacy.neon11.main"]=nil
    dofile("main.lua")
    assert(chosen[#chosen]==expected,"expected "..expected.." launch")
    if expected=="foosball" then
        assert(package.path:find("experiments/foosball/?.lua",1,true),"Foosball module path absent")
    end
end
check({_version_major=11},{[0]="."},"foosball")
check({_version_major=11},{[0]=".",[1]="--legacy"},"legacy")
check({_version="11.5"},{[1]="--neon11"},"legacy")
check({window={}},{},"legacy") -- prior 11vs11 Lua tests use mocked love tables
love,arg,package.path=originalLove,originalArg,originalPath
for name,values in pairs(original) do
    package.preload[name]=values.preload
    package.loaded[name]=values.loaded
end
assert(#chosen==4)
print("PASS: root Foosball default, opt-in legacy 11vs11 and test-mock compatibility")
