#!/usr/bin/env python3
"""Read-only foosball GLB and STEP metadata. No third-party Python packages."""
import argparse
import json
import re
import struct
import tempfile
from pathlib import Path

def glb_report(path):
    data = Path(path).read_bytes()
    if len(data) < 20:
        raise ValueError("GLB truncated")
    magic, version, total = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or total != len(data):
        raise ValueError("Invalid glTF 2.0 header")
    size, kind = struct.unpack_from("<I4s", data, 12)
    if kind != b"JSON" or 20+size > len(data):
        raise ValueError("Missing JSON chunk")
    root = json.loads(data[20:20+size])
    accessors = root.get("accessors", [])
    meshes = root.get("meshes", [])
    primitives = [p for m in meshes for p in m.get("primitives", [])]
    triangles = 0
    vertices = 0
    for p in primitives:
        if p.get("mode", 4) != 4:
            continue
        indices = p.get("indices")
        count = accessors[indices]["count"] if indices is not None \
            else accessors[p["attributes"]["POSITION"]]["count"]
        triangles += count//3
        if "POSITION" in p.get("attributes", {}):
            vertices += accessors[p["attributes"]["POSITION"]]["count"]
    png_dimensions = []
    blobstart = 20+size
    if blobstart+8 <= len(data):
        binary_size, binary_type = struct.unpack_from("<I4s", data, blobstart)
        if binary_type == b"BIN\x00":
            binary = blobstart+8
            for im in root.get("images", []):
                if im.get("mimeType") != "image/png" or "bufferView" not in im:
                    continue
                view = root["bufferViews"][im["bufferView"]]
                at = binary+view.get("byteOffset", 0)
                chunk = data[at:at+view["byteLength"]]
                if chunk.startswith(b"\x89PNG\r\n\x1a\n") and len(chunk) >= 24:
                    png_dimensions.append(list(struct.unpack_from(">II", chunk, 16)))
    return {
        "file": Path(path).name, "bytes": len(data), "glb_version": version,
        "meshes": len(meshes), "primitives": len(primitives),
        "vertices": vertices, "triangles": triangles,
        "materials": len(root.get("materials", [])),
        "textures": len(root.get("textures", [])),
        "embedded_images": len(root.get("images", [])),
        "png_dimensions": png_dimensions,
        "animations": len(root.get("animations", [])),
        "skins": len(root.get("skins", [])),
        "declared_credit": root.get("asset", {}).get("extras", {})
    }

def step_report(path):
    source = Path(path).read_text(encoding="latin-1")
    products = re.findall(r"=\s*PRODUCT\s*\('((?:[^']|'')*)'", source)
    faces = re.findall(r"=\s*ADVANCED_FACE\s*\(", source)
    schema = re.search(r"FILE_SCHEMA\s*\(\('([^']+)'", source)
    return {
        "file": Path(path).name, "bytes": Path(path).stat().st_size,
        "schema": schema.group(1) if schema else None,
        "product_definitions": len(products),
        "product_names": products, "advanced_face_records": len(faces),
        "redistribution_license": "UNKNOWN / NOT PRESENT IN THE UPLOADED FILE",
        "note": "Exact solids require a CAD BREP reader (e.g. OpenCascade)."
    }

def self_test():
    payload = {"asset":{"extras":{"license":"CC BY 4.0"}},
               "accessors":[{"count":3}, {"count":3}],
               "meshes":[{"primitives":[{"attributes":{"POSITION":0},"indices":1}]}]}
    block = json.dumps(payload).encode()
    block += b" " * ((-len(block))%4)
    binary = struct.pack("<4sII", b"glTF", 2, 20+len(block))
    binary += struct.pack("<I4s", len(block), b"JSON")+block
    with tempfile.TemporaryDirectory() as d:
        glb, stp = Path(d)/"sample.glb", Path(d)/"sample.stp"
        glb.write_bytes(binary)
        stp.write_text("ISO-10303-21;\nFILE_SCHEMA(('CONFIG_CONTROL_DESIGN'));\n"
                       "#1=PRODUCT('Sipka','','',());\n#2=ADVANCED_FACE((),#3,.T.);\n")
        a, b = glb_report(glb), step_report(stp)
        assert a["meshes"] == 1 and a["triangles"] == 1
        assert a["declared_credit"]["license"] == "CC BY 4.0"
        assert b["product_definitions"] == 1 and b["advanced_face_records"] == 1
    print("PASS: safe GLB/STEP metadata inspection")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("glb", nargs="?", help="GLB input path")
    parser.add_argument("step", nargs="?", help="STEP input path")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.glb and args.step:
        print(json.dumps({"glb": glb_report(args.glb),
                          "step": step_report(args.step)},
                         ensure_ascii=False, indent=2))
    else:
        parser.error("provide GLB and STEP paths or --self-test")
