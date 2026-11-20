# PAUL 36-01 — UNIFY / Fix reale della camera fronte lato lungo

**Status:** DONE_WITH_CONCERNS · CODE+GPU VERIFIED · WINDOWS HUMAN UAT NOT_RUN.
**PR:** [#34](https://github.com/Askeladd22/FoosballPhysicsLab/pull/34) **MERGED** in `main` con squash commit `5130617e67b63e8a6950ca2771028695aaa4dc6f`.
**Verified code revision:** `185a59e19b2eb643485eb0ea00db137161a6465f` (include il gate più rigoroso 55% di campo visibile).
**CI:** [run 44790760084](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44790760084) **7/7 PASS** including 2 Lua Foosball, 2 frozen NEON11, 3 real/synthetic GLB and GPU validations.
**Visual evidence:** [native LÖVE GPU run 44789804738](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44789804738) **7/7 PASS**, actual CC BY 4.0 model and [gameplay/showcase screenshot artifact 14655132976](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44789804738/artifacts/14655132976).

## PLAN → APPLY → UNIFY
| Task | Status | Evidence |
|---|---|---|
| T1: reproduce the wrong camera | PASS | Old merged PR #33 still used eye offset (-100,+1060,-780) and target (500,10,280), FOV35, protecting screenshot of the bug; user photo instead depicts front LONG-rail / horizontal edge / all support legs |
| T2: minimal functional correction | PASS | `renderer3d.lua` GAMEPLAY now aims at (500,-200,280), offset (0,+1100,side*915), FOV43, ~50° incline; SHOWCASE untouched FOV35 |
| T3: verified tests and native screenshot | PASS | `tests/test_foosball_camera_framing.lua` replaced erroneous screenshot-anchor test with symmetric horizontal rails, four legs, goal opening, five viewport sizes, sides and yaw, ball-foot markers; GPU shader focal tests adjusted to FOV43; CI screenshot available |
| T4: stronger GPU coverage guarantee | PASS | `ThreeD.assertFieldVisible` now requires >=55% green projected field in GAMEPLAY (retains existing 46% SHOWCASE threshold). Native rendering observed **62/99** green GAMEPLAY and **67/99** SHOWCASE, **4/4 physical legs** in both view modes |
| T5: docs / reviewer handoff | PASS | This summary, SEED PLANNING, README and PAUL state/roadmap updated; human verification separately open |

## Trail of Bits — specification compliance in lieu of C++ code review
The changed files are Lua, YAML and Markdown: **there is no C++ code to audit**. The Trail of Bits C++ code review cannot legitimately be run against nonexistent C++ changes. The transferable `tob-spec-compliance` check is grounded in:
| Requirement | File/function | Proof | Result |
|---|---|---|---|
| Front long-side / horizontal edges | `renderer3d.cameraBasis` | Level projected left/right rim Y at z0/z560, x center and camera X=500 across yaw 0/180 and both sides | PASS Lua |
| Entire cabinet / four legs | `renderer3d.project` + `assertLegVisible` | All four y=-740 support coordinates within viewport plus actual GLB sample hits **4/4** | PASS Lua+native GPU |
| Both goals, readable green field | `renderer3d.assertFieldVisible` | Both projected goal centres, GPU green samples GAMEPLAY 62/99 >=55% gate | PASS Lua+GPU |
| F4 original showcase and F2/F3/Home | `setViewMode`, `cameraBasis`, `resetCamera` | existing + new tests across two camera sides and two scene yaw positions, SHOWCASE FOV35 | PASS Lua |
| Mouse/physics/NEON11 unaffected | `model.lua` unchanged, legacy untouched | diff inspection and existing Foosball/NEON11 Lua suites both VMs | PASS CI |

## Matt Pocock / Simplify / CCteam QA / Unlazy
- **Standards axis:** no new third-party dependencies, asset edits, camera packages or duplicated projection state. `currentFovDegrees()` was already centralized; reuse is appropriate.
- **Spec axis:** the old PR was a no-op relative to the *physical-table* image; this PR **actually changes X, Y aim, distance/pitch and FOV**. Screenshot/user's exact pixel identity is an impossible promise because GLB materials/models differ; geometric composition matches the specified view.
- **CCteam QA:** 7 passing GitHub Actions on the same code revision, native GLB screenshot and 4/4 support-leg detector, no stale source SHA confused with documentation.
- **Unlazy gates:** AC-1 PASS, AC-2 PASS, AC-3 PASS (revised calibrated green threshold), AC-4 PASS; AC-5 Windows native human playtest NOT_RUN.
- **Game Design Lab:** full-table framing can make a ball appear smaller. The actual native screenshot has ball and feet physically anchored, but ten user mouse strikes and subjective anticipation remain unverified.

## Remaining question / next single action
On Windows launch `love .` from an updated PR #34 checkout, capture a GAMEPLAY screenshot at approximately 1271×874 and compare it to the supplied real-product photo. Try ten precise mouse strokes and five side-bank shots; decide whether to enlarge **visual-only** ball marker later without changing physics.

## Invariants
Source GLB and licence attribution unchanged. No edits to `legacy/neon11/`, foot hitboxes, AI, scoring, 120Hz ball dynamics, ramps, ball spin, mouse controls or original SHOWCASE camera.

## Post-merge
PR #34 merged successfully after 7/7 verified code CI. The fixed front-facing camera is now on `main`; run `git pull` in the local repository. User Windows playtest/subjective visual sign-off remains OPEN.
