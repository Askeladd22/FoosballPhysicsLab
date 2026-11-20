# PAUL UNIFY 37-01 — DOPPIA Difesa+Attacco e camera più ravvicinata

**Result:** DONE_WITH_CONCERNS / VERIFIED_AUTOMATED / HUMAN_WINDOWS_UAT_NOT_RUN
**PR:** [#35](https://github.com/Askeladd22/FoosballPhysicsLab/pull/35) · branch `feat/foosball-dual-rods-closer-camera`.
**Tested source SHA:** `153522d63e6964fac64f34f4c3988dba13d5cba2`. [GitHub Actions #44798062408](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44798062408): **7/7 PASS** on that SHA, including Foosball Lua5.4 + LuaJIT, frozen NEON11 Lua5.4 + LuaJIT, real GLB model importer, real LÖVE GPU synthetic and **true 3D CC BY GLB**.

## PLAN vs APPLY / implementation
- **T1 DONE / PASS:** `model.lua` implements `dual` control mode, with `Game:toggleDualRod()` and `Game:isRodControlled(slot)`. Mouse X/Y sets target angles/slides for both human rods 2 (Difesa) and 4 (Attacco). No physical slide/omega/velocity teleports and no special ball impulse; original contact solver and individual clamps are unchanged.
- **T2 DONE / PASS:** `main.lua` maps **D** to toggle DOPPIA, HUD names both active rods, 2D paints both active; `renderer3d.lua` projects two real shafts and all five physical foot markers (2+3), while preserving old single marker call. TAB leaves dual into AUTO, 1–4/rotella into MANUALE, D-off restores previous state and slot, C zeroes both target angles and reset clears prior mode.
- **T3 DONE / PASS automated:** camera reset=0.78 (~128%; was 1.00), min zoom=0.70 (~143%; was 0.80) with same 43-degree GAMEPLAY FOV, scene/camera yaw, HUD viewport and original GLB. `ThreeD.effectiveCameraDistance()` protects original 100%-fit SHOWCASE F4 while GAMEPLAY boots at approx 128% zoom (slightly closer than the screenshot at 125%) and keeps zoom percentages coherent.
- **T4 DONE / PASS tests & doc:** added `tests/test_foosball_dual_rods.lua`, updated 3D CPU/GPU marker tests, HUD key D checks, 5 viewport camera framing tests and showcase reset/zoom test. Updated `PLANNING.md` and PAUL plan, STATE, ROADMAP, SUMMARY.

## Trail of Bits spec-compliance matrix (this is Lua, not C++)
| Requirement | Code/evidence | Result |
|---|---|---|
| Mouse controls 2 + 4 simultaneously without extra IA | `Game:mouseMoved`, dual regression, 120Hz servo | IMPLEMENTED / PASS |
| Physical limits/contacts remain separate and deterministic | `stepRod` / `contact`, two stopCounts, real hit test | IMPLEMENTED / PASS |
| Reversible controls (D, TAB, 1–4, wheel, C, reset) | `toggleDualRod`, `selectRod`, `toggleAutoRod`, test | IMPLEMENTED / PASS |
| Visual feedback 2D / GPU 3D for both rods | HUD/rods() / `playerIndicators`, 5 toes, mock GPU test | IMPLEMENTED / PASS |
| GAMEPLAY closer, SHOWCASE unchanged | `resetCamera`, `effectiveCameraDistance`, camera tests | IMPLEMENTED / PASS |
| Human perception/fun under simultaneous strokes | Windows playtest | UNKNOWN / NOT_RUN |

## Matt Pocock / Simplify Codebase / CCteam QA
- **Spec:** user asked to be a bit closer and manipulate defence+attack simultaneously; tests reject auto switching during DOPPIA and ensure two independent physical rods. All code changes in pure Lua.
- **Architecture:** no second input system, extra 3D engine, persistent duplicate rod state or collision override; a third control mode reuses original physics. A small camera normalization handles SHOWCASE without a second orbital rig.
- **Failure loop:** Initial runs [44796424442](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44796424442) and [44796693138](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44796693138) revealed two test issues: SHOWCASE scale originally was affected by reduced GAMEPLAY distance, corrected by normalizing distance; and GPU test assumed AUTO after returning from DOPPIA even when MANUALE was the stored mode, corrected to verify MANUALE restoration. Complete run 44798062408 proves both fixes.
- **Completion gate (Unlazy):** 7 automatic jobs PASS on verified code. Windows native gameplay, physical pointing device and subjective legibility still NOT_RUN; do not mark fully user validated.

## Game Design Lab — reality check
**Goal:** playable attack and defence without switching between rods mid-gesture.
**Mechanism:** synchronized mouse X/Y targeting on two authentic physical rods, with real collisions; dual visually visible.
**Weakest assumption:** symmetric strokes might produce unwanted off-ball or simultaneous touches because two rods cannot receive opposite intents. Validation: 10 passes/shots and 10 saves in DOPPIA versus AUTO, count unintentional contacts and whether the 128% default camera crops action. If poor, consider a modifier key to temporarily isolate one rod in DOPPIA, but DO NOT add this unrequested complexity now.

## Next action
On Windows, `git pull` (only after merge); launch `love .`, press **D**, move/rotate both, press TAB / 1–4 / D and confirm prior behavior; compare zoom. User-supplied screenshot is direct complaint, automated GLB screenshot is CI evidence, not proof of subjective gameplay comfort.
