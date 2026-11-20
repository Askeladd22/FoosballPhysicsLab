# PAUL Phase 20-01 — UNIFY: Foosball-first repository and supplied models

**Date:** 2026-11-20. **Branch:** `feature/foosball-primary-project-pivot`.
**PR:** [#18](https://github.com/Askeladd22/FootballPhysicsLab/pull/18) (draft, **not merged**).
**Baseline:** `71b8c0bde5a89e70888c6bc0738f49e6e8e8524c`.
**Status:** `APPLY_DONE / CI_VERIFIED / HUMAN_UAT_NOT_RUN`.

## PLAN → APPLY → evidence
| Gate | Change | Result |
|---|---|---|
| AC1 — primary executable | Root `main.lua` dispatches to Foosball on genuine LÖVE 11.x; `--legacy` explicitly routes to frozen NEON 11; `conf.lua` has Foosball settings | `tests/test_project_boot.lua` **PASS** on LuaJIT / Lua5.4; native Windows **NOT_RUN** |
| AC2 — preserve old code | Original 11vs11 controller copied byte-for-byte to `legacy/neon11/main.lua` and all `src/` unchanged. New root launcher maps existing headless test mocks to original controller. | Full historical NEON 11 suites **PASS** on LuaJIT / Lua5.4 |
| AC3 — product documents | New Foosball-first `README.md`, `PLANNING.md`, `.paul/STATE.md`; original README/SEED/PAUL preserved in `legacy/neon11/`; Windows .bat launchers for both. | Paths in PR verified; old tests not removed |
| AC4 — model provenance | `docs/asset-intake/` and `assets/reference/` record exact provided model geometry/licensing. Pure Python metadata parser with self-test. Models **not** committed. | `python3 tools/inspect_foosball_models.py --self-test` **PASS** |
| AC5 — CI and UAT | Full GitHub Actions [run 44699893496](https://github.com/Askeladd22/FootballPhysicsLab/actions/runs/44699893496) on code/docs commit `2d8db8d4e3065dc6b070be507568b131d158ef0c` | LuaJIT **PASS**, Lua5.4 **PASS**; native LÖVE and human fun test **NOT_RUN** |

## SEED decision ledger
- **DECIDED:** Foosball Lab is the *actual* default runnable game, with existing Neon Glass visuals, the user-facing mouse rod controller, physical ball, quick solo matches and basic AI.
- **DECIDED:** Old 11vs11 is frozen and fully preserved, not renamed away/deleted, with an explicit runtime route.
- **DECIDED:** Supplied GLB/STEP are **reference files only**, not directly loaded or redistributed; CC BY 4.0 attribution for the GLB is documented. Original STEP redistribution rights remain **UNKNOWN**.
- **ASSUMED / UNVERIFIED:** a future 2.5D static-table pre-render might improve presentation, but live rods in the GLB are merged with the mesh; 3D implementation/rigging is not done, and no FPS or native visual playtest is claimed.
- **OPEN:** whether to rename the existing GitHub repository after the pivot, whether the STEP can be redistributed, and whether offline GLB art improves actual gameplay.

## Game Design Lab — next decisive experiment
1. On Windows with LÖVE 11.5: `love .` must start Foosball and `love . --legacy` NEON 11.
2. Test ten intentionally aimed Foosball strokes and three trapped balls, verify neutral restarts/foot clarity at Glow ON/OFF.
3. Only then consider offline 3D table art and physically independent rods, comparing against existing procedural Neon Glass.

**Exit condition:** do not merge merely because CI is green; native launch and visual/controls UAT still require user confirmation.
