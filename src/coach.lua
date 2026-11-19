-- Original, observable coaching heuristics. FM role vocabulary is supplied by
-- the catalog; these six plans are not a reconstruction of FM's AI manager.
local Settings=require("src.tactical_settings")
local Roles=require("src.football_roles")
local Coach={}
local min,max,abs=math.min,math.max,math.abs
local REVIEW,DWELL=12,24
local plans={
    balanced={label="Equilibrio",formation="4-4-2",team={}},
    possession={label="Costruzione paziente",formation="4-3-3",team={
        mentality=0.3,passing=-0.5,tempo=-0.5,width=0.5,playOut=true,
        finalThird="work",distribution="playmaker",transitionWin="hold"}},
    wide_attack={label="Allargare il blocco",formation="4-3-3",team={
        mentality=0.3,width=1,passing=0,tempo=0.5,overlap="both",
        finalThird="early",transitionLoss="counterpress",distribution="flanks"}},
    direct_transition={label="Attaccare la profondità",formation="4-4-2",team={
        mentality=0.3,passing=1,tempo=0.5,passIntoSpace=true,
        transitionWin="counter",distribution="target",finalThird="mixed"}},
    protect_lead={label="Proteggere il vantaggio",formation="5-2-3",team={
        mentality=-0.65,passing=-0.5,tempo=-0.5,defensiveLine=-0.5,
        engagement=-1,pressing=-0.5,transitionLoss="regroup",transitionWin="hold",
        dribbling=-1,distribution="short"}},
    chase_goal={label="Cercare il gol",formation="3-5-2",team={
        mentality=0.65,width=0.5,passing=0.5,tempo=1,passIntoSpace=true,
        engagement=1,pressing=1,defensiveLine=0.5,preventShortGK=true,
        transitionLoss="counterpress",transitionWin="counter",finalThird="shoot"}}
}
local function contains(list,value)
    for _,item in ipairs(list) do if item==value then return true end end
    return false
end
local function active(s)
    return #s.players==22 and s.teamTactics and s.teamTactics[1] and s.teamTactics[2]
end
local function roleFor(plan,position,index)
    if position=="GK" then
        if plan=="possession" then return "sweeper_keeper","support" end
        if plan=="chase_goal" then return "sweeper_keeper","attack" end
        return "goalkeeper","defend"
    elseif position=="DC" then
        if plan=="possession" or plan=="chase_goal" then return "ball_playing_defender","defend" end
        if plan=="direct_transition" then return "no_nonsense_centre_back","defend" end
        return "central_defender",plan=="protect_lead" and index==2 and "cover" or "defend"
    elseif position=="DL" or position=="DR" or position=="WBL" or position=="WBR" then
        if plan=="chase_goal" then return "complete_wing_back","attack" end
        if plan=="protect_lead" then return "wing_back","defend" end
        if plan=="wide_attack" then return "wing_back","attack" end
        if plan=="possession" and position=="DR" then return "inverted_wing_back","support" end
        return "full_back","support"
    elseif position=="DM" then
        if plan=="wide_attack" then return "half_back","defend" end
        if plan=="chase_goal" then return "regista","support" end
        return "deep_lying_playmaker","defend"
    elseif position=="MC" then
        if plan=="possession" then
            return index==1 and "advanced_playmaker" or "box_to_box_midfielder","support"
        elseif plan=="wide_attack" then
            return index==1 and "deep_lying_playmaker" or "mezzala",index==1 and "support" or "attack"
        elseif plan=="chase_goal" then
            return index==1 and "advanced_playmaker" or "mezzala","attack"
        elseif plan=="protect_lead" then
            return index==1 and "deep_lying_playmaker" or "ball_winning_midfielder","defend"
        elseif plan=="direct_transition" then
            return index==1 and "ball_winning_midfielder" or "central_midfielder",index==1 and "defend" or "support"
        end
        return "central_midfielder",index==1 and "defend" or "attack"
    elseif position=="ML" or position=="MR" then
        return plan=="direct_transition" and "winger" or "wide_midfielder",
            plan=="direct_transition" and "attack" or "support"
    elseif position=="AML" or position=="AMR" then
        if plan=="protect_lead" then return "inverted_winger","support" end
        if position=="AML" and plan=="possession" then return "inverted_winger","support" end
        return "winger","attack"
    elseif position=="AMC" then return "advanced_playmaker","support"
    elseif position=="ST" then
        if plan=="possession" then return "false_nine","support" end
        if plan=="protect_lead" or (plan=="direct_transition" and index==1) then return "target_forward","support" end
        if plan=="chase_goal" and index==2 then return "complete_forward","support" end
        if plan=="balanced" and index==1 then return "deep_lying_forward","support" end
        return "advanced_forward","attack"
    end
