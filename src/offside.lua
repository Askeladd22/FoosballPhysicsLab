-- Law 11 adapted to a top-down disc model. Position uses disc centres.
-- A stored position is not an offence until the player becomes involved.
local Offside={}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
function Offside.line(s,team)
    local defenders={}
    for _,p in ipairs(s.players) do
        if p.team~=team then defenders[#defenders+1]=clamp(p.x,0,s.field.w) end
    end
    table.sort(defenders,function(a,b) if team==1 then return a>b else return a<b end end)
    local second=defenders[2] or (team==1 and s.field.w or 0)
    if team==1 then return math.max(s.field.w/2,second,s.ball.x) end
    return math.min(s.field.w/2,second,s.ball.x)
end
function Offside.inPosition(s,p)
    local line=Offside.line(s,p.team)
    return p.team==1 and p.x>line+0.001 or p.team==2 and p.x<line-0.001
end
local function snapshot(s,passer)
    local line=Offside.line(s,passer.team)
    local candidates={}
    for _,p in ipairs(s.players) do
        if p.team==passer.team and p~=passer and
            ((p.team==1 and p.x>line+0.001) or (p.team==2 and p.x<line-0.001)) then
            candidates[p]=true
        end
    end
    return {team=passer.team,line=line,candidates=candidates}
end
function Offside.capture(s,passer,exempt)
    s.offsidePhases={}
    s.offside=not exempt and snapshot(s,passer) or nil
    s.offsidePhases[passer.team]=s.offside
end
function Offside.phase(s,team)
    return s.offsidePhases and s.offsidePhases[team] or
        (s.offside and s.offside.team==team and s.offside or nil)
end
function Offside.involved(s,p)
    local phase=Offside.phase(s,p.team)
    return phase and phase.candidates[p] or false
end
-- A deliberate opponent kick resets the phase; a rebound/deflection does not.
function Offside.touch(s,p,deliberate,exempt)
    if deliberate or exempt then
        Offside.capture(s,p,exempt)
    else
        -- A deflection can create candidates on the other team without
        -- cancelling the original phase (including rebounds from a save).
        s.offsidePhases=s.offsidePhases or {}
        s.offside=snapshot(s,p)
        s.offsidePhases[p.team]=s.offside
    end
end
return Offside
