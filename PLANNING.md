---
project: Football Physics Lab
project_type: custom/game-development
status: exploring
plan_version: "0.2"
last_updated: 2026-11-19
---

# Football Physics Lab — SEED

> Single-player arcade-tactical football where one permanently controlled disc plays in an AI team, leading eventually to an individual career.

## Audience and outcome
Players who want simple direct controls, emergent ball physics, tactical movement without the ball, and eventually a personal football career.

## Decided
- LÖVE2D/Lua for the native desktop prototype.
- Offline single-player only.
- One disc permanently controlled by the human.
- Top-down, readable field inspired by the supplied tactical match screenshot.
- Physical ball: no magnetic possession or automatic dribbling.
- Individual player career as a later milestone.

## Prototype assumptions (to validate)
- 5v5 including goalkeepers is sufficient to test positional play.
- 120×70 simulation units and a field-fitting camera give readable space.
- Fixed 120 Hz simulation and independent view coordinates provide useful consistency.
- Team AI using roles, pressing and pass scoring is enough for first gameplay playtests.
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
| Teammates cluster around ball | Watch AI debug targets for several transitions |
| Input or physics depends on resolution | Run fixed-step simulation independent of drawing and vary window size |
| Scoring/restarts deadlock | Headless goal and restart assertions; manual LÖVE matches |
| Sprite rights unclear | Prototype only; verify rights or replace for release |

## Milestones
1. Field + physics foundation: playable disc and ball in world coordinates.
2. Team intelligence: 5v5 roles, pressing, support, passing.
3. Playable match: goals, time, scoreboard and restarts.
4. Gameplay refinement: test and tune, no premature career feature.
5. Career foundation: persistent player, clubs, roles and seasonal loop.

## Quality gate
WARN: conceptual and technical slice implemented on a draft branch, but meaningful human playtesting is still required for dribbling, tactical AI, and UI readability.

## Next action
Run the branch using LÖVE and record first-pass feedback on speed, pass decisions and control without the ball.
