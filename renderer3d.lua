-- True geometry renderer for the user's privately converted Table Soccer OBJ.
-- Each independent rod is a real GPU mesh, rotated/slid every frame from
-- model.lua. The physical game is still 2D and owns scoring/ball contacts.
-- No original or converted third-party model is included in the repository.
local Model=require("model")
local ThreeD={
    loaded=false,enabled=false,error=nil,meshes={},canvas=nil,
    viewportHeight=0,viewportWidth=0,
    source="local_assets/3d/",stride=28,
    axisHeight=(83.2-76.64)*(560/83.56),
    ballHeight=16.5,ballScale=0.68,
    fovDegrees=35, -- original 3/4 SHOWCASE camera preserved
    gameplayFovDegrees=43, -- front long-rail full-table frame including legs
    cameraSide="front",
    cameraDistance=1,
    viewMode="gameplay", -- default: readable feet/ball and enlarged green pitch
    -- Rigid 180-degree Y-axis turn of the ENTIRE 3D WORLD, not the camera.
    sceneYaw=180,
    modelKind="private-original"
}
local ROLES={"goalkeeper","defence","midfield","attack"}
local FORMAT={
    {"VertexPosition","float",3},
    {"VertexNormal","float",3},
    {"VertexColor","byte",4}
}
local SHADER=[[
    extern vec3 uEye;
    extern vec3 uRight;
    extern vec3 uUp;
    extern vec3 uForward;
    extern vec3 uMove;
    extern vec2 uRotate;
    extern float uScale;
    extern float uAspect;
    extern float uFocal;
    // 1 = source orientation, -1 = 180-degree yaw around world Y at table center.
    extern float uWorldOrientation;
    // A combined LÖVE shader is compiled twice: attribute is vertex-only.
    #ifdef VERTEX
    attribute vec3 VertexNormal;
    #endif
    varying vec3 vNormal;

    #ifdef VERTEX
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
        vec3 p = vertex_position.xyz * uScale;
        p = vec3(p.x*uRotate.x-p.y*uRotate.y,
                 p.x*uRotate.y+p.y*uRotate.x,p.z);
        p += uMove;
        // Apply the SAME rigid world yaw to table, field, 8 rods and ball.
        // Local rod spin and slide happen FIRST; no physics coordinates change.
        p.x = 500.0 + (p.x - 500.0) * uWorldOrientation;
        p.z = 280.0 + (p.z - 280.0) * uWorldOrientation;
        vec3 delta = p-uEye;
        float d = dot(delta,uForward);
        const float nearPlane=2.0;
        const float farPlane=4000.0;
        float depth = (farPlane+nearPlane)/(farPlane-nearPlane)*d
                    - (2.0*farPlane*nearPlane)/(farPlane-nearPlane);
        vec3 n = VertexNormal;
        vNormal = normalize(vec3(
            (n.x*uRotate.x-n.y*uRotate.y)*uWorldOrientation,
             n.x*uRotate.y+n.y*uRotate.x,
             n.z*uWorldOrientation));
        // CRITICAL LÖVE Canvas correction: when a manually projected 3D
        // clip-space position is rendered into an offscreen Canvas and then
        // displayed with love.graphics.draw(canvas), framebuffer Y is flipped
        // relative to the screen's upper-left pixel coordinate system.
        // Before this minus sign, the whole foosball appeared UPSIDE-DOWN:
        // table legs drew above the field even though source Y was correct.
        // CPU ThreeD.project already uses screen Y = center - projected UP.
        // Negate this GPU clip-Y ONLY to match CPU projection after Canvas.
        return vec4(dot(delta,uRight)*uFocal/uAspect,
                    -dot(delta,uUp)*uFocal,depth,d);
    }
    #endif
    #ifdef PIXEL
    vec4 effect(vec4 vertexColor, Image tex, vec2 uv, vec2 screenCoords) {
        vec3 n=normalize(vNormal);
        vec3 sunlight=normalize(vec3(-0.35,0.88,0.43));
        float diffuse=abs(dot(n,sunlight));
        // Preserve the actual model's materials but lift ambient lighting
        // so a small coloured figure is distinguishable from its dark rod.
        float light=0.67+0.33*diffuse;
        return vec4(vertexColor.rgb*light,vertexColor.a);
    }
    #endif
]]
local function norm(x,y,z)
    local len=math.sqrt(x*x+y*y+z*z)
    if len<1e-6 then return 0,0,-1 end
    return x/len,y/len,z/len
