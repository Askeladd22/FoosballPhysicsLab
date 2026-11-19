---
project: Football Physics Lab
project_type: custom/game-development
status: exploring
plan_version: "0.2.2"
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
- Team AI with dynamic support lanes, triangle geometry, rotation into vacant space, pressure-aware pass scoring and back-pass selection is enough for a first tactical playtest (still unverified in real LÖVE gameplay).
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
WARN: v0.2.1 regression tests for game flow and a mocked renderer pass, but meaningful human LÖVE playtesting is still required for dribbling, tactical AI, and actual FM27-style 2D readability.

## Next action
Play a full match as GK from merged PR #6 and record defensive movement, clearances, teammate rotation and off-ball play; also verify the FM27-inspired view.
\n## SEED decision update — v0.2.2\n- **DECIDED:** GK #1 and RM #10 prematch role selection; a single human-controlled disc remains fixed through the match.\n- **IMPLEMENTED (scenario-tested):** dynamic support targets, lateral lanes, lane rotation, pressure-aware back-pass selection, safe E requests.\n- **UNVERIFIED:** full-match tactical quality, goalkeeper experience and real LÖVE render/UI behavior.\n- **DEFERRED:** wall-based techniques, complex corner tactics, career progression and skill assists.\n