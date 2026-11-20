# Table Soccer — REAL 3D in LÖVE 11.5

## Current implementation
The game's `renderer3d.lua` creates **eleven actual GPU Mesh objects** from the author's original OBJ, converted locally to a compact interleaved vertex format (6×float32 = XYZ+normal, 4×byte RGBA, **28 bytes/vertex**). The original author mesh has **132,246 source vertices, 261,576 triangles and 29 groups**; the converter exports all visible groups into: complete static table/counters, field, physical ball, and eight separate rod/figure assemblies. Colors come from original material group names, with a restrained cyan/red/graphite palette. This first pass does not yet load the author's JPEG textures, but **it does render the full triangle geometry**, not screenshots.

### Coordinate mapping
Original author's OBJ: Y is UP, X spans rod shafts/field width, Z spans field length (centimeters). `tools/import_table_soccer_3d.py` maps its X → game Z-width, Z → game X-length, Y → 3D up. Each rod is recentered on its own axis from imported geometry; the GUI dynamically translates it to `rod.x`, `280 + rod.slide` and rotates it around its shaft using `rod.angle`. Because OBJ loses Maya pivot metadata, the conversion reconstructs group pivots at source Y≈83.2. This is a physically plausible rig mapping, not a claim of micrometre-level collider matching.

The 3D ball object is the real source ball sphere, moved each frame to `game.ball.x, 16.5, game.ball.y`; it is scaled to approximate the simulation's 10-unit ball radius and sits on the imported field surface. The **existing fixed-step 2D physical model remains authoritative** for kicks, bounces, goal scoring and dead-ball recovery.

### Renderer
LÖVE 11.5's `love.graphics.newMesh` + vertex shader are used with a real perspective projection and depth-buffered render target. Normals support directional shading. The camera is elevated from the near edge, matching the *kind* of view requested in the reference (not a claim to match exactly). `P` or `V` toggles full 3D vs flat procedural 2D with no match restart. There is no fake affine skew and no PNG sprite interpolation in true 3D mode.

### Installation (private)
```powershell
git switch feat/true-3d-table-soccer-runtime
py -3 tools\import_table_soccer_3d.py "C:\Users\YOURNAME\Downloads\Table_Soccer.zip"
love .
```
Alternatively extract the privately converted `local_assets/3d/` pack into the repository root, then run `love .`. On Windows use `install-table-soccer-3d.bat` if the ZIP is in Downloads. The importer is **stdlib only** and does not execute scripts found in ZIP or upload anything. `local_assets/` is excluded from Git. For CI, `--fixture` generates **synthetic triangles**, verifying the renderer rather than redistributing the original model.

### License and testing
The attached `Readme.txt` explicitly identifies Hend Z. / VERTX3D and states that the model may be used commercially or non-commercially but must **not be redistributed or sold, whole or in part**. Therefore neither original source nor this converted geometry is committed to the public GitHub repository or suitable for unrestricted game distribution. Obtain author permission before bundling assets in a publicly distributed build.

**UNVERIFIED:** visual appearance on the user's Windows display, input feel with the mesh renderer and 60/144Hz FPS; native synthetic test validates API, not the commercial model's visual quality. Validate with 10 intended rod strokes and collisions using the exact source geometry and compare with the 2D fallback. If necessary, tune imported pivot/coordinate mapping; do not alter the game's physics to compensate for a mesh mismatch.
