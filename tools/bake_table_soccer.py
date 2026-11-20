#!/usr/bin/env python3
"""Private Table Soccer ZIP -> optional 2.5D PNGs for Foosball Lab.

Requires Pillow for baking (python -m pip install Pillow). Inspection and tests
use the standard library only. No original or converted mesh is tracked in Git.
VERTX3D's 2014 Readme forbids redistributing the model, in whole or in part.
Use generated assets locally; get author permission before distribution.
"""
import argparse
from collections import defaultdict
import hashlib
import io
import json
import math
from pathlib import Path
import tempfile
import zipfile

ROLES = ("Goalkeeper", "Defence", "Midfield", "Attack")
GROUPS = tuple("TS_%s_Team_%s" % (team, role)
               for team in ("Blue", "Red") for role in ROLES)
STATIC = ("TS_Main", "TS_Field")
NEEDED = set(GROUPS + STATIC)
FRAMES = 9
COLORS = {"Metal":(124,168,181),"Plastic_Black":(35,51,67),
          "Plastic_White":(224,238,231),"Table":(32,51,68),
          "FIELD":(26,113,128),"Blue_Team":(29,197,237),
          "Red_Team":(239,74,88),"Ball":(238,243,216)}
def load_mesh(archive):
    vertices=[]
    faces=defaultdict(list)
    group,material="",""
    with zipfile.ZipFile(archive) as z:
        names=[name for name in z.namelist()
               if name.endswith("Table_Soccer.obj") and "POSERversion/" not in name]
        if len(names)!=1:
            raise ValueError("Expected root Table_Soccer.obj in original ZIP")
        if z.getinfo(names[0]).file_size>120_000_000:
            raise ValueError("Unexpectedly large OBJ")
        with io.TextIOWrapper(z.open(names[0]),encoding="latin-1") as stream:
            for line in stream:
                if line.startswith("v "):
                    _,x,y,zz=line.split()[:4]
                    vertices.append((float(x),float(y),float(zz)))
                elif line.startswith("g "):
                    group=line[2:].strip()
                elif line.startswith("usemtl "):
                    material=line[7:].strip().split(":")[-1]
                elif line.startswith("f ") and group in NEEDED:
                    refs=[int(v.split("/")[0])-1 for v in line.split()[1:]]
                    for i in range(1,len(refs)-1):
                        faces[group].append((refs[0],refs[i],refs[i+1],material))
    missing=NEEDED-set(faces)
    if missing:
        raise ValueError("Missing Table Soccer groups: "+", ".join(sorted(missing)))
    return vertices,faces

def render(vertices,triangles,group,angle=0.0,size=(128,560)):
    try:
        from PIL import Image,ImageDraw
    except ImportError as error:
        raise SystemExit("Install Pillow to bake locally: python -m pip install Pillow") from error
    w,h=size
    static=group in STATIC
    ids={idx for a,b,c,_ in triangles for idx in (a,b,c)}
    center_z=0 if static else (
        min(vertices[idx][2] for idx in ids)+max(vertices[idx][2] for idx in ids))/2
    team_dir=-1 if "_Red_" in group else 1
    cosine,sine=math.cos(angle*team_dir),math.sin(angle*team_dir)
    xscale,yscale=1000/(2*68.7),560/(2*41.78)
    projected,heights={},{}
    for idx in ids:
        x,y,z=vertices[idx]
        if static:
            projected[idx]=(w/2+z*xscale,h/2+x*yscale)
            heights[idx]=y
        else:
            dz,zheight=z-center_z,y-83.2
            turned_z=dz*cosine-zheight*sine*0.68
            turned_y=zheight*cosine+dz*sine
            projected[idx]=(w/2+turned_z*xscale,h/2+x*yscale-turned_y*0.25)
            heights[idx]=83.2+turned_y
    ordered=[]
    for a,b,c,material in triangles:
        ax,ay,az=vertices[a];bx,by,bz=vertices[b];cx,cy,cz=vertices[c]
        ux,uy,uz=bx-ax,by-ay,bz-az
        vx,vy,vz=cx-ax,cy-ay,cz-az
        ny=uz*vx-ux*vz
        normal=math.sqrt((uy*vz-uz*vy)**2+ny**2+(ux*vy-uy*vx)**2) or 1.0
        bright=0.63+0.33*max(0,min(1,abs(ny/normal)))
        color=tuple(min(255,int(channel*bright+4))
                    for channel in COLORS.get(material,(105,120,130)))+(246,)
        ordered.append(((heights[a]+heights[b]+heights[c])/3,
                        projected[a],projected[b],projected[c],color))
    ordered.sort(key=lambda item:item[0])
    image=Image.new("RGBA",(w,h),(0,0,0,0))
    draw=ImageDraw.Draw(image,"RGBA")
    for _,a,b,c,color in ordered:
        xs=(a[0],b[0],c[0]);ys=(a[1],b[1],c[1])
        if max(xs)<0 or min(xs)>w or max(ys)<0 or min(ys)>h:
            continue
        draw.polygon((a,b,c),fill=color)
    return image

