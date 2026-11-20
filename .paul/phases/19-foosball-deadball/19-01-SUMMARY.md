# PAUL 19-01 — UNIFY: Foosball dead-ball recovery

**Branch:** `fix/foosball-unreachable-dead-ball`. **Draft PR:** [#17](https://github.com/Askeladd22/FootballPhysicsLab/pull/17).
**Baseline:** `df126f107c7912d6361d4d063925ab264c23403d`.
**Status:** `APPLY_DONE / AUTOMATED_VERIFICATION`; native LÖVE UAT **NOT_RUN**.

## PLAN / APPLY implementation
- **AC1, geometric reachability:** `M.isBallReachable(s)` checks every rod's physical X footprint at maximal legal rotation, ball/shoe radius, per-figure Y offset and full legal rod travel. Detects the 430–570 midfield void visible in screenshots; never assumes a static current foot position is the whole reach envelope.
- **AC2, no false ball reset:** the accumulator advances only if ball stays on the field, has velocity below 6 px/s and cannot be contacted by any rod. Moving or reachable balls clear the timer. No magnetic steering or impulses added to ordinary play.
- **AC3, recovery:** after 2 seconds of this state, `Game:recoverDeadBall()` serves at X=465 for the cyan 5-rod or X=535 for the red 5-rod, Y=280, preserving all scores, rods and match phase. Opposite team from last valid hit receives the re-serve; unknown last touch alternates teams.
- **AC4, warning HUD:** compact Neon Glass lower HUD countdown and brief team award notice; visible ring around the stalled ball.
- **AC5, tests and isolation:** `tests/test_foosball_deadball.lua` exercises full dead zones, reachable stationary balls, moving balls, service on both teams, score preservation, timing and reset state. The previous 11vs11 and foosball source remain intact except targeted `experiments/foosball/model.lua`, `main.lua` and documentation.

## Game Design Lab evidence distinction
**Observed:** the user's screenshots show balls remaining stuck between opposing rods; model numbers prove a horizontal reach gap (two midfield rods X=430/570, max projected foot reach about 27.4, 10-unit half-foot and 10-unit ball radius, leaving about 45 units of uncontactable space).

**Derived:** a physical foot cannot reach such X-coordinates, so a dead-ball restart is necessary unless the rod geometry/controls are fundamentally redesigned.

**Assumed:** two seconds feels natural; automated rule does not feel intrusive; the opposite-team restart convention is accepted as a prototype *house rule*, not an official regulations claim.

**Unverified:** on-device visual clarity and gameplay timing at 60/144Hz. Test by trapping a ball, watching the 2-second warning and verifying the opponent's accessible midfield restart, then trying a slow but still reachable ball.

## Next single action
Run the PR in native LÖVE and gather user feedback on countdown and fairness. Keep PR in draft until human UAT is accepted. No development on the frozen 11vs11.