end
local function cross(ax,ay,az,bx,by,bz)
    return ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx
end
-- The CC BY source model is ALREADY upright in world Y:
-- field Y≈-4, real leg bottoms Y=-740, raised rim Y=130.
-- Earlier cameras targeted only the pitch at Y=15 and could NEVER show
-- the table's support legs, producing the recurring "upside-down" illusion.
-- Frame the WHOLE table (body + 4 downward legs + pitch) from a three-
-- quarter corner view, validated with an actual render of its GLB meshes.
-- Preserve the optional 180-degree YAW; never flip vertical geometry.
local function viewportFit(w,h)
    local vh=math.max(240,(h or 850)-252)
    local aspect=(w or 1280)/vh
    -- The three-quarter pose was calibrated on the actual *full* model
    -- including Y=-740 support legs, not just the green field rectangle.
    -- Vertical framing dominates standard landscape game windows.
    return math.max(1,1.60/aspect)
end
function ThreeD.setViewMode(mode)
    assert(mode=="gameplay" or mode=="showcase","unknown 3D camera preset")
    ThreeD.viewMode=mode
    return mode
end
function ThreeD.toggleViewMode()
    return ThreeD.setViewMode(ThreeD.viewMode=="gameplay" and "showcase" or "gameplay")
end
function ThreeD.currentFovDegrees()
    return ThreeD.viewMode=="gameplay" and ThreeD.gameplayFovDegrees
        or ThreeD.fovDegrees
end
function ThreeD.resetCamera()
    ThreeD.cameraSide="front"
    ThreeD.cameraDistance=1
    ThreeD.viewMode="gameplay"
end
function ThreeD.setSceneYaw(degrees)
    assert(degrees==0 or degrees==180,"scene rotation must be 0 or 180 degrees")
    ThreeD.sceneYaw=degrees
    return degrees
end
function ThreeD.toggleSceneYaw()
    return ThreeD.setSceneYaw(ThreeD.sceneYaw==180 and 0 or 180)
end
function ThreeD.resetSceneYaw()
    return ThreeD.setSceneYaw(180)
end
-- Same rigid scene transform as the 3D shader. Y is world UP.
-- The model/physics positions are unchanged; only projected coordinates turn.
function ThreeD.worldPoint(x,y,z)
    if ThreeD.sceneYaw==180 then return 1000-x,y,560-z end
    return x,y,z
end
function ThreeD.flipCamera()
    ThreeD.cameraSide=ThreeD.cameraSide=="front" and "back" or "front"
    return ThreeD.cameraSide
end
function ThreeD.zoomCamera(delta)
    ThreeD.cameraDistance=math.max(0.80,
        math.min(1.80,ThreeD.cameraDistance+delta))
    return ThreeD.cameraDistance
