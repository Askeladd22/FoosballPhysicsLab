# PAUL State — Football Physics Lab

**Milestone:** v0.2.2 — Temporary arena touchlines and pass impulse tuning
**Current phase:** 04 — physics/gameplay refinement
**Cycle:** UNIFY PARTIAL — code + headless tests PASS, manual game-feel UAT NOT_RUN
**Branch:** fix/no-throw-ins-stronger-passes
**Pull Request:** https://github.com/Askeladd22/FootballPhysicsLab/pull/8
**Date:** 2026-11-19

## Evidence
- `src/sim.lua`: no throw-ins on upper/lower touchlines, physical rebound inbounds; goal-line restarts retained.
- `src/sim.lua`: only `action=="pass"` boosted via `passMultiplier=1.35`; shots and manual kicks unchanged.
- `tests/test_sim.lua` and `tests/test_boundary_passing.lua`: side rails, goal-lines, pass power, baseline game flow.
- CI GitHub Actions run **44555895328**, conclusion **success** on commit `ee0a70acec14d8bd3203691541bd6218ee6fcfd5`.
- Full task record: `.paul/phases/04-arena-rules/04-01-PLAN.md` and `04-01-SUMMARY.md`.

## Invariants
- LÖVE2D, original FM-inspired classic 2D camera, Etrusco prototype asset.
- Offline 5v5, single permanently controlled disc, pre-match goalkeeper/midfielder selection.
- Career remains deferred.

## Open checks
- Real LÖVE2D UAT of side rebound loop and kick-pass power.
- Adjust multiplier only after recording manual playtest feedback.
- Revert to authentic throw-ins later if requested.

## Single next action
Play one full 5v5 match on PR #8 in LÖVE2D and report ball-control / passing feedback.
