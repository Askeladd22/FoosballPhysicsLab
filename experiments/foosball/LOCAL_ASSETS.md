# Private Table Soccer 2.5D assets

This directory is **ignored by Git**. Never commit the author's OBJ, FBX,
Maya files, or converted player/rod sprites into a public repository.

From the repository root, using **your own original Table_Soccer.zip**:

```sh
python -m pip install Pillow
python tools/bake_table_soccer.py "C:/path/to/Table_Soccer.zip"
love .
```

The baker processes real OBJ geometry, preserving eight groups of rod/player
meshes, and creates nine 3D rotation poses per rod plus a static tabletop
reference. The game loads them automatically if all expected files are present.
**V** toggles mesh-inspired 2.5D vs procedural Neon Glass.
Physical collision/goal/dead-ball rules remain 2D and authoritative.

Rights: `Readme.txt` by Hend Z. / VERTX3D (2014) allows commercial or
noncommercial use but forbids redistribution or sale of the model in whole
or in part. This program does not grant redistribution permission for the
converted rig sprites; obtain authorization before shipping them.

The original archive is never uploaded by this script. Baking uses Pillow
only on your machine. The game runs with no Python/dependency once the
local PNGs are prepared.
