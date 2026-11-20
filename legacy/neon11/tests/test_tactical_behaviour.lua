package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Settings=require("src.tactical_settings")
local Tactics=require("src.tactics")
local AI=require("src.ai")
local Combinations=require("src.combinations")
local Marking=require("src.marking")
local function find(s,position,team)
    for _,p in ipairs(s.players) do if p.team==(team or 1) and p.position==position then return p end end
end
local function fixture()
    local s=Sim.new("GK")
    s.phase="play";s.setPiece=nil;s.lastTouch=1;s.elapsed=5
    s.ball.x,s.ball.y,s.ball.vx,s.ball.vy=60,34,0,0
    return s
end
local function role(s,p,id,duty)
    assert(Settings.setRole(s,p,id));if duty then assert(Settings.setDuty(s,p,duty)) end
end
local function team(s,key,value) assert(Settings.setTeamInstruction(s,1,key,value)) end
local function instruction(s,p,key,value) assert(Settings.setPlayerInstruction(s,p,key,value)) end

-- FM24-specific rotations are different tasks, not synonymous inverted names.
local shape=fixture()
local fb,cb,cm,st=find(shape,"DL"),find(shape,"DC"),find(shape,"MC"),find(shape,"ST")
role(shape,fb,"inverted_full_back","defend")
local ifbx,ifby=Tactics.supportPoint(shape,fb)
role(shape,fb,"inverted_wing_back","support")
local iwbx,iwby=Tactics.supportPoint(shape,fb)
assert(iwbx>ifbx+6 and math.abs(iwby-34)<math.abs(ifby-34),"IFB and IWB did not occupy defence/midfield")
role(shape,cb,"libero","support")
local blocked=Tactics.supportPoint(shape,cb)
role(shape,fb,"full_back","support")
local released=Tactics.supportPoint(shape,cb)
assert(released>blocked+6,"same-side IWB did not take midfield priority over Libero")
assert(Settings.setPosition(shape,cm,"DM"));role(shape,cm,"half_back","defend")
assert(Tactics.supportPoint(shape,cm)<=shape.ball.x-16,"half back failed to drop into back line")
role(shape,st,"false_nine","support")
local dropping=Tactics.supportPoint(shape,st)
role(shape,st,"advanced_forward","attack")
assert(Tactics.supportPoint(shape,st)>dropping+12,"false nine did not come short")

-- A selected CM duty supersedes the legacy shirt-number holding rule.
assert(Settings.setPosition(shape,cm,"MC"));role(shape,cm,"central_midfielder","defend")
local defensive=Tactics.supportPoint(shape,cm)
role(shape,cm,"central_midfielder","attack")
local attacking=Tactics.supportPoint(shape,cm)
assert(defensive<=shape.ball.x-9 and attacking>=shape.ball.x+6,"CM duty ignored by shape")
local wide=find(shape,"MR")
team(shape,"width",-1);local _,narrowY=Tactics.supportPoint(shape,wide)
team(shape,"width",1);local _,wideY=Tactics.supportPoint(shape,wide)
assert(math.abs(wideY-34)>math.abs(narrowY-34)+2,"team width had no shape effect")

-- A compact decision fixture keeps two genuine reachable passing choices.
local function choices()
    local s=fixture()
    local p=find(s,"MC");role(s,p,"central_midfielder","support")
    local a,b=find(s,"ML"),find(s,"MR")
    local e1,e2=find(s,"DC",2),find(s,"GK",2)
    s.players={s.controlled,p,a,b,e1,e2}
    for _,v in ipairs(s.players) do v.vx,v.vy=0,0 end
    s.controlled.x,s.controlled.y=5,4
    s.ball.x,s.ball.y=50,34;p.x,p.y=47.4,34
    a.x,a.y=65,20;b.x,b.y=65,48
    e1.x,e1.y=100,4;e2.x,e2.y=100,64
    return s,p,a,b
end
local focus,p,left,right=choices()
team(focus,"focus","left");assert(AI.passOption(focus,p)==left)
team(focus,"focus","right");assert(AI.passOption(focus,p)==right,"focus did not change receiver")
team(focus,"focus","mixed")
left.x,left.y=57,43;right.x,right.y=8,4
instruction(focus,p,"dribbling",1)
AI.chooseAction(focus,p);local dribbleHigh=p.aiScores.advance
instruction(focus,p,"dribbling",-1)
AI.chooseAction(focus,p);assert(p.aiScores.advance<dribbleHigh-0.15,"dribbling instruction had no utility effect")
team(focus,"tempo",-1);AI.chooseAction(focus,p);local slowRelease=p.aiScores.pass
team(focus,"tempo",1);AI.chooseAction(focus,p)
assert(p.aiScores.pass>slowRelease+0.1,"tempo did not change release preference")

