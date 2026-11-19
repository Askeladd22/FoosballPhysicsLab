-- Football Physics Lab - Match Lab v0.2
-- Single-player, fixed-step physics, one permanently controlled disc.
local Sim=require("src.sim")
local View=require("src.view")
local STEP=1/120
local accumulator=0
local match
local ui={mode="instant",charging=false,charge=0,debug=false,chooseRole=true}
local pendingKick,pendingCall=nil,false
local beforePause="play"
local function axis(positive,negative)
    return (positive and 1 or 0)-(negative and 1 or 0)
end
function love.load()
    love.window.setTitle("Football Physics Lab - Match Lab 0.2.1")
    love.window.setMode(1280,800,{vsync=1,resizable=true,minwidth=920,minheight=610})
    match=Sim.new()
    View.load()
end
function love.keypressed(key,_,isrepeat)
    if key=="escape" then
        love.event.quit()
        return
    end
    -- Role is chosen before starting a new match. No live player swapping.
    if ui.chooseRole then
        if key=="1" or key=="kp1" then
            match=Sim.new("GK")
            ui.chooseRole=false
            accumulator=0
        elseif key=="2" or key=="kp2" then
            match=Sim.new("RM")
            ui.chooseRole=false
            accumulator=0
        end
        return
    end
    if key=="tab" then
        ui.chooseRole=true
        match=Sim.new()
        accumulator=0
        pendingKick,pendingCall=nil,false
        ui.charging,ui.charge=false,0
    elseif key=="r" then
        Sim.restart(match)
        accumulator=0
        pendingKick,pendingCall=nil,false
        ui.charging,ui.charge=false,0
    elseif key=="p" then
        if match.phase=="paused" then
            match.phase=beforePause
        elseif match.phase~="fulltime" then
            beforePause=match.phase
            match.phase="paused"
        end
    elseif key=="f1" then
        ui.debug=not ui.debug
    elseif key=="c" then
        ui.mode=ui.mode=="instant" and "charge" or "instant"
        ui.charging,ui.charge=false,0
        pendingKick=nil
    elseif key=="n" then
        match.params.maxSpeed=math.max(8,match.params.maxSpeed-0.8)
    elseif key=="m" then
        match.params.maxSpeed=math.min(19,match.params.maxSpeed+0.8)
    elseif key=="j" then
        match.params.ballDrag=math.max(0.45,match.params.ballDrag-0.15)
    elseif key=="k" then
        match.params.ballDrag=math.min(4,match.params.ballDrag+0.15)
    elseif key=="[" then
        match.params.kickSpeed=math.max(15,match.params.kickSpeed-2)
    elseif key=="]" then
        match.params.kickSpeed=math.min(60,match.params.kickSpeed+2)
    elseif key=="e" and not isrepeat then
        pendingCall=true
    elseif key=="space" and not isrepeat then
        if ui.mode=="instant" then
            pendingKick=1
        else
            ui.charging=true
            ui.charge=0
        end
    end
end
function love.keyreleased(key)
    if key=="space" and ui.mode=="charge" and ui.charging then
        pendingKick=0.70+0.60*(ui.charge/0.6)
        ui.charging,ui.charge=false,0
    end
end
function love.update(dt)
    if ui.chooseRole then
        accumulator=0
        return
    end
    dt=math.min(dt,0.05)
    if ui.charging and match.phase=="play" then
        ui.charge=math.min(0.6,ui.charge+dt)
    end
    accumulator=math.min(accumulator+dt,0.1)
    local left=love.keyboard.isDown("a","left")
    local right=love.keyboard.isDown("d","right")
    local up=love.keyboard.isDown("w","up")
    local down=love.keyboard.isDown("s","down")
    local x,y=axis(right,left),axis(down,up)
    if x~=0 and y~=0 then
        x,y=x*0.70710678118,y*0.70710678118
    end
    while accumulator>=STEP do
        Sim.step(match,STEP,{
            x=x,y=y,kick=pendingKick,call=pendingCall
        })
        pendingKick,pendingCall=nil,false
        accumulator=accumulator-STEP
    end
end
function love.draw()
    View.draw(match,ui)
end
