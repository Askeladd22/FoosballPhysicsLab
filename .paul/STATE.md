# PAUL State — Foosball Lab

**Primary:** Foosball Lab (active, scoped single-player game).
**Legacy:** NEON 11 / FootballPhysicsLab 11vs11 (FROZEN; not deleted).
**Phase:** 20 — Foosball-first repository and supplied GLB/STEP audit.
**Branch:** `feature/foosball-primary-project-pivot`.
**Updated:** 2026-11-20
**Status:** APPLY underway, UAT native LÖVE NOT_RUN.

Foosball launch: `love .`. Legacy launch: `love . --legacy`.
NEON 11 historical record preserved: [legacy state](../legacy/neon11/PAUL-STATE.md); all earlier PAUL phase folders remain unchanged.
This pivot does not modify `src/`, the Foosball physics model, or the user's other Project Folio repository.

## Next gate
Run all LuaJIT and Lua5.4 regression suites; play mouse-controlled Foosball natively before calling the new entry point validated. GLB/STEP assets remain reference-only until runtime/rights decisions.