local distribution,k,short,long=choices()
k=distribution.controlled;distribution.ball.x,distribution.ball.y=12,34;k.x,k.y=9.4,34
short.x,short.y=25,20;long.x,long.y=44,45
distribution.players[2].x,distribution.players[2].y=5,4
team(distribution,"distribution","short");assert(AI.passOption(distribution,k)==short)
team(distribution,"distribution","long");assert(AI.passOption(distribution,k)==long,"GK distribution did not route to longer receiver")

-- Engagement starts pressure in different zones; tight marking stays local.
local defend=fixture();defend.lastTouch=2;defend.ball.x,defend.ball.y=84,34
for _,v in ipairs(defend.players) do
    if v.team==1 then v.x,v.y=60,8 else v.x,v.y=95,60 end
end
local defender=find(defend,"MC");defender.x,defender.y=73,34
team(defend,"engagement",-1);AI.update(defend)
assert(not defend.pressers[1],"low block pressed beyond its engagement zone")
team(defend,"engagement",1);AI.update(defend)
assert(defend.pressers[1],"high engagement failed to assign a presser")
local marked=fixture();marked.lastTouch=2;marked.ball.x,marked.ball.y=45,34
local marker=find(marked,"DC");local threat=find(marked,"ST",2)
for _,v in ipairs(marked.players) do if v.team==2 then v.x,v.y=100,60 end end
threat.x,threat.y=32,25
local function anchor() return 30,25 end
local loose=Marking.assign(marked,1,{marker},nil,anchor)[marker]
assert(loose)
instruction(marked,marker,"markTighter",true)
local tight=Marking.assign(marked,1,{marker},nil,anchor)[marker]
assert(tight and threat.x-tight.x<threat.x-loose.x,"tighter marking did not close distance")

-- Holding a position prevents unsolicited runs; an attacking task can release.
local runs=fixture();runs.ball.x,runs.ball.y=50,34
local runner=find(runs,"MC");local carrier=find(runs,"ML")
for _,v in ipairs(runs.players) do v.x,v.y=v.team==1 and 8 or 100,8 end
runner.x,runner.y=42,30;carrier.x,carrier.y=47.5,34
for _,v in ipairs(runs.players) do if v.team==1 and v~=runner then instruction(runs,v,"depth","hold") end end
role(runs,runner,"central_midfielder","defend");Combinations.update(runs)
assert(not runs.supportActions[1],"hold duty made an unsolicited forward run")
role(runs,runner,"central_midfielder","attack");Combinations.update(runs)
assert(runs.supportActions[1] and runs.supportActions[1].player==runner,"attack duty failed to enable run")
local human=runs.controlled;human.moveX,human.moveY=0.3,-0.2
local hx,hy=human.x,human.y
AI.update(runs)
assert(human.x==hx and human.y==hy and human.moveX==0.3 and human.moveY==-0.2,"tactical settings drove human input")

-- Directional delivery instructions affect real plans, not just UI profiles.
local delivery,passer,a,b=choices()
a.x,a.y=60,34;b.x,b.y=78,34
team(delivery,"passing",-1);assert(AI.passOption(delivery,passer)==a)
team(delivery,"passing",1);assert(AI.passOption(delivery,passer)==b,"directness did not change delivery distance")
team(delivery,"passing",0)
assert(Settings.setPosition(delivery,a,"ST"));role(delivery,a,"advanced_forward","attack")
a.x,a.y=65,34;b.x,b.y=8,4
local _,_,_,toFeet=AI.passOption(delivery,passer)
team(delivery,"passIntoSpace",true)
local receiver,_,_,toSpace=AI.passOption(delivery,passer)
assert(receiver==a and toSpace.targetX>toFeet.targetX+2.9,"space instruction did not lead runner")
team(delivery,"passIntoSpace",false)
delivery.ball.x,delivery.ball.y=80,12;passer.x,passer.y=77.4,12
a.x,a.y=90,25;b.x,b.y=90,43
instruction(delivery,passer,"crossing",1)
instruction(delivery,passer,"crossAim","near");local near=AI.passOption(delivery,passer)
instruction(delivery,passer,"crossAim","far");local far=AI.passOption(delivery,passer)
assert(near==a and far==b,"grounded cross aim did not choose near/far receiver")
instruction(delivery,passer,"crossFrom","deep");local _,earlyScore=AI.passOption(delivery,passer)
instruction(delivery,passer,"crossFrom","byline");local _,lateScore=AI.passOption(delivery,passer)
assert(earlyScore>lateScore+5,"cross origin had no contextual preference")
delivery.ball.x,delivery.ball.y=85,34;passer.x,passer.y=82.4,34
instruction(delivery,passer,"shooting",-1);AI.chooseAction(delivery,passer);local lowShot=passer.aiScores.shot
instruction(delivery,passer,"shooting",1);AI.chooseAction(delivery,passer)
assert(lowShot and passer.aiScores.shot>lowShot+0.2,"shoot instruction had no effect on available shot")

