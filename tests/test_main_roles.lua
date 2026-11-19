-- End-to-end controller selection exercised through LÖVE callbacks.
package.path="./?.lua;./?/init.lua;"..package.path
local selected
package.loaded["src.view"]={
    load=function() end,
    draw=function(s,ui) selected={match=s,ui=ui} end
}
love={
    window={setTitle=function() end,setMode=function() end},
    keyboard={isDown=function() return false end},
    event={quit=function() end}
}
dofile("main.lua")
love.load()
love.draw()
assert(selected.ui.chooseRole,"prematch selection should be open")
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
print("PASS: actual prematch key inputs, GK/midfielder, role lock and reset")
