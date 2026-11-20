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


## Phase 21 — Table Soccer local visuals + contextual rod selector (2026-11-20)
**Current branch:** `feature/table-soccer-local-mesh-and-auto-rod` (draft PR review).
**Active:** default AUTO selects the best human rod as the ball changes X zones, with hysteresis/gesture hold; manual wheel/1-4 locks until TAB. 2.5D original model-derived sprites are generated **locally** with `tools/bake_table_soccer.py` from the user's own ZIP and never tracked by Git. V is A/B 2.5D/procedural. Physical collision 2D unchanged.
**Rights:** VERTX3D original Readme forbids redistribution in whole/part; no 3D source or derived sprite shipped via public repo. **Frozen:** NEON 11, all original sources/tests preserved.
**UAT:** native LÖVE and human feel NOT_RUN. See [PAUL 21 plan](phases/21-table-soccer/21-01-PLAN.md).
