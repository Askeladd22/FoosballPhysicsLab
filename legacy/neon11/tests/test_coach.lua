package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Coach=require("src.coach")
local Settings=require("src.tactical_settings")
local Roles=require("src.football_roles")
local function contains(list,value)
    for _,v in ipairs(list) do if v==value then return true end end
    return false
end
local function fixture(kind)
    local s=Sim.new("GK")
    s.phase="play";s.setPiece=nil;s.lastTouch=1;s.ball.x,s.ball.y=50,34
    local index=0
    for _,p in ipairs(s.players) do
        p.vx,p.vy,p.moveX,p.moveY=0,0,0,0
        if p.team==2 and p.role~="GK" then
            index=index+1
            p.x=kind=="high" and 45+index or 85
            p.y=kind=="compact" and 30+(index%3)*2 or 4+index*5.5
        end
    end
    return s
end
local function physical(s)
    local values={s.controlled,s.ball.x,s.ball.y,s.ball.vx,s.ball.vy,s.elapsed,s.score[1],s.score[2]}
    for _,p in ipairs(s.players) do
        for _,v in ipairs({p,p.number,p.team,p.x,p.y,p.vx,p.vy,p.moveX,p.moveY}) do values[#values+1]=v end
    end
    return values
end
local function same(a,b)
    assert(#a==#b)
    for i,v in ipairs(a) do assert(v==b[i],"coach changed physical match state or human input") end
end
local function compatible(s)
    local goalkeepers={0,0}
    for _,p in ipairs(s.players) do
        local r=assert(Roles.get(p.tacticalRole))
        assert(contains(r.positions,p.position) and contains(r.duties,p.duty),"coach selected incompatible role/duty")
        if p.position=="GK" then goalkeepers[p.team]=goalkeepers[p.team]+1 end
    end
    assert(#s.players==22 and goalkeepers[1]==1 and goalkeepers[2]==1)
end
local function review(s,time)
    s.elapsed=time
    local before=physical(s)
    Coach.update(s,1/120)
    same(before,physical(s));compatible(s)
end

local wide=fixture("compact")
wide.controlled.moveX,wide.controlled.moveY=0.3,-0.2
local before=physical(wide);Coach.reset(wide);same(before,physical(wide))
review(wide,12)
assert(wide.coaches[1].plan=="balanced" and wide.coaches[1].changes==0,"coach reacted to one sample")
review(wide,24)
assert(wide.coaches[1].plan=="wide_attack" and wide.teamTactics[1].formation=="4-3-3")
assert(wide.teamTactics[1].instructions.width==1 and wide.coaches[1].reason:find("stretto"))
local actualDuty=false
for _,p in ipairs(wide.players) do
    if p.team==1 and p.tacticalRole=="wing_back" and p.duty=="attack" then actualDuty=true end
end
assert(actualDuty,"plan label changed without role and duty assignments")

-- Same plan must not run setters again or destroy a live combination.
local original,count={},0
for _,name in ipairs({"setFormation","setRole","setDuty","setTeamInstruction","setPlayerInstruction"}) do
    original[name]=Settings[name]
    Settings[name]=function(...) count=count+1;return original[name](...) end
end
local combination={runner=wide.players[9],stage="outbound",expires=100}
wide.combinations[1]=combination
review(wide,36)
for name,fn in pairs(original) do Settings[name]=fn end
assert(count==0 and wide.combinations[1]==combination,"unchanged coaching churned settings/intents")

-- Reset keeps the previous tactical setup while clearing observation history.
local roleIds={}
for i,p in ipairs(wide.players) do roleIds[i]=p.tacticalRole..":"..p.duty end
wide.elapsed=0;wide.score[1],wide.score[2]=0,0
Coach.reset(wide)
assert(wide.coaches[1].plan=="wide_attack" and wide.coaches[1].nextReview==12 and not wide.coaches[1].observation)
for i,p in ipairs(wide.players) do assert(roleIds[i]==p.tacticalRole..":"..p.duty) end

local high=fixture("high");review(high,12);review(high,24)
assert(high.coaches[1].plan=="direct_transition" and high.teamTactics[1].instructions.passIntoSpace,
    "high opponent block did not produce depth attack")
local wasteful=fixture("broad")
wasteful.passStats[1].attempts,wasteful.passStats[1].completed=12,3
review(wasteful,12);review(wasteful,24)
assert(wasteful.coaches[1].plan=="possession" and wasteful.teamTactics[1].instructions.playOut,
    "poor stagnant passing did not produce safer build-up")

local score=fixture("broad")
score.score[1],score.score[2]=1,0
review(score,230)
assert(score.coaches[1].plan=="protect_lead" and score.coaches[2].plan=="chase_goal",
    "coaches interpreted their own score with the wrong sign")
assert(score.teamTactics[1].formation=="5-2-3" and score.teamTactics[2].formation=="3-5-2")
score.score[2]=2;review(score,231)
assert(score.coaches[1].plan=="protect_lead","rapid score change bypassed minimum emergency dwell")
review(score,234)
assert(score.coaches[1].plan=="chase_goal" and score.coaches[2].plan=="protect_lead",
    "decisive late score did not override ordinary commitment")

-- A manual/custom slot layout cannot leak an incompatible role into a plan.
local custom=fixture("high")
local fullback
for _,p in ipairs(custom.players) do if p.team==1 and p.position=="DL" then fullback=p;break end end
assert(Settings.setPosition(custom,fullback,"WBL"))
review(custom,12);review(custom,24)
assert(custom.coaches[1].plan=="direct_transition" and fullback.position=="DL")
compatible(custom)

local unstable=fixture("broad")
for step=1,10 do
    local index=0
    for _,p in ipairs(unstable.players) do
        if p.team==2 and p.role~="GK" then
            index=index+1;p.y=step%2==1 and 30+(index%3)*2 or 4+index*5.5
        end
    end
    review(unstable,step*12)
end
assert(unstable.coaches[1].changes==0,"coach oscillated between unconfirmed contexts")
unstable.phase="paused";local nextReview=unstable.coaches[1].nextReview
Coach.update(unstable,100)
assert(unstable.coaches[1].nextReview==nextReview,"coach advanced while paused")

-- Exercise the production Sim.step hook, not just calls to the coach module.
local integrated=fixture("compact")
integrated.autoCoachEnabled=true
integrated.aiTimer=-1000 -- Keep the observed block still until coaching reacts.
local human=integrated.controlled
for _=1,3100 do
    Sim.step(integrated,1/120,{})
    if integrated.coaches[1].changes>0 then break end
end
assert(integrated.coaches[1].changes==1 and integrated.coaches[1].plan=="wide_attack",
    "match stepping did not automatically invoke the coach")
assert(integrated.controlled==human and integrated.elapsed>=24 and integrated.elapsed<26)
compatible(integrated)

local legacy=Sim.new("GK",5)
local old=physical(legacy)
Coach.reset(legacy);Coach.update(legacy,1)
assert(not legacy.coaches);same(old,physical(legacy))
print("PASS: contextual automatic coaches, compatible roles/duties, stable commitment, score reactions, no churn/teleport, restart and Sim hook")
