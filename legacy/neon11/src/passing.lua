-- Shared physical prediction and pass lifecycle. No ownership of the ball.
local Passing={}
local sqrt,exp,min,max,abs=math.sqrt,math.exp,math.min,math.max,math.abs
local STEP=1/120
local function clamp(x,a,b) return max(a,min(b,x)) end
local function norm(x,y)
    local d=sqrt(x*x+y*y)
    if d<0.000001 then return 0,0,0 end
    return x/d,y/d,d
end

-- Exact displacement factor for the simulation's decay-then-move 120 Hz tick.
function Passing.travelFactor(drag,time)
    if drag<0.000001 then return time end
    return STEP*(1-exp(-drag*time))/(exp(drag*STEP)-1)
end

-- Used by both the planner's launch check and Sim.kick. Preserve contact geometry.
function Passing.kickVelocity(s,p,tx,ty,power,action)
    local b=s.ball
    local nx,ny=norm(b.x-p.x,b.y-p.y)
    if tx and ty then
        local ax,ay=norm(tx-b.x,ty-b.y)
        if ax*nx+ay*ny>0.25 then
            nx,ny=norm(nx*0.52+ax*0.48,ny*0.52+ay*0.48)
        end
    end
    local approach=max(0,p.vx*nx+p.vy*ny)
    local multiplier=action=="pass" and s.params.passMultiplier or 1
    -- A deliberate dribble touch is shorter than a pass or shot. Keep the
    -- existing input/pass bounds while honouring the carry planner's power.
    local minimum=action=="advance" and 0.25 or 0.45
    local impulse=s.params.kickSpeed*clamp(power or 1,minimum,1.35)
        *multiplier+approach*0.12
    return b.vx+nx*impulse,b.vy+ny*impulse
end

---@class PassPlan
---@field receiver table
---@field targetX number
---@field targetY number
---@field aimX number
---@field aimY number
---@field power number
---@field flightTime number

---@return PassPlan|nil
function Passing.plan(s,p,receiver)
    local b,par=s.ball,s.params
    local best,bestCost=nil,math.huge
    -- A small bounded search accounts for lead, drag and incoming ball velocity.
    -- Prefer a receivable arrival speed, rather than maximum power for every pass.
    -- A calmer ball needs a longer flight window to keep long passes viable.
    for tick=5,50 do
        local time=tick*0.05
        local tx=clamp(receiver.x+receiver.vx*time,receiver.r,s.field.w-receiver.r)
        local ty=clamp(receiver.y+receiver.vy*time,receiver.r,s.field.h-receiver.r)
        local dx,dy=tx-b.x,ty-b.y
        local distance=sqrt(dx*dx+dy*dy)
        if distance>5.5 and distance<48 then
            local factor=Passing.travelFactor(par.ballDrag,time)
            local vx,vy=dx/factor,dy/factor
            local nx,ny,impulse=norm(vx-b.vx,vy-b.vy)
            local approach=max(0,p.vx*nx+p.vy*ny)*0.12
            local power=(impulse-approach)/(par.kickSpeed*par.passMultiplier)
            if power>=0.45 and power<=1.35 then
                local arrival=sqrt(vx*vx+vy*vy)*exp(-par.ballDrag*time)
                local cost=abs(arrival-8)+time*0.4
                if cost<bestCost then
                    bestCost=cost
                    best={receiver=receiver,targetX=tx,targetY=ty,
                        aimX=b.x+nx*10,aimY=b.y+ny*10,
                        power=power,flightTime=time}
                end
            end
        end
    end
    return best
end

function Passing.canLaunch(s,p,plan)
    local vx,vy=Passing.kickVelocity(s,p,plan.aimX,plan.aimY,plan.power,"pass")
    local factor=Passing.travelFactor(s.params.ballDrag,plan.flightTime)
    local dx=s.ball.x+vx*factor-plan.targetX
    local dy=s.ball.y+vy*factor-plan.targetY
    -- Reposition before kicking if the physical contact angle would miss.
    return dx*dx+dy*dy<(plan.receiver.r+s.ball.r-0.25)^2
end

function Passing.reset(s)
    s.passStats={}
    for team=1,2 do
        s.passStats[team]={attempts=0,completed=0,intercepted=0,missed=0}
    end
    s.activePass=nil
    s.passFeedback=nil
end

function Passing.finish(s,result,reason,player)
    local pass=s.activePass
    if not pass then return false end
    local stats=s.passStats[pass.team]
    stats[result]=stats[result]+1
    s.passFeedback={team=pass.team,result=result,reason=reason,
        number=player and player.number,at=s.elapsed}
    s.activePass=nil
    return true
end

function Passing.touch(s,p)
    local pass=s.activePass
    if not pass then return false end
    if p==pass.passer then
        -- Do not count the kicker's residual overlap as a new reception.
        if s.elapsed-pass.started<0.12 then return false end
        return Passing.finish(s,"missed","retouched",p)
    end
    return Passing.finish(s,p.team==pass.team and "completed" or "intercepted",
        "contact",p)
end

function Passing.begin(s,p,plan)
    s.passStats[p.team].attempts=s.passStats[p.team].attempts+1
    s.activePass={team=p.team,passer=p,receiver=plan and plan.receiver,
        targetX=plan and plan.targetX,targetY=plan and plan.targetY,
        started=s.elapsed,expires=s.elapsed+(plan and plan.flightTime+0.9 or 3)}
end

function Passing.update(s)
    if s.activePass and s.elapsed>=s.activePass.expires then
        Passing.finish(s,"missed","timeout")
    end
end

-- Earliest approximately reachable point on the actual, freely moving ball.
-- Recomputed after rebounds/deflections; steering still uses ordinary forces.
function Passing.receivePoint(s,p)
    local b=s.ball
    local horizon=min(1.5,max(0,s.activePass.expires-s.elapsed))
    local tx,ty=b.x,b.y
    for tick=0,15 do
        local time=min(tick*0.1,horizon)
        local factor=Passing.travelFactor(s.params.ballDrag,time)
        tx=clamp(b.x+b.vx*factor,p.r,s.field.w-p.r)
        ty=clamp(b.y+b.vy*factor,p.r,s.field.h-p.r)
        local dx,dy=tx-p.x,ty-p.y
        local reach=s.params.maxSpeed*0.80*time+p.r+b.r
        if dx*dx+dy*dy<=reach*reach or time>=horizon then break end
    end
    return tx,ty
end

return Passing