end
local function applyPlan(s,team,id)
    local plan,config=plans[id],s.teamTactics[team]
    if config.formation~=plan.formation or config.custom then
        assert(Settings.setFormation(s,team,plan.formation))
    end
    for _,row in ipairs(Settings.teamInstructionList) do
        if not row.disabled then
            local value=plan.team[row.id]
            if value==nil then value=row.default end
            if config.instructions[row.id]~=value then assert(Settings.setTeamInstruction(s,team,row.id,value)) end
        end
    end
    local counts={}
    for _,p in ipairs(s.players) do
        if p.team==team then
            counts[p.position]=(counts[p.position] or 0)+1
            local role,duty=roleFor(id,p.position,counts[p.position])
            local catalog=role and Roles.get(role)
            assert(catalog and contains(catalog.positions,p.position),"coach role incompatible with formation")
            assert(contains(catalog.duties,duty),"coach selected unsupported duty")
            if p.tacticalRole~=role then assert(Settings.setRole(s,p,role)) end
            if p.duty~=duty then assert(Settings.setDuty(s,p,duty)) end
            local individual={}
            if id=="wide_attack" and (p.role=="FB" or p.role=="LM" or p.role=="RM") then
                individual.crossing=1;individual.crossFrom="deep";individual.crossAim="centre"
            elseif id=="protect_lead" then
                individual.risk=-1
                if p.role=="DF" or p.role=="FB" then individual.markTighter=true end
                if p.role=="ST" or p.position=="AML" or p.position=="AMR" then
                    individual.depth="hold";individual.holdUp="yes"
                end
            elseif id=="direct_transition" then
                if p.role=="ST" then individual.channels=true end
            elseif id=="possession" then individual.passing=-1;individual.shooting=-1
            elseif id=="chase_goal" then
                if p.role~="GK" and p.role~="DF" then individual.channels=true;individual.shooting=1 end
            end
            for _,row in ipairs(Settings.playerInstructionList) do
                if not row.disabled then
                    local value=individual[row.id]
                    if value==nil then value=row.default end
                    if (p.instructions or {})[row.id]~=value then
                        assert(Settings.setPlayerInstruction(s,p,row.id,value))
                    end
                end
            end
        end
    end
end
local function observe(s,team,coach)
    local minY,maxY,sumDepth,lastDefender,count=math.huge,-math.huge,0,0,0
    for _,p in ipairs(s.players) do
        if p.team~=team and p.role~="GK" then
            local depth=team==1 and p.x or s.field.w-p.x
            minY,maxY=min(minY,p.y),max(maxY,p.y)
            sumDepth,lastDefender,count=sumDepth+depth,max(lastDefender,depth),count+1
        end
    end
    local stats=s.passStats and s.passStats[team] or {}
    local attempts,completed=stats.attempts or 0,stats.completed or 0
    local samples=attempts-(coach.attempts or 0)
    local receipts=completed-(coach.completed or 0)
    if samples<4 then samples,receipts=attempts,completed end
    local ballDepth=team==1 and s.ball.x or s.field.w-s.ball.x
    local progress=coach.ballDepth and ballDepth-coach.ballDepth or 0
    coach.progress=(coach.progress or 0)*0.6+(s.lastTouch==team and progress or 0)*0.4
    coach.ballDepth,coach.attempts,coach.completed=ballDepth,attempts,completed
    return {blockWidth=count>0 and maxY-minY or s.field.h,
        blockDepth=count>0 and sumDepth/count or s.field.w,lastDefender=lastDefender,
        completion=samples>0 and max(0,min(1,receipts/samples)) or 1,samples=samples,progress=coach.progress}
