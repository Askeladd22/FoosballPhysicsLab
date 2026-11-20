# PAUL State — FoosballPhysicsLab

**Active:** Foosball Lab in root, real CC BY GLB true 3D as default, Neon Glass 2D fallback.
**Frozen:** NEON 11 with full source, test and documentation in `legacy/neon11/`.
**Current phase:** 37 — dual human defence/attack rods and slightly closer default GAMEPLAY view.
**Branch:** `main`; [PR #35](https://github.com/Askeladd22/FoosballPhysicsLab/pull/35) **MERGED** as `0da91aeac9f27fcfd9bbc987f99f6d623dabeae8`.
**Status:** `VERIFIED_AUTOMATED / UAT_NOT_RUN`; phase 37 features on code commit 153522d passed [CI 44798062408](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44798062408) **7/7** with Lua5.4/LuaJIT, native real GLB and frozen NEON11. Physical Windows playtest NOT_RUN.
**Date:** 2026-11-20.

## SEED decisions
- Keep the original 2D ball, collision and 120 Hz fixed outer simulation.
- Human-only input rods use bounded, low-latency target-following; AI's slower spring unchanged.
- AUTO recognizes sustained small mouse movements as a gesture; TAB manual lock remains.
- Current true 3D runtime renders the CC BY GLB table and real rigged feet; the flat 2D fallback remains available. Earlier 2.5D sprite experiments are historical, not the present default.
- Proprietary Table Soccer content stays outside GitHub; the openly licensed CC BY GLB model is versioned with its required attribution.
- No additional career, rankings, multiplayer, 11vs11 gameplay or Project Folio changes.

## Evidence
[PLAN phase 37](phases/37-dual-rods-close-camera/37-01-PLAN.md) · [UNIFY phase 37](phases/37-dual-rods-close-camera/37-01-SUMMARY.md) · [CI 44798062408](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44798062408) 7/7 PASS for dual physical rod input and closer camera, including real 3D GLB. Native human playtest NOT_RUN.

## Next single action
Windows UAT: play 10 blocks and 10 shots using DOPPIA (D) then AUTO (TAB), ensure two golden rods move and shoot physically; compare camera default 128% (slightly closer than the screenshot at 125%) with user-controlled zoom up to ~143% while checking visibility.


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

## Phase 28 — Whole-world 180° 3D rotation (2026-11-20)
**Branch:** `fix/foosball-rotate-world-180`; new draft PR covers this change, independent of previously merged camera and model work.
**Change:** actual Table Soccer GPU geometry rotated **180° about world Y** centered at (500,280) in X/Z space. The ball, all eight rods, field, table, lighting normals and CPU selected-rod marker use the same transform. Source mesh buffers and the fixed-step physical game are not rotated or overwritten. **F3** toggles 180°/0°, **F2** still flips camera, **Home** resets camera and 180°.
**SEED:** no g3d dependency; unnecessary, because the existing true-3D shader already supports a rigid world transform.
**PAUL:** [PLAN](phases/28-world-rotation/28-01-PLAN.md); UNIFY follows CI results. **Native user screenshot/playtest NOT_RUN**.

### PAUL phase 28 UNIFY — 7/7 code/GLB/native GPU gates PASS
[PLAN](phases/28-world-rotation/28-01-PLAN.md) · [SUMMARY](phases/28-world-rotation/28-01-SUMMARY.md) · [CI 44743973107](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44743973107).
The **whole world** yaw is now 180° about upright Y, rigidly rotating the actual GLB table, field, all 8 rods, ball and normals, with CPU marker projection synchronized. **F3** toggles to 0°; F2 camera side is separate, Home restores 180° and camera defaults. No g3d dependency, since existing LÖVE shader/mesh runtime is already true 3D. All seven jobs PASS, including real GLB/11 GPU meshes/169 of 255 visible-pixel checks, two Foosball Lua, two frozen NEON11 Lua and synthetic model smoke. **User Windows screenshot/playing feel remains NOT_RUN**. No 3D model source, binary asset or 11vs11 gameplay changed.

### PAUL phase 29 — real legs below, visible field (2026-11-20)
**Branch:** `fix/foosball-upright-playable-pitch`, [PR #27](https://github.com/Askeladd22/FoosballPhysicsLab/pull/27) draft. [PLAN](phases/29-upright-pitch/29-01-PLAN.md) · [SUMMARY](phases/29-upright-pitch/29-01-SUMMARY.md).
**Geometric evidence:** the actual CC BY GLB is already Y-up, table legs min world Y=-740 and field Y≈-4; upright orientation invariant now tested. The alleged skyward "legs" in screenshots are rod handles; do not invert the source vertically.
**Applied:** default camera raised to ~79° pitch / FOV35 above the near rim, keeping the 180° world Y yaw and all physics.
**CI:** [run 44747974175](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44747974175) **7/7 PASS**, real GPU model rendered 73/99 green field samples, near 26/33, far 23/33, leg-below-field test PASS. Frozen NEON11 untouched.
**Remaining:** native Windows screenshot, human input/readability and foot alignment UAT NOT_RUN.

### Phase 30 — Canvas Y inversion FIXED; complete upright 3D table (2026-11-20)
**Branch** `fix/foosball-show-real-legs-3quarter-camera` · [PR #28](https://github.com/Askeladd22/FoosballPhysicsLab/pull/28) draft.
**Actual diagnosis**: source geometry was already upright, but custom GPU shader output was vertically inverted on LÖVE Canvas. The earlier high camera compounded the bug by cropping all four real support feet outside frame. **Corrected** shader clip-Y sign, CPU/GPU selection alignment and 3/4 camera aimed at whole table center Y=-305.
**CI evidence**: [run 44756697687](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687) **7/7 PASS**, with REAL CC BY model **67/99 projected green field samples** and **4/4 support legs visible**; compare native prior failure **2/99**. Real [GPU screenshot artifact](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687/artifacts/14639560551). Frozen NEON11 untouched. No g3d/physics rewrites.
[PLAN](phases/30-full-table-camera/30-01-PLAN.md) · [UNIFY](phases/30-full-table-camera/30-01-SUMMARY.md).
**Open:** user Windows screenshot and ten-shot feel check; do not merge without human review.

### Phase 31 — Gameplay Readability, 2026-11-20
**Branch:** `feat/foosball-gameplay-readability`; [draft PR #29](https://github.com/Askeladd22/FoosballPhysicsLab/pull/29), main unchanged by this PR.
**Applied:** default true-3D camera GAMEPLAY targets the playing surface; F4 switches to original full-legs SHOWCASE (same score/ball and rod physics); Home returns GAMEPLAY. All selected foot markers derive from `Model.foot`, and white ball tracking derives from `match.ball`. Slightly improved material readability and compact camera/HUD labels.
**Automated proof:** [CI 44761457020](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020), **7/7 jobs PASS**, actual CC BY GLB used in both real LÖVE modes. SHOWCASE 4/4 legs, 56/255 pixel probes; GAMEPLAY 207/255 pixel probes, 74/99 green field. Two native 3D screenshots in [artifact](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020/artifacts/14641711806). Physical gameplay, original GLB, frozen 11vs11 untouched.
[PLAN](phases/31-gameplay-readability/31-01-PLAN.md) · [UNIFY](phases/31-gameplay-readability/31-01-SUMMARY.md).
**Remaining:** Windows human screenshot + 10-shot input/readability UAT NOT_RUN. Next action: test default GAMEPLAY with intentional strokes.


### PAUL phase 32 — unreachable-ball recovery (2026-11-20)
**Branch:** `fix/foosball-unreachable-ball-recovery` · [PR #30](https://github.com/Askeladd22/FoosballPhysicsLab/pull/30) (draft, main unaffected).
**Root cause:** a velocity cutoff prevented the 2-second dead-ball timer from advancing if the unreachable ball continued ricocheting vertically between cushions.
**Change:** count continuous geometric unreachability even during movement; reset only on restored reachability or exit. Restore team serve without modifying collision physics, score or 3D view.
**Proof:** [run 44766380466](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44766380466) **7/7 PASS**, including targeted ricochet, horizontal-escape regressions, Lua5.4/LuaJIT, legacy NEON11 and actual 3D GLB smoke.
**UAT:** NOT_RUN; mouse feel and timing fairness require human testing on Windows.
[PLAN](phases/32-unreachable-ball-recovery/32-01-PLAN.md) · [SUMMARY](phases/32-unreachable-ball-recovery/32-01-SUMMARY.md).

### PAUL phase 33 — microgesture AUTO protection (2026-11-20)
**Branch:** `fix/foosball-auto-mouse-microgestures` · [draft PR #31](https://github.com/Askeladd22/FoosballPhysicsLab/pull/31), not merged to main.
**Defect:** old single-callback mouse delta >=3px gate ignored rapid consecutive 1px mouse events and allowed AUTO rod changes mid-stroke.
**Fix:** aggregate a maximum 3px within 60ms between events, reuse 200ms hold and clear history when resetting or toggling AUTO/MANUALE.
**Automated proof:** [7/7 GitHub Actions PASS](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44772526612), actual CC BY GLB native GPU plus Lua Foosball/NEON11. 
**Still unknown:** real Windows mouse polling and perceived fairness; UAT NOT_RUN.
[PLAN](phases/33-auto-microgestures/33-01-PLAN.md) · [UNIFY](phases/33-auto-microgestures/33-01-SUMMARY.md).

### PAUL phase 34 — angled side/corner ramps (2026-11-20)
**Branch:** `feat/foosball-edge-corner-ramps` · [draft PR #32](https://github.com/Askeladd22/FoosballPhysicsLab/pull/32), not merged to main.
**Implemented:** shared low 2D slope acceleration and native 3D mesh, six edge segments, diagonal effect at corners, open goals. Lua input, AI, scoring and frozen NEON11 untouched.
**Proof:** [CI #44777414138](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44777414138) 7/7 PASS for base implementation.
**Later camera-related correction:** GPU ramp floor now begins at the actual rendered ball contact altitude; tracking marker follows lifted ball. Regression added; fresh CI required.
**SEED / Game Design Lab:** ramp width/intensity unverified on Windows. Independently, camera GAMEPLAY FOV35, fixed vertical viewport/header/footer, 180 degree world yaw and camera perspective may make gameplay hard to read even if mesh/projected markers are mathematically aligned. Do not claim screenshot/player feel verified without native user playtest.
[PLAN](phases/34-edge-corner-ramps/34-01-PLAN.md) · [SUMMARY](phases/34-edge-corner-ramps/34-01-SUMMARY.md).

**Phase 34 latest verification:** [run 44778209050](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44778209050) 7/7 PASS on commit `3c64bbd70475886cdeb07bc7b945c70078a0ea22` for finalized ramp and marker code. Subsequent documentation-only commits do not alter the code under test. Camera composition remains a separate open design task, not silently changed in this branch.

### PAUL phase 35 — photo-reference correction (2026-11-20)
**Branch:** `fix/foosball-gameplay-camera-composition` · [draft PR #33](https://github.com/Askeladd22/FoosballPhysicsLab/pull/33), not merged.
**User revision supersedes early assistant draft:** original user's 1271×874 3/4 screenshot is the precise desired viewpoint. Proposed 70° overhead and 33° FOV were explicitly discarded. Preserve original photographed front-eye {-100,+1060,-780}, target {500,10,280}, FOV35, yaw180 and zoom1.
**Proof:** [7/7 GitHub Actions #44786693825](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44786693825) on source commit `d38f2096` including seven photo landmark anchors, HUD cropping, markers, F4 and native real GLB.
**Game Design Lab:** objective framing can be regression-tested; gameplay readability and pleasure still require ten human strokes. F2, F3, Home and SHOWCASE untouched.
**Next:** compare a newly captured Windows screenshot 1271×874 to the user reference and perform a ten-shot ball-foot test.

### PAUL phase 36 — correction after user screenshot complaint (2026-11-20)
**Root problem:** previous PR #33 was merged but made no meaningful camera composition change. The supplied photo shows a centered view from a LONG edge with straight horizontal rails and complete support legs; the in-game diagonal camera was not the right reference.
**Changed GAMEPLAY:** target `{500,-200,280}`, eye offset `{0,+1100,side*915}`, FOV43°, pitch~50°, compared with old target `{500,10,280}`, eye `{-100,+1060,side*780}`, FOV35°. SHOWCASE remains original FOV35.
**Native proof:** [CI 44789804738](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44789804738) **7/7 PASS**, native LÖVE true CC BY GLB shows 4/4 real legs and 62/99 field-green samples in GAMEPLAY. Real screenshots [artifact](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44789804738/artifacts/14655132976). New post-commit gate ≥55% green.
**Matt Pocock, Simplify, CCteam QA, Trail of Bits spec compliance, Unlazy:** photo requirements audited against actual source/diff, front rails and support legs regression verified with both Lua VMs and GPU CI, no C++ file involved. No extra camera subsystem or physics changes.
**UAT:** Windows physical feel and comparison to image not yet run. The camera fix is available on main after PR #34 merge; update local checkout with `git pull`. [PLAN](phases/36-front-long-side-photo-camera/36-01-PLAN.md); [SUMMARY](phases/36-front-long-side-photo-camera/36-01-SUMMARY.md).

**Phase 36 final merge (2026-11-20):** PR #34 successfully merged to `main` (squash SHA `5130617e67b63e8a6950ca2771028695aaa4dc6f`). Verified source CI [44790760084](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44790760084) 7/7 PASS. Pull main to play; human UAT remains NOT_RUN.

### PAUL 37 — DOPPIA Difesa+Attacco, zoom GAMEPLAY (2026-11-20)
- **Implementation:** `model.lua`: `Game:toggleDualRod()`, `Game:isRodControlled()`, mouse target updates for rods 2 and 4 through original physical servos, force-notice and auto-switch disabled only while dual; TAB/1–4 and C behave as documented. `main.lua` HUD/2D dual highlights and D shortcut; `renderer3d.lua` optional rod index for foot markers, 2 independent highlighted shafts, GAMEPLAY starts at distance0.78 (128%) with min0.70 (143%) and the original SHOWCASE fit at reset.
- **Evidence:** [run 44798062408](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44798062408) 7/7 PASS on code `153522d`, including new dual tests, two Lua VMs, NEON11, native GPU GLB. Changes after that run are documentation-only.
- **Matt Pocock / Simplify:** original input contact integration preserved without a new controller layer; selection-restore semantics and independent travel clamps are covered by tests.
- **Trail of Bits:** spec compliance reviewed on Lua changes; no C++ file in this PR, so no C++ security review claimed.
- **Game Design Lab:** synchronized motion may cause unintended simultaneous hits, so 10-shot/10-save native Windows UAT is still an explicit open gate. Automated tests do not prove preferred feel.
[PLAN](phases/37-dual-rods-close-camera/37-01-PLAN.md) · [UNIFY](phases/37-dual-rods-close-camera/37-01-SUMMARY.md).

**Phase 37 final merge (2026-11-20):** PR #35 successfully squash-merged into `main` (SHA `0da91aeac9f27fcfd9bbc987f99f6d623dabeae8`). Source verified 7/7 GitHub Actions #44798062408 on `153522d`, followed only by docs changes. Local Windows UAT still pending; `git pull` then `love .` and press D to test synchronized Defence+Attack.
