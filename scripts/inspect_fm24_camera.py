"""Read-only inspection of the installed FM24 camera resource (Python 3.15+).

Prints scalar evidence only; does not copy FM assets into the game.
Usage: python scripts/inspect_fm24_camera.py [path/to/simatchviewer.fmf]
"""
import hashlib
import json
from pathlib import Path
import struct
import sys
from compression import zstd

archive = Path(sys.argv[1] if len(sys.argv) > 1 else
               r"S:\Epic Games\FootballManager24\data\simatchviewer.fmf")
magic = bytes.fromhex("28b52ffd")
with archive.open("rb") as stream:
    header = stream.read(32)
    assert header[2:6] == b"fmf.", "Not the observed FMF format"
    index_offset = struct.unpack_from("<Q", header, 9)[0]
    assert index_offset < archive.stat().st_size
    stream.seek(index_offset)
    tail = stream.read()
    chunks = []
    while True:
        start = tail.find(magic)
        if not 0 <= start < 64:
            break
        decoder = zstd.ZstdDecompressor()
        chunks.append(decoder.decompress(tail[start:]))
        assert decoder.eof, "Incomplete directory frame"
        tail = decoder.unused_data
    directory = b"".join(chunks)
    name = b"cameras_match"
    record = struct.pack("<I", len(name)) + name + b"\x04\0\0\0.jsb"
    assert directory.count(record) == 1, "Camera record ambiguous or absent"
    record_offset = directory.index(record)
    offset, stored, decoded = struct.unpack_from("<3Q", directory,
                                                record_offset + len(record))
    # In this FMF variant data offsets are relative to byte 25. A resource
    # begins with a flag, then a 32-bit compressed frame size.
    stream.seek(25 + offset)
    frame_header = stream.read(5)
    frame_size = struct.unpack_from("<I", frame_header, 1)[0]
    assert frame_header[0] == 5 and frame_size + 4 == stored
    decoder = zstd.ZstdDecompressor()
    payload = decoder.decompress(stream.read(frame_size))
    assert decoder.eof and len(payload) == decoded

begin = payload.index(b"two_d_classic")
end = payload.index(b"two_d_classic_radar", begin)
section = payload[begin:end]
assert b"typehortho" in section and b"match_view_2d" in section
values = {}
locations = {}
for name, tag, fmt in [("length_border", 2, "<i"), ("width_border", 2, "<i"),
                       ("min_zoom", 7, "<d"), ("max_zoom", 7, "<d")]:
    key = bytes([len(name)]) + name.encode() + bytes([tag])
    assert section.count(key) == 1
    pos = section.index(key) + len(key)
    values[name] = struct.unpack_from(fmt, section, pos)[0]
    locations[name] = begin + pos
print(json.dumps({
    "archive": str(archive), "archive_bytes": archive.stat().st_size,
    "directory_offset": index_offset, "record_offset_in_directory": record_offset,
    "resource": "cameras_match.jsb", "resource_offset": 25 + offset,
    "decoded_bytes": len(payload), "decoded_sha256": hashlib.sha256(payload).hexdigest(),
    "camera": "two_d_classic", "projection": "ortho", "layer": "match_view_2d",
    "values": values, "value_offsets_in_decoded_resource": locations,
    "limits": "Static camera parameters; viewport formula and saved user zoom unverified."
}, indent=2))
