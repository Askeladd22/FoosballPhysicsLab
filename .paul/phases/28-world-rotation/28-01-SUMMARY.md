# PAUL Phase 28-01 — UNIFY: Rotate complete 3D Foosball world 180°

**Date:** 2026-11-20. **Branch:** `fix/foosball-rotate-world-180`.
**Draft PR:** [#26](https://github.com/Askeladd22/FoosballPhysicsLab/pull/26).
**Baseline:** `d56c223b91d20907d7ab47c794a10d0a61003134`.
**Status:** `DONE_WITH_CONCERNS`: actual 3D rotation implemented; all automated CI gates PASS; real Windows player visual UAT **NOT_RUN**.

## PAUL PLAN → APPLY → UNIFY

| Acceptance | Implementation | Verified evidence |
|---|---|---|
| AC1: whole table turns 180° | A **rigid yaw about the world-up Y axis** centered at game-space `x=500,z=280`: `(x,y,z) -> (1000-x,y,560-z)` at default 180°. Applied in the existing GPU vertex shader **after** per-rod rotation/slide, to **the complete static table + field, eight rods and ball**. Shading normals use the same transformation. | `tests/test_foosball_world_yaw.lua` checks center, corners, arbitrary points, all physical rods and ball; `test_foosball_renderer3d.lua` confirms GPU receives -1 for 180° and +1 for 0°. **PASS** Lua5.4/LuaJIT. |
| AC2: selection indicator aligned | `ThreeD.project(x,y,z)` applies precisely the same world yaw in CPU before perspective projection. No visual controller marker displaced from its GPU rod. | Four-window projected comparisons in `test_foosball_world_yaw.lua`; **PASS**. |
| AC3: reversible controls | **F3** switches `180° ↔ 0°` model orientation; F2 remains independent camera-side toggle; **Home** restores camera and 180° default. On-screen readout shows `TAVOLO 180 GRADI`. 2D fallback unchanged. | `test_foosball_view.lua` checks key presses and reset. **PASS**. |
| AC4: no physical changes / real GLB | Original field positions, rod angles, ball impulses, 120 Hz model, AI and scoring are not modified. No new g3d dependency, original CC BY model or binaries changed. Frozen NEON11 untouched. | Git diff: `renderer3d.lua`, `main.lua`, Foosball tests, docs only; all legacy tests PASS. |
| AC5: native renderer / model | Native LÖVE 11.5 software-GPU shader/depth test with synthetic meshes AND actual committed CC BY GLB, checking rendered pixel coverage. | [GitHub Actions #44743973107](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44743973107) **7/7 jobs PASS**. Real GLB native output: `Table Soccer TRUE 3D: 11 independent GPU meshes loaded (cc-by-glb)`; `3D GPU visible pixel probes: 169/255`; `PASS ... (12 frames)`. |

## SEED decisions and limits
**Observed:** the user rejected a rotated camera alone and explicitly requested a 180° turn of the whole table. **Decided:** yaw about Y, because the physical tabletop must remain upright and playable; rotating it upside down around a horizontal axis would break the visual floor. **Decided:** reuse the existing native LÖVE 3D mesh/shader rather than import g3d to do an elementary rigid transform. **Assumed:** a Y-axis 180° turn is the exact requested interpretation.
**Unverified:** whether turning the source table 180° is sufficient to eliminate the obstructing near rail / unusual tilt in the user's latest Windows screenshot; that depends on camera elevation and relative source model geometry. GPU color coverage alone does not prove good camera framing or enjoyable shots.

## Game Design Lab cheapest decisive human test
Run `love .` from PR #26 branch on Windows, capture the mouse, compare table orientation **180° default** to **0° via F3** from the same play state. Check visibility of ball, all players and both goals, then try 10 intended shots. If the same rail still blocks the field in both orientations, adjust **camera elevation and visibility separately**, not the shader or 2D physics.

**Next single action:** user screenshot of default 180° orientation on Windows.
