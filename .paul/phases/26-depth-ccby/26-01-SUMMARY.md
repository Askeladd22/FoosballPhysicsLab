# PAUL 26-01 — UNIFY: fix black 3D, choose redistributable GLB

**Date:** 2026-11-20. **Base main:** `343b9e8b6733a0f0da5df75e082d9bcb4b2140d7`.
**Branch:** `fix/3d-depth-and-ccby-model-pipeline`. **Draft PR:** [#24](https://github.com/Askeladd22/FoosballPhysicsLab/pull/24).
**Status:** IMPLEMENTED / 6 CI JOBS PASS / NATIVE USER FULL-MODEL UAT NOT_RUN.

## Root cause / PAUL verification
The screenshot shows black video content, although the renderer claimed to have loaded real GPU meshes. In `renderer3d.lua`, the depth clear was `love.graphics.clear(0.016,0.025,0.040,1,1,0)` — i.e. **clear depth = 0**, whereas `lg.setDepthMode("lequal",true)` accepts fragments only at or nearer than the existing depth. Normal 3D geometry cannot pass a depth buffer initially cleared to the closest possible depth.

**FIXED:** clear stencil = 0, depth = 1. `ThreeD.assertVisible()` samples 255 **actual framebuffer pixels** and rejects blank output. The synthetic CI asset draws a field covering a meaningful projected area instead of a few microscopic triangles. [GitHub Actions run #44728693467](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44728693467) **6 / 6 PASS**: native LÖVE software GPU reported `3D GPU visible pixel probes: 46/255`, then 12 frames completed. The original CI never verified pixel colors, hence its false confidence.

## Comparison of the actual user GLB uploads
| Uploaded name | Triangles | 3D mesh primitives | License in GLB metadata | Practical assessment |
|---|---:|---:|---|---|
| foosball_table (1).glb | 116027 | 2 | CC BY 4.0 | largely fused; difficult rod separation |
| **foosball_table (2).glb** | **73636** | **103** | **CC BY 4.0** | **SELECTED**, independent rod and figure components, eight source materials, source by 3D Content Online |
| foosball_table (3).glb | 22855 | 1 | CC BY 4.0 | fused single mesh, only suitable as a static reference |
| marble_foosball.glb | 148309 | 103 | CC BY-NC 4.0 | redistribution possible with NC restrictions; unsuitable for unrestricted commercial game |
| marble_foosball (1).glb | 136164 | 123 | CC BY-NC 4.0 | same NC limitation; larger download |

The uploaded model metadata for the selected GLB declares: author `3D Content Online` (Sketchfab `hknoblauch`), source `https://sketchfab.com/3d-models/foosball-table-5f70863c2cf74e99ad084a493209dbac`, CC BY 4.0. Its SHA-256 is `6234047d83db0df64a7d5f7ef5044432b7e6f144e3b272019f546f6a2e44174`. Attribution and change notices are recorded in `assets/models/ATTRIBUTION.md`.

## SEED / APPLY / actual asset processing
- `tools/import_foosball_glb_ccby.py`: converts the real uploaded GLB via trimesh+numpy **offline** into 11 GPU vertex buffers with real surface geometry and original-material-informed colors. Its 103 separable GLB mesh parts are grouped into field, table and 8 animated rods.
- The source GLB player distribution is **not 1-2-5-3**, so the importer reinstantiates actual blue/red player mesh geometry at the physics-defined rod offsets instead of changing scoring/collisions to fit the asset. This maintains the existing physically authoritative 1-2-5-3 layout.
- The GLB has no independently suitable ball mesh; the importer adds one small original procedural triangle sphere governed by `model.lua`.
- A manifest calibrates source-specific 3D pivot (50) and ball radius/height (10), retaining backward compatibility with old private TableSoccer meshes when installed.
- **Real attached GLB converted successfully** in container: 11 mesh buffers (~6 MB raw); packaged with the exact original CC BY GLB, credits and ready-to-use `local_assets/3d/` in a separate download. There are **no third-party mesh binaries in the GitHub PR itself**. The CC BY license permits adding the original GLB to GitHub with attribution, unlike the previous VERTX3D model; the uploaded source is bundled at `assets/models/foosball_table.glb` in the downloadable repo-ready archive. The GitHub connector's available write path did not provide direct streaming of the current conversation's binary GLB into a Git blob, so claiming it was pushed to GitHub would be incorrect. User needs to extract the artifact and commit the GLB once to version its source.
- `install-foosball-ccby.bat` accepts a GLB in the repo's assets folder, Downloads or file path. Requirements are needed only for offline conversion, not game runtime. `assets/models/ATTRIBUTION.md` documents author, source, license, modifications, hash.
- `legacy/neon11/` not modified.

## CI gates (run 44728693467)
- Foosball Lua 5.4: PASS
- Foosball LuaJIT: PASS
- Frozen NEON11 Lua 5.4: PASS
- Frozen NEON11 LuaJIT: PASS
- CC BY GLB 103-part importer with synthetic fixture, 11 GPU buffers and NC rejection: PASS
- Native LÖVE Xvfb/Mesa GPU shader+depth and **real pixel coverage**: PASS (46/255 sampled pixels).

## Game Design Lab — decisive remaining user test
**UNVERIFIED:** a Windows screenshot with the entire 103-part selected source GLB running on the user's GPU, exact camera field of view, collision-foot visual alignment, per-frame performance and subjective mouse feel. Run the PR with the accompanying 3D pack, compare P/V 3D/2D for 10 intentional shots. If physics and visual feet disagree, correct the rig mapping rather than replacing collision with an arbitrary scripted hit. Keep PR draft until this test.
