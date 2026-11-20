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
local Camera=require("src.camera")
View.load()
local s=Sim.new()
s.limit=300
local id=s.controlled
local function hasText(expected)
    for _,text in ipairs(texts) do if text:find(expected,1,true) then return true end end
    return false
end
for _,resolution in ipairs({{1280,800},{920,610},{1920,1080}}) do
    w,h=resolution[1],resolution[2]
    local scale,ox,oy,_,_,pw,ph=Camera.fit(s.field,w,h)
    assert(math.abs(pw/ph-105/68)<1e-10,"camera distorted field aspect")
    assert(ox-4.2*scale>=0 and ox+pw+4.2*scale<=w,"nets clipped")
    assert(oy-3.5*scale>=0 and oy+ph+3.5*scale<h-52,"thrower apron covered by HUD")
    local previousScale=math.min((w-32)/(105+10),(h-78-84)/(68+6))
    assert(scale>previousScale*1.05,"field did not gain usable screen area")
    for _,phase in ipairs({"kickoff","play","restart","paused","fulltime"}) do
        s.phase=phase
        View.draw(s,{mode="instant",charging=false,charge=0,debug=true})
    end
    s.phase="play"
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
    s.phase="restart"
    s.setPiece={kind="offside",team=2,taker=s.players[12]}
    texts={}
    View.draw(s,{mode="instant",charging=false,charge=0,debug=false})
    assert(hasText("FUORIGIOCO") and hasText("ARANCIO"),"offside restart label missing")
    s.elapsed=0
    texts={}
    View.draw(s,{mode="instant",charging=false,charge=0,debug=false})
    assert(hasText("05:00"),"countdown should begin at five minutes")
    s.elapsed=299.2
    texts={}
    View.draw(s,{mode="instant",charging=false,charge=0,debug=false})
    assert(hasText("00:01"),"countdown must not show zero prematurely")
    assert(s.elapsed==299.2,"rendering mutated the match clock")
    s.elapsed=0
    s.phase="play"
    s.controlled.protectInput=true
    texts={}
    View.draw(s,{mode="context",charging=false,charge=0,debug=false})
    assert(hasText("CTRL controlla/proteggi") and hasText("Q + SPAZIO uno-due"),"new controls missing")
    assert(hasText("CONTROLLO"),"control-ready status missing")
    s.controlled.shielding=true
    texts={}
    View.draw(s,{mode="context",charging=false,charge=0,debug=false})
    assert(hasText("PROTEZIONE"),"shield status missing")
    s.controlled.controlFlash=0.18
    texts={}
    View.draw(s,{mode="context",charging=false,charge=0,debug=false})
    assert(hasText("PRIMO CONTROLLO"),"first-touch feedback missing")
    s.controlled.protectInput,s.controlled.shielding,s.controlled.controlFlash=false,false,0
    s.passFeedback=nil
    s.combinationFeedback={kind="one_two_run",player=s.controlled,expires=s.elapsed+2}
    texts={}
    View.draw(s,{mode="context",charging=false,charge=0,debug=false})
    assert(hasText("Uno-due: attacca lo spazio"),"one-two instruction missing")
    s.combinationFeedback=nil
    texts={}
    View.draw(s,{mode="context",charging=true,charge=0.1,debug=false})
    assert(hasText("SPAZIO passa") and hasText("TIENI SPAZIO tira"),"tap/hold controls missing")
    assert(hasText("PASSAGGIO") and not hasText("C carica"),"old shooting-mode prompt retained")
    texts={}
    View.draw(s,{mode="context",charging=true,charge=0.3,debug=false})
    assert(hasText("TIRO / rilascia SPAZIO"),"hold shooting feedback missing")
end
s.phase="play"
View.draw(s,{mode="context",charging=true,charge=0.75,debug=false})
local keeperMatch=Sim.new("GK")
View.draw(keeperMatch,{mode="instant",charging=false,charge=0,
    debug=false,chooseRole=true})
assert(keeperMatch.controlled.role=="GK","GK renderer changed selected role")
assert(s.controlled==id,"rendering changed controlled player")
assert(counts.ball>=16,"Etrusco ball was not drawn")
assert(counts.circles>=160,"discs or feet failed to render")
assert(counts.field>=16,"field failed to render")
print("PASS: neon 2D renderer, three resolutions, offside label, countdown and role HUD")
