-- Tactical support for eleven-a-side, retaining isolated five-a-side fixtures.
-- positioning/off-ball principles. Entirely independent from love.graphics.
-- The team uses role-based starting positions, but rotates into space in play.
local Tactics={}
local Offside=require("src.offside")
local Combinations=require("src.combinations")
local Marking=require("src.marking")
local Space=require("src.space")
local Settings=require("src.tactical_settings")
local abs,min,max,sqrt=math.abs,math.min,math.max,math.sqrt
local function clamp(x,a,b) return max(a,min(b,x)) end
local function distance(x,y,u,v)
    local dx,dy=x-u,y-v
    return sqrt(dx*dx+dy*dy)
end
function Tactics.phase(s,team)
    if s.lastTouch==team then return "attack" end
    if s.lastTouch==3-team then return "defend" end
    return "neutral"
end
local function holdsMidfield(s,p)
    if #s.players~=22 or p.role~="CM" or Tactics.phase(s,p.team)~="attack"
        or Combinations.runTarget(s,p) then return false end
    local profile=Settings.profile(s,p)
    if profile and profile.hold then return true end
    if not profile and p.number==6 then return true end
    for _,mate in ipairs(s.players) do
        if mate.team==p.team and mate.role=="CM" and mate~=p and Combinations.runTarget(s,mate) then
            return true
        end
    end
    return false
end
-- Original game coefficients translate the configured football task to a
-- destination; they are not Football Manager's internal match-engine values.
local function configuredPoint(s,p,q,x,y,phase)
    local f,b=s.field,s.ball
    local attack=p.team==1 and 1 or -1
    local mid=f.h/2
    local ballDepth=p.team==1 and b.x or f.w-b.x
    local depth=p.team==1 and x or f.w-x
    local side=p.homeY<mid and -1 or 1
    depth=depth+(q.depth or 0)*10+(q.mentality or 0)*4
    if phase=="attack" then
        y=mid+(y-mid)*(1+(q.width or 0)*0.35)
        if p.role=="CM" and not q.hold and (q.depth or 0)>0 then
            depth=max(depth,ballDepth+q.depth*14)
        end
        if q.hold then
            local home=p.team==1 and p.homeX or f.w-p.homeX
            depth=min(depth,home+(ballDepth-f.w/2)*0.3+5)
        end
        local back=clamp(ballDepth-18,6,46)
        if q.rotation=="invert_defence" or q.rotation=="half_back" then
            depth,y=back,mid+side*(q.rotation=="half_back" and 3 or 9)
        elseif q.rotation=="invert_midfield" or q.rotation=="libero" then
            local blocked=false
            if q.rotation=="libero" then
                for _,mate in ipairs(s.players) do
                    local other=mate.team==p.team and mate~=p and Settings.profile(s,mate)
                    if other and other.rotation=="invert_midfield" and
                        (mate.homeY-mid)*(p.homeY-mid)>=0 then blocked=true end
                end
            end
            depth=blocked and back or clamp(ballDepth-9,19,64)
            y=mid+side*(blocked and 8 or 5)
        elseif q.rotation=="false_nine" or q.rotation=="drop_forward" then
            depth=clamp(ballDepth-(q.rotation=="false_nine" and 8 or 3),24,68)
            y=mid+(b.y-mid)*0.25
        end
        if q.roam then y=y+(b.y-y)*0.15 end
        if q.focus=="left" then y=y-attack*4 elseif q.focus=="right" then y=y+attack*4
        elseif q.focus=="centre" then y=mid+(y-mid)*0.82 end
        local recent=s.aiTransition and s.elapsed-s.aiTransition.at<3
        if recent and q.transitionWin=="counter" and not q.hold then depth=depth+5
        elseif recent and q.transitionWin=="hold" then depth=depth-4 end
    elseif phase=="defend" then
        depth=depth+(q.defensiveLine or 0)*8+(q.engagement or 0)*4
        local recent=s.aiTransition and s.elapsed-s.aiTransition.at<3
        if recent and q.transitionLoss=="regroup" then depth=depth-6
        elseif recent and q.transitionLoss=="counterpress" then depth=depth+5 end
        if q.preventShortGK and ballDepth>f.w*0.8 and
            (p.position=="ST" or p.position=="AML" or p.position=="AMR" or p.position=="AMC") then
            depth=max(depth,ballDepth-9)
        end
    end
    if p.role=="GK" then
        depth=5.3+(q.gkRush and clamp((ballDepth-22)*0.13,0,7) or 0)
    end
    return p.team==1 and depth or f.w-depth,y
