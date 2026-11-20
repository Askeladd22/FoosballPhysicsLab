# PAUL Phase 31-01 — UNIFY: gameplay-first visual readability

**Date:** 2026-11-20. **Branch:** `feat/foosball-gameplay-readability`. **Draft PR:** [#29](https://github.com/Askeladd22/FoosballPhysicsLab/pull/29).
**Base `main`:** `dc0c1999818991fe0cf3e63582b9fa2204b0afeb`.
**Status:** `IMPLEMENTED / CODE_AND_NATIVE_CI_VERIFIED / HUMAN_WINDOWS_UAT_NOT_RUN`.

## PLAN → APPLY → VERIFY
| Acceptance | Implementation and preserved behavior | Evidence |
| --- | --- | --- |
| AC1 — camera optimized for actual gameplay | Real 3D `renderer3d.lua` defaults to **GAMEPLAY**: camera targets the center of the green field with a wider projection of rods/ball, using a genuine perspective shader. **SHOWCASE** preserves the phase-30 camera aimed at entire furniture including four support legs. No geometry changed. | New `tests/test_foosball_gameplay_readability.lua` confirms projected green pitch more than **1.4×** the showroom view, with all field points in bounds at 900×650, 1280×850, 1650×895, 1920×1080. Lua 5.4 and LuaJIT **PASS**. |
| AC2 — easily reversible and safe controls | F4 toggles GAMEPLAY/SHOWCASE while maintaining score, match state and physical rod positions. Home returns GAMEPLAY; F2 camera side, F3 180° yaw, P/V 2D fallback, mouse capture and rod selection all preserved. | `tests/test_foosball_view.lua` covers F4 and Home without resetting gameplay. **PASS**. |
| AC3 — readable contact, selection and ball | Selected human shaft drawn as a subtle gold world-projected line. **Every selected foot marker** is projected directly from `Model.foot`, which the physical ball collider uses; these markers reflect actual translation and rotation. Actual `match.ball` receives a restrained white circle and a velocity line only when moving. No fake gameplay or added collision. | New pure Lua marker/projection assertions in gameplay camera and `test_foosball_renderer3d.lua` confirm every selected physical foot and the actual ball coordinates exactly. **PASS**. |
| AC4 — materials and HUD | Mild ambient material brightness boost in GPU shader; compact HUD with more concise controls at narrow window widths and explicit explanation of gold contact/white ball markers. CC BY source geometry intact. | Foosball render/input/headless tests **PASS**; native actual GLB smoke renders successfully. |
| AC5 — native model and legacy | CI runs two real LÖVE/Mesa GLB modes: SHOWCASE requires green surface plus **all 4 true legs**; GAMEPLAY requires enlarged visible green surface, no dark frame. Both actual GPU frames uploaded as artifacts. No `model.lua`, source GLB or frozen NEON11 edits. | [GitHub Actions #44761457020](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020): **7/7 jobs PASS**, Foosball/NEON11 on Lua5.4+LuaJIT, synthetic renderer/GLB importer, native real GLB. |

## Real GPU evidence, not a mock
The actual *versioned CC BY GLB* was converted and rendered in native LÖVE with a depth buffer:
- **SHOWCASE:** 56/255 probes above the non-background threshold; **67/99** green field probes; **4/4 actual legs visible**.
- **GAMEPLAY:** **207/255** probes above the non-background threshold; **74/99** green field probes, near 23/33 and far 24/33; native frame completed.
- Both genuine GPU Canvas images are in [the GitHub Actions artifact](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020/artifacts/14641711806). These are rendering/coverage metrics, NOT a fun, precision, FPS or eye-tracking measure.

## SEED decision log
**Observed** from user's Windows screenshot: upright model but relatively small pitch/figures/ball, isolated selection ring, visually black unused margins.
**Derived from code:** one camera was aimed at furniture center Y=-305, not play; projected selected rod and ball had no actual contact guidance. The importer already has actual 1018-triangle colored player geometry; camera and contact readability are a cheaper first fix than rewriting mesh rigging.
**Decided:** separated gameplay and showroom camera objectives; added restrained non-physics contact visualization and real match ball tracking rather than new features or g3d.
**Not verified:** readability, precision and enjoyment during real mouse play on the user's Windows GPU and input setup. A raster from Mesa cannot verify input feel.

## Game Design Lab next one step
**10 intentional real mouse strikes** under default GAMEPLAY camera; compare F4 SHOWCASE optionally. For each attempt ask whether selected rod, physical foot nearest the ball and shot direction are understandable; count unreadable contacts and accidental switching. If the markers are too strong or obscure the ball, adjust color/radii/opacity in `renderer3d.lua` rather than retuning physics.

**Merge gate:** keep PR #29 draft until the native Windows screenshot and user playtest approve the readability change.
