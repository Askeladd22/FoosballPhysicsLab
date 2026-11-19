-- Independent LÖVE2D foosball prototype, pure Lua physics for headless tests.
-- Physical dimensions are prototype pixels, not claims about tournament equipment.
local M={}
M.W,M.H=1000,560
M.GOAL_HALF=94
M.BALL_RADIUS=10
M.FOOT_RADIUS=13
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
    return {
        team=def.team,kind=def.kind,x=def.x,offsets=def.offsets,travel=def.travel,
        slide=0,targetSlide=0,vy=0,angle=-0.70,targetAngle=-0.70,omega=0,
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
function M.new()
    local self=setmetatable({},Game)
    self:reset()
    return self
end
function Game:reset()
    self.rods={}
    for _,def in ipairs(layout) do self.rods[#self.rods+1]=newRod(def) end
    self.selected=4
    self.score={0,0}
    self.clock=0
    self.aiClock=0
    self.phase="play"
    self.phaseClock=0
    self.lastScorer=nil
    self.hits=0
    self.lastHit=nil
    self.mouseSensitivity={slide=0.83,angle=0.020}
    self:serve()
end
function Game:serve()
    -- Start next to the forward human rod, so the first test needs only a mouse swipe.
    self.ball={x=746,y=H/2,vx=0,vy=0,r=M.BALL_RADIUS}
    self.phase="play"
    self.phaseClock=0
end
function Game:selectRod(slot)
    if slot>=1 and slot<=4 and slot==math.floor(slot) then
        self.selected=slot
        return true
    end
    return false
end
function Game:mouseMoved(dx,dy)
    if self.phase~="play" then return end
    local r=self.rods[self.selected]
    dx,dy=clamp(dx or 0,-140,140),clamp(dy or 0,-140,140)
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
    -- Critically damped targets prevent teleporting or rotating instantly with dx/dy.
    local accel=(r.targetSlide-r.slide)*120-r.vy*19
    r.vy=clamp(r.vy+accel*dt,-620,620)
    r.slide=clamp(r.slide+r.vy*dt,-r.travel,r.travel)
    if r.slide==-r.travel and r.vy<0 or r.slide==r.travel and r.vy>0 then r.vy=0 end
    local acceleration=(r.targetAngle-r.angle)*180-r.omega*20
    r.omega=clamp(r.omega+acceleration*dt,-19,19)
    r.angle=clamp(r.angle+r.omega*dt,limits.min,limits.max)
    if r.angle==limits.min and r.omega<0 or r.angle==limits.max and r.omega>0 then r.omega=0 end
end
local function contact(s,rod,i)
    local b=s.ball
    local fx,fy=M.foot(rod,i)
    local dx,dy=b.x-fx,b.y-fy
    local collisionRadius=b.r+M.FOOT_RADIUS
    local d2=dx*dx+dy*dy
    if d2>=collisionRadius*collisionRadius then return end
    local d=sqrt(d2)
    local direction=rod.team==1 and 1 or -1
    local nx,ny
    if d<0.00001 then nx,ny=direction,0;d=0.00001
    else nx,ny=dx/d,dy/d end
    -- Dynamic body is the ball. The figure's constrained contact point drives it.
    local vx=direction*M.FOOT_REACH*cos(rod.angle)*rod.omega
    local vy=rod.vy
    b.x=b.x+nx*(collisionRadius-d+0.02)
    b.y=b.y+ny*(collisionRadius-d+0.02)
    local approach=(b.vx-vx)*nx+(b.vy-vy)*ny
    if approach<-3 then
        local impulse=-(1+0.78)*approach
        b.vx=b.vx+nx*impulse
        b.vy=b.vy+ny*impulse
        s.hits=s.hits+1
        s.lastHit={team=rod.team,kind=rod.kind,clock=s.clock}
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
end
M.Game=Game
return M
