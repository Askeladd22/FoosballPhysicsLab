# PAUL Phase 29-01 — UNIFY: Upright Table Soccer, visible pitch

**Date:** 2026-11-20.
**Branch:** `fix/foosball-upright-playable-pitch`.
**Draft PR:** [#27](https://github.com/Askeladd22/FoosballPhysicsLab/pull/27).
**Base main:** `49529f09cbbb865799cfb28596aa0d157bc4d8d1`.
**Status:** `CODE_COMPLETED / ALL_7_CI_JOBS_PASS / WINDOWS_HUMAN_UAT_NOT_RUN`.

## The actual error — SEED evidence (measured, not guessed)
The user's Windows screenshot made the **CC BY 4.0 3D table look inverted** with handles sticking upward and the near frame obscuring the green field. Previous fixes repeatedly changed the scene yaw or camera side and missed the source.

The actual source `foosball_table (2).glb` is **already oriented correctly in Y-up space**: field vertices at source Y≈0.7359; legs/underside mesh parts reach source Y≈0.04. After `tools/import_foosball_glb_ccby.py`: field at world **Y≈−4.1..−3.6**, real under-table supports at **Y=−740**, the upper rim at **Y=130**. An X/Z 180° flip would be wrong — it would put the **legs above** the pitch. The apparent upward "legs" are protruding rod handles, not supports.

The true defect was **camera occlusion by the 130-unit-high side rail**: previously the camera looked down ~50° above horizon from beyond the near rail, so the black wall dominated the frame and hid the green pitch.

## PLAN → APPLY → Verification
| Gate | Work | Verification |
|---|---|---|
| AC1 — legs must point down | Preserve correct GLB vertex Y and the user-requested 180° *horizontal* yaw. No vertical inversion, no model binary rewriting. Add `tools/test_foosball_model_upright.py`, reading the actual converted 28-byte GPU vertices, checking field near Y0, 46,080 vertices below -250 and min Y<-450 versus pitch; rim above. | **PASS** real CC BY source: supports min Y **−740**, field **−4**, rim max Y **130**. |
| AC2 — field actually visible | Move default camera inside the tall near wall's footprint and above it: effective `eyeY=15+1300×fit`, `eyeZ=280±250×fit`, target at `(500,15,280)`, FOV **35°**. View roughly **79° downward**, rather than ~50°. Both sides F2 continue to work. Gameplay, physics, mouse, 180° yaw, F3 and Home retained. | `tests/test_foosball_upright_camera.lua` checks >75° elevation, eye inside side rails and field visibility at 4 resolutions. Historical camera regression updated to FOV35. **PASS** LuaJIT/Lua5.4. |
| AC3 — real green surface, not rail pixels | `ThreeD.assertFieldVisible()` projects a **99-point grid** onto the actual field mesh and samples native GPU Canvas pixel colors. It requires substantial green coverage in the overall field and **both near/far areas**. The CLI `--verify-3d-field` is independent of old `--verify-3d-pixels`. | Actual versioned CC BY GLB converted in CI and rendered under real LÖVE/Mesa: **73/99 green field samples**, **near 26/33, far 23/33**. Old generic pixels 147/255. 12-frame smoke PASS. |
| AC4 — preserve other game | No changes in `model.lua`, imported GLB, material, raw mesh, `legacy/neon11/` or game UI controls. | [GitHub Actions run #44747974175](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44747974175): **7/7 jobs PASS**, 2 Foosball, 2 legacy NEON11, 1 synthetic GLB importer, 1 synthetic GPU, 1 native GPU/real GLB + field. |

## Game Design Lab hypothesis and test
**Supported:** this camera now shows a substantial part of the *actual green playfield*, not merely an opaque wall. The geometric feet-below-field invariant is enforced. **Not demonstrated:** whether the Windows player's view is aesthetically correct, the full model's 3D foot contact accurately matches the game physics, frame rate on user's hardware, and whether 10 swipes are now naturally readable. These remain native user UAT and must not be inferred from CI success.

**Next one action:** on Windows check out PR #27, run `love .`, capture the mouse, compare F2 and F3, and test 10 shots while inspecting whether the field/ball and physically correct underside supports are obvious. If the user dislikes the high camera, adjust composition/height without inverting the mesh.