local direction,dribbler,da,db=choices()
direction.ball.x,direction.ball.y=60,20;dribbler.x,dribbler.y=57.4,20
da.x,da.y=5,4;db.x,db.y=5,64
instruction(direction,dribbler,"dribbling",1)
instruction(direction,dribbler,"carryDirection","inside")
local _,insideY,_,insideAction=AI.chooseAction(direction,dribbler)
instruction(direction,dribbler,"carryDirection","wide")
local _,outsideY,_,outsideAction=AI.chooseAction(direction,dribbler)
assert(insideAction=="advance" and outsideAction=="advance" and insideY>20 and outsideY<20,
    "carry direction failed to choose inside/outside physical corridor")

-- Counterpress/regroup act only in the early transition; trapping changes side.
defend.ball.x,defend.ball.y=84,20;defender.x,defender.y=73,20
team(defend,"engagement",1);team(defend,"trap","inside");AI.update(defend)
local insideApproach=defender.targetY
team(defend,"trap","outside");AI.update(defend)
assert(insideApproach<20 and defender.targetY>20,"pressing trap did not change approach side")
team(defend,"trap","balanced");team(defend,"engagement",0)
team(defend,"transitionLoss","counterpress");AI.update(defend)
assert(defend.pressers[1],"counterpress did not trigger early pressure")
team(defend,"transitionLoss","regroup");AI.update(defend)
assert(not defend.pressers[1],"regroup failed to release pressure into the block")
team(defend,"transitionLoss","counterpress");defend.elapsed=9;AI.update(defend)
assert(not defend.pressers[1],"counterpress transition never expired")
defend.ball.x=100;defender.x=80
team(defend,"preventShortGK",true);AI.update(defend)
assert(defend.pressers[1],"prevent short GK instruction left the keeper unpressed")

local transition=fixture();AI.update(transition)
local outlet=find(transition,"ST");role(transition,outlet,"advanced_forward","attack")
team(transition,"transitionWin","hold");local holdX=Tactics.supportPoint(transition,outlet)
team(transition,"transitionWin","counter");local counterX=Tactics.supportPoint(transition,outlet)
assert(counterX>holdX+8,"recovery instruction did not change forward transition")

-- Duties affect both destinations and on-ball scoring, including Automatic.
local duties,midfielder,ma,mb=choices()
duties.ball.x,duties.ball.y=85,34;midfielder.x,midfielder.y=82.4,34
ma.x,ma.y=95,20;mb.x,mb.y=95,48
role(duties,midfielder,"central_midfielder","defend")
AI.chooseAction(duties,midfielder)
local defendShot,defendCarry=midfielder.aiScores.shot,midfielder.aiScores.advance
role(duties,midfielder,"central_midfielder","support")
AI.chooseAction(duties,midfielder);local supportShot=midfielder.aiScores.shot
role(duties,midfielder,"central_midfielder","attack")
AI.chooseAction(duties,midfielder)
assert(defendShot<supportShot and supportShot<midfielder.aiScores.shot and
    midfielder.aiScores.advance>defendCarry,"duty changed label but not pass/carry/shot evaluation")
role(duties,midfielder,"central_midfielder","automatic")
team(duties,"mentality",-1)
local cautiousX=Tactics.supportPoint(duties,midfielder)
assert(Settings.profile(duties,midfielder).duty=="defend")
AI.chooseAction(duties,midfielder);local cautiousShot=midfielder.aiScores.shot
team(duties,"mentality",1)
assert(Settings.profile(duties,midfielder).duty=="attack")
assert(Tactics.supportPoint(duties,midfielder)>cautiousX+8,"Automatic did not change movement with mentality")
AI.chooseAction(duties,midfielder)
assert(midfielder.aiScores.shot>cautiousShot,"Automatic did not change ball decisions with mentality")
local stopper=fixture();stopper.lastTouch=2
local central=find(stopper,"DC")
role(stopper,central,"central_defender","stopper")
local stopX=Tactics.supportPoint(stopper,central)
role(stopper,central,"central_defender","cover")
assert(stopX>Tactics.supportPoint(stopper,central)+5,"Stopper and Cover held the same defensive depth")

local preferred=find(marked,"MC",2)
assert(Settings.setPosition(marked,preferred,"AMC"));preferred.x,preferred.y=34,26
instruction(marked,marker,"markPosition","AMC")
local chosenMark=Marking.assign(marked,1,{marker},nil,anchor)[marker]
assert(chosenMark and chosenMark.opponent==preferred,"position priority was consumed by earlier unrelated threat")

-- Every provided formation can run the unchanged physical match loop.
for _,formation in ipairs(Settings.formations) do
    local s=Sim.new("GK")
    assert(Settings.setFormation(s,1,formation.id));assert(Settings.setFormation(s,2,formation.id))
    local controlled=s.controlled
    for _=1,600 do Sim.step(s,1/120,{}) end
    assert(s.controlled==controlled and #s.players==22,"formation changed human identity or team size")
    for _,p in ipairs(s.players) do
        assert(p.x==p.x and p.y==p.y and math.abs(p.x)<200 and math.abs(p.y)<150,
            "formation produced invalid physical state")
    end
end
print("PASS: configured role rotations/duties, contextual instructions, physical plans, local marking and five-formation soak")
