-- Default Foosball Lab window. NEON 11 overrides the window in its love.load.
function love.conf(t)
    t.identity="foosball-lab"
    t.version="11.5"
    t.window.title="Foosball Lab | Neon Glass"
    t.window.width=1280
    t.window.height=850
    t.window.minwidth=900
    t.window.minheight=650
    t.window.resizable=true
end

-- In a noninteractive GPU smoke run, fail instead of leaving a GUI blue
-- error screen open until CI timeout. Regular users retain LÖVE's normal UI.
local testing=false
for _,value in pairs(rawget(_G,"arg") or {}) do
    if value=="--require-3d" then testing=true end
end
if testing then
    function love.errorhandler(message)
        io.stderr:write("NATIVE_LOVE_ERROR: "..tostring(message).."\n"..
            debug.traceback("",2).."\n")
        return function() return 1 end
    end
end
