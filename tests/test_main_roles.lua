-- End-to-end controller selection exercised through LÖVE callbacks.
package.path="./?.lua;./?/init.lua;"..package.path
local selected
local keys={}
local fullscreen,maximized=false,false
package.loaded["src.view"]={
    load=function() end,
    draw=function(s,ui) selected={match=s,ui=ui} end
}
love={
    window={setTitle=function() end,setMode=function() end,
        maximize=function() maximized=true end,
        getFullscreen=function() return fullscreen end,
        setFullscreen=function(value,kind) assert(kind=="desktop");fullscreen=value end},
    keyboard={isDown=function(...)
        for _,key in ipairs({...}) do if keys[key] then return true end end
        return false
    end},
    event={quit=function() end}
}
dofile("main.lua")
love.load()
love.draw()
assert(selected.ui.chooseRole,"prematch selection should be open")
assert(maximized,"game should open using available desktop space")
local initial=selected.match
love.keypressed("f11",nil,false);love.draw()
assert(fullscreen and selected.match==initial and selected.ui.chooseRole,"fullscreen altered prematch")
love.keypressed("f11",nil,true)
assert(fullscreen,"key repeat toggled fullscreen")
love.keypressed("1",nil,false)
love.draw()
local goalkeeper=selected.match.controlled
assert(goalkeeper and goalkeeper.role=="GK","prematch 1 should select GK")
assert(goalkeeper.number==1,"GK is blue #1")
assert(not selected.ui.chooseRole,"selection should close")
love.keypressed("r",nil,false)
love.draw()
assert(selected.match.controlled==goalkeeper,"R changed selected goalkeeper")
love.keypressed("tab",nil,false)
love.draw()
assert(selected.ui.chooseRole,"TAB should open new match role selection")
love.keypressed("2",nil,false)
love.draw()
assert(selected.match.controlled.role=="RM" and
       selected.match.controlled.number==10,"prematch 2 should select midfielder")
love.update(1/30)
love.draw()
assert(not selected.ui.chooseRole,"role changed during gameplay")
assert(#selected.match.players==22,"UI did not start eleven-a-side")
local playing=selected.match
love.keypressed("f11",nil,false);love.draw()
assert(not fullscreen and selected.match==playing,"leaving fullscreen reset match")
selected.match.phase="play";selected.match.setPiece=nil
for _,shift in ipairs({"lshift","rshift"}) do
    keys={d=true,[shift]=true}
    love.update(1/120)
    assert(selected.match.controlled.sprinting,"Shift not wired to simulation: "..shift)
    keys={d=true}
    love.update(1/120)
    assert(not selected.match.controlled.sprinting,"released Shift still active")
end
print("PASS: actual prematch key inputs, GK/midfielder, role lock and reset")
