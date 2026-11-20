#!/usr/bin/env python3
"""Synthetic, self-contained CC BY model importer test. No proprietary file needed."""
import json
from pathlib import Path
import struct
import tempfile
import trimesh

from import_foosball_glb_ccby import convert,metadata,RODS
from trimesh.visual.material import PBRMaterial
from trimesh.visual.texture import TextureVisuals

def fixture(destination,license="CC-BY-4.0"):
    scene=trimesh.Scene()
    for i in range(103):
        material="wood"
        x,y,z=0,.74,0
        if i==0:
            material="Blue_plastic";x=-.48;y=.78
        if i==1:
            material="Red_plastic";x=.46;y=.78
        if i==2:
            material="field"
        if 3<=i<11:
            material="Mirror-Handles";x=RODS[i-3][2];y=.79
        box=trimesh.creation.box(extents=[.01,.02,.02])
        box.visual=TextureVisuals(material=PBRMaterial(
            name=material,baseColorFactor=[255,255,255,255]))
        tf=trimesh.transformations.translation_matrix([x,y,z])
        scene.add_geometry(box,node_name="n"+str(i),geom_name="g"+str(i),transform=tf)
    data=scene.export(file_type="glb")
    magic,version,total=struct.unpack_from("<4sII",data)
    jsonsize,kind=struct.unpack_from("<I4s",data,12)
    assert magic==b"glTF" and kind==b"JSON"
    j=json.loads(data[20:20+jsonsize])
    j["asset"]["extras"]={
        "author":"3D Content Online (https://sketchfab.com/hknoblauch)",
        "license":license,
        "source":"https://sketchfab.com/3d-models/foosball-table-5f70863c2cf74e99ad084a493209dbac",
    }
    encoded=json.dumps(j,separators=(",",":")).encode("utf-8")
    encoded+=b" "*((-len(encoded))%4)
    tail=data[20+jsonsize:]
    destination.write_bytes(struct.pack("<4sII",magic,version,20+len(encoded)+len(tail))
      +struct.pack("<I4s",len(encoded),b"JSON")+encoded+tail)

def main():
    with tempfile.TemporaryDirectory() as dirname:
        temp=Path(dirname)
        glb=temp/"synthetic.glb"
        fixture(glb)
        assert metadata(glb)["license"]=="CC-BY-4.0"
        result=convert(glb,temp/"out")
        files=list((temp/"out").glob("*.bin"))
        assert len(files)==11,files
        assert all(p.stat().st_size%84==0 and p.stat().st_size>0 for p in files)
        assert result["blue_midfield"]>result["blue_goalkeeper"]
        assert result["red_attack"]>result["red_goalkeeper"]
        manifest=json.loads((temp/"out/manifest.json").read_text())
        assert manifest["license"].startswith("CC BY 4.0")
        assert manifest["axis_height"]==50 and manifest["ball_height"]==10
        fixture(glb,"CC-BY-NC-4.0")
        try:
            convert(glb,temp/"must-not-build")
        except ValueError:
            pass
        else:
            raise AssertionError("NC license passed the CC BY importer gate")
    print("PASS: GLB 103-part import, 11 GPU rigs, 1-2-5-3 reinstance, credit and NC rejection")

if __name__=="__main__":main()
