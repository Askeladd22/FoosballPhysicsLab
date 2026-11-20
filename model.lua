-- Independent LÖVE2D foosball prototype, pure Lua physics for headless tests.
-- Physical dimensions are prototype pixels, not claims about tournament equipment.
local M={}
-- Native LÖVE sees foosball/ as its root; isolated root-based Lua tests do not.
local RodSelector=require("rod_selector")
M.W,M.H=1000,560
M.GOAL_HALF=94
M.BALL_RADIUS=10
M.FOOT_RADIUS=13 -- legacy nominal radius; geometry below owns the collision
M.FOOT_HALF_WIDTH=10
M.FOOT_HALF_HEIGHT=14
M.FOOT_REACH=30
local W,H=M.W,M.H
local abs,min,max,sin,cos,sqrt,exp=math.abs,math.min,math.max,math.sin,math.cos,math.sqrt,math.exp
local pi=math.pi
local function clamp(v,a,b) return max(a,min(b,v)) end
local function magnitude(x,y) return sqrt(x*x+y*y) end
local limits={min=-1.15,max=1.15}
local layout={
    {team=1,kind="Portiere",x=78,offsets={0},travel=84},
    {team=1,kind="Difesa",x=185,offsets={-145,145},travel=82},
    {team=1,kind="Centrocampo",x=430,offsets={-193,-96,0,96,193},travel=40},
    {team=1,kind="Attacco",x=710,offsets={-148,0,148},travel=74},
    {team=2,kind="Portiere IA",x=922,offsets={0},travel=84},
    {team=2,kind="Difesa IA",x=812,offsets={-145,145},travel=82},
    {team=2,kind="Centrocampo IA",x=570,offsets={-193,-96,0,96,193},travel=40},
    {team=2,kind="Attacco IA",x=288,offsets={-148,0,148},travel=74}
}
local Game={}
Game.__index=Game
local function newRod(def)
    -- The nearest figure reaches the cushion before an arbitrary invisible travel clamp.
    -- Single-figure goalkeeper retains a mechanical bearing stop, like a real table.
    local outer=0
    for _,offset in ipairs(def.offsets) do outer=max(outer,abs(offset)) end
    local cushion=H/2-outer-M.FOOT_HALF_HEIGHT-5
    local travel=#def.offsets==1 and min(132,cushion) or max(0,cushion)
    return {
        team=def.team,kind=def.kind,x=def.x,offsets=def.offsets,travel=travel,
        slide=0,targetSlide=0,vy=0,angle=-0.70,targetAngle=-0.70,omega=0,
        stopSide=0,stopPulse=0,stopCount=0,
        nextStrike=0,strikeUntil=-1,aiChoice=1
    }
end
local function figureY(rod,i)
    return H/2+rod.slide+rod.offsets[i]
end
function M.foot(rod,index)
    local direction=rod.team==1 and 1 or -1
    return rod.x+direction*M.FOOT_REACH*sin(rod.angle),figureY(rod,index)
end
function M.footRect(rod,index)
    local x,y=M.foot(rod,index)
    return x-M.FOOT_HALF_WIDTH,y-M.FOOT_HALF_HEIGHT,
        M.FOOT_HALF_WIDTH*2,M.FOOT_HALF_HEIGHT*2
end
-- An articulated side-projection of the same physical shoe. The socket
-- remains on the shaft, while body/head visually follow the angular swing.
-- This is presentation only: the colliding rectangle above is unchanged.
function M.figurePose(rod,index)
    local footX,footY=M.foot(rod,index)
    local lean=(footX-rod.x)*0.37
    local bodyX=rod.x+lean
    local headX=rod.x+lean*0.9
    return bodyX,footY,headX,footY-19
end

-- Full possible contact envelope, not just the feet's current position.
-- Because the rods cannot translate in X, some gaps are *truly unreachable*
-- despite unlimited mouse movement. Ball speed is checked separately.
function M.isBallReachable(s)
    local b=s.ball
    local xRange=M.FOOT_REACH*sin(limits.max)+M.FOOT_HALF_WIDTH+b.r+0.01
    local halfHeight=M.FOOT_HALF_HEIGHT+b.r+0.01
    for _,r in ipairs(s.rods) do
        if abs(b.x-r.x)<=xRange then
            for _,offset in ipairs(r.offsets) do
                local middle=H/2+offset
                if abs(b.y-middle)<=r.travel+halfHeight then
                    return true
                end
            end
        end
    end
    return false
