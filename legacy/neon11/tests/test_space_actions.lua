package.path="./?.lua;./?/init.lua;"..package.path
local selected
local keys={}
package.loaded["src.view"]={load=function() end,draw=function(s,ui) selected={s=s,ui=ui} end}
love={window={setTitle=function() end,setMode=function() end,maximize=function() end},
 keyboard={isDown=function(...)
  for _,key in ipairs({...}) do if keys[key] then return true end end
  return false
 end},event={quit=function() end}}
dofile("main.lua")
love.load();love.keypressed("2");love.draw()
local function ready()
 keys={}
 love.keypressed("r");love.draw()
 local s=selected.s
 s.phase="play";s.setPiece=nil;s.aiTimer=-1000
 for _,p in ipairs(s.players) do p.x,p.y=95,60 end
 s.controlled.x,s.controlled.y=47.4,34
 s.players[5].x,s.players[5].y=70,34
 s.ball.x,s.ball.y=50,34
 return s
end
local s=ready()
love.keypressed("space",nil,false)
assert(s.totalKicks==0,"press fired before knowing tap/hold")
love.keyreleased("space");love.update(1/120)
assert(s.passAttempts==1 and s.shotAttempts==0 and s.totalKicks==1)
assert(s.activePass and s.activePass.receiver==s.players[5],"tap did not choose reachable teammate")
love.update(1/30)
assert(s.totalKicks==1,"tap repeated across fixed steps")
s=ready()
love.keypressed("space",nil,false)
for _=1,10 do love.update(0.04) end
assert(s.totalKicks==0 and selected.ui.charge>0.18)
love.keypressed("space",nil,true) -- OS repeat must not reset charge
love.keyreleased("space");love.update(1/120)
assert(s.shotAttempts==1 and s.passAttempts==0 and s.totalKicks==1)
local shortSpeed=math.sqrt(s.ball.vx^2+s.ball.vy^2)
s=ready();love.keypressed("space",nil,false)
for _=1,25 do love.update(0.04) end
assert(selected.ui.charge==0.75)
love.keyreleased("space");love.update(1/120)
assert(s.shotAttempts==1 and math.sqrt(s.ball.vx^2+s.ball.vy^2)>shortSpeed)
s=ready();love.keypressed("space",nil,false);love.update(0.04)
love.keypressed("p");love.keyreleased("space");love.keypressed("p");love.update(1/30)
assert(s.totalKicks==0,"pause leaked pending kick")
love.keypressed("space",nil,false);love.focus(false);love.keyreleased("space");love.update(1/30)
assert(s.totalKicks==0,"lost focus leaked pending kick")
-- Modifier commands are read through the real input callbacks.
for _,ctrl in ipairs({"lctrl","rctrl"}) do
 s=ready();keys={[ctrl]=true,d=true,lshift=true}
 love.update(1/120)
 assert(s.controlled.protectInput and s.controlled.shielding,"Ctrl not wired")
 assert(not s.controlled.sprinting and s.controlled.controlMoveScale<1,"shield allowed sprint")
 keys={};love.update(1/120)
 assert(not s.controlled.shielding and s.controlled.controlMoveScale==1,"Ctrl release kept slow stance")
end
s=ready();keys={q=true}
love.keypressed("space",nil,false);love.keyreleased("space");keys={}
love.update(1/120)
assert(s.combinations[1] and s.combinations[1].runner==s.controlled,"Q+tap not passed to combination")
assert(s.combinations[1].x>s.players[5].x+2,"one-two run cannot get beyond wall player")
love.keypressed("r");love.update(1/120)
assert(not s.combinations[1] and not s.controlled.protectInput,"restart leaked new controls")
-- Human keeper can still take a goal kick with a tap.
love.keypressed("tab");love.keypressed("1");love.draw();s=selected.s
s.phase="play";s.setPiece=nil;s.lastTouch=2;s.ball.x,s.ball.y=-2,10
love.update(1/120)
for _=1,20 do love.update(0.04) end
assert(s.phase=="restart")
love.keypressed("space",nil,false);love.keyreleased("space");love.update(1/120)
assert(s.phase=="play" and s.totalKicks==1)
print("PASS: actual Space tap pass, hold/release shot, charge strength/cap, repeat, pause/focus and goalkeeper restart")
