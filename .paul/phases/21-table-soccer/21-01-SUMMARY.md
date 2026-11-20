# PAUL 21-01 — UNIFY: private Table Soccer mesh sprites + easy rod selection

**Date:** 2026-11-20. **Project:** FoosballPhysicsLab (Foosball Lab is primary; 11vs11 is frozen).
**Branch:** `feature/table-soccer-local-mesh-and-auto-rod`. **Draft PR:** [#19](https://github.com/Askeladd22/FoosballPhysicsLab/pull/19).
**Baseline main:** `b6a9074e58f2544156d9fd429ea81e97c3ef14cc`.
**Status:** APPLY_DONE / AUTOMATED_VERIFIED / HUMAN_UAT_NOT_RUN.

## PLAN → APPLY evidence
| Acceptance criterion | Implemented | Result |
|---|---|---|
| AC1 — intuitive rod control | Added `rod_selector.lua`: default AUTO selects from 4 human rods using predicted ball X and reachable Y, 32px hysteresis, 280ms cooldown and 200ms gesture lock. `Tab` toggles AUTO/MANUALE; wheel/1–4 locks manual selection. No automatic rotation/shooting. | New `tests/test_foosball_selector.lua`: **PASS Lua 5.4 and LuaJIT** |
| AC2 — actual source geometry | `tools/bake_table_soccer.py` processes *user-owned* `Table_Soccer.zip` OBJ groups, bakes 9 true 3D rotation poses for each of the 8 named rods (72 PNGs) and one static table image; manifest records author/rights/source hash. The script extracts nothing to a public tracked path. | Real archive inspected and **73 private PNGs generated** locally, 132,246 OBJ vertices and 10 selected groups. CLI synthetic group-parser self-test in CI: **PASS**. |
| AC3 — 2.5D live rendering | `mesh_art.lua` loads 73 files *only* if local `manifest.json` and all frames exist. Physical `model.lua` remains authoritative; rendered rig slides to its rod Y, frames interpolate across true player rotation. White 2D collision-strike face remains visible. `V` toggles original Neon Glass when local pack exists. A missing/incomplete pack falls back safely. | `tests/test_foosball_mesh_art.lua` **PASS Lua 5.4 and LuaJIT**; native LÖVE **NOT_RUN**. |
| AC4 — no distribution and regressions | Model-derived sprite output excluded by root `.gitignore`; original ZIP/FBX/OBJ not committed. Readme/license notes and optional Windows local converter added; frozen `src/` unchanged. | Diff targeted to Foosball files, documents, build helper/tests. [CI run 44704660956](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44704660956) **PASS Lua 5.4 + LuaJIT**. |
| AC5 — Game Design Lab user experience | Test plan specifies comparison AUTO/MANUALE and V mesh/procedural while taking ten intentional shots. | **NOT_RUN** — no actual native Windows game session or timed FPS measurement. |

## SEED decisions
- **DECIDED:** 2.5D sprites using the real separated mesh groups, not migration to 3D physics or another engine.
- **DECIDED:** AUTO is default, explicit manual lock for predictable skill control, mouse Y and X remain physically meaningful.
- **DECIDED:** preserve no-download procedural Neon Glass playability and exact original ball/kick physics. No career, leaderboards or network mode.
- **DECIDED:** originals and derived sprites are **not published** in the public GitHub repository. User received a separate private conversion package from their own supplied original; it is not part of git history.
- **RIGHTS:** VERTX3D/Hend Z. `Readme.txt` allows commercial/noncommercial use but forbids redistribution of the model in whole or part; any distributable build containing mesh-derived assets needs further rights clarification.
- **UNKNOWN:** long-session AUTO switch feel, precise perception of foot/collider alignment for every pose, Windows GPU performance. Automated tests do not establish these.

## Corrected during verification
- UI smoke test initially failed because a shortened footer no longer printed `glow OFF`; the status label was restored.
- AUTO switching initially ignored the brief initial cooldown after reset; state now initializes `rodSwitchedAt=0`, and the full AUTO/manual regression passes.
- No merged changes were made to `main` during this task.

## Game Design Lab next decisive action
From branch PR #19, place the user's private `local_assets/` beside `experiments/foosball/main.lua`; run `love .`. Perform 10 aimed strikes in AUTO, three with manual selection, press V to compare original mesh sprites against procedural drawing, and observe any unexpected switches/misaligned strike faces or slowdowns. **If AUTO interrupts more than one deliberate strike, change the switching policy before adding visual polish.**
