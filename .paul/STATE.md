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


### UNIFY phase 24, 2026-11-20
GitHub [PR #22](https://github.com/Askeladd22/FoosballPhysicsLab/pull/22): **CI 4/4 PASS** on [run 44712405674](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44712405674). First view is oblique (P reverses to top-down), sprite feet are visibly linked to shaft and physically authoritative collision rectangle, and selected rod slide indicator is available. No 3D rig/physics migration; native Windows user camera test remains NOT_RUN. Phase [UNIFY](phases/24-oblique-camera/24-01-SUMMARY.md).


## Phase 25 — Real Table Soccer GPU meshes (2026-11-20)
Branch `feat/true-3d-table-soccer-runtime`. L'utente ha scartato esplicitamente le viste basate su sprite 2.5D e shear affine. Il nuovo `renderer3d.lua` renderizza le **vere mesh OBJ convertite localmente**, con prospettiva, profondità e otto aste animate dal mouse e dall'IA tramite `model.lua`. `tools/import_table_soccer_3d.py` importa il modello originale in 11 buffer privati senza dipendenze Python. **P/V** commuta 3D/2D; in assenza di file proprietari il gioco mantiene un fallback procedurale. Asset Table Soccer esclusi da Git. NEON11 non modificato. Piano in `phases/25-true-3d/25-01-PLAN.md`; native 3D screenshot/UAT ancora da verificare.

### Phase 25 UNIFY
[PLAN](phases/25-true-3d/25-01-PLAN.md) · [SUMMARY](phases/25-true-3d/25-01-SUMMARY.md) · [Verified code CI](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44717700176). **5/5 jobs PASS** including native software GPU LÖVE 11.5 with synthetic meshes and all Lua Foosball/NEON11 regressions. Local original OBJ converted to 11 real mesh buffers; user's full-model native Windows screenshot/FPS/input UAT remains **NOT_RUN**. PR #23 draft, main untouched.

## Phase 26 — Black-screen fixed and CC BY model pipeline
**Branch:** `fix/3d-depth-and-ccby-model-pipeline`. **PR:** [#24](https://github.com/Askeladd22/FoosballPhysicsLab/pull/24), draft.
**Code/CI status:** `IMPLEMENTED / 6 of 6 PASS` in [run 44728693467](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44728693467), including actual canvas pixel coverage 46/255 and synthetic 103-part GLB importer.
**Diagnosis:** mistakenly initialized depth=0 with `lequal`, hiding all 3D triangles. Fixed to depth=1.
**Art direction:** select user-uploaded CC BY 4.0 `foosball_table (2).glb` from 3D Content Online. 103 mesh parts converted to 11 game rigs, re-instanced to physical 1-2-5-3, more efficient than private old VERTX3D model.
**Asset provenance:** `assets/models/ATTRIBUTION.md` and offline importer committed. Full CC BY binary GLB provided in separate repo-ready downloadable package but **NOT uploaded to GitHub yet**, due lack of direct binary attachment bridging into connector. Do not misrepresent its Git state. Frozen NEON11 untouched.
**Human native Windows UAT:** NOT_RUN. Read [PLAN](phases/26-depth-ccby/26-01-PLAN.md) · [UNIFY](phases/26-depth-ccby/26-01-SUMMARY.md).

## Phase 27 — CAMERA opposite-side, adaptive zoom (2026-11-20)
**Branch:** `fix/foosball-3d-camera-orientation-distance`, [PR #25](https://github.com/Askeladd22/FoosballPhysicsLab/pull/25) draft, `main` not modified by this PR.
**Implementation:** The CC BY real 3D tabletop now defaults to a farther/elevated view from the opposite long edge. The eye is adapted to viewport aspect; F2 flips the side, PageUp/PageDown zoom, Home resets. Same GPU shader/CPU camera basis. Physics, mouse rods, 3D GLB and frozen NEON11 not changed.
**Verification:** [GitHub Actions run #44731794359](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44731794359) **7/7 PASS**, including native rendering with the actual CC BY GLB (169/255 visible framebuffer pixel probes), synthetic mesh smoke, camera geometry tests and both Lua Foosball/NEON11 suites.
**Not verified:** real screenshot with this exact new camera on user's Windows PC and human readability/feel. [PLAN](phases/27-camera-fix/27-01-PLAN.md) · [UNIFY](phases/27-camera-fix/27-01-SUMMARY.md).