end
local function behindBall(s,team,x)
    if team==1 then return min(x,clamp(s.ball.x-9,4,s.field.w-4)) end
    return max(x,clamp(s.ball.x+9,4,s.field.w-4))
end
-- A formation anchor is not an immutable position: it follows the ball while
-- keeping a defender behind it and midfielders in distinct passing lanes.
function Tactics.supportPoint(s,p)
    local b,f=s.ball,s.field
    local attack=p.team==1 and 1 or -1
    local phase=Tactics.phase(s,p.team)
    local profile=Settings.profile(s,p)
    local mid=f.h/2
    local x,y=p.homeX,p.homeY
    if p.role=="GK" then
        x=p.team==1 and 5.3 or f.w-5.3
        y=clamp(mid+(b.y-mid)*0.34,14,f.h-14)
    elseif #s.players==22 then
        -- 4-4-2 block: retain each player's lane, move the lines with the ball.
        -- The shared coordinator below reserves outlets and replacement cover.
        local progress=(b.x-f.w/2)*attack
        local home=p.team==1 and p.homeX or f.w-p.homeX
        local push=phase=="attack" and 13 or (phase=="defend" and -3 or 0)
        local depth=clamp(home+progress*0.45+push,5,f.w-6)
        if p.role=="DF" then depth=min(depth,(p.team==1 and b.x or f.w-b.x)-12) end
        if p.role=="FB" and phase=="attack" then depth=depth+6 end
        if p.role=="CM" and phase=="attack" then
            local ballDepth=p.team==1 and b.x or f.w-b.x
            -- #6 connects behind the ball; #7 offers the next diagonal.
            -- Timed support runs may temporarily exchange these duties.
            if not profile then
                if p.number==6 then depth=min(depth,ballDepth-9)
                else depth=max(depth,ballDepth+6) end
            end
        end
        if p.role=="ST" and phase=="attack" then
            -- One striker offers a shorter outlet, the other threatens depth.
            local ballDepth=p.team==1 and b.x or f.w-b.x
            depth=max(depth,ballDepth+(p.number==9 and 9 or 16))
        end
        x=p.team==1 and depth or f.w-depth
        y=p.homeY+(b.y-mid)*0.22
        if phase=="defend" and p.role~="ST" then
            -- Recover a compact block while continuing to follow the ball.
            y=mid+(p.homeY-mid)*0.78+(b.y-mid)*0.28
        elseif phase=="attack" and p.role=="FB" and
            (p.homeY-mid)*(b.y-mid)<0 then
            -- Far-side fullback narrows and holds while the near side advances.
            x=x-attack*7
            y=mid+(y-mid)*0.7
        end
    elseif phase=="attack" then
        if p.role=="DF" then
            x=p.homeX*0.48+(b.x-attack*18)*0.52
            y=mid+(b.y-mid)*0.38
        elseif p.role=="LM" then
            x=b.x-attack*7
            y=b.y-15
        elseif p.role=="RM" then
            x=b.x-attack*7
            y=b.y+15
        elseif p.role=="ST" then
            x=b.x+attack*17
            y=b.y+(mid-b.y)*0.45
        end
    elseif phase=="defend" then
        if p.role=="DF" then
            x=b.x-attack*17
            y=mid+(b.y-mid)*0.43
        elseif p.role=="LM" then
            x=b.x-attack*10
            y=b.y-13
        elseif p.role=="RM" then
            x=b.x-attack*10
            y=b.y+13
        elseif p.role=="ST" then
            x=b.x+attack*7
            y=b.y+(mid-b.y)*0.35
        end
    else
        local dx=(b.x-f.w/2)*0.17
        local dy=(b.y-mid)*0.16
        x=p.homeX+dx-attack*1.8
        y=p.homeY+dy
    end

    if profile then x,y=configuredPoint(s,p,profile,x,y,phase) end
    x,y=clamp(x,4,f.w-4),clamp(y,7,f.h-7)
    local roleX,roleY=x,y

    -- The human can occupy any lane. AI must yield and rotate instead of
    -- chasing its fixed role slot or forcing the human out of position.
    local human=s.controlled
    if human and human.team==p.team and human~=p and p.role~="GK" then
        if distance(x,y,human.x,human.y)<9.5 then
            local options={
                {clamp(b.x-attack*15,5,f.w-5),clamp(b.y-14,8,f.h-8)},
                {clamp(b.x-attack*15,5,f.w-5),clamp(b.y+14,8,f.h-8)},
                {clamp(b.x+attack*6,5,f.w-5),clamp(mid+(b.y-mid)*0.2,8,f.h-8)}
            }
            local bestX,bestY,bestScore=x,y,-math.huge
            for _,option in ipairs(options) do
                local ox,oy=option[1],option[2]
                local separation=distance(ox,oy,human.x,human.y)
                local score=min(separation,24)-distance(ox,oy,x,y)*0.13
                if separation>=9.5 and score>bestScore then
                    bestX,bestY,bestScore=ox,oy,score
                end
            end
            if bestScore>-math.huge then x,y=bestX,bestY end
        end
    end
    if profile and profile.hold and phase=="attack" then
        x=p.team==1 and min(x,roleX) or max(x,roleX)
        y=clamp(y,max(7,roleY-10),min(f.h-7,roleY+10))
    end
    if holdsMidfield(s,p) then x=behindBall(s,p.team,x) end
    return x,y,phase
