-- Full-length deterministic matches with a scripted human, not a human UAT.
package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local function check(ok,msg) if not ok then error(msg,2) end end
local function run(role)
    local s=Sim.new(role)
    local human=s.controlled
    for tick=1,37000 do
        local tx,ty
        if role=="GK" then tx,ty=6,math.max(27,math.min(43,s.ball.y))
        else tx,ty=s.ball.x-2.6,s.ball.y end
        local dx,dy=tx-human.x,ty-human.y
        local d=math.sqrt(dx*dx+dy*dy)
        local input={x=0,y=0,call=tick%180==0}
        if d>0.3 then input.x,input.y=dx/math.max(1,d),dy/math.max(1,d) end
        if (s.ball.x-human.x)^2+(s.ball.y-human.y)^2<3.1^2 then input.kick=0.7 end
        Sim.step(s,1/120,input)
        check(s.controlled==human,"AC-2: controlled identity changed")
        local bodies={s.ball}
        for _,player in ipairs(s.players) do bodies[#bodies+1]=player end
        for _,body in ipairs(bodies) do
            for _,key in ipairs({"x","y","vx","vy"}) do
                local value=body[key]
                check(value==value and math.abs(value)<10000,"non-finite/exploding physics")
            end
        end
        for team=1,2 do
            local stats=s.passStats[team]
            local pending=s.activePass and s.activePass.team==team and 1 or 0
            check(stats.attempts==stats.completed+stats.intercepted+stats.missed+pending,
                "AC-3: inconsistent full-match pass accounting")
        end
        check(s.passAttempts==s.passStats[1].attempts+s.passStats[2].attempts,
            "AC-3: team attempts do not match total")
        if s.phase=="fulltime" then break end
    end
    check(s.phase=="fulltime" and s.elapsed==300,"match did not finish in five minutes")
    check(not s.activePass,"fulltime retained receiving intent")
    local a,b=s.passStats[1],s.passStats[2]
    check(a.completed+b.completed>0,"no physical receptions during full match")
    local summary=string.format("%s score=%d-%d blue=%d/%d intercepted=%d missed=%d red=%d/%d intercepted=%d missed=%d",
        role,s.score[1],s.score[2],a.completed,a.attempts,a.intercepted,a.missed,
        b.completed,b.attempts,b.intercepted,b.missed)
    return summary
end
for _,role in ipairs({"RM","GK"}) do
    local first=run(role)
    check(run(role)==first,"full-match result was not deterministic")
    print("PASS: 300s scripted match "..first)
end
