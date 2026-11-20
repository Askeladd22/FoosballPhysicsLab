-- One authoritative ramp profile for pure-Lua ball physics, 2D paint and
-- 3D procedural geometry. Field coordinates: X across the goals, Y/Z long rail.
-- A low sloped floor causes a SLOW ball to roll into play, not a scripted kick.
local R={}
R.DEPTH=44
R.HEIGHT=7
R.MAX_ACCEL=240
R.GOAL_TAPER=24
local min,max,abs,ceil,sqrt=math.min,math.max,math.abs,math.ceil,math.sqrt
local function clamp(x,a,b) return max(a,min(b,x)) end

-- The short-end wedges stop outside the goal opening, including ball radius.
-- A 24-unit taper avoids a hard lip at the end of each side ramp.
local function factors(x,y,w,h,goalHalf,ballRadius)
    local d=R.DEPTH
    local up=clamp((d-y)/d,0,1)
    local down=clamp((y-(h-d))/d,0,1)
    local gate=clamp((abs(y-h/2)-goalHalf-(ballRadius or 10))/R.GOAL_TAPER,0,1)
    local left=clamp((d-x)/d,0,1)*gate
    local right=clamp((x-(w-d))/d,0,1)*gate
    return up,down,left,right
end

function R.acceleration(ball,w,h,goalHalf)
    local up,down,left,right=factors(ball.x,ball.y,w,h,goalHalf,ball.r)
    return R.MAX_ACCEL*(left-right),R.MAX_ACCEL*(up-down)
end

-- Sum of low quadratic side slopes: a corner is naturally twice-inclined.
-- Height is entirely zero in the centre and inside both goal channels.
function R.heightAt(x,y,w,h,goalHalf,ballRadius)
    local up,down,left,right=factors(x,y,w,h,goalHalf,ballRadius)
    return R.HEIGHT*(up*up+down*down+left*left+right*right)
end

function R.sections(w,h,goalHalf,ballRadius)
    local d=R.DEPTH
    local upper=h/2-goalHalf-(ballRadius or 10)
    local lower=h/2+goalHalf+(ballRadius or 10)
    return {
        {id="top",edge="top",x0=0,y0=0,x1=w,y1=d},
        {id="bottom",edge="bottom",x0=0,y0=h-d,x1=w,y1=h},
        {id="left-upper",edge="left",x0=0,y0=d,x1=d,y1=upper},
        {id="left-lower",edge="left",x0=0,y0=lower,x1=d,y1=h-d},
        {id="right-upper",edge="right",x0=w-d,y0=d,x1=w,y1=upper},
        {id="right-lower",edge="right",x0=w-d,y0=lower,x1=w,y1=h-d}
    }
end

-- Native LÖVE uses the existing shader/vertex layout, no imported meshes.
-- Split the strips in small cells to reproduce the *same* smooth heightAt
-- surface as the 2D force. Trim the end strips: never cover a goal opening.
function R.meshVertices(w,h,goalHalf,ballRadius,groundY)
    local verts={}
    groundY=groundY or 7.2
    local step=22
    local function vertex(x,z)
        local height=R.heightAt(x,z,w,h,goalHalf,ballRadius)
        local eps=0.5
        local gx=(R.heightAt(x+eps,z,w,h,goalHalf,ballRadius)
                -R.heightAt(x-eps,z,w,h,goalHalf,ballRadius))/(2*eps)
        local gz=(R.heightAt(x,z+eps,w,h,goalHalf,ballRadius)
                -R.heightAt(x,z-eps,w,h,goalHalf,ballRadius))/(2*eps)
        local nx,ny,nz=-gx,1,-gz
        local size=sqrt(nx*nx+ny*ny+nz*nz)
        -- Float color channels 0..1 are packed into the VertexColor byte4
        -- attribute by LÖVE. Smoke/glass tint leaves the physical ball legible.
        return {x,groundY+height,z,nx/size,ny/size,nz/size,0.35,0.57,0.60,0.91}
    end
    for _,sec in ipairs(R.sections(w,h,goalHalf,ballRadius)) do
        local nx=max(1,ceil((sec.x1-sec.x0)/step))
        local nz=max(1,ceil((sec.y1-sec.y0)/step))
        for ix=1,nx do
            local x0=sec.x0+(sec.x1-sec.x0)*(ix-1)/nx
            local x1=sec.x0+(sec.x1-sec.x0)*ix/nx
            for iz=1,nz do
                local z0=sec.y0+(sec.y1-sec.y0)*(iz-1)/nz
                local z1=sec.y0+(sec.y1-sec.y0)*iz/nz
                local a,b,c,d=vertex(x0,z0),vertex(x1,z0),
                    vertex(x1,z1),vertex(x0,z1)
                verts[#verts+1]=a;verts[#verts+1]=b;verts[#verts+1]=c
                verts[#verts+1]=a;verts[#verts+1]=c;verts[#verts+1]=d
            end
        end
    end
    return verts
end
return R
