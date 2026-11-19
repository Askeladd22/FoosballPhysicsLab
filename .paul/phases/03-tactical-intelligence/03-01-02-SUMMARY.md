# PAUL SUMMARY 03-01 / 03-02 — Tactical support and goalkeeper role

**Verdict:** DONE_WITH_CONCERNS / UNIFY_PARTIAL. Gameplay and pre-match GK selection integrated via merged PR #6. Additional input/UI tests and documentation prepared as PR #7. Full manual gameplay verification still not performed.

## PLAN → APPLY

| Task | Implemented | Evidence | Qualification |
| --- | --- | --- | --- |
| 03-01 T1: dynamic off-ball targets | `src/tactics.lua`: attack/defend/neutral targets for GK/DF/LM/RM/ST, flank separation and lane rotation around controlled human | Tactical headless tests, CI run 44554353825 success | PASS in tested scenarios; UAT NOT_RUN |
| 03-01 T2: safer passing | `src/ai.lua`: interception, receiver marking and pressure-weighted backward pass; E bonus only on safe lane | Tactical headless tests, CI run 44554353825 success | PASS in tested scenarios; UAT NOT_RUN |
| 03-02 T1: prematch role choice | `src/sim.lua`, `main.lua`: GK #1 with key 1, RM #10 with key 2, fixed control; TAB creates new match, R restarts same role | Role headless tests in merged PR #6; callback-level tests proposed in PR #7 | PASS in previous headless tests; new regression pending CI |
| 03-02 T2: playable GK | `src/sim.lua`: same WASD / physical Space clearance, other players remain AI | `tests/test_roles.lua`, CI run 44554353825 | PASS scenario; UAT NOT_RUN |
| 03-02 T3: role menu and HUD | `src/view.lua`: pre-match selection overlay, role-sensitive HUD | Mocked 2D rendering test (merged); extended test in PR #7 | PASS structural; actual visuals NOT_RUN |

## Acceptance criteria
- AC-1: Different flank supports and rear outlet — PASS (headless).
- AC-2: Deterministic rotation away from human occupied lane — PASS (headless).
- AC-3: Defensive backline with stable press assignment — PASS (headless).
- AC-4: Under pressure, safe back-pass preferred to marked forward lane — PASS (headless).
- AC-5: E request influences but does not force unsafe passes — PASS (headless).
- AC-6: Legacy goal/kickoff/restart/identity tests remain green — PASS (CI run 44554353825).
- GK-1: GK role via key 1 — PASS model test; actual key callback test added to PR #7, latest result must be checked.
- GK-2: RM role via key 2 — PASS model default; callback test added to PR #7, latest result must be checked.
- GK-3: GK movement and kick — PASS (headless).
- GK-4: Role stays locked through restart; TAB is new game — callback test in PR #7, latest CI result must be checked.
- GK-5: Existing match invariants remain green — PASS (CI run 44554353825).

## Deviations and deferred
The original player was #10 only; the user's new request explicitly extends the design with goalkeeper #1. This is a **pre-match role choice**, not player swapping during an active match. No new player powers or physics were introduced. HaxBall wall techniques, absorption and full corner routines remain future research.

## Constraints and human UAT
Do not declare tactical quality proven by headless tests. Real match behavior, controlling the goalkeeper, legibility of the menu and balanced passing must be tested by playing LÖVE2D. Etrusco texture is a prototype asset with commercial rights unverified.

## Next action
Play a complete match as blue goalkeeper #1, confirming movement, shot blocking, clearances, teammate cover and role lock.
