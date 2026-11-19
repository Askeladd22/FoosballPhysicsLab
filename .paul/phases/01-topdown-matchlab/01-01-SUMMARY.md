# SUMMARY 01-01 — Top-down Match Lab v0.2

**Result:** PARTIAL — code submitted in draft PR #4, automated Lua verification PASS, manual gameplay/UAT NOT_RUN.

## Planned vs actual
| Task | Implemented | Evidence | Qualification |
| --- | --- | --- | --- |
| T1 physics and field | World-coordinate fixed step, ten discs, scoring, time and restarts | `src/sim.lua`; headless CI success | DONE_WITH_CONCERNS: physical feel untested |
| T2 team AI | Basic role anchors, pressing, support, passes, shots | `src/ai.lua`; code inspection | DONE_WITH_CONCERNS: tactical UAT missing |
| T3 render, ball and checks | Wide pitch/camera/HUD, prototype Etrusco texture, CI | `src/view.lua`; `assets/etrusco_unico.png`; Lua workflow successful | DONE_WITH_CONCERNS: LÖVE render untested |

## Acceptance criteria
| AC | Result | Evidence |
| --- | --- | --- |
| AC-1 10 players | PASS | `tests/test_sim.lua` in passing Lua CI |
| AC-2 permanent one-disc control | PASS (headless) | `tests/test_sim.lua`; visual check outstanding |
| AC-3 score and kickoff | PASS (headless) | `tests/test_sim.lua` |
| AC-4 deterministic fixed step | PASS (headless) | `tests/test_sim.lua` |
| AC-5 image in rendered match | NOT_RUN | Asset blob present; LÖVE graphics not executed |
| AC-6 teammate pass decisions | NOT_RUN | Manual tactical UAT pending |
| AC-7 close ball control | NOT_RUN | Manual ball-feel UAT pending |

## Automated test evidence
GitHub Actions workflow **Lua match simulation**, run `44543543086`: completed with conclusion **success** on PR head at the time of this report. Final branch head changes after this summary may trigger fresh CI.

## Deviations and limitations
- Initial 5v5 AI deliberately simple, no sophisticated team tactics yet.
- Restart logic simplified; no authentic throw-ins, corners, fouls or offside.
- User ball design is included as a small prototype texture. Rights for public/commercial distribution have not been established.
- Existing Physics Lab preserved under `legacy/physics_lab_01`.
- No local LÖVE executable was used in this session; no claims about actual game feel or rendering.

## State and next action
Keep PAUL state **APPLYING / awaiting UAT**, PR in draft, and run one manual LÖVE full-match playtest before marking the milestone ready for UNIFY closure.
