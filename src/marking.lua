-- Local zonal assignments. Recomputed from visible threats, never hard locks.
local Marking={}
local Settings=require("src.tactical_settings")
local abs,sqrt,min,max=math.abs,math.sqrt,math.min,math.max
local function distance(ax,ay,bx,by) return sqrt((ax-bx)^2+(ay-by)^2) end
function Marking.assign(s,team,candidates,guard,anchor)
    local assignments={}
    if #s.players~=22 or s.lastTouch~=3-team then return assignments end
    local attack=team==1 and 1 or -1
    local function depth(x) return team==1 and x or s.field.w-x end
    local threats={}
    local shortBuild=false
    for _,enemy in ipairs(s.players) do
        if enemy.team~=team and enemy.role=="GK" and depth(enemy.x)>s.field.w*0.8 and
            distance(enemy.x,enemy.y,s.ball.x,s.ball.y)<8 then
            for _,p in ipairs(candidates) do
                local q=Settings.profile(s,p)
                if q and q.preventShortGK then shortBuild=true end
            end
        end
    end
    for _,enemy in ipairs(s.players) do
        -- The presser already handles the carrier. Other defenders track
        -- passing threats in their own area rather than chasing everyone.
        if enemy.team~=team and enemy.role~="GK" and depth(enemy.x)>=4
            and depth(enemy.x)<s.field.w*(shortBuild and 1 or 0.64) and enemy.y>=0 and enemy.y<=s.field.h
            and distance(enemy.x,enemy.y,s.ball.x,s.ball.y)>5 then
            threats[#threats+1]=enemy
        end
    end
    table.sort(threats,function(a,b)
        local ca=depth(a.x)+abs(a.y-s.field.h/2)*0.2
        local cb=depth(b.x)+abs(b.y-s.field.h/2)*0.2
        return ca==cb and a.number<b.number or ca<cb
    end)
    for _,enemy in ipairs(threats) do
        local best,cost=nil,math.huge
        for _,p in ipairs(candidates) do
            if p~=guard and p.role~="GK" and (p.role~="ST" or shortBuild) and not assignments[p] then
                local profile=Settings.profile(s,p)
                local ax,ay=anchor(s,p)
                local zone=distance(ax,ay,enemy.x,enemy.y)
                local reserved=false
                if profile and profile.markPosition and profile.markPosition~="none" and
                    enemy.position~=profile.markPosition then
                    for _,preferred in ipairs(threats) do
                        if preferred.position==profile.markPosition and
                            distance(ax,ay,preferred.x,preferred.y)<=25 and abs(ay-preferred.y)<=18 then
                            local taken=false
                            for _,mark in pairs(assignments) do if mark.opponent==preferred then taken=true end end
                            if not taken then reserved=true;break end
                        end
                    end
                end
                if not reserved and zone<=25 and abs(ay-enemy.y)<=18 then
                    local score=zone+distance(p.x,p.y,enemy.x,enemy.y)*0.25
                    if profile and profile.markPosition and profile.markPosition~="none" then
                        score=score+(enemy.position==profile.markPosition and -12 or 6)
                    end
                    if score<cost or (score==cost and (not best or p.number<best.number)) then
                        best,cost=p,score
                    end
                end
            end
        end
        if best then
            local profile=Settings.profile(s,best)
            local gap=profile and profile.markTighter and 2.8 or 3.5
            assignments[best]={opponent=enemy,
                x=max(2,min(s.field.w-2,enemy.x-attack*gap)),
                y=max(4,min(s.field.h-4,enemy.y+(s.field.h/2-enemy.y)*0.08))}
        end
    end
    return assignments
end
return Marking
