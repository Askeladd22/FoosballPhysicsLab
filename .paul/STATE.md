# PAUL State

**Project:** Football Physics Lab
**Milestone:** v0.2.1 — Gameplay stability + classic 2D
**Phase:** 02 — stabilization and visual verification
**Loop:** APPLYING — automated checks PASS, LÖVE UAT NOT_RUN
**Branch:** fix/matchlab-stable-setpieces-and-passes
**Pull request:** https://github.com/Askeladd22/FootballPhysicsLab/pull/5
**Updated:** 2026-11-19

## Verified evidence
- GitHub Actions run 44551540530: SUCCESS on syntax, headless match tests and mocked renderer smoke.
- Four boundary restarts, kickoff, analog steering, pressing stability and AI passing have scenario-level regressions.
- FM27-inspired classic 2D view implemented in src/view.lua with ball shadow, feet direction and nets.

## Limits / UAT
- The mocked renderer cannot verify real frame appearance in LÖVE.
- Full-match tactical behavior and feel are NOT_RUN; do not mark gameplay ready.
- Set pieces are intentionally simplified, not full real football rules.
- Etrusco ball design from user reference is prototype-only pending redistribution rights.

## Planning and partial UNIFY
- .paul/phases/02-gameplay-stability/02-01-PLAN.md
- .paul/phases/02-gameplay-stability/02-02-PLAN.md
- .paul/phases/02-gameplay-stability/02-01-02-SUMMARY.md

## Next action
Play one complete three-minute 5v5 match from PR #5 in LÖVE and report movement, rimesse, passaggi and camera readability.