def bake(source,output,inspect_only):
    vertices,groups=load_mesh(source)
    print("OBJ: %s vertices, %s usable named groups" % (len(vertices),len(groups)))
    for name in STATIC+GROUPS:
        print("  %s: %s triangles" % (name,len(groups[name])))
    if inspect_only:
        return
    output.mkdir(parents=True,exist_ok=True)
    (output/"rods").mkdir(exist_ok=True)
    # Exclude the source's permanently baked metal shafts: active shafts in
    # the game must remain MOVABLE and match physical 2D colliders.
    static=[t for t in groups["TS_Main"] if t[3] in ("Table","Plastic_Black")]
    static.extend(t for t in groups["TS_Field"] if t[3]=="FIELD")
    render(vertices,static,"TS_Main",size=(1000,560)).save(output/"table.png",optimize=True)
    for name in GROUPS:
        role=name[3:].replace("_Team_","_").lower()
        for index in range(FRAMES):
            angle=-1.15+2.30*index/(FRAMES-1)
            render(vertices,groups[name],name,angle,(128,560)).save(
                output/"rods"/("%s_%02d.png" % (role,index)),optimize=True)
        print("  baked %s poses: %s" % (FRAMES,role))
    manifest={"kind":"table-soccer-local-visuals","version":1,"frames":FRAMES,
              "source_zip_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),
              "author":"Hend Z. / VERTX3D, Table Soccer (June 2014)",
              "rights":"Local use only. Readme prohibits redistributing model in whole/part.",
              "do_not_commit":True}
    (output/"manifest.json").write_text(
        json.dumps(manifest,indent=2),encoding="utf-8")
    print("Private local sprite pack ready in",output)

def self_test():
    # No Pillow needed: metadata/OBJ group parsing against synthetic safe ZIP.
    lines=["# synthetic OBJ"]
    for i in range(3): lines.append("v %d 82 %d" % (i,i))
    for name in STATIC+GROUPS:
        lines.extend(["g "+name,"usemtl Synthetic","f 1 2 3"])
    with tempfile.TemporaryDirectory() as d:
        path=Path(d)/"Table_Soccer.zip"
        with zipfile.ZipFile(path,"w") as archive:
            archive.writestr("Table_Soccer.obj","\n".join(lines))
        vertices,groups=load_mesh(path)
        assert len(vertices)==3 and len(groups)==len(NEEDED)
        assert all(len(groups[name])==1 for name in NEEDED)
    print("PASS: safe ZIP ingestion and eight separate rod/field groups")

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive",nargs="?",type=Path,
                        help="Your own original Table_Soccer.zip")
    parser.add_argument("--output",type=Path,
                        default=Path("experiments/foosball/local_assets"))
    parser.add_argument("--inspect-only",action="store_true")
    parser.add_argument("--self-test",action="store_true")
    args=parser.parse_args()
    if args.self_test: self_test()
    elif args.archive:
        bake(args.archive,args.output,args.inspect_only)
    else: parser.error("Provide your original Table_Soccer.zip or --self-test")
if __name__=="__main__":main()
