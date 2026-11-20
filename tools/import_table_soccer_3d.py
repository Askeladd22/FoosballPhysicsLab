#!/usr/bin/env python3
"""Import the user's *own* Table_Soccer.zip into real LÖVE GPU vertex meshes.

Python stdlib only; output local_assets/3d/*.bin remains private/ignored by Git.
Hend Z. / VERTX3D (2014) forbids redistribution of the model in whole or part.
No pre-rendered PNGs, Blender or internet are needed.
"""
import argparse
import collections
import hashlib
import io
import json
import math
import struct
import tempfile
import zipfile
from pathlib import Path

ROLES = ("Goalkeeper", "Defence", "Midfield", "Attack")
RODS = [f"TS_{team}_Team_{role}"
        for team in ("Blue", "Red") for role in ROLES]
COUNTERS = [f"TS_{side}_SU_{i}"
            for side in ("R", "B") for i in range(1, 10)]
EXPECTED = set(RODS + ["TS_Main", "TS_Field", "TS_Ball"])
LONG = 1000 / 137.4
WIDE = 560 / 83.56
UP = WIDE
FLOOR_Y, AXIS_Y, BALL_Y = 76.64, 83.2, 78.245
ROD_Z = (-59.94, -42.82, -8.56, 25.69,
          59.94, 42.82, 8.56, -25.69)
COLORS = {
    "Metal": (172, 193, 201),
    "Plastic_Black": (34, 51, 62),
    "Plastic_White": (216, 226, 222),
    "Table": (42, 57, 63),
    "FIELD": (32, 104, 113),
    "Blue_Team": (39, 196, 233),
    "Red_Team": (238, 72, 98),
    "Ball": (246, 244, 219),
    "Red_SU": (239, 81, 107),
    "Blue_SU": (39, 196, 233),
}

def group_key(group):
    if group in ("TS_Main", "TS_Field", "TS_Ball"):
        return {"TS_Main":"table","TS_Field":"field","TS_Ball":"ball"}[group]
    if group in COUNTERS:
        return "table"
    if group in RODS:
        parts = group.split("_")
        return (parts[1]+"_"+parts[-1]).lower()
    return None

def position(source_vertex, group):
    x,y,z = source_vertex
    if group in RODS:
        return ((z-ROD_Z[RODS.index(group)])*LONG,
                (y-AXIS_Y)*UP,x*WIDE)
    if group == "TS_Ball":
        return (z*LONG,(y-BALL_Y)*UP,x*WIDE)
    return ((z+68.7)*LONG,(y-FLOOR_Y)*UP,280+x*WIDE)

