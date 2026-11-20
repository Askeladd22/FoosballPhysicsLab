-- Optional local-only 2.5D renders baked from the user's own Table Soccer ZIP.
-- All source geometry and produced sprites stay in gitignored local_assets/.
-- Physics remains authoritative in model.lua. No meshes are redistributed.
local Art={enabled=true,loaded=false,frameCount=9,rodFrames={},tableImage=nil,source=nil}
local roles={"goalkeeper","defence","midfield","attack"}
local function exists(path)
    return love and love.filesystem and love.filesystem.getInfo and
        love.filesystem.getInfo(path)~=nil
end
local function loadImage(path)
    if not exists(path) or not love.graphics or not love.graphics.newImage then return nil end
    local ok,image=pcall(love.graphics.newImage,path)
    if not ok then return nil end
    if image.setFilter then image:setFilter("linear","linear") end
    return image
end
function Art.load()
    Art.loaded=false
    Art.rodFrames={}
    Art.tableImage=nil
    local prefix=nil
    for _,candidate in ipairs({"experiments/foosball/local_assets/","local_assets/"}) do
        if exists(candidate.."manifest.json") then prefix=candidate;break end
    end
    if not prefix then return false end
    local tableImage=loadImage(prefix.."table.png")
    if not tableImage then return false end
    local all={}
    for i=1,8 do
        local team=i<=4 and "blue" or "red"
        local role=roles[(i-1)%4+1]
        local frames={}
        for pose=0,Art.frameCount-1 do
            local filename=string.format("%srods/%s_%s_%02d.png",prefix,team,role,pose)
            local image=loadImage(filename)
            if not image then
                -- One missing frame invalidates the whole pack; fallback is safe.
                return false
            end
            frames[#frames+1]=image
        end
        all[i]=frames
    end
    Art.source=prefix
    Art.tableImage=tableImage
    Art.rodFrames=all
    Art.loaded=true
    Art.enabled=true
    return true
end
function Art.active()
    return Art.loaded and Art.enabled
end
function Art.toggle()
    if not Art.loaded then return false end
    Art.enabled=not Art.enabled
    return Art.enabled
end
function Art.drawTable(lg)
    if not Art.active() or not Art.tableImage then return false end
    -- Ghosted render of source table geometry under the Neon Glass line art.
    -- An opaque prop would duplicate fixed rods and hide the physics view.
    lg.setColor(1,1,1,0.12)
    lg.draw(Art.tableImage,0,0)
    lg.setColor(1,1,1,1)
    return true
end
function Art.drawRod(lg,rod,index)
    if not Art.active() then return false end
    local frames=Art.rodFrames[index]
    if not frames then return false end
    -- Alpha-blend two nearest pre-baked 3D poses for smooth rotation.
    local t=math.max(0,math.min(Art.frameCount-1,
        (rod.angle+1.15)/2.30*(Art.frameCount-1)))
    local low=math.floor(t)+1
    local high=math.min(low+1,Art.frameCount)
    local alpha=t-(low-1)
    local x=rod.x-64
    local y=rod.slide -- each 128×560 sprite is anchored at the physical shaft
    lg.setColor(1,1,1,0.96*(1-alpha))
    lg.draw(frames[low],x,y)
    if alpha>0 and high~=low then
        lg.setColor(1,1,1,0.96*alpha)
        lg.draw(frames[high],x,y)
    end
    lg.setColor(1,1,1,1)
    return true
end
return Art