end
function ThreeD.cameraBasis(w,h)
    local side=ThreeD.cameraSide=="front" and -1 or 1
    local distance=ThreeD.cameraDistance*viewportFit(w,h)
    local target,eye
    if ThreeD.viewMode=="showcase" then
        -- Presentation/inspection only: entire upright cabinet and 4 legs.
        -- Keep the verified 3/4 composition from PAUL phase 30.
        target={500,-305,280}
        eye={target[1]-1012.35*distance,
             target[2]+2119.05*distance,
             target[3]+side*1795.20*distance}
    else
        -- The real-table PHOTO shows the cabinet head-on from the LONG
        -- edge. Centre X on the table so both horizontal rails look level.
        -- Aim below the pitch to include its cabinet and four real legs.
        -- ~50-degree elevation retains a view of the green field, unlike
        -- either the old skewed 3/4 camera or a near-vertical overhead.
        -- At 1271x874 the extreme rear rim and leg tips project inside
        -- the 112..734 gameplay viewport with margin.
        target={500,-200,280}
        eye={target[1],
             target[2]+1100*distance,
             target[3]+side*915*distance}
    end
    local fx,fy,fz=norm(target[1]-eye[1],target[2]-eye[2],target[3]-eye[3])
    local rx,ry,rz=norm(cross(fx,fy,fz,0,1,0))
    local ux,uy,uz=cross(rx,ry,rz,fx,fy,fz)
    return eye,{rx,ry,rz},{ux,uy,uz},{fx,fy,fz}
