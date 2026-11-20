-- Root app: Foosball Lab. The frozen 11vs11 game remains opt-in.
-- Native LÖVE: 'love .' => Foosball; 'love . --legacy' => NEON 11.
-- Historical Lua tests use a minimal love mock; route them to original code.
local function legacyRequested(args)
    if type(args)~="table" then return false end
    for _,value in pairs(args) do
        if value=="--legacy" or value=="--neon11" then return true end
    end
    return false
end
local native=type(love)=="table" and
    (love._version_major~=nil or love._version~=nil)
if legacyRequested(rawget(_G,"arg")) or not native then
    require("legacy.neon11.main")
else
    package.path="experiments/foosball/?.lua;"..package.path
    require("experiments.foosball.main")
end
