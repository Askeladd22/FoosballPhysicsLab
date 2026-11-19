-- Football Physics Lab - Match Lab v0.2.3
-- Single-player, fixed-step physics, one permanently controlled disc.
local Sim=require("src.sim")
local View=require("src.view")
local TacticsPanel=require("src.tactics_panel")
local STEP=1/120
local accumulator=0
local match
local ui={mode="context",charging=false,charge=0,debug=false,chooseRole=true}
local tacticsPanel=TacticsPanel.new()
local pendingKick,pendingCall,pendingPass,pendingShot,pendingOneTwo=nil,false,false,false,false
local TAP_TIME,MAX_CHARGE=0.18,0.75
local function clearInput()
    pendingKick,pendingCall,pendingPass,pendingShot,pendingOneTwo=nil,false,false,false,false
    ui.charging,ui.charge=false,0
end
local beforePause="play"
local function axis(positive,negative)
    return (positive and 1 or 0)-(negative and 1 or 0)
end
function love.load()
    love.window.setTitle("Football Physics Lab - NEON 11")
    love.window.setMode(1280,800,{vsync=1,resizable=true,minwidth=920,minheight=610})
    love.window.maximize()
    match=Sim.new()
    View.load()
end
function love.keypressed(key,_,isrepeat)
    if isrepeat and (key=="t" or key=="escape") then return end
    if key=="f11" then
        if not isrepeat then
            clearInput()
            love.window.setFullscreen(not love.window.getFullscreen(),"desktop")
        end
        return
    end
    if ui.tactics then
        if key=="t" or key=="escape" then
            ui.tactics=false;accumulator=0;clearInput()
        else TacticsPanel.keypressed(tacticsPanel,match,key) end
        return
    end
    if key=="t" and not ui.chooseRole and not isrepeat then
        ui.tactics=true;accumulator=0;clearInput();return
    end
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
        clearInput()
    elseif key=="r" then
        Sim.restart(match)
        accumulator=0
        clearInput()
    elseif key=="p" then
        clearInput()
        if match.phase=="paused" then
            match.phase=beforePause
        elseif match.phase~="fulltime" then
            beforePause=match.phase
            match.phase="paused"
        end
    elseif key=="f1" then
        ui.debug=not ui.debug
    elseif key=="f2" and not isrepeat then
        match.autoCoachEnabled=not match.autoCoachEnabled
    elseif key=="n" then
        match.params.maxSpeed=math.max(4.5,match.params.maxSpeed-0.4)
    elseif key=="m" then
        match.params.maxSpeed=math.min(10,match.params.maxSpeed+0.4)
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
    elseif key=="space" and not isrepeat and not ui.charging then
        if match.phase=="play" or (match.phase=="restart" and match.setPiece and
            match.setPiece.taker==match.controlled) then
            ui.charging=true
            ui.charge=0
        end
    end
end
function love.keyreleased(key)
    if ui.tactics then return end
    if key=="space" and ui.charging then
        if ui.charge<TAP_TIME then
            pendingPass=true
            pendingOneTwo=love.keyboard.isDown("q")
        else
            pendingKick=0.75+0.60*math.min(1,(ui.charge-TAP_TIME)/(MAX_CHARGE-TAP_TIME))
            pendingShot=true
        end
        ui.charging,ui.charge=false,0
    end
end
function love.focus(focused)
    if not focused then clearInput() end
end
function love.mousepressed(x,y,button)
    if ui.tactics and TacticsPanel.mousepressed(tacticsPanel,match,x,y,button)=="close" then
        ui.tactics=false;accumulator=0;clearInput()
    end
end
function love.wheelmoved(_,y)
    if ui.tactics then TacticsPanel.wheelmoved(tacticsPanel,match,y) end
end
function love.update(dt)
    if ui.chooseRole or ui.tactics then
        accumulator=0
        return
    end
    dt=math.min(dt,0.05)
    if ui.charging and (match.phase=="play" or
        (match.phase=="restart" and match.setPiece and match.setPiece.taker==match.controlled)) then
        ui.charge=math.min(MAX_CHARGE,ui.charge+dt)
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
            x=x,y=y,kick=pendingKick,call=pendingCall,pass=pendingPass,shot=pendingShot,
            oneTwo=pendingOneTwo,protect=love.keyboard.isDown("lctrl","rctrl"),
            sprint=love.keyboard.isDown("lshift","rshift")
        })
        pendingKick,pendingCall,pendingPass,pendingShot,pendingOneTwo=nil,false,false,false,false
        accumulator=accumulator-STEP
    end
end
function love.draw()
    View.draw(match,ui)
    if ui.tactics then TacticsPanel.draw(tacticsPanel,match) end
end
