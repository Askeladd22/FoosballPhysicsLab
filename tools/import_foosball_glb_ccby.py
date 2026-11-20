#!/usr/bin/env python3
"""Convert user-supplied CC-BY GLB to the real 11 LÖVE GPU mesh binaries.

Upstream: Foosball table by 3D Content Online (Sketchfab hknoblauch)
https://sketchfab.com/3d-models/foosball-table-5f70863c2cf74e99ad084a493209dbac
License: CC BY 4.0 (attribution and changes must accompany any distribution).

Offline build dependency: pip install "trimesh>=4,<5" numpy
The 2D physics and 1-2-5-3 rod layout remain authoritative.
"""
import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct

RODS = (
    ("blue", "goalkeeper", -.48, (0,)),
    ("blue", "defence", -.37, (-145, 145)),
    ("blue", "midfield", -.09, (-193, -96, 0, 96, 193)),
    ("blue", "attack", .18, (-148, 0, 148)),
    ("red", "goalkeeper", .46, (0,)),
    ("red", "defence", .32, (-145, 145)),
    ("red", "midfield", .06, (-193, -96, 0, 96, 193)),
    ("red", "attack", -.22, (-148, 0, 148)),
)
COLORS = {
    "Mirror-Handles": (178,188,196),
    "wood": (57,55,57), "Blue_plastic": (32,195,240),
    "Red_plastic": (240,80,98), "Black_plastic": (42,51,66),
    "Field_lines": (196,221,222), "field": (27,117,113),
    "Grey": (141,149,155),
}
LENGTH=1000/1.12
WIDTH=560/.56
TABLE_TOP=.74
ROD_AXIS=.79


def metadata(file):
    with file.open("rb") as inp:
        header=inp.read(20)
        if len(header)!=20 or header[:4]!=b"glTF":
            raise ValueError("Not a valid binary GLB file")
        import struct as st
        size,kind=st.unpack_from("<I4s",header,12)
        if kind!=b"JSON" or size>50_000_000:
            raise ValueError("Invalid GLB JSON chunk")
        asset=json.loads(inp.read(size))
    return asset.get("asset",{}).get("extras",{})