end
-- Coordinate a team's off-ball destinations once per AI decision. These are
-- steering targets, never player teleports or an assignment for the human.
function Tactics.teamTargets(s,team)
    local targets,reserved,candidates={},{},{}
    local attacking=Tactics.phase(s,team)=="attack"
    local human=s.controlled
    if human.team==team then reserved[#reserved+1]={human.x,human.y} end
    local pass=s.activePass
    local receiver=pass and pass.team==team and pass.receiver
    local attack=team==1 and 1 or -1
    local offsideLine=Offside.line(s,team)-attack*0.8
    local function onsideX(x)
        if team==1 then return min(x,offsideLine) end
        return max(x,offsideLine)
    end
    if receiver then
        reserved[#reserved+1]={receiver.x,receiver.y}
        reserved[#reserved+1]={pass.targetX,pass.targetY}
    end
    -- While receiving, the original presser also returns to team support.
    local presser=not receiver and s.pressers[team] or nil
    for _,p in ipairs(s.players) do
        if p.team==team and p~=human and p~=receiver and p~=presser then
            candidates[#candidates+1]=p
        end
    end
    local guard
    for _,p in ipairs(candidates) do
        local q=Settings.profile(s,p)
        local stepsIntoMidfield=attacking and q and (q.rotation=="libero" or q.rotation=="invert_midfield")
        if p.role~="GK" and not stepsIntoMidfield and not Combinations.runTarget(s,p) and (not guard or
            (team==1 and p.x<guard.x) or (team==2 and p.x>guard.x)) then
            guard=p
        end
    end
    local marks=Marking.assign(s,team,candidates,guard,Tactics.supportPoint)
    -- Reserve the covering player first, then assign distinct nearby outlets.
    table.sort(candidates,function(a,b)
        if a==guard then return b~=guard end
        if b==guard then return false end
        if marks[a] and not marks[b] then return true end
        if marks[b] and not marks[a] then return false end
        if attacking then
            local qa,qb=Settings.profile(s,a),Settings.profile(s,b)
            local pa,pb=qa and qa.playmaker or false,qb and qb.playmaker or false
            if pa~=pb then return pa end
        end
        return a.number<b.number
    end)
    for _,p in ipairs(candidates) do
        local x,y=Tactics.supportPoint(s,p)
        local profile=Settings.profile(s,p)
        local positionHold=attacking and profile and profile.hold
        local cover=p==guard
        local mark=marks[p]
        local runX,runY=Combinations.runTarget(s,p)
        if runX and not cover then x,y=runX,runY end
        local holding=holdsMidfield(s,p)
        if holding then x=behindBall(s,team,x) end
        if mark then x,y=mark.x,mark.y end
        if cover then
            if team==1 then x=min(x,clamp(s.ball.x-16,4,s.field.w-4))
            else x=max(x,clamp(s.ball.x+16,4,s.field.w-4)) end
        end
        if p.role~="GK" then
            local bestX,bestY,bestScore=x,y,-math.huge
            local bestSpaced=false
            -- Keep a useful outlet through tiny movements, but allow a blocked
            -- one to move. Existing steering intent avoids persistent locks.
            local previous=attacking and not runX and p.decision=="support"
                and p.targetX and p.targetY
                and distance(p.targetX,p.targetY,x,y)<20
            for ix=-2,2 do
                for iy=-3,3 do
                    local spacing=mark and 1 or 8
                    local candidateX=x+ix*spacing
                    if positionHold then
                        candidateX=team==1 and clamp(candidateX,x-10,x) or clamp(candidateX,x,x+10)
                    end
                    local tx=onsideX(clamp(candidateX,4,s.field.w-4))
                    local ty=clamp(y+iy*spacing,7,s.field.h-7)
                    if positionHold then ty=clamp(ty,max(7,y-12),min(s.field.h-7,y+12)) end
                    if holding then tx=behindBall(s,team,tx) end
                    if mark then
                        if team==1 then tx=min(tx,mark.opponent.x-2.5)
                        else tx=max(tx,mark.opponent.x+2.5) end
                        tx=clamp(tx,2,s.field.w-2)
                    end
                    if cover then
                        if team==1 then tx=min(tx,x) else tx=max(tx,x) end
                    end
                    local gap=math.huge
                    for _,point in ipairs(reserved) do
                        gap=min(gap,distance(tx,ty,point[1],point[2]))
                    end
                    local deviation=distance(tx,ty,x,y)
                    local score=-deviation/8-max(0,8-gap)*12.5
                    if attacking and not runX then
                        -- Bounded costs share a scale: roles and team spacing
                        -- still matter even against a crowded defensive block.
                        local pressure=clamp((8-Space.clearance(s,team,tx,ty))/8,0,1)
                        local screening=min(1,Space.laneRisk(s,s.ball.x,s.ball.y,tx,ty,team)/9)
                        score=score-pressure*1.75-screening*1.25-(deviation/16)^2*0.25
                        if previous then
                            score=score-min(2,distance(tx,ty,p.targetX,p.targetY)/8)*0.35
                        end
                    end
                    local spaced=gap>=8-0.000001
                    if (spaced and not bestSpaced) or (spaced==bestSpaced and score>bestScore) then
                        bestX,bestY,bestScore,bestSpaced=tx,ty,score,spaced
                    end
                end
            end
            x,y=bestX,bestY
        end
        targets[p]={x=x,y=y,cover=cover,mark=mark and mark.opponent or nil}
        reserved[#reserved+1]={x,y}
    end
    return targets
end
return Tactics
