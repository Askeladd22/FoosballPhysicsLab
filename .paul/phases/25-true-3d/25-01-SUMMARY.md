# PAUL Phase 25-01 — UNIFY: Table Soccer truly rendered as 3D GPU meshes

**Date:** 2026-11-20. **Branch:** `feat/true-3d-table-soccer-runtime`.
**Draft PR:** [#23](https://github.com/Askeladd22/FoosballPhysicsLab/pull/23).
**Baseline:** `e240562c6a12fa1adf914c0dab65399789c4b689`.
**Status:** `IMPLEMENTED / CODE_CI_VERIFIED / NATIVE_SOURCE_MODEL_UAT_NOT_RUN`.

## PLAN → APPLY → VERIFY

| Acceptance criterion | Implemented | Verification |
| --- | --- | --- |
| AC1 — actual proprietary model geometry | A Python stdlib local importer reads the user's real `Table_Soccer.zip`: **132,246 source OBJ vertices, 261,576 triangles, 29 original groups**. It generates 11 binary GPU streams with source mesh XYZ positions, computed normals and material-derived RGB (table and 18 scoring units, field, ball, eight rod/figure assemblies). No runtime PNG sprite interpolation. | Real uploaded ZIP converted locally successfully to **11 GPU mesh binaries**, total ~21 MB uncompressed, plus manifest. Private pack handed to original file's holder separately. Public repository contains **zero** copied original/derived model meshes. Python synthetic self-test PASS in CI. |
| AC2 — perspective 3D linked to 2D physics | `renderer3d.lua` uses LÖVE 11.5 `love.graphics.newMesh`, dynamic independent shader transforms for eight rods, 3D ball mesh at `ball.x,ball.y`, real perspective camera, depth-enabled Canvas and directional surface shading. Physical `model.lua` remains authoritative for velocity, kicks, rebounds, scoring and dead-ball rules. | Headless `tests/test_foosball_renderer3d.lua` verifies 11 independent buffers, depth selection, perspective shader, physical ball/rod positions and manual 3D/2D toggle. Native LÖVE 11.5 software GPU + Xvfb **loaded all 11 synthetic geometry meshes and rendered 12 frames** successfully. |
| AC3 — local-only source/derivatives | Installer `tools/import_table_soccer_3d.py` uses the original user's ZIP only, writes to gitignored `local_assets/3d/`. A Windows `.bat` installs from the Downloads copy. Manifest and `docs/TRUE-3D.md` document author/rights and reconstructed OBJ pivots. Old 2.5D sprite pipeline no longer loads in active game. | Git comparison contains **no** original or derived binary, no changes to `legacy/neon11/`. |
| AC4 — regression + real runtime | 4 Lua CI jobs (Foosball, frozen NEON11 × Lua 5.4/LuaJIT) + dedicated native LÖVE GPU shader/depth job. Debug `--frames=12 --require-3d` guarantees a native 3D smoke instead of a silent 2D fallback. | [GitHub Actions run #44717700176](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44717700176): **all 5 jobs PASS**, including LÖVE native GPU smoke. Earlier shader validation and HUD test regressions were diagnosed and corrected. |
| AC5 — human visual controls | `P` or `V` toggles actual 3D vs flat 2D without restarting match. Native renderer defaults active only when the user's private mesh pack is installed; otherwise an explicit procedural 2D fallback remains usable. | **NOT_RUN**: user's specific Windows GPU/FPS, actual source model visual appearance, precise imported footwear alignment, feel after 10 shots. Synthetic mesh native smoke cannot prove those. |

## SEED / Game Design Lab decisions and limitations
- **Observed:** Previous oblique scene was not a true 3D mesh renderer; user rejected it. The original ZIP indeed has eight independently named rod mesh groups and real 3D geometry.
- **Decided:** Use an actual GPU perspective/depth pipeline with geometry converted only from the owner's copy; never reintroduce affine sprite illusions. Keep existing fixed-step 2D match physics, and allow immediate 2D A/B fallback.
- **Assumed:** OBJ pivot re-centering at source rod axis (Y≈83.2) and group Z centers maps closely to existing physical field coordinates. The author's README warns **OBJ loses Maya pivot and constraint setup**; the imported geometry may require visual rig calibration.
- **Open:** exact source JPEG textures are not yet integrated (materials currently use color shading), native FPS and match feel with full 261,576-triangle model, accuracy of each 3D player's foot relative to authoritative 2D collider.
- **Rights:** uploaded `Readme.txt` by Hend Z. / VERTX3D (2014) allows commercial/noncommercial use but prohibits redistribution of model whole or part. Private user's transformed pack must **not** be published or shipped publicly without authorization.

## Native smoke evidence
Run #44717700176 (success): software-rendered native LÖVE 11.5 on Linux / Xvfb invoked with synthetic 11-part mesh fixtures, emitted `Table Soccer TRUE 3D: 11 independent GPU meshes loaded.` and `PASS: native LÖVE TRUE 3D frame smoke (12 frames)`.
**Do not represent this as a native benchmark or screenshot of the user's original copyrighted model.**

## Game Design Lab next decisive action
On the user's Windows installation, extract the private `local_assets/3d/` from their owned ZIP conversion into the repo root, select the Phase 25 branch and run `love .`. Click to capture the mouse. Play 10 intentional hits, verify shaft translation/rotation and visible ball rolling, compare P/V 2D fallback, then report image, GPU FPS and any mismatch between the 3D foot and physical hit position. Fix mapping only if observed. PR remains draft until native full-model UAT.
