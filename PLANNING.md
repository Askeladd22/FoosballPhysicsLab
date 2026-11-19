---
project: Football Physics Lab
project_type: custom/game-development
status: exploring
plan_version: "0.2.3"
last_updated: 2026-11-19
---

# Football Physics Lab — SEED

> Single-player arcade-tactical football where one permanently controlled disc plays in an AI team, leading eventually to an individual career.

## Audience and outcome
Players who want simple direct controls, emergent ball physics, tactical movement without the ball, and eventually a personal football career.

## Decided
- LÖVE2D/Lua for the native desktop prototype.
- Offline single-player only.
- One disc permanently controlled by the human, chosen **before the match**: blue GK #1 or blue RM #10; no live switching.
- Top-down, readable field inspired by the supplied tactical match screenshot.
- FM27-inspired **classic 2D match view** (smaller numbered discs, feet-based facing cues, ball shadow, transparent nets), with original art and HUD.
- Physical ball: no magnetic possession or automatic dribbling.
- Temporary **arena rules**: no throw-ins; top/bottom touchlines are bouncy boundaries while goals and goal-line restarts still work.
- Pass-only physical kick impulse multiplier set to **1.35**, shot/manual kick strength unchanged; provisional playtest value.
- Individual player career as a later milestone.

## Prototype assumptions (to validate)
- 5v5 including goalkeepers is sufficient to test positional play.
- 120×70 simulation units and a field-fitting camera give readable space.
- Fixed 120 Hz simulation and independent view coordinates provide useful consistency.
- Team AI with dynamic support lanes, pressure-aware passing, physically reachable trajectories and coordinated reception is enough for a tactical playtest. Scenario and scripted full-match tests pass; human match quality remains unverified.
- Ball and player movement parameters remain provisional, adjustable in game.

## In scope for Match Lab v0.2
- Field, camera, ten discs, physics, initial tactical AI.
- Autonomous opponent and teammates, human pass request.
- 3-minute match, goals, simple restarts and HUD.
- Debug toggles, reproducible headless tests.
- User-provided Etrusco Unico image as prototype ball texture.

## Out of scope
Multiplayer, full career, transfer markets, data persistence, 11v11, complex substitutions, sophisticated offside, official branded assets or licensed leagues.

## Risks and tests
| Risk | Test |
| --- | --- |
| Ball control difficult or too elastic | Repeated close-touch playtests, compare with legacy lab |
| Teammates cluster or oscillate | Sticky press assignment, velocity steering, dynamic support slots, flank separation and regression scenarios |
| Input or physics depends on resolution | Run fixed-step simulation independent of drawing and vary window size |
| Kickoff or goal-line restart loops | Designated taker and endline regressions; LÖVE UAT |
| Excessive rebounds or long passes | Bouncy touchline and pass-only physics tests; adjust multiplier based on manual playtest |
| Sprite rights unclear | Prototype only; verify rights or replace for release |

## Milestones
1. Field + physics foundation: playable disc and ball in world coordinates.
2. Team intelligence: 5v5 roles, pressing, support, passing.
3. Playable match: goals, time, scoreboard and restarts.
4. Gameplay refinement: tactical triangles, off-ball rotation, safer passing and playable GK, with UAT pending.
5. Career foundation: persistent player, clubs, roles and seasonal loop.

## Quality gate
WARN: v0.2.3 passes eight LuaJIT suites, including trajectories and full scripted matches as GK/RM. The actual LÖVE renderer was checked at three resolutions. Meaningful human playtesting remains necessary for dribbling, tactical balance and receiving feel; scripted receptions do not establish fun or stable possession.

## Next action
Play the current build once as RM and once as GK, using E and the receiving marker; record missed receptions and whether teammates provide useful passing options.

## SEED decision update — v0.2.2
- **DECIDED:** GK #1 and RM #10 prematch role selection; a single human-controlled disc remains fixed through the match.
- **IMPLEMENTED (scenario-tested):** dynamic support targets, lateral lanes, lane rotation, pressure-aware back-pass selection, safe E requests.
- **UNVERIFIED:** full-match tactical quality, goalkeeper experience and real LÖVE render/UI behavior.
- **DEFERRED:** wall-based techniques, complex corner tactics, career progression and skill assists.

## SEED decision update — v0.2.3
- **DECIDED:** implement the approved passing/reception/feedback increment; retain the physical ball and fixed human role.
- **IMPLEMENTED:** variable AI pass power and lead, physical contact-angle check, temporary receiving intent, per-team pass outcomes and visible call/receiver feedback.
- **ASSUMED:** constant receiver velocity is a useful short-term lead estimate; arrival speed near 8 simulation units/s is a provisional tuning target.
- **VERIFIED:** isolated trajectories, original 40-unit pass, moving receivers, both teams, interceptions and lifecycle; deterministic 180-second scripted matches for both human roles.
- **UNVERIFIED:** human enjoyment, difficulty and practical completion rates. No inference of improved completion rates from different scripted scenarios.
- **DEFERRED:** assisted first touch, new manual passing controls and career systems. Details: `.paul/phases/05-pass-reception/05-01-SUMMARY.md`.

## SEED decision update — coordinated team shape
- **DECIDED:** use documented FM24 positional-play principles for an original 5v5 support coordinator.
- **IMPLEMENTED:** shared team targets, receiver-space reservation and replacement cover; tests PASS.
- **ASSUMED:** spacing 8 and cover depth 16 suit this pitch; neither is an FM24 coefficient.
- **UNVERIFIED:** attacking balance after greater defensive cover; two deterministic scripted matches ended 0–0.
- **NEXT:** human RM/GK playtest; retain the physical ball and single controlled disc.
