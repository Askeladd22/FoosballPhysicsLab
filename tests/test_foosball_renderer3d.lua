-- PAUL25: actual GPU mesh load, eight separate animated rigs, pure-Lua mock.
package.path="./?.lua;./?/init.lua;"..package.path
local ThreeD=require("renderer3d")
local Model=require("model")
local fake={files={},draws={},sends={},depth=false}
local shader={send=function(_,name,value)
    fake.sends[#fake.sends+1]={name,value}
end}
local graphics={
    newShader=function(source)
        assert(source:find("vertex_position.xyz",1,true),"3D geometry vertex shader absent")
        assert(source:find("uFocal",1,true),"perspective projection absent")
        assert(source:find("VertexNormal",1,true),"lighting absent")
        return shader
    end,
    newMesh=function(format,count,mode,usage)
        assert(format[1][1]=="VertexPosition" and format[1][3]==3)
        assert(format[2][1]=="VertexNormal" and format[2][3]==3)
        assert(count==3 and mode=="triangles" and usage=="static")
        return {kind="mesh",setVertices=function(_,data)
            assert(#data==84,"incorrect private GPU data stride")
        end}
    end,
    newCanvas=function(w,h)
        return {kind="canvas",w=w,h=h}
    end,
    push=function() end, pop=function() end,
    setCanvas=function(arg)
        if type(arg)=="table" and not arg.kind then
            assert(arg.depth==true,"real depth buffer not requested")
            fake.depth=true
        end
    end,
    clear=function() end,
    setDepthMode=function(mode,write)
        if mode=="lequal" then assert(write) end
    end,
    setShader=function() end,
    setColor=function() end,
    setLineWidth=function() end,
    circle=function() end,line=function() end,
    draw=function(thing)
        fake.draws[#fake.draws+1]=thing
    end
}
local files={getInfo=function(path)
    if path:match("^local_assets/3d/.*%.bin$") then return {type="file"} end
end,
read=function(path)
    fake.files[#fake.files+1]=path
    return string.rep("A",84),84
end}
local data={newByteData=function(raw) return raw end}
assert(ThreeD.load(graphics,{getInfo=function() end},data)==false)
assert(not ThreeD.active(),"should stay off without third-party model")
assert(ThreeD.load(graphics,files,data),"eleven independent GPU meshes failed to load")
assert(ThreeD.loaded and ThreeD.active())
assert(#fake.files==11 and #ThreeD.files()==11)
assert(ThreeD.meshes.blue_midfield~=ThreeD.meshes.red_midfield)
assert(ThreeD.meshes.table and ThreeD.meshes.field and ThreeD.meshes.ball)
assert(ThreeD.toggle()==false and ThreeD.toggle()==true,"P 3D/2D toggle failed")
local match=Model.new()
local before=match.rods[4].slide
match:selectRod(4)
match:mouseMoved(55,-17)
for i=1,5 do match:step(1/120) end
assert(match.rods[4].slide~=before,"actual mouse motion must drive rod translation")
local oldLove=love
love={graphics=graphics}
assert(ThreeD.draw(match,1280,850),"3D render did not run")
assert(fake.depth,"renderer did not render into depth-enabled target")
assert(#fake.draws==12,"expected static table+field, 8 moving rods, ball, and color canvas")
local rodTranslations={}
for i,send in ipairs(fake.sends) do
    if send[1]=="uMove" then
        rodTranslations[#rodTranslations+1]=send[2]
    end
end
assert(#rodTranslations==11,"rig transform not sent for every 3D mesh")
assert(math.abs(rodTranslations[7][1]-match.rods[4].x)<0.001,
       "attacker x must follow 2D collision rod origin")
assert(math.abs(rodTranslations[7][3]-(280+match.rods[4].slide))<0.001,
       "attacker slide not reflected in 3D position")
assert(math.abs(rodTranslations[11][1]-match.ball.x)<0.001 and
       math.abs(rodTranslations[11][3]-match.ball.y)<0.001,
       "mesh ball must match actual 2D physical position")
local px,py=ThreeD.project(500,15,280,1280,850)
assert(px>100 and px<1180 and py>0 and py<850,
       "camera projected game center off-screen")
love=oldLove
print("PASS: real GPU mesh contract, 8 moving 3D rods, ball, depth and perspective")
