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
