package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Tactics=require("src.tactics")
local Space=require("src.space")
local Offside=require("src.offside")
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end

-- Pressure at or behind the passer is distinct from a blocked delivery.
local lane={players={{team=2,x=-2,y=0},{team=2,x=0,y=0},
    {team=2,x=12,y=0},{team=1,x=5,y=0}}}
assert(Space.laneRisk(lane,0,0,10,0,1)==0,"behind/beyond/own players block lane")
lane.players[#lane.players+1]={team=2,x=5,y=0}
assert(Space.laneRisk(lane,0,0,10,0,1)>9,"interceptor in lane was ignored")
assert(Space.laneRisk(lane,10,0,0,0,1)>9,"mirrored lane missed interceptor")
assert(Space.clearance({players={{team=1,x=0,y=0}}},1,0,0)==math.huge)
assert(Space.clearance(lane,1,5,0)==0)

for team=1,2 do
    local s=Sim.new("GK")
    local attack=team==1 and 1 or -1
    local function world(x) return team==1 and x or s.field.w-x end
    s.phase="play";s.setPiece=nil;s.lastTouch=team
    s.ball.x,s.ball.y=world(52),34
    local enemies={}
    for _,p in ipairs(s.players) do
        if p.team~=team then
            p.x,p.y=world(94),5+#enemies*5
            enemies[#enemies+1]=p
        end
    end
    local before=Tactics.teamTargets(s,team)
    -- Screen the actual configured outlets, not coordinates tied to a previous
    -- hard-coded formation. The same scenario applies to either mirrored team.
    local outlets={}
    for p,t in pairs(before) do
        if p.role~="GK" and not t.cover then outlets[#outlets+1]={player=p,target=t} end
    end
    table.sort(outlets,function(a,b) return a.player.number<b.player.number end)
    for i=1,4 do
        local target=outlets[i].target
        enemies[i].x,enemies[i].y=target.x,target.y
    end
    s.controlled.moveX,s.controlled.moveY=0.3,-0.2
    local humanX,humanY=s.controlled.x,s.controlled.y
    local after=Tactics.teamTargets(s,team)
    local oldPlayable,newPlayable,changed,oldRisk,newRisk=0,0,0,0,0
    local function playable(t)
        local risk=Space.laneRisk(s,s.ball.x,s.ball.y,t.x,t.y,team)
        return risk<9 and Space.clearance(s,team,t.x,t.y)>=6,risk
    end
    local cover=false
    for p,t in pairs(after) do
        if p.role~="GK" then
            local oldGood,r1=playable(before[p])
            local newGood,r2=playable(t)
            oldPlayable=oldPlayable+(oldGood and 1 or 0)
            newPlayable=newPlayable+(newGood and 1 or 0)
            oldRisk,newRisk=oldRisk+r1,newRisk+r2
            if distance(t,before[p])>1 then changed=changed+1 end
            assert(distance(t,before[p])<=16.01,"pressure moved support too far from role")
            assert((t.x-Offside.line(s,team))*attack<=-0.79,"support target is offside")
            if p.role=="CM" and p.number==6 then
                assert((s.ball.x-t.x)*attack>=8.99,"holding midfielder abandoned cover")
            end
            if t.cover then
                cover=true
                assert((s.ball.x-t.x)*attack>=15.99,"last covering player advanced")
            end
            for other,o in pairs(after) do
                if other~=p and other.role~="GK" then
                    assert(distance(t,o)>=7.99,"new spatial cost broke teammate spacing")
                end
            end
            -- Feed back actual support intent, then perturb defenders by 1 cm.
            p.decision,p.targetX,p.targetY="support",t.x,t.y
        end
    end
    assert(cover and changed>=1,"opponent movement did not change support")
    assert(newPlayable>oldPlayable and newRisk<oldRisk,"rotation did not open more playable lanes")
    assert(not after[s.controlled],"human received a support assignment")
    assert(s.controlled.x==humanX and s.controlled.y==humanY and
        s.controlled.moveX==0.3 and s.controlled.moveY==-0.2,"support changed human movement")
    for _,enemy in ipairs(enemies) do enemy.y=enemy.y+0.01 end
    local stable=Tactics.teamTargets(s,team)
    for p,t in pairs(after) do
        assert(distance(t,stable[p])<0.01,"tiny defender movement caused support oscillation")
    end
end
print("PASS: segment-only risk, mirrored contextual support, playable lanes, role/spacing constraints, stability and human control")
