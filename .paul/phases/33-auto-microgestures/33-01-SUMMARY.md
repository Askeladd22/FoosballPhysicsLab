# SUMMARY 33-01 — AUTO mouse microgestures

**Result:** DONE_WITH_CONCERNS / automated VERIFIED; Windows human UAT NOT_RUN.
**Branch:** `fix/foosball-auto-mouse-microgestures` · [draft PR #31](https://github.com/Askeladd22/FoosballPhysicsLab/pull/31).
**CI:** [GitHub Actions 44772526612](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44772526612) **7 of 7 PASS** on tested source commit `6985c15d5dff0accecff0086952c8c68de595912`.

## Apply — planned vs actual
| Task | Result | Evidence |
|---|---|---|
| T1 — microgesture aggregation | DONE, PASS | `rod_selector.lua` window=60ms, threshold=3 cumulative pixels; `model.lua` accumulator with reset on new match or AUTO/MANUALE transition |
| T2 — regressions | DONE, PASS | `tests/test_foosball_response.lua` verifies four 1px events, lock while swiping, contextual resume, sparse jitter, mode reset. Lua5.4 and LuaJIT Foosball PASS; both frozen NEON11 and three 3D/GLB gates PASS |
| T3 — PAUL/SEED | DONE, PASS (written) | PLAN, SUMMARY, STATE, ROADMAP, PLANNING in PR #31 |

## Acceptance Criteria
- **AC-1 PASS:** consecutive high-polling microevents register an intentional gesture and prevent a mid-swipe AUTO selection.
- **AC-2 PASS:** isolated 1px movements 100ms apart do not accumulate into a false lock.
- **AC-3 PASS:** AUTO resumes after existing 200ms hold and resets partial motion on mode toggle. MANUALE still ignores contextual AUTO switching (existing suite).
- **AC-4 PASS automated:** 7/7 jobs; no 3D/GLB or NEON11 regressions.
- **Windows UAT NOT_RUN:** automated scripts cannot establish subjective rod-selection smoothness, input timing or perceived skill expression.

## SEED / Game Design Lab reality check
**Observed:** old single-event >=3px gate could miss 1px high-polling streams.
**Decided:** 3px cumulative within a 60ms inter-event window, with no change to the ball collision or physical input servo.
**Assumed:** sparse jitter rejection vs very gentle deliberate motion is acceptable at this window.
**Unverified:** real hardware player-facing behavior. Counterexample: continuous 1px noise at intervals under 60ms could still hold AUTO; test with actual device.

## Guardrails
No career, rankings, multiplayer, FOOSBALL camera redesign, collision physics, third-party assets, or frozen `legacy/neon11/` modifications. `main` not changed by this PR.

## Next single action
On Windows, compare ten gentle mouse swipes near a rod-switch point with ten idle/jitter intervals; report any unwanted switch or blocked AUTO.