def convert(source,output,inspect=False):
    try:
        import trimesh
        import numpy as np
    except ImportError as error:
        raise SystemExit("Install offline importer deps: py -3 -m pip install trimesh numpy") from error
    source=Path(source)
    output=Path(output)
    extra=metadata(source)
    if "CC-BY-4.0" not in extra.get("license","") or "5f70863" not in extra.get("source",""):
        raise ValueError("Expected CC BY 4.0 Foosball table by 3D Content Online")
    scene=trimesh.load(source,force="scene",process=False)
    if len(scene.graph.nodes_geometry)<95:
        raise ValueError("This GLB is not the separable 103-part source table")
    buffers={n:bytearray() for n in
             ["table","field","ball"]+[t+"_"+r for t,r,_,_ in RODS]}
    templates={}
    counts=defaultdict(int)
    def emit(name,triangles,normals,color):
        out=buffers[name]
        for vertices,normal in zip(triangles,normals):
            for x,y,z in vertices:
                out.extend(struct.pack("<6f4B",float(x),float(y),float(z),
                           float(normal[0]),float(normal[1]),float(normal[2]),
                           *color,255))
            counts[name]+=1
    def map_static(geometry):
        result=np.empty_like(geometry)
        result[:,:,0]=(geometry[:,:,0]+.56)*LENGTH
        result[:,:,1]=(geometry[:,:,1]-TABLE_TOP)*WIDTH
        result[:,:,2]=(geometry[:,:,2]+.28)*WIDTH
        return result
    def map_rod(geometry,rod_x):
        result=np.empty_like(geometry)
        result[:,:,0]=(geometry[:,:,0]-rod_x)*LENGTH
        result[:,:,1]=(geometry[:,:,1]-ROD_AXIS)*WIDTH
        result[:,:,2]=geometry[:,:,2]*WIDTH
        return result
    for node in scene.graph.nodes_geometry:
        transform,key=scene.graph.get(node)
        mesh=scene.geometry[key]
        material=getattr(getattr(mesh.visual,"material",None),"name","") or ""
        if not len(mesh.faces):
            continue
        vertices=trimesh.transform_points(mesh.vertices,transform)
        triangles=vertices[mesh.faces]
        normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
        length=np.linalg.norm(normals,axis=1)
        normals/=np.maximum(length[:,None],1e-9)
        center=triangles.reshape(-1,3).mean(axis=0)
        color=COLORS.get(material,(160,169,179))
        rod=None
        if center[1]>.70 and material in ("Mirror-Handles","Blue_plastic","Red_plastic","Black_plastic"):
            close=min(RODS,key=lambda r:abs(r[2]-center[0]))
            if abs(close[2]-center[0])<=.04:rod=close
        if material in ("Blue_plastic","Red_plastic") and rod:
            # Upstream GLB has a different player count than the physics game.
            # Re-instance REAL source geometry at precise 1-2-5-3 physical Y lanes.
            team=material.split("_")[0].lower()
            if team not in templates:
                templates[team]=(triangles.copy(),normals.copy(),color,center.copy())
            continue
        if rod:
            team,role,rod_x,_=rod
            emit(team+"_"+role,map_rod(triangles,rod_x),normals,color)
        else:
            dest="field" if material in ("field","Field_lines") else "table"
            emit(dest,map_static(triangles),normals,color)
    for team,role,rod_x,offsets in RODS:
        if team not in templates:raise ValueError("Missing "+team+" source player mesh")
        triangles,normals,color,center=templates[team]
        for offset in offsets:
            instance=triangles.copy()
            instance[:,:,0]+=rod_x-center[0]
            instance[:,:,2]+=offset/WIDTH-center[2]
            emit(team+"_"+role,map_rod(instance,rod_x),normals,color)
    # Source GLB has no independent physical ball rig. A small original
    # mesh replaces that single missing asset; placement is physics-driven.
    for row in range(12):
        lat0=-math.pi/2+row*math.pi/12
        lat1=-math.pi/2+(row+1)*math.pi/12
        for col in range(24):
            a=col*2*math.pi/24;b=(col+1)*2*math.pi/24
            def point(lat,lon):
                return (math.cos(lat)*math.cos(lon)*10,
                        math.sin(lat)*10,
                        math.cos(lat)*math.sin(lon)*10)
            p0,p1,p2,p3=point(lat0,a),point(lat1,a),point(lat1,b),point(lat0,b)
            for part in ((p0,p1,p2),(p0,p2,p3)):
                vertices=np.asarray([part],dtype="float32")
                normal=vertices[0].mean(axis=0)
                normal/=max(np.linalg.norm(normal),1e-9)
                emit("ball",vertices,np.asarray([normal]),(242,238,213))
    if not inspect:
        output.mkdir(parents=True,exist_ok=True)
        for key,buf in buffers.items():
            if not buf or len(buf)%84:raise ValueError("Invalid output mesh "+key)
            (output/(key+".bin")).write_bytes(buf)
        manifest={
          "format":"FV3D-RGBA8","version":1,
          "source":extra["source"],
          "author":extra["author"],
          "license":"CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)",
          "source_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),
          "modifications":"Re-rigged the source model for eight independently moving rods and the game's 1-2-5-3 player layout; material recoloring; reconstructed geometry pivots; original substitute ball sphere.",
          "mesh_triangle_counts":dict(counts),
          "axis_height":50.0,"ball_height":10.0
        }
        (output/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
    print("PASS: 3D Content Online CC BY model, 11 GPU meshes, eight animated 1-2-5-3 rods")
    print("Meshes:",dict(counts))
    return counts


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("glb",type=Path)
    p.add_argument("--output",default="local_assets/3d",type=Path)
    p.add_argument("--inspect",action="store_true")
    args=p.parse_args()
    convert(args.glb,args.output,args.inspect)
