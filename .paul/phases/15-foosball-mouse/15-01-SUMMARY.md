# PAUL 15-01 — UNIFY: Mouse-Controlled Foosball Rods

**Status:** APPLY_DONE; UNIFY_DOCUMENTED; **DONE_WITH_CONCERNS** because no human LÖVE playtest has yet taken place. **Branch:** `experiment/foosball-mouse-rods`. **PR:** [#11](https://github.com/Askeladd22/FootballPhysicsLab/pull/11) (draft, not merged).

## PLAN → APPLY / verify
| AC | Implementation | Evidence |
| --- | --- | --- |
| AC-1 | Orthogonal mouse Y-slide and X-rotation targets, bounded and selected per rod (1–4 / wheel) | `tests/test_foosball.lua` Lua5.4/LuaJIT PASS |
| AC-2 | Finite rod translation/rotation acceleration; velocity-dependent collision impulse from each moving foot to a physical ball | `tests/test_foosball.lua` Lua5.4/LuaJIT PASS, native feel UNVERIFIED |
| AC-3 | Top/bottom and sidewall rebound, open goal scoring, 5-goal match, deterministic steps | `tests/test_foosball.lua` Lua5.4/LuaJIT PASS |
| AC-4 | Independent LÖVE entrypoint, top-down greybox, visible rod selector, relative mouse capture/cancel, sensitivity adjustment, simple four-rod AI | LÖVE callbacks/view `tests/test_foosball_view.lua` Lua5.4/LuaJIT PASS; real window rendering NOT_RUN |
| AC-5 | CI runs foosball syntax, core simulation and mocked LÖVE smoke | [GitHub Actions 44633281050](https://github.com/Askeladd22/FootballPhysicsLab/actions/runs/44633281050) success on Lua5.4 + LuaJIT |

## SEED decision ledger
**Decided:** keep standalone `experiments/foosball/`; four manually selectable human rods, four basic opponent rods; mouse motion alone changes the selected rod's linear and angular target, requiring actual moving contact to shoot.
**Assumed:** mouse horizontal/vertical gesture will feel intuitive and expressive; this is not proved by passing tests.
**Unverified:** native LÖVE visual result, control latency, 2-axis interference, angular momentum accuracy and whether deliberate shots are reliably repeatable.
**Open:** calibrate horizontal rotation sensitivity and rod acceleration with human testing; decide whether to pivot from football only after comparison.
**Deferred:** career, licensed teams, sophisticated AI, full official rules and high-fidelity ball spin.

## Game Design Lab evidence gate
During a five-minute first playtest, try 10 deliberately aimed shots with rod 4, then change between rods 1–4 and repeat. Record how many shots were intentionally aimed versus accidental, whether x/y gestures interfere, whether mouse capture helps, and whether the foot contact feels like a real rod rather than a scripted kick.
**Pass/Revise decision:** prioritize predictable repeated contact and low accidental firing before adding additional rods or modes. An automated green pipeline is not a human playtest.

**Next single action:** play `love experiments/foosball` in native LÖVE and report rod sensitivity, missed contacts and perceived shot control.
