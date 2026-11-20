# PAUL State — FoosballPhysicsLab

**Active:** Foosball Lab directly in root, Neon Glass / optional private Table Soccer 2.5D sprites.
**Frozen:** NEON 11 with full source, test and documentation in `legacy/neon11/`.
**Current phase:** 23 — human rod responsiveness and visual 2.5D clarity.
**Branch:** `fix/foosball-direct-rods-crisp-table-soccer`, [draft PR #21](https://github.com/Askeladd22/FoosballPhysicsLab/pull/21).
**Status:** `DONE_WITH_CONCERNS`; Foosball and legacy regression gates verified on LuaJIT/Lua5.4, native Windows/LÖVE UAT not yet done.
**Date:** 2026-11-20.

## SEED decisions
- Keep the original 2D ball, collision and 120 Hz fixed outer simulation.
- Human-only input rods use bounded, low-latency target-following; AI's slower spring unchanged.
- AUTO recognizes sustained small mouse movements as a gesture; TAB manual lock remains.
- Display original Table Soccer as **local pre-rendered 2.5D sprites** only, not 3D meshes: avoid ghost double pose, increase table visibility, preserve selected physical strike edge. 25-frame local re-bake available; 9-frame pack compatible.
- User-provided Table Soccer material and derived images stay outside GitHub due redistribution restriction.
- No additional career, rankings, multiplayer, 11vs11 gameplay or Project Folio changes.

## Evidence
[PLAN](phases/23-foosball-response/23-01-PLAN.md) · [UNIFY](phases/23-foosball-response/23-01-SUMMARY.md).
[CI 44709666789](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44709666789) 4/4 PASS. Final guidance UI adjustment has independent [run 44709875435](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44709875435) (legacy Lua5.4 still running at last check). Real mouse feel and native visuals not verified.

## Next single action
Native Windows playtest: click once to capture the mouse, perform 10 rapid physical shots with AUTO and MANUALE, compare V on/off and report perceived response and sprite alignment.


## Phase 24 — Oblique 2.5D camera and physical shoe linkage
Branch `feat/foosball-oblique-camera-strike-alignment`. The elevated oblique camera defaults on; **P** toggles top-down. World physics is unchanged, and the root view transforms ball, feet and backdrop together. Rendered Table Soccer feet are now accompanied by a **connected physically authoritative shoe**, rather than detached collision markers. Native Windows camera/feel UAT **NOT_RUN**; refer to `.paul/phases/24-oblique-camera/24-01-PLAN.md`.
