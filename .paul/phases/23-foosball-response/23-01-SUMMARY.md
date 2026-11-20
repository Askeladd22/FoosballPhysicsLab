# PAUL Phase 23-01 — UNIFY: rod response + honest Table Soccer rendering

**Date:** 2026-11-20.
**Branch:** `fix/foosball-direct-rods-crisp-table-soccer`. **Draft PR:** [#21](https://github.com/Askeladd22/FoosballPhysicsLab/pull/21).
**Baseline main:** `49ca0360504dfed4bb6f6f47782111ad91fe001d`.
**Status:** `DONE_WITH_CONCERNS` — automated Foosball verification successful; native LÖVE/Windows response + model visual UAT **NOT_RUN**.

## PLAN → APPLY → verification

| AC | Implemented | Evidence |
| --- | --- | --- |
| AC1 — responsive rods, physical collision | Human rods follow target slide/angle through fast but capped velocity servos in the existing 1/240s microsteps; live `vy/omega` still drive contact impulses and bumpers. AI retains original damped spring. | `tests/test_foosball_response.lua` speed caps, 100ms latency envelope, physical ball hit and AI comparison; normal `tests/test_foosball.lua`; **PASS LuaJIT + Lua5.4** |
| AC2 — AUTO during small repeated mouse swipes | Input hold triggers on small-but-real mouse events (`abs(dx)+abs(dy)>=3`) as well as large swipes; TAB and manual rod locking remain intact. | `tests/test_foosball_response.lua`, `tests/test_foosball_selector.lua` **PASS** |
| AC3 — 2.5D visual integrity | Replaced two simultaneous alpha-faded poses with **one crisp pose**, raised table transparency from 12% to 36%; selected foot collision square is highlighted, unselected floating white contact markers de-emphasized, HUD correctly says 'sprite 2.5D'. | `tests/test_foosball_mesh_art.lua`: 9-pose fallback, single draw call and 25-pose upgrade **PASS**; visual screenshot **NOT_RUN** |
| AC3b — optional high resolution | Local-only OBJ baker now emits 25 pose sprites per rod, total 201 PNG with table. Existing 9-pose packs load and still work. Assets remain ignored by Git and are never published. | Synthetic baker self-test **PASS**; full user ZIP conversion with this new version **NOT_RUN** |
| AC4 — regression / 11vs11 freeze | Only root Foosball and docs/tests updated, no change in `legacy/neon11` modules. | [CI 44709666789](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44709666789): **4 jobs PASS** on LuaJIT + Lua5.4. Later one-line guidance UI commit: Foosball jobs PASS in [run 44709875435](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44709875435); legacy Lua5.4 was still running on last inspection. |
| AC5 — native LÖVE | Highlighted hint for unlocked OS pointer: click inside game to capture relative mouse motion, otherwise cursor hits window edge. | Code/UI mock test PASS; Windows UAT **NOT_RUN** |

## SEED decision / truth in evidence
- **Observed:** user screenshot reads 'TABLE SOCCER 2.5D' and shows translucent ghost figures; the cursor is **not** captured according to the HUD.
- **Derived:** the game displays private **pre-rendered geometry sprites**, NOT independent real-time 3D meshes; blending two sprites creates visual doubling, while low-damped spring creates lag. A free cursor cannot rotate indefinitely when it hits the OS window boundary.
- **Decided:** solve input-to-pose lag first, retain 2D physical contact, make 2.5D rendering precise about its nature, and defer a complete 3D renderer/rig until that separately justified milestone.
- **Unverified:** individual strike power and fairness at 240Hz microstep, FPS under full model, whether 25-frame stepping is sufficiently smooth, and human comfort. Automated checks do not establish fun or perceived responsiveness.

## Game Design Lab decisive test
Check out PR21 and **click** once to capture cursor. Make ten rapid horizontal strokes in AUTO and five in MANUALE, then press V to compare the procedural model and private Table Soccer sprites. Check whether each hit occurs on the displayed *white physical edge* and whether AUTO switches under the player mid-stroke. For the smoothest local appearance, regenerate user's private sprites with `python tools/bake_table_soccer.py C:/path/Table_Soccer.zip` (no model/mesh redistribution).

**Next one action:** native LÖVE UAT at 1280×850 with captured mouse and regenerated 25-pose pack, then adjust servo gain only if actual gameplay shows a problem.
