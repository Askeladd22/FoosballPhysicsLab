# PAUL 27-01 — UNIFY: true 3D camera viewpoint and adaptive distance

**Date:** 2026-11-20. **Branch:** `fix/foosball-3d-camera-orientation-distance`. **Draft PR:** [#25](https://github.com/Askeladd22/FoosballPhysicsLab/pull/25).
**Base:** `ee471773a9ae7560be9922348bdfb50674b748a0`.
**Status:** `APPLY_DONE / 7-CI-JOBS_PASS / WINDOWS_FULL-MODEL_VISUAL_UAT_NOT_RUN`.

## PLAN → APPLY → verification

| Criterion | Work completed | Evidence |
| --- | --- | --- |
| AC1: Correct viewing side | Default **real perspective** eye from the opposite long edge. Eye at approximately `(500,780,-360)`, target `(500,15,280)`, FOV 42°. The original side remains available via **F2**. No model or physics inversion is performed. | `tests/test_foosball_3d_camera.lua` verifies opposite-side default and strict near/far screen order on both sides. PASS LuaJIT and Lua5.4. |
| AC2: No more clipped rim | Camera distance adapts to window aspect ratio via `max(1,2.62/(windowWidth/viewportHeight))`; keeps the four **outer top-rim corners** inside the viewport at **900×650, 1280×850, 1650×895, 1920×1080** with margin. | 3D camera projection tests check four corners, ball center and consistent near/far relation at all four window sizes. PASS. |
| AC3: Adjustable but predictable camera | **F2** reverses viewing side, **PageUp** zooms in, **PageDown** zooms out, **Home** restores defaults; bounded zoom in [0.8, 1.8]. Mouse wheel remains dedicated to changing the rod. Both the GPU shader and selected-rod ring use a shared `cameraBasis(w,h)`. HUD displays selected camera side/zoom. | `tests/test_foosball_3d_camera.lua` confirms monotonic zoom, bounds and reset; `test_foosball_view.lua` checks key handling. PASS. |
| AC4: Preserve gameplay | No `model.lua` changes, no new models or source rights changes. The GLB CC BY remains versioned in `main`; `legacy/neon11/` is completely unchanged. All camera changes affect rendering only, not 120 Hz simulation, score, rod mouse dynamics, AUTO or 2D fallback. | Lua Foosball and frozen NEON11 suites PASS on Lua5.4 and LuaJIT. |
| AC5: True GPU/real model smoke | Native LÖVE under Mesa/Xvfb renders both synthetic sample and the **actual committed CC BY GLB**, after offline conversion to 11 GPU buffers, with explicit GPU framebuffer pixel coverage. | [GitHub Actions #44731794359](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44731794359): **7/7 jobs PASS**. Actual CC BY mesh native test reports **169/255 visible pixel probes**, 11 GPU meshes, 12 frames. |

## SEED rationale
- **Observed:** user screenshot of the true model, 1650×895, showed a visually inverted/unhelpful viewpoint with dominant dark far wall and cropped shafts/board, after the earlier too-close `eye=(500,520,750)` implementation.
- **Derived from code:** camera viewpoint was at the undesired positive-Z side; too-close fixed eye combined with FOV45 and varying viewport ratio made the field and upper rim clip or occupy too much screen. This does **not** prove the actual CC BY geometry is literally upside down: model vertex coordinates and 2D physics remain untouched.
- **Decided:** relocate camera to negative-Z side and pull back; make side switch and zoom explicit. Use a single view matrix basis for CPU/GPU.
- **Not verified:** user-perceived camera orientation, model pose readability, visible ball-to-foot collision consistency, FPS on the user's Windows graphics hardware. Screenshot/native playtest still required.

## Game Design Lab next gate
With PR #25 branch and the existing CC BY mesh pack, play ten deliberate mouse strokes in default camera (mouse click captured), compare F2 reverse-side orientation without restarting the match, try PageDown for a little more distance and Home to reset. Report whether the eight rods, both goals, ball and rim are unobstructed and whether visually judged collisions correspond to physics. **Do not claim the view is definitively better on the basis of green automated tests alone.**

## Scope boundary
No reintroduction of 11vs11, multiplayer, career, new third-party assets, or 3D collision engine; PAUL 27 is a camera and readability correction only.