end
function M.new()
    local self=setmetatable({},Game)
    self:reset()
    return self
end
function Game:reset()
    self.rods={}
    for _,def in ipairs(layout) do self.rods[#self.rods+1]=newRod(def) end
    self.selected=4
    self.controlMode="auto"
    self.controlHoldUntil=0
    self.rodSwitchedAt=0 -- short startup cooldown; no twitch at the opening serve
    self.autoRodNotice=nil
    self.score={0,0}
    self.clock=0
    self.aiClock=0
    self.phase="play"
    self.phaseClock=0
    self.lastScorer=nil
    self.hits=0
    self.lastHit=nil
    self.deadBallTimer=0
    self.deadBallCount=0
    self.deadBallLastTeam=nil
    self.deadBallNotice=nil
    self.mouseSensitivity={slide=0.83,angle=0.020}
    self:serve()
end
function Game:serve()
    -- Standard training/goal serve near the forward human rod.
    self.ball={x=746,y=H/2,vx=0,vy=0,r=M.BALL_RADIUS}
    self.phase="play"
    self.phaseClock=0
    self.deadBallTimer=0
    self.deadBallNotice=nil
    self.lastHit=nil
end

function Game:recoverDeadBall()
    -- House-rule neutral restart: award the opposite of the last striker;
    -- if nobody has touched the ball, alternate between the two teams.
    local team
    if self.lastHit and self.lastHit.team then
        team=3-self.lastHit.team
    else
        team=self.deadBallLastTeam==1 and 2 or 1
    end
    local rod=self.rods[team==1 and 3 or 7]
    local attack=team==1 and 1 or -1
    self.ball={
        x=rod.x+attack*35,
        y=H/2,
        vx=0,vy=0,r=M.BALL_RADIUS
    }
    self.deadBallTimer=0
    self.deadBallCount=self.deadBallCount+1
    self.deadBallLastTeam=team
    self.deadBallNotice={team=team,expires=self.clock+1.55}
    self.lastHit=nil
    -- Intentionally preserve the score, rod states, running match clock and phase.
    return team
end
function Game:selectRod(slot)
    if slot>=1 and slot<=4 and slot==math.floor(slot) then
        self.selected=slot
        self.controlMode="manual"
        self.rodSwitchedAt=self.clock
        self.autoRodNotice=nil
        return true
    end
    return false
end
function Game:toggleAutoRod()
    self.controlMode=self.controlMode=="auto" and "manual" or "auto"
    self.controlHoldUntil=0
    self.rodSwitchedAt=-1
    if self.controlMode=="auto" then RodSelector.update(self,true) end
    return self.controlMode
end
function Game:autoUpdate()
    return RodSelector.update(self,false)
end
function Game:mouseMoved(dx,dy)
    if self.phase~="play" then return end
    local r=self.rods[self.selected]
    dx,dy=clamp(dx or 0,-140,140),clamp(dy or 0,-140,140)
    -- Avoid changing the selected rod in the middle of a deliberate swipe.
    -- High-frequency mouse events often carry <9px deltas even in a hard shot.
    -- Treat an intentional stream of small events as a real ongoing gesture.
    if self.controlMode=="auto" and abs(dx)+abs(dy)>=3 then
        self.controlHoldUntil=self.clock+RodSelector.GESTURE_HOLD
    end
    -- Y translates the entire rod; X rotates all its figures about that rod.
    r.targetSlide=clamp(r.targetSlide+dy*self.mouseSensitivity.slide,-r.travel,r.travel)
    r.targetAngle=clamp(r.targetAngle+dx*self.mouseSensitivity.angle,limits.min,limits.max)
end
function Game:neutralRod()
    local r=self.rods[self.selected]
    r.targetAngle=0
end
local function updateAI(s)
    local b=s.ball
    for i=5,8 do
        local r=s.rods[i]
        local predictY=clamp(b.y+b.vy*0.095,18,H-18)
        local bestTarget,bestCost,bestIndex=0,math.huge,1
        for j,offset in ipairs(r.offsets) do
            local candidate=clamp(predictY-H/2-offset,-r.travel,r.travel)
            local resultingY=H/2+offset+candidate
            local cost=abs(resultingY-predictY)+abs(candidate-r.targetSlide)*0.025
            if cost<bestCost then
                bestCost,bestTarget,bestIndex=cost,candidate,j
            end
        end
        r.aiChoice=bestIndex
        r.targetSlide=bestTarget
        local near=abs(b.x-r.x)<69 and abs(b.y-(H/2+r.slide+r.offsets[bestIndex]))<55
        if near and s.clock>=r.nextStrike then
            r.targetAngle=1.09
            r.strikeUntil=s.clock+0.18
            r.nextStrike=s.clock+0.77
        elseif s.clock>=r.strikeUntil then
            r.targetAngle=-0.72
        end
    end
end
local function stepRod(r,dt)
    -- A real rod hits a mechanical end-stop; the impulse is not silently discarded.
    r.stopPulse=max(0,(r.stopPulse or 0)-dt)
    -- Human rods are direct but BOUNDED servos: the target follows the mouse
    -- within a few 120Hz ticks. The resulting physical vy/omega still drive
    -- foot-ball impulse and the two microstep collision tests.
    --
    -- AI rods deliberately retain their slower spring-like response.
    local nextSlide
    if r.team==1 then
        local error=r.targetSlide-r.slide
        local amount=clamp(error*(1-exp(-dt/0.030)),-1600*dt,1600*dt)
        nextSlide=clamp(r.slide+amount,-r.travel,r.travel)
        r.vy=(nextSlide-r.slide)/dt
    else
        local accel=(r.targetSlide-r.slide)*120-r.vy*19
        r.vy=clamp(r.vy+accel*dt,-620,620)
        nextSlide=r.slide+r.vy*dt
    end
    local side=nextSlide<=-r.travel and -1 or nextSlide>=r.travel and 1 or 0
    -- Springs approach a clamped target asymptotically: snap the final 0.55px
    -- only when the user is actively asking to push into the end stop.
    if r.targetSlide>=r.travel-0.001 and nextSlide>=r.travel-0.55 then side=1 end
    if r.targetSlide<=-r.travel+0.001 and nextSlide<=-r.travel+0.55 then side=-1 end
    if side~=0 then
        r.slide=side*r.travel
        r.vy=0
        if r.stopSide~=side then
            r.stopPulse=0.22
            r.stopCount=r.stopCount+1
        end
        r.stopSide=side
    else
        r.slide=nextSlide
        if abs(r.slide)<r.travel-2 then r.stopSide=0 end
    end
    if r.team==1 then
        local error=r.targetAngle-r.angle
        local amount=clamp(error*(1-exp(-dt/0.022)),-38*dt,38*dt)
        local nextAngle=clamp(r.angle+amount,limits.min,limits.max)
        r.omega=(nextAngle-r.angle)/dt
        r.angle=nextAngle
    else
        local acceleration=(r.targetAngle-r.angle)*180-r.omega*20
        r.omega=clamp(r.omega+acceleration*dt,-19,19)
        r.angle=clamp(r.angle+r.omega*dt,limits.min,limits.max)
        if r.angle==limits.min and r.omega<0 or r.angle==limits.max and r.omega>0 then r.omega=0 end
    end
end
local function contact(s,rod,i)
    local b=s.ball
    -- Closest-point circle versus the EXACT foot rectangle drawn on screen.
    local left,top,width,height=M.footRect(rod,i)
    local nearestX=clamp(b.x,left,left+width)
    local nearestY=clamp(b.y,top,top+height)
    local dx,dy=b.x-nearestX,b.y-nearestY
    local d2=dx*dx+dy*dy
    if d2>=b.r*b.r then return end
    local direction=rod.team==1 and 1 or -1
    local nx,ny,d
    if d2<0.000001 then
        -- If the ball centre penetrates, separate along its nearest face,
        -- not from an imaginary round foot. Bias a perfect tie toward attack.
        local dl=b.x-left
        local dr=left+width-b.x
        local dt=b.y-top
        local db=top+height-b.y
        local nearest=min(dl,dr,dt,db)
        if nearest==dl and direction<0 or nearest==dr and direction>0 then
            nx,ny=direction,0
        elseif nearest==dl then nx,ny=-1,0
        elseif nearest==dr then nx,ny=1,0
        elseif nearest==dt then nx,ny=0,-1
        else nx,ny=0,1 end
        d=-nearest
    else
        d=sqrt(d2)
        nx,ny=dx/d,dy/d
    end
    local vx=direction*M.FOOT_REACH*cos(rod.angle)*rod.omega
    local vy=rod.vy
    b.x=b.x+nx*(b.r-d+0.02)
    b.y=b.y+ny*(b.r-d+0.02)
    local approach=(b.vx-vx)*nx+(b.vy-vy)*ny
    if approach<-3 then
        local impulse=-(1+0.78)*approach
        b.vx=b.vx+nx*impulse
        b.vy=b.vy+ny*impulse
        s.hits=s.hits+1
        s.lastHit={team=rod.team,kind=rod.kind,clock=s.clock,face=nx,side=ny}
    end
end

function Game:goal(team)
    if self.phase~="play" then return end
    self.score[team]=self.score[team]+1
    self.lastScorer=team
    self.phase=self.score[team]>=5 and "finished" or "goal"
    self.phaseClock=0
end
local function stepBall(s,dt)
    local b=s.ball
    local drag=exp(-0.68*dt)
    b.vx,b.vy=b.vx*drag,b.vy*drag
    local speed=magnitude(b.vx,b.vy)
    if speed>1320 then b.vx,b.vy=b.vx*1320/speed,b.vy*1320/speed end
    if speed<1.15 then b.vx,b.vy=0,0 end
    b.x,b.y=b.x+b.vx*dt,b.y+b.vy*dt
    for _,rod in ipairs(s.rods) do
        for i=1,#rod.offsets do contact(s,rod,i) end
    end
    -- A wall is continuous except for the goal opening.
    if b.y<b.r then b.y=b.r;b.vy=abs(b.vy)*0.82 end
    if b.y>H-b.r then b.y=H-b.r;b.vy=-abs(b.vy)*0.82 end
    local inGoal=abs(b.y-H/2)<=M.GOAL_HALF-b.r
    if b.x<b.r and not inGoal then b.x=b.r;b.vx=abs(b.vx)*0.82 end
    if b.x>W-b.r and not inGoal then b.x=W-b.r;b.vx=-abs(b.vx)*0.82 end
    if inGoal and b.x<-b.r then s:goal(2) end
    if inGoal and b.x>W+b.r then s:goal(1) end
end
local DEAD_BALL_SPEED=6
local DEAD_BALL_SECONDS=2.0
M.DEAD_BALL_SECONDS=DEAD_BALL_SECONDS

local function updateDeadBall(s,dt)
    local b=s.ball
    local inside=b.x>=b.r and b.x<=W-b.r and b.y>=b.r and b.y<=H-b.r
    local slow=b.vx*b.vx+b.vy*b.vy<DEAD_BALL_SPEED*DEAD_BALL_SPEED
    if inside and slow and not M.isBallReachable(s) then
        s.deadBallTimer=s.deadBallTimer+dt
        if s.deadBallTimer>=DEAD_BALL_SECONDS then
            s:recoverDeadBall()
        end
    else
        s.deadBallTimer=0
    end
end

function Game:step(dt)
    if dt<=0 then return end
    dt=min(dt,1/30)
    self.clock=self.clock+dt
    if self.phase=="finished" then return end
    if self.phase=="goal" then
        self.phaseClock=self.phaseClock+dt
        if self.phaseClock>1.1 then self:serve() end
        return
    end
    self.aiClock=self.aiClock+dt
    if self.aiClock>=0.10 then
        self.aiClock=self.aiClock-0.10
        updateAI(self)
    end
    -- Two microsteps at the 120 Hz outer step: ball cannot leap across thin feet.
    local micro=dt/2
    for _=1,2 do
        for _,rod in ipairs(self.rods) do stepRod(rod,micro) end
        stepBall(self,micro)
        if self.phase~="play" then break end
    end
    if self.phase=="play" then
        updateDeadBall(self,dt)
        RodSelector.update(self,false)
    end
end
M.Game=Game
return M
