# PAUL 30-01 — UNIFY: ACTUAL 3D foosball upright

**Date:** 2026-11-20. **Base:** `7292fceddf761bf5fa51a1284732dca2a6d45cbe`.
**Branch:** `fix/foosball-show-real-legs-3quarter-camera`. **Draft PR:** [#28](https://github.com/Askeladd22/FoosballPhysicsLab/pull/28).
**Status:** `APPLY_COMPLETE / 7 of 7 CI PASS / USER_WINDOWS_VISUAL_UAT_NOT_RUN`.

## Evidence chain and corrected diagnosis
1. **Observed user symptom:** repeated screenshots of apparent upside-down foosball, field difficult to read and four physical support legs invisible, despite earlier CI saying GPU scene was visible.
2. **Source geometric truth:** source CC BY GLB field ~Y=-4, legs down to Y=-740, top rim Y=130. Thus upside-down is NOT a flaw in the mesh authoring, nor something to fix by vertically flipping the source.
3. **Actual visual proof:** independently rendered the real 11 private/exported GPU meshes into a full tabletop screenshot with offscreen VTK. The model appears upright with all four support legs when camera is centered on **Y=-305**, not the field at Y=15, and viewed from a three-quarter corner pose. This image is a geometry reference, not a replacement sprite asset.
4. **Definitive underlying BUG:** when rendering the manually projected 3D shader into a LÖVE **Canvas**, the shader's projected clip-space Y was **opposite to the Canvas/display orientation**. Previous code used `dot(delta,uUp)*uFocal` and produced an upside-down GPU frame; this mismatched the CPU projection of field/selection ring. On the first native CI attempt with full-body camera, `assertFieldVisible()` failed at **2/99** projected green points and the GPU ASCII raster was vertically mirrored relative to the expected geometric reference.
5. **Fix:** shader vertex clip-space UP now outputs `-dot(delta,uUp)*uFocal`; CPU screen projection stays unchanged. Regression `tests/test_foosball_renderer3d.lua` requires this exact stage-specific correction. There is no g3d rewrite, source model change, vertical flip, or gameplay physics alteration.
6. **After fix:** **7/7 jobs green** in [native GitHub Actions #44756697687](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687). Real committed CC BY GLB native Mesa/Xvfb reports **67/99 visible GREEN field samples** (near 25/33, far 17/33), **4/4 true support legs with visible GPU geometry**, 56/255 overall general pixel probes and successful 12 frames. [Genuine LÖVE Canvas screenshot artifact](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687/artifacts/14639560551) captured as an image, not invented or rendered from a mock.

## PLAN → APPLY → VERIFY

| Goal | Implementation | Proof |
|---|---|---|
| Real table upright | Keep Y-up source vertices (feet below). Fix GPU Canvas Y clip output sign. | Real GLB native GPU after fix: 4/4 legs visible; shader regression test PASS. |
| See **whole table** | Three-quarter corner camera at center `(500,-305,280)`, approximately 45° down, FOV 35; F2 reverse side and PageUp/PageDown remain, F3 yaw 180° preserved. | Test `tests/test_foosball_upright_camera.lua` checks all four leg-bottom anchors BELOW field and within viewport at 900×650, 1280×850, 1650×895, 1920×1080, both viewing sides. Lua5.4/LuaJIT PASS. |
| Leg + pitch visibility, not false-green gates | Native GPU reads back actual Canvas and requires green field coverage near/far **and** four lower support locations. CI saves actual screenshot and prints a low-res ASCII visual map for diagnosis. | Real CC BY 11 meshes converted in CI; green 67/99; legs 4/4. |
| Preserve physics and legacy | No changes to `model.lua`, mouse input, AI, scores, CC BY source binary or `legacy/neon11/`. | Foosball LuaJIT/Lua5.4 and frozen NEON11 LuaJIT/Lua5.4 suites PASS; Git compare shows no legacy files. |
| Human feel | Native user screenshot and 10-shot playtest are still required. | **NOT_RUN** on the user's Windows display; CI evidence is real GPU but doesn't establish fun or tactile feedback. |

## Game Design Lab
**Goal:** real 3D tabletop reads as a physical foosball with **feet down**, intelligible green pitch and readable rod motion. **Tools:** actual source meshes, corrected Canvas clip-Y, full-body camera/viewport tests and live native screenshot. **Validated:** geometric orientation and actual GPU framebuffer visibility; **not validated:** perceived visual quality on the user's display and whether controlling rotating rods at this camera angle feels intuitive. If user screenshot still fails, debug that specific frame rather than repeatedly inverting the model.

**Next single action:** check out PR #28 on Windows and launch `love .`; compare screenshot and 10 intentional shots with F2/F3 as needed. Remain draft until human UAT.
