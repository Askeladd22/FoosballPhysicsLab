-- True geometry renderer for the user's privately converted Table Soccer OBJ.
-- Each independent rod is a real GPU mesh, rotated/slid every frame from
-- model.lua. The physical game is still 2D and owns scoring/ball contacts.
-- No original or converted third-party model is included in the repository.
local ThreeD={
    loaded=false,enabled=false,error=nil,meshes={},canvas=nil,
    viewportHeight=0,viewportWidth=0,
    source="local_assets/3d/",stride=28,axisHeight=(83.2-76.64)*(560/83.56)
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
        vec3 delta = p-uEye;
        float d = dot(delta,uForward);
        const float nearPlane=2.0;
        const float farPlane=4000.0;
        float depth = (farPlane+nearPlane)/(farPlane-nearPlane)*d
                    - (2.0*farPlane*nearPlane)/(farPlane-nearPlane);
        vec3 n = VertexNormal;
        vNormal = normalize(vec3(n.x*uRotate.x-n.y*uRotate.y,
                                 n.x*uRotate.y+n.y*uRotate.x,n.z));
        return vec4(dot(delta,uRight)*uFocal/uAspect,
                    dot(delta,uUp)*uFocal,depth,d);
    }
    #endif
    #ifdef PIXEL
    vec4 effect(vec4 vertexColor, Image tex, vec2 uv, vec2 screenCoords) {
        vec3 n=normalize(vNormal);
        vec3 sunlight=normalize(vec3(-0.35,0.88,0.43));
        float diffuse=abs(dot(n,sunlight));
        float light=0.56+0.44*diffuse;
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
function ThreeD.cameraBasis()
    -- An honest perspective camera, elevated above the near side of the table.
    local eye={500,790,1240}
    local target={500,30,280}
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
    g=g or (love and love.graphics)
    filesystem=filesystem or (love and love.filesystem)
    dataAPI=dataAPI or (love and love.data)
    if not (filesystem and filesystem.getInfo and
            filesystem.getInfo(ThreeD.assetPath("table"))) then
        ThreeD.error="Pacchetto 3D assente: local_assets/3d/"
        return false
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
    print("Table Soccer TRUE 3D: 11 independent GPU meshes loaded.")
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
    local eye,right,up,forward=ThreeD.cameraBasis()
    local dx,dy,dz=x-eye[1],y-eye[2],z-eye[3]
    local depth=dx*forward[1]+dy*forward[2]+dz*forward[3]
    if depth<=2 then return nil end
    local ratio=w/height
    local focal=1/math.tan(math.rad(54)/2)
    local px=dx*right[1]+dy*right[2]+dz*right[3]
    local py=dx*up[1]+dy*up[2]+dz*up[3]
    return w/2+px*focal/ratio/depth*w/2,
        top+height/2-py*focal/depth*height/2
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
    local eye,right,up,forward=ThreeD.cameraBasis()
    lg.push("all")
    lg.setCanvas({ThreeD.canvas,depth=true})
    lg.clear(0.016,0.025,0.040,1,1,0)
    lg.setDepthMode("lequal",true)
    lg.setShader(shader)
    lg.setColor(1,1,1,1)
    shader:send("uEye",eye)
    shader:send("uRight",right)
    shader:send("uUp",up)
    shader:send("uForward",forward)
    shader:send("uAspect",w/vh)
    shader:send("uFocal",1/math.tan(math.rad(54)/2))
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
    drawMesh(lg,shader,ThreeD.meshes.ball,b.x,10,b.y,0,0.68)
    lg.setShader()
    lg.setDepthMode()
    lg.setCanvas()
    lg.pop()
    lg.setColor(1,1,1,1)
    lg.draw(ThreeD.canvas,0,top)
    -- Highlight which full 3D rod the mouse owns, never move its geometry.
    local active=match.rods[match.selected]
    local x,y=ThreeD.project(active.x,ThreeD.axisHeight+28,280+active.slide,w,h)
    if x then
        lg.setColor(1,0.76,0.35,0.90)
        lg.setLineWidth(2.5)
        lg.circle("line",x,y,19)
        lg.line(x+14,y-14,x+27,y-27)
        lg.setColor(1,1,1,1)
    end
    return true
end
return ThreeD
