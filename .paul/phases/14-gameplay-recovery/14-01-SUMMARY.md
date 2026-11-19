# PAUL 14-01 SUMMARY — Gameplay Recovery

**Date:** 2026-11-19. **Outcome:** APPLY_DONE / UNIFY_DOCUMENTED / DONE_WITH_CONCERNS.
**Project:** Football Physics Lab; implemented on an unmerged PR branch, not main.
**Baseline:** ba8e5251c58479fb6d9080d7525c3785b0f79003
**PR:** https://github.com/Askeladd22/FootballPhysicsLab/pull/10

## PLAN → APPLY results
| AC | Evidence / qualification |
| --- | --- |
| AC1 Directional manual pass | `src/sim.lua`: aim-cone receiver selection (dot >= 0.55) with directional space-pass fallback; new test `tests/test_gameplay_recovery.lua`. Automated **PASS under LuaJIT**; UAT NOT_RUN. |
| AC2 Failed input | `src/sim.lua` stores 180 ms input retry; HUD feedback in `src/view.lua`; reset clears queue. LuaJIT test **PASS**, UAT NOT_RUN. |
| AC3 11v11 scale | Ball radius 0.83 → 0.62; player radius 1.32 → 1.10 in 11v11. Legacy 5v5 dimensions retained. Offside regression fixture now derives distance from radii rather than hard coding. LuaJIT suite **PASS**, UAT NOT_RUN. |
| AC4 AI support stability | `src/ai.lua`: 1.75-unit support-target deadband within 8 units of anchor; pressing/receiving remain responsive. Regression suites **PASS under LuaJIT**; naturalistic quality not measured. |
| AC5 Tactics A/B | `src/sim.lua` defaults live auto-coach OFF, `main.lua` exposes F2 toggle; existing coach and 45 role definitions kept. Existing coach test explicitly opts into live updates. LuaJIT tests **PASS**. |
| AC6 Touchlines | `src/sim.lua`: top/bottom rail bounces without throw-ins; goal line keeps corners, goal kicks and scoring. Boundary and rule tests updated; LuaJIT **PASS**. |
| AC7 Full regression gate | GitHub Actions [run 44630731256](https://github.com/Askeladd22/FootballPhysicsLab/actions/runs/44630731256): LuaJIT **PASS**. Lua 5.4 status must be checked before merge; human in-game UAT NOT_RUN. |

## QA record
- Two earlier iterations exposed test failures: old hard-coded offside challenge distance after physical resizing, and an HUD smoke test expecting the original Q + SPAZIO label. Both corrected without removing those checks.
- New `tests/test_gameplay_recovery.lua` isolates manual direction, free-space action, prompt feedback/buffer, radii and frozen coaching mode.
- Existing procedural passing physics remains for AI; human pass direction uses a deliberate aimed impulse at genuine contact. This is an arcade control choice, **not** a physical billiardino-foot collision model.
- CPU/memory profiling, exact human pass accuracy, goalkeeper satisfaction, and AI naturalness are not validated by CI.

## SEED / Game Design Lab decision
**Committed:** protect 11v11 on main and test its repaired feel in a review-only PR.
**Candidate only:** alternative realistic foosball (8 rods, sliding and rotating figures, mechanical contact, wall rebounding, single-player skill career), specified in `docs/Foosball-Feasibility.md`.
**Not implemented:** the foosball game or career mode.
**Next single action:** manual LÖVE UAT on the PR (RM/GK directional passing, collisions, tactical A/B), then decide whether to create the separate foosball vertical slice.