end
local function choose(s,team,o)
    local scores={balanced=1,possession=0.2,wide_attack=0.2,direct_transition=0.2,protect_lead=0.2,chase_goal=0.2}
    local reasons={balanced="Mantengo distanze e coperture: nessun vantaggio stabile per cambiare."}
    if o.blockWidth<s.field.h*0.55 and o.blockDepth>s.field.w*0.58 then
        scores.wide_attack=2.5+(1-o.blockWidth/s.field.h)
        reasons.wide_attack="Il blocco avversario è stretto e arretrato: cerco ampiezza e appoggi sulle fasce."
    end
    if o.lastDefender<s.field.w*0.73 and o.blockDepth<s.field.w*0.62 then
        scores.direct_transition=2.8
        reasons.direct_transition="Gli avversari sono alti: cerco i corridoi liberi alle loro spalle."
    end
    if o.samples>=6 and o.completion<0.58 and o.progress<8 then
        scores.possession=2.5+(0.58-o.completion)
        reasons.possession="Perdiamo troppi passaggi senza avanzare: accorcio gli appoggi e rallento la costruzione."
    end
    local lead=s.score[team]-s.score[3-team]
    local fraction=s.elapsed/max(1,s.limit or 300)
    if lead<0 and (fraction>=0.5 or (lead<=-2 and fraction>=0.25)) then
        scores.chase_goal=5
        reasons.chase_goal="Siamo sotto e il tempo diminuisce: aumento pressione e presenze in avanti."
    elseif lead>0 and fraction>=0.65 then
        scores.protect_lead=5
        reasons.protect_lead="Siamo avanti nella parte finale: proteggo le corsie e conservo appoggi sicuri."
    end
    local best="balanced"
    -- Explicit order gives reproducible ties; it does not cycle through plans.
    for _,id in ipairs({"possession","wide_attack","direct_transition","protect_lead","chase_goal"}) do
        if scores[id]>scores[best] then best=id end
    end
    return best,reasons[best],scores,fraction>=0.75 and (best=="chase_goal" or best=="protect_lead")
end
function Coach.reset(s)
    if not active(s) then s.coaches=nil;return end
    local previous=s.coaches
    s.coaches={}
    for team=1,2 do
        local old=previous and previous[team]
        local id=old and plans[old.plan] and old.plan or "balanced"
        s.coaches[team]={plan=id,label=plans[id].label,
            reason=old and "Nuova partita: riparto dall'assetto precedente e osservo gli avversari."
                or "Parto dal 4-4-2 equilibrato e osservo gli avversari.",
            changedAt=s.elapsed,nextReview=s.elapsed+REVIEW,changes=0,
            lastOwnScore=s.score[team],lastOtherScore=s.score[3-team]}
    end
end
function Coach.update(s,dt)
    if not active(s) or s.phase~="play" then return end
    if not s.coaches then Coach.reset(s) end
    for team=1,2 do
        local coach=s.coaches[team]
        local scoreChanged=s.score[team]~=coach.lastOwnScore or s.score[3-team]~=coach.lastOtherScore
        local lateScore=scoreChanged and s.elapsed/max(1,s.limit or 300)>=0.75
        if s.elapsed>=coach.nextReview or lateScore then
            local evidence=observe(s,team,coach)
            local desired,reason,scores,urgent=choose(s,team,evidence)
            coach.observation=evidence
            if desired==coach.candidate then coach.confirmations=(coach.confirmations or 0)+1
            else coach.candidate,coach.confirmations=desired,1 end
            local committed=s.elapsed-coach.changedAt>=DWELL
            if urgent and lateScore and desired~=coach.plan then coach.pendingUrgent=desired end
            if not urgent or desired==coach.plan then coach.pendingUrgent=nil end
            local urgency=urgent and coach.pendingUrgent==desired and s.elapsed-coach.changedAt>=4
            if desired~=coach.plan and scores[desired]>scores[coach.plan]+0.3 and
                ((committed and coach.confirmations>=2) or urgency) then
                applyPlan(s,team,desired)
                coach.plan,coach.label,coach.reason=desired,plans[desired].label,reason
                coach.changedAt=s.elapsed;coach.changes=coach.changes+1
                coach.candidate,coach.confirmations=nil,0
                coach.pendingUrgent=nil
            elseif desired==coach.plan then coach.reason=reason end
            coach.nextReview=s.elapsed+REVIEW
            if coach.pendingUrgent then coach.nextReview=min(coach.nextReview,coach.changedAt+4) end
            coach.lastOwnScore,coach.lastOtherScore=s.score[team],s.score[3-team]
        end
    end
end
return Coach