end
function ThreeD.files()
    local names={"table","field","ball"}
    for _,team in ipairs({"blue","red"}) do
        for _,role in ipairs(ROLES) do
            names[#names+1]=team.."_"..role
        end
    end
    return names
end
function ThreeD.assetPath(name)
    return ThreeD.source..name..".bin"
end
function ThreeD.load(g,filesystem,dataAPI)
    ThreeD.loaded,ThreeD.enabled=false,false
    ThreeD.error=nil
    ThreeD.meshes={}
    ThreeD.axisHeight=(83.2-76.64)*(560/83.56)
    ThreeD.ballHeight,ThreeD.ballScale=16.5,0.68
    ThreeD.modelKind="private-original"
    g=g or (love and love.graphics)
    filesystem=filesystem or (love and love.filesystem)
    dataAPI=dataAPI or (love and love.data)
    if not (filesystem and filesystem.getInfo and
            filesystem.getInfo(ThreeD.assetPath("table"))) then
        ThreeD.error="Pacchetto 3D assente: local_assets/3d/"
        return false
    end
    -- CC BY 4.0 Sketchfab import: the player's rod bearings sit ~50 units
    -- above its real field, and its generated ball is already radius 10.
    -- The previous VERTX3D/OBJ mesh pack remains backwards compatible.
    if filesystem.read and filesystem.getInfo and
        filesystem.getInfo(ThreeD.source.."manifest.json") then
        local manifest=filesystem.read(ThreeD.source.."manifest.json")
        if type(manifest)=="string" and
            manifest:find("5f70863c2cf74e99ad084a493209dbac",1,true) then
            ThreeD.axisHeight=50.0
            ThreeD.ballHeight,ThreeD.ballScale=10.0,1.0
            ThreeD.modelKind="cc-by-glb"
        end
    end
    if not (g and g.newShader and g.newMesh and dataAPI and dataAPI.newByteData) then
        ThreeD.error="GPU / API LÖVE 11.5 per mesh 3D non disponibili"
        return false
    end
    local ok,err=pcall(function()
        local shader=g.newShader(SHADER)
        local meshes={}
        for _,name in ipairs(ThreeD.files()) do
            local path=ThreeD.assetPath(name)
            local raw,size=filesystem.read(path)
            if type(raw)~="string" or #raw%ThreeD.stride~=0
                 or #raw==0 or #raw>55*1024*1024 then
                error("Invalid or missing private 3D mesh: "..path)
            end
            local count=#raw/ThreeD.stride
            if count%3~=0 then error("non-triangular 3D mesh: "..path) end
            local mesh=g.newMesh(FORMAT,count,"triangles","static")
            mesh:setVertices(dataAPI.newByteData(raw))
            meshes[name]=mesh
        end
        -- A small native GPU floor mesh (not a decal) mirrors the same
        -- mathematical slope applied to the ball in model.lua. Retain every
        -- original third-party field, rod, table and ball mesh unchanged.
        -- Build the slope at the ball's actual ground-contact altitude.
        -- A fixed positive field Y would float above the imported GLB
        -- and mask the ball from a steep gameplay camera.
        local rampGround=ThreeD.ballHeight-Model.BALL_RADIUS
        local rampVerts=Model.Ramps.meshVertices(Model.W,Model.H,
            Model.GOAL_HALF,Model.BALL_RADIUS,rampGround)
        assert(#rampVerts>0 and #rampVerts%3==0,"invalid ramp triangles")
        local rampMesh=g.newMesh(FORMAT,#rampVerts,"triangles","static")
        rampMesh:setVertices(rampVerts)
        meshes.ramps=rampMesh
        ThreeD.shader=shader
        ThreeD.meshes=meshes
    end)
    if not ok then
        ThreeD.error=tostring(err)
        ThreeD.meshes={}
        print("Table Soccer 3D load error: "..ThreeD.error)
        return false
    end
    ThreeD.loaded,ThreeD.enabled=true,true
    print("Table Soccer TRUE 3D: 11 independent GPU meshes loaded ("..
        ThreeD.modelKind..").")
    return true
end
function ThreeD.active()
    return ThreeD.loaded and ThreeD.enabled
end
function ThreeD.toggle()
    if not ThreeD.loaded then return false end
    ThreeD.enabled=not ThreeD.enabled
    return ThreeD.enabled
end
local function drawMesh(lg,shader,mesh,x,y,z,angle,scale)
    shader:send("uMove",{x,y,z})
    shader:send("uRotate",{math.cos(angle),math.sin(angle)})
    shader:send("uScale",scale or 1)
    lg.draw(mesh)
end
function ThreeD.viewport(w,h)
    return 112,math.max(240,math.floor(h-252))
end
function ThreeD.project(x,y,z,w,h)
    local top,height=ThreeD.viewport(w,h)
    local eye,right,up,forward=ThreeD.cameraBasis(w,h)
    x,y,z=ThreeD.worldPoint(x,y,z)
    local dx,dy,dz=x-eye[1],y-eye[2],z-eye[3]
    local depth=dx*forward[1]+dy*forward[2]+dz*forward[3]
    if depth<=2 then return nil end
    local ratio=w/height
    local focal=1/math.tan(math.rad(ThreeD.currentFovDegrees())/2)
    local px=dx*right[1]+dy*right[2]+dz*right[3]
    local py=dx*up[1]+dy*up[2]+dz*up[3]
    return w/2+px*focal/ratio/depth*w/2,
        top+height/2-py*focal/depth*height/2
end
-- Authoritative projected contact markers: the highlighted toe centers are
-- read from the SAME model.foot used by ball/foot collision resolution.
function ThreeD.playerIndicators(match,w,h)
    local r=assert(match.rods[match.selected],"selected physical rod missing")
    local x1,y1=ThreeD.project(r.x,ThreeD.axisHeight,0,w,h)
    local x2,y2=ThreeD.project(r.x,ThreeD.axisHeight,560,w,h)
    local feet={}
    for i=1,#r.offsets do
        local fx,fz=Model.foot(r,i)
        local px,py=ThreeD.project(fx,ThreeD.ballHeight,fz,w,h)
        feet[#feet+1]={x=px,y=py,worldX=fx,worldZ=fz}
    end
    return {shaft={x1,y1,x2,y2},feet=feet}
end
function ThreeD.ballIndicator(match,w,h)
    local ball=match.ball
    local lift=Model.Ramps.heightAt(ball.x,ball.y,Model.W,Model.H,
        Model.GOAL_HALF,ball.r)
    local px,py=ThreeD.project(ball.x,ThreeD.ballHeight+5+lift,ball.y,w,h)
    local futureX,futureY=ball.x+ball.vx*0.09,ball.y+ball.vy*0.09
    local futureLift=Model.Ramps.heightAt(futureX,futureY,Model.W,Model.H,
        Model.GOAL_HALF,ball.r)
    local vx,vy=ThreeD.project(futureX,
        ThreeD.ballHeight+5+futureLift,futureY,w,h)
    return {x=px,y=py,velocityX=vx,velocityY=vy,
            worldX=ball.x,worldZ=ball.y}
end
function ThreeD.draw(match,w,h)
    if not ThreeD.active() then return false end
    local lg=love.graphics
    local top,vh=ThreeD.viewport(w,h)
    if not ThreeD.canvas or ThreeD.viewportWidth~=w or ThreeD.viewportHeight~=vh then
        -- Only allocate on resize; depth is attached during setCanvas.
        ThreeD.canvas=lg.newCanvas(w,vh,{format="rgba8",msaa=0})
        ThreeD.viewportWidth,ThreeD.viewportHeight=w,vh
    end
    local shader=ThreeD.shader
    local eye,right,up,forward=ThreeD.cameraBasis(w,h)
    lg.push("all")
    lg.setCanvas({ThreeD.canvas,depth=true})
    -- CRITICAL: lequal depth testing only draws fragments <= the stored depth.
    -- Clearing depth to 0 made *every real 3D mesh invisible* on the user's PC.
    -- Initialize stencil=0 and depth=1 (the farthest possible depth).
    lg.clear(0.016,0.025,0.040,1,0,1)
    lg.setDepthMode("lequal",true)
    lg.setShader(shader)
    lg.setColor(1,1,1,1)
    shader:send("uEye",eye)
    shader:send("uRight",right)
    shader:send("uUp",up)
    shader:send("uForward",forward)
    shader:send("uAspect",w/vh)
    -- Keep overlay projection and actual GPU shader on the SAME preset FOV.
    shader:send("uFocal",1/math.tan(math.rad(ThreeD.currentFovDegrees())/2))
    shader:send("uWorldOrientation",ThreeD.sceneYaw==180 and -1 or 1)
    drawMesh(lg,shader,ThreeD.meshes.table,0,0,0,0,1)
    drawMesh(lg,shader,ThreeD.meshes.field,0,0,0,0,1)
    for i,r in ipairs(match.rods) do
        local team=i<=4 and "blue" or "red"
        local key=team.."_"..ROLES[(i-1)%4+1]
        drawMesh(lg,shader,ThreeD.meshes[key],r.x,ThreeD.axisHeight,
                 280+r.slide,r.angle,1)
    end
    -- This is the source OBJ's real spherical mesh, animated at the precise
    -- physical ball X/Y; its radius is scaled to ~10 game units.
    local b=match.ball
    -- The imported field's visible surface is at ~6.5 world Y. With a
    -- ~10-unit scaled mesh radius, 16.5 seats the real sphere on the field.
    local rampHeight=Model.Ramps.heightAt(b.x,b.y,Model.W,Model.H,
        Model.GOAL_HALF,b.r)
    drawMesh(lg,shader,ThreeD.meshes.ball,b.x,
        ThreeD.ballHeight+rampHeight,b.y,0,ThreeD.ballScale)
    -- Depth-tested true 3D slopes; they remain under the visible ball.
    drawMesh(lg,shader,ThreeD.meshes.ramps,0,0,0,0,1)
    lg.setShader()
    lg.setDepthMode()
    lg.setCanvas()
    lg.pop()
    lg.setColor(1,1,1,1)
    lg.draw(ThreeD.canvas,0,top)
    if ThreeD.viewMode=="gameplay" then
        -- Minimal world-anchored feedback: distinguish the selected rod,
        -- its *physical* striking feet, and the actual moving ball.
        -- No changes to native mesh, angle, slide or collision rectangles.
        local marker=ThreeD.playerIndicators(match,w,h)
        local shaft=marker.shaft
        if shaft[1] and shaft[3] then
            lg.setLineWidth(5)
            lg.setColor(0.01,0.025,0.04,0.80)
            lg.line(shaft[1],shaft[2],shaft[3],shaft[4])
            lg.setLineWidth(2.2)
            lg.setColor(1,0.77,0.28,0.85)
            lg.line(shaft[1],shaft[2],shaft[3],shaft[4])
        end
        for _,foot in ipairs(marker.feet) do
            if foot.x then
                lg.setColor(0.01,0.025,0.04,0.80)
                lg.setLineWidth(3.0)
                lg.circle("line",foot.x,foot.y,8)
                lg.setColor(1,0.78,0.29,0.95)
                lg.setLineWidth(1.8)
                lg.circle("line",foot.x,foot.y,7)
            end
        end
        local ball=ThreeD.ballIndicator(match,w,h)
        if ball.x then
            lg.setColor(0.01,0.035,0.045,0.90)
            lg.setLineWidth(4.0)
            lg.circle("line",ball.x,ball.y,13)
            lg.setColor(0.93,0.98,0.83,0.96)
            lg.setLineWidth(2)
            lg.circle("line",ball.x,ball.y,12)
            if ball.velocityX then
                local dx,dy=ball.velocityX-ball.x,ball.velocityY-ball.y
                if dx*dx+dy*dy>16 then
                    lg.setColor(0.93,0.98,0.83,0.66)
                    lg.setLineWidth(2)
                    lg.line(ball.x,ball.y,ball.velocityX,ball.velocityY)
                end
            end
        end
    else
        -- A light-touch identifier when inspecting the complete furniture.
        local active=match.rods[match.selected]
        local x,y=ThreeD.project(active.x,ThreeD.axisHeight+28,280+active.slide,w,h)
        if x then
            lg.setColor(1,0.76,0.35,0.90)
            lg.setLineWidth(2.5)
            lg.circle("line",x,y,19)
            lg.line(x+14,y-14,x+27,y-27)
        end
    end
    lg.setColor(1,1,1,1)
    return true
end
-- Native image semantic test: green FIELD pixels at known field coordinates
-- (the third-party GLB's ground plane), not just arbitrary nonblack table
-- wall pixels. An occluding near rail must not pass the game-readability gate.
function ThreeD.assertFieldVisible()
    assert(ThreeD.active() and ThreeD.canvas,
        "Cannot verify 3D pitch without an active render target")
    local image=ThreeD.canvas:newImageData()
    local w,h=image:getDimensions()
    local screenH=h+252
    local top=ThreeD.viewport(w,screenH)
    local green,total=0,0
    local nearGreen,nearTotal=0,0
    local farGreen,farTotal=0,0
    for iz=1,9 do
        local z=45+iz*47
        for ix=1,11 do
            local x=75+ix*71
            -- GLB field material is y ~ -4 after import; the 180° world yaw
            -- is handled inside ThreeD.project exactly as the GPU shader.
            local px,py=ThreeD.project(x,-4,z,w,screenH)
            if px and py then
                local rx=math.floor(px+0.5)
                local ry=math.floor(py-top+0.5)
                if rx>=0 and rx<w and ry>=0 and ry<h then
                    local cr,cg,cb=image:getPixel(rx,ry)
                    local isGreen=cg>0.15 and cg>cr*1.35
                        and cb>cr*1.15
                    total=total+1
                    if isGreen then green=green+1 end
                    if iz<=3 then
                        nearTotal=nearTotal+1
                        if isGreen then nearGreen=nearGreen+1 end
                    elseif iz>=7 then
                        farTotal=farTotal+1
                        if isGreen then farGreen=farGreen+1 end
                    end
                end
            end
        end
    end
    print(("3D FIELD visibility: green=%d/%d, near=%d/%d, far=%d/%d"):format(
        green,total,nearGreen,nearTotal,farGreen,farTotal))
    -- Front-on GAMEPLAY must retain a readable green pitch even while
    -- showing the full cabinet and support legs. Preserve the older
    -- SHOWCASE threshold because that mode prioritises furniture.
    local minimumGreen=ThreeD.viewMode=="gameplay" and 0.55 or 0.46
    assert(total>=75 and green>=math.floor(total*minimumGreen)
        and nearGreen>=math.floor(nearTotal*0.25)
        and farGreen>=math.floor(farTotal*0.25),
        "3D PITCH OCCLUDED: actual green playing surface not visible. Check perspective/rail geometry, not only frame pixels.")
    return green,total
end

-- Verify the gameplay view contains real UNDER-TABLE SUPPORTS as well as
-- the green pitch. Generic "non-black framebuffer" tests previously accepted
-- views with no table legs. This gate runs only for the actual CC BY GLB.
function ThreeD.assertLegVisible()
    assert(ThreeD.active() and ThreeD.canvas,"3D leg test requires a GPU frame")
    local image=ThreeD.canvas:newImageData()
    local w,vh=image:getDimensions()
    local screenH=vh+252
    local top=ThreeD.viewport(w,screenH)
    local present=0
    for _,leg in ipairs({{0,0},{0,560},{1000,0},{1000,560}}) do
        -- The real GLB legs go to Y=-740. Inspect their solid dark section at
        -- Y=-590, *far below the green pitch* at roughly Y=-4.
        local x,y=ThreeD.project(leg[1],-590,leg[2],w,screenH)
        local hits=0
        if x and y then
            local cx,cy=math.floor(x+0.5),math.floor(y-top+0.5)
            for dy=-18,18,3 do
                for dx=-18,18,3 do
                    local px,py=cx+dx,cy+dy
                    if px>=0 and px<w and py>=0 and py<vh then
                        local red,green,blue=image:getPixel(px,py)
                        if red>0.075 and green>0.075 and blue>0.075 then
                            hits=hits+1
                        end
                    end
                end
            end
        end
        if hits>=8 then present=present+1 end
    end
    print(("3D UNDER-TABLE LEGS visible: %d/4"):format(present))
    assert(present>=3,
        "3D FULL TABLE NOT VISIBLE: less than 3 of 4 support legs have projected GPU geometry")
    return present
end

-- Capture a real LÖVE software/hardware GPU frame into the game save
-- directory for native CI review, not a fabricated mock screenshot.
function ThreeD.captureFrame()
    assert(ThreeD.canvas,"no true-3D frame to capture")
    local image=ThreeD.canvas:newImageData()
    local encoded=image:encode("png")
    assert(love.filesystem.write("foosball_3d_camera.png",encoded:getString()),
        "failed to save native GPU screenshot")
    print("NATIVE_3D_SCREENSHOT: "..love.filesystem.getSaveDirectory()..
        "/foosball_3d_camera.png")
end

-- CI / developer-only GPU readback. The old smoke passed with a totally
-- black frame because it only counted callbacks, never visible pixels.
function ThreeD.assertVisible()
    assert(ThreeD.active() and ThreeD.canvas,
        "Cannot verify visibility without an active true-3D Canvas")
    local image=ThreeD.canvas:newImageData()
    local w,h=image:getDimensions()
    local lit,total=0,0
    for j=3,17 do
        local y=math.floor((j/20)*h)
        for i=2,18 do
            local x=math.floor((i/20)*w)
            local r,g,b=image:getPixel(x,y)
            -- Compare with the documented 3D background, NOT full black:
            -- antialiasing variations are tolerated.
            if r>0.095 or g>0.12 or b>0.16 then lit=lit+1 end
            total=total+1
        end
    end
    print(("3D GPU visible pixel probes: %d/%d"):format(lit,total))
    assert(lit>=6,
        "3D EMPTY FRAME: GPU mesh loading succeeded but no geometry appeared. Check depth, camera and shaders.")
    return lit,total
end
return ThreeD
