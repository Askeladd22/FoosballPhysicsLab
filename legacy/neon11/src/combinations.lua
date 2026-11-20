-- Intentions, not possession: all deliveries still use Passing + Sim.kick.
local Passing=require("src.passing")
local Offside=require("src.offside")
local Space=require("src.space")
local Settings=require("src.tactical_settings")
local Combinations={}
local sqrt,min,max,abs=math.sqrt,math.min,math.max,math.abs
local function clamp(x,a,b) return max(a,min(b,x)) end
local function distance(a,b)
    return sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
local function init(s)
    s.combinations=s.combinations or {}
    s.supportActions=s.supportActions or {}
    s.runTriggers=s.runTriggers or {}
    s.combinationCooldown=s.combinationCooldown or {}
end
function Combinations.reset(s)
    s.combinations={};s.supportActions={};s.runTriggers={}
    s.combinationCooldown={};s.combinationFeedback=nil
end
local function onside(s,team,x)
    local line=Offside.line(s,team)
    return team==1 and min(x,line-0.8) or max(x,line+0.8)
end
local function feedback(s,kind,p,x,y)
    s.combinationFeedback={kind=kind,player=p,targetX=x,targetY=y,expires=s.elapsed+2.5}
end
function Combinations.onKick(s,p,action,plan)
    init(s)
    s.combinations[3-p.team]=nil
    s.supportActions[3-p.team]=nil
    local combo=s.combinations[p.team]
    if combo and p==combo.wall and action=="pass" and plan and plan.receiver==combo.runner then
        combo.stage="returning";combo.expires=s.elapsed+(plan.flightTime or 1.2)+1.2
        feedback(s,"one_two_return",combo.runner,plan.targetX,plan.targetY)
        return
    end
    if combo then s.combinations[p.team]=nil end
    if s.setPiece or action~="pass" or not plan or not plan.receiver or plan.combinationReturn then return end
    local mate=plan.receiver
    local attack=p.team==1 and 1 or -1
    local d=distance(p,mate)
    local forward=(mate.x-p.x)*attack
    local requested=plan.oneTwo==true
    local profile=Settings.profile(s,p)
    local pressure=Space.clearance(s,p.team,p.x,p.y)
    local automatic=p~=s.controlled and p.role~="GK" and p.role~="DF" and
        mate.role~="GK" and d>=7 and d<=21 and forward>=-3 and forward<=14 and
        pressure<12 and pressure>2 and (s.combinationCooldown[p.team] or 0)<=s.elapsed
        and (not profile or (not profile.hold and (profile.runs or 0)>-0.4))
    if not (requested or automatic) or d>32 or mate==p then return end
    local depth=max(p.x*attack+22+(profile and (profile.runs or 0)*3 or 0),mate.x*attack+7)
    local x=onside(s,p.team,clamp(depth*attack,5,s.field.w-5))
    if (x-p.x)*attack<6 then return end
    if (x-mate.x)*attack<3 then return end
    local y,space=nil,-math.huge
    for _,offset in ipairs({-9,9,-15,15}) do
        local ty=clamp(mate.y+offset,6,s.field.h-6)
        local gap=Space.clearance(s,p.team,x,ty)
        local value=min(gap,15)-Space.laneRisk(s,mate.x,mate.y,x,ty,p.team)*0.5
        if value>space then y,space=ty,value end
    end
    if not requested and space<5 then return end
    s.combinations[p.team]={runner=p,wall=mate,stage="outbound",x=x,y=y,
        started=s.elapsed,expires=s.elapsed+4.5}
    s.combinationCooldown[p.team]=s.elapsed+7
    s.supportActions[p.team]=nil
    feedback(s,"one_two_run",p,x,y)
end
function Combinations.onTouch(s,p)
    init(s)
    s.combinations[3-p.team]=nil
    s.supportActions[3-p.team]=nil
    local combo=s.combinations[p.team]
    if not combo then return end
    if combo.stage=="outbound" and p==combo.wall then
        combo.stage="return_ready";combo.readyAt=s.elapsed;combo.expires=s.elapsed+3
    elseif combo.stage=="returning" and p==combo.runner then
        feedback(s,"one_two_complete",p,p.x,p.y)
        s.combinations[p.team]=nil
    elseif p~=combo.runner and p~=combo.wall then
        s.combinations[p.team]=nil
    end
end
function Combinations.returnPlan(s,p)
    local combo=s.combinations and s.combinations[p.team]
    if not combo or combo.wall~=p or combo.stage~="return_ready" or p==s.controlled or
        s.elapsed>=combo.expires or Offside.inPosition(s,combo.runner) then return end
    local attack=p.team==1 and 1 or -1
    -- Wait for the runner to advance instead of returning to the original spot.
    if (combo.runner.x-p.x)*attack<2 then return end
    local plan=Passing.plan(s,p,combo.runner)
    if plan then plan.combinationReturn=true end
    return plan
