-- Contact-only first touch and shielding. No owner, attachment or attraction.
-- The player must place their body between pressure and the freely moving ball.
local Control={}
local sqrt,max,min=math.sqrt,math.max,math.min
local function length(x,y) return sqrt(x*x+y*y) end
local function requested(s,p)
    -- Human input is explicit; do not silently take over an AI/human receiver.
    return p==s.controlled and p.protectInput==true
end

function Control.update(s,p,dt)
    p.controlCooldown=max(0,(p.controlCooldown or 0)-dt)
    p.controlFlash=max(0,(p.controlFlash or 0)-dt)
    local b=s.ball
    local nearby=length(b.x-p.x,b.y-p.y)<=p.r+b.r+1.8
    p.shielding=s.phase=="play" and requested(s,p) and nearby
    p.controlMoveScale=p.shielding and 0.55 or 1
end

function Control.contact(s,p,incomingVx,incomingVy,receiving)
    local aiReception=p~=s.controlled and receiving==true
    if s.phase~="play" or not (requested(s,p) or aiReception) or (p.controlCooldown or 0)>0 then return false end
    local b=s.ball
    local dx,dy=b.x-p.x,b.y-p.y
    local d=length(dx,dy)
    -- resolvePair has already removed penetration; tolerate only rounding.
    if d<0.00001 or d>p.r+b.r+0.0001 then return false end
    local nx,ny=dx/d,dy/d
    local rvx,rvy=incomingVx-p.vx,incomingVy-p.vy
    if rvx*nx+rvy*ny>0.2 then return false end -- ball already departing

    -- A challenger on the ball side can win it. Protection never increases
    -- body mass, ignores opponents, or pulls a tackled ball back to the player.
    for _,other in ipairs(s.players) do
        if other.team~=p.team then
            local ox,oy=other.x-p.x,other.y-p.y
            if ox*nx+oy*ny>0 and length(other.x-b.x,other.y-b.y)<d then
                return false
            end
        end
    end

    local mx,my=p.moveX or 0,p.moveY or 0
    local magnitude=length(mx,my)
    if magnitude>1 then mx,my=mx/magnitude,my/magnitude end
    -- Keep the ball outside the body, and let direction input choose the
    -- tangent of the first touch. A stationary trap rolls gently outward.
    local along=mx*nx+my*ny
    local tx,ty=mx-nx*along,my-ny*along
    -- Do not copy recoil away from the ball into the first touch: that would
    -- turn a small rebound into a faster backwards-moving ball. Carry forward
    -- motion and half of lateral movement, retaining an outward rolling gap.
    local playerNormal=p.vx*nx+p.vy*ny
    local outward=max(0,playerNormal)+0.9
    local targetX=nx*outward+(p.vx-nx*playerNormal)*0.5+tx*3.2
    local targetY=ny*outward+(p.vy-ny*playerNormal)*0.5+ty*3.2
    if aiReception then targetX,targetY=nx*0.45,ny*0.45 end
    local changeX,changeY=targetX-b.vx,targetY-b.vy
    local change=length(changeX,changeY)
    local maxChange=14
    if change>maxChange then changeX,changeY=changeX*maxChange/change,changeY*maxChange/change end
    b.vx,b.vy=b.vx+changeX,b.vy+changeY
    p.controlCooldown=0.22
    p.controlFlash=0.18
    p.shielding=true
    return true
end

return Control
