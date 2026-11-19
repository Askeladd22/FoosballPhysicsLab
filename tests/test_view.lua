-- Mocked 2D renderer smoke test. Not a substitute for visual LÖVE playtesting.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local w,h=1280,800
local counts={field=0,circles=0,ball=0,feet=0,nets=0}
local activeFont
local texts={}
local font={
    getWidth=function(_,text) return #tostring(text)*7 end,
    getHeight=function() return 13 end
}
local img={
    setFilter=function() end,
    getWidth=function() return 64 end,
    getHeight=function() return 64 end
}
local function noop() end
love={graphics={
    newFont=function() return font end,
    newImage=function() return img end,
    getDimensions=function() return w,h end,
    setFont=function(f) activeFont=f end,
    getFont=function() return activeFont or font end,
    clear=noop,setColor=noop,setLineWidth=noop,
    push=noop,pop=noop,scale=noop,translate=noop,
    rectangle=function() counts.field=counts.field+1 end,
    circle=function() counts.circles=counts.circles+1 end,
    ellipse=function() counts.nets=counts.nets+1 end,
    polygon=noop,line=noop,
    print=function(text,x,y)
        texts[#texts+1]=tostring(text)
        -- Check horizontal text bounds with the deliberately conservative mock font.
        assert(x>=0 and x+font:getWidth(text)<=w,"HUD text exceeds viewport: "..text)
    end,
    draw=function() counts.ball=counts.ball+1 end
}}
local View=require("src.view")
View.load()
local s=Sim.new()
local id=s.controlled
local function hasText(expected)
    for _,text in ipairs(texts) do if text:find(expected,1,true) then return true end end
    return false
end
for _,resolution in ipairs({{1280,800},{920,610},{1920,1080}}) do
    w,h=resolution[1],resolution[2]
    for _,phase in ipairs({"kickoff","play","restart","paused","fulltime"}) do
        s.phase=phase
        View.draw(s,{mode="instant",charging=false,charge=0,debug=true})
    end
    s.passStats[1]={attempts=123,completed=100,intercepted=20,missed=3}
    s.passStats[2]={attempts=100,completed=90,intercepted=8,missed=2}
    s.activePass={team=1,receiver=s.controlled,targetX=55,targetY=35}
    texts={}
    View.draw(s,{mode="instant",charging=false,charge=0,debug=false})
    assert(hasText("Ricevuti: 100/123") and hasText("Ricevuti: 90/100"),"team denominators missing")
    assert(hasText("Passaggio per te"),"human reception feedback missing")
    s.activePass=nil
    s.requestTimer=1
    texts={}
    View.draw(s,{mode="instant",charging=false,charge=0,debug=false})
    assert(hasText("Richiesta inviata"),"call feedback missing")
    s.requestTimer=0
    for _,result in ipairs({"completed","intercepted","missed"}) do
        s.passFeedback={team=2,result=result,number=10,at=s.elapsed}
        View.draw(s,{mode="instant",charging=false,charge=0,debug=false})
    end
end
s.phase="play"
View.draw(s,{mode="charge",charging=true,charge=0.3,debug=false})
local keeperMatch=Sim.new("GK")
View.draw(keeperMatch,{mode="instant",charging=false,charge=0,
    debug=false,chooseRole=true})
assert(keeperMatch.controlled.role=="GK","GK renderer changed selected role")
assert(s.controlled==id,"rendering changed controlled player")
assert(counts.ball>=16,"Etrusco ball was not drawn")
assert(counts.circles>=160,"discs or feet failed to render")
assert(counts.field>=16,"field failed to render")
print("PASS: classic 2D renderer, prematch role selection and GK HUD")