end
function Combinations.runTarget(s,p)
    if p==s.controlled then return end
    local combo=s.combinations and s.combinations[p.team]
    if combo and combo.runner==p and combo.stage~="returning" and s.elapsed<combo.expires then
        return onside(s,p.team,combo.x),combo.y,"one_two_run"
    end
    local run=s.supportActions and s.supportActions[p.team]
    if run and run.player==p and s.elapsed<run.expires then
        return onside(s,p.team,run.x),run.y,run.kind
    end
end
function Combinations.update(s)
    init(s)
    if s.phase~="play" then return end
    if s.combinationFeedback and s.elapsed>=s.combinationFeedback.expires then s.combinationFeedback=nil end
    for team=1,2 do
        if s.lastTouch~=team then s.runTriggers[team]=nil end
        local combo=s.combinations[team]
        if combo and (s.elapsed>=combo.expires or s.lastTouch==3-team) then s.combinations[team]=nil end
        local run=s.supportActions[team]
        if run and (s.elapsed>=run.expires or s.lastTouch~=team or
            distance(run.player,{x=run.x,y=run.y})<1.2) then s.supportActions[team]=nil end
        if not s.combinations[team] and not s.supportActions[team] and s.lastTouch==team and
            not s.activePass and s.ball.vx^2+s.ball.vy^2<100 and #s.players==22 then
            local carrier,gap=nil,5
            for _,p in ipairs(s.players) do
                if p.team==team then
                    local d=distance(p,s.ball)
                    if d<gap then carrier,gap=p,d end
                end
            end
            local previous=s.runTriggers[team]
            local refresh=previous and s.elapsed-previous.at>=8
            local changed=carrier and (not previous or previous.carrier~=carrier or
                distance(s.ball,previous)>8 or refresh)
            if changed and (not previous or s.elapsed-previous.at>=3) then
                local attack=team==1 and 1 or -1
                local wide=abs(carrier.y-s.field.h/2)>s.field.h*0.20
                local best,bestX,bestY,bestKind,bestValue=nil,nil,nil,nil,-math.huge
                for _,p in ipairs(s.players) do
                    local profile=Settings.profile(s,p)
                    local eligible=(wide and p.role=="FB") or p.role=="CM" or p.role=="ST"
                    if profile then
                        eligible=p.role~="GK" and not profile.hold and (profile.runs or 0)>-0.4
                            and (eligible or (profile.runs or 0)>0.4)
                    end
                    if p.team==team and p~=carrier and p~=s.controlled and eligible and
                        not (refresh and previous.player==p) then
                        local behind=(carrier.x-p.x)*attack
                        local sameWing=(p.homeY-s.field.h/2)*(carrier.y-s.field.h/2)>0
                        if behind>=-3 and behind<28 and (p.role~="FB" or sameWing) then
                            local side=carrier.y<s.field.h/2 and -1 or 1
                            local kind=wide and (p.role=="FB" and "overlap" or "underlap") or "support_run"
                            local requested=profile and profile.overlap or "none"
                            local localY=team==1 and carrier.y or s.field.h-carrier.y
                            local sideRequested=requested:find("both") or
                                (requested:find("left") and localY<s.field.h/2) or
                                (requested:find("right") and localY>=s.field.h/2)
                            if wide and profile and profile.rotation=="invert_midfield" then kind="underlap" end
                            if wide and sideRequested and requested:find("under") then kind="underlap" end
                            local offsets=kind=="overlap" and {side*6,side*10} or
                                (kind=="underlap" and {-side*10,-side*16} or {-10,10,-16,16})
                            for _,depth in ipairs({10,16}) do
                                local x=onside(s,team,clamp(carrier.x+attack*depth,5,s.field.w-5))
                                for _,offset in ipairs(offsets) do
                                    local y=clamp(carrier.y+offset,6,s.field.h-6)
                                    local space=Space.clearance(s,team,x,y)
                                    local risk=Space.laneRisk(s,carrier.x,carrier.y,x,y,team)
                                    local value=min(space,16)-risk*0.8-distance(p,{x=x,y=y})*0.12
                                    if profile then
                                        value=value+(profile.runs or 0)*4+(profile.depth or 0)*2
                                        if sideRequested then
                                            local desired=requested:find("under") and "underlap" or "overlap"
                                            value=value+(kind==desired and 5 or -3)
                                        end
                                    end
                                    if kind=="overlap" then value=value+1 end
                                    if space>5 and risk<8 and (x-p.x)*attack>6 and value>bestValue then
                                        best,bestX,bestY,bestKind,bestValue=p,x,y,kind,value
                                    end
                                end
                            end
                        end
                    end
                end
                if best then
                    s.supportActions[team]={player=best,carrier=carrier,x=bestX,y=bestY,kind=bestKind,expires=s.elapsed+4.5}
                    s.runTriggers[team]={carrier=carrier,player=best,x=s.ball.x,y=s.ball.y,at=s.elapsed}
                    feedback(s,bestKind,best,bestX,bestY)
                end
            end
        end
    end
end
return Combinations
