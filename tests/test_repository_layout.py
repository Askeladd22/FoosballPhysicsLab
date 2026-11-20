"""Guard structural migration without touching gameplay state."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for file in ("main.lua","conf.lua","model.lua","layout.lua","theme.lua","mesh_art.lua","rod_selector.lua"):
    assert (root/file).is_file(), "Foosball root file missing: "+file
for file in ("main.lua","conf.lua","assets/etrusco_unico.png"):
    assert (root/"legacy/neon11"/file).is_file(), "Legacy file missing: "+file
mods=list((root/"legacy/neon11/src").glob("*.lua"))
tests=list((root/"legacy/neon11/tests").glob("test_*.lua"))
assert len(mods)==16, "Expected all 16 original NEON11 source modules"
assert len(tests)==32, "Expected 32 frozen NEON11 tests"
assert len(list((root/"tests").glob("test_foosball*.lua")))>=7
assert not (root/"src").exists(), "Old 11vs11 root src still present"
assert not (root/"experiments/foosball/main.lua").exists()
assert not (root/"assets/etrusco_unico.png").exists()
assert (root/"legacy/neon11/.paul/ROADMAP.md").is_file()
for f in mods+tests:
    assert f.stat().st_size>0, "Empty original legacy file: "+str(f)
print("PASS: Foosball real root and all NEON11 source, tests, docs and texture isolated")