def convert(source, output, inspect_only=False):
    source = Path(source)
    output = Path(output)
    names = ["table", "field", "ball"] + [
        f"{team.lower()}_{role.lower()}"
        for team in ("Blue", "Red") for role in ROLES
    ]
    buffers = {name:bytearray() for name in names}
    vertices = []
    faces = collections.Counter()
    group, material = "default", ""
    with zipfile.ZipFile(source) as archive:
        if "Table_Soccer.obj" not in archive.namelist():
            raise ValueError("Expected root Table_Soccer.obj in the user's ZIP")
        info = archive.getinfo("Table_Soccer.obj")
        if info.file_size > 90_000_000:
            raise ValueError("Unexpectedly large OBJ; import refused")
        with io.TextIOWrapper(archive.open(info),encoding="latin1") as stream:
            for line in stream:
                if line.startswith("v "):
                    _,x,y,z = line.split()[:4]
                    vertices.append((float(x),float(y),float(z)))
                elif line.startswith("g "):
                    group=line[2:].strip()
                elif line.startswith("usemtl "):
                    material=line[7:].strip().rsplit(":",1)[-1]
                elif line.startswith("f "):
                    key=group_key(group)
                    if not key:
                        continue
                    indices=[int(k.split("/")[0])-1 for k in line.split()[1:]]
                    if min(indices)<0 or max(indices)>=len(vertices):
                        raise ValueError("Invalid face index: "+group)
                    faces[group]+=len(indices)-2
                    if inspect_only:
                        continue
                    color=COLORS.get(material,(168,180,191))
                    out=buffers[key]
                    for i in range(1,len(indices)-1):
                        tri=[position(vertices[n],group)
                             for n in (indices[0],indices[i],indices[i+1])]
                        a,b,c=tri
                        ux,uy,uz=(b[0]-a[0],b[1]-a[1],b[2]-a[2])
                        vx,vy,vz=(c[0]-a[0],c[1]-a[1],c[2]-a[2])
                        nx,ny,nz=(uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx)
                        length=math.sqrt(nx*nx+ny*ny+nz*nz) or 1.0
                        nx,ny,nz=nx/length,ny/length,nz/length
                        for x,y,z in tri:
                            out.extend(struct.pack("<6f4B",
                                                   x,y,z,nx,ny,nz,*color,255))
    missing=EXPECTED-set(faces)
    if missing:
        raise ValueError("OBJ is missing these parts: "+", ".join(sorted(missing)))
    result={
        "format":"FV3D-RGBA8","version":1,"stride_bytes":28,
        "source_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),
        "copyright":"Hend Z. / VERTX3D 2014; no redistribution in whole or part",
        "triangles_by_source_group":dict(faces),
        "vertex_counts":{name:len(buf)//28 for name,buf in buffers.items()}
    }
    print("Real source OBJ:",len(vertices),"vertices,",
          sum(faces.values()),"triangles,",len(faces),"groups.")
    if not inspect_only:
        output.mkdir(parents=True,exist_ok=True)
        for key,buf in buffers.items():
            if not buf:
                raise ValueError("Missing independent GPU mesh "+key)
            (output/(key+".bin")).write_bytes(buf)
        (output/"manifest.json").write_text(
            json.dumps(result,indent=2),encoding="utf-8")
        (output/"PRIVATE_USE_ONLY.txt").write_text(
            "Original author: Hend Z. / VERTX3D (2014)\n"
            "Original source: your own Table_Soccer.zip\n"
            "Original README forbids redistribution in whole or in part.\n"
            "Keep this directory private; do not commit it or ship publicly.\n",
            encoding="utf-8")
        print("Wrote 11 real 3D mesh files to",output)
    return result

def synthetic_fixture_zip(path):
    lines=[]
    index=1
    for name in ["TS_Main","TS_Field","TS_Ball"]+RODS:
        if name=="TS_Field":
            # A full-size, vivid source-model field. Earlier tests drew only
            # microscopic triangles and falsely accepted an empty framebuffer.
            lines.extend([
                "v -41.78 76.64 -68.7",
                "v 41.78 76.64 -68.7",
                "v 41.78 76.64 68.7",
                "v -41.78 76.64 68.7",
                "g "+name, "usemtl Table_Soccer:FIELD",
                f"f {index} {index+1} {index+2}",
                f"f {index} {index+2} {index+3}"
            ])
            index+=4
        else:
            lines += ["v 0 83.2 0","v 1 83.2 0","v 0 84.2 0",
                      "g "+name,"usemtl Table_Soccer:Metal",
                      f"f {index} {index+1} {index+2}"]
            index+=3
    with zipfile.ZipFile(path,"w") as archive:
        archive.writestr("Table_Soccer.obj","\n".join(lines))

def fixture(output):
    with tempfile.TemporaryDirectory() as tmp:
        source=Path(tmp)/"synthetic.zip"
        synthetic_fixture_zip(source)
        return convert(source,output)

def self_test():
    with tempfile.TemporaryDirectory() as tmp:
        dest=Path(tmp)/"meshes"
        result=fixture(dest)
        assert result["vertex_counts"]["table"]==3
        assert result["vertex_counts"]["blue_attack"]==3
        assert (dest/"red_goalkeeper.bin").stat().st_size==84
        assert len(list(dest.glob("*.bin")))==11
    print("PASS: independent GPU meshes, real geometry format and local import")

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("zip",nargs="?",type=Path,help="your own Table_Soccer.zip")
    p.add_argument("--output",type=Path,default=Path("local_assets/3d"))
    p.add_argument("--inspect",action="store_true")
    p.add_argument("--self-test",action="store_true")
    p.add_argument("--fixture",action="store_true",
                   help="generate 11 tiny original synthetic meshes for CI only")
    args=p.parse_args()
    if args.self_test:self_test()
    elif args.fixture:fixture(args.output)
    elif args.zip:convert(args.zip,args.output,args.inspect)
    else:p.error("Give the path to your own Table_Soccer.zip")
