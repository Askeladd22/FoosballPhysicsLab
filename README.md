# Football Physics Lab — Match Lab v0.2.3

Prototype of a **single-player, top-down tactical football game** built in LÖVE2D (Lua). One disc is permanently under player control; four teammates and five opponents are controlled by tactical AI. Before kickoff, choose whether to play as the **goalkeeper #1** or the **midfielder #10**. A full individual career is the long-term goal, not yet implemented.

## Run

Install LÖVE 11.x and launch the repository folder with LÖVE (e.g. `love .`). The match starts after a short kickoff countdown. A match lasts **3 minutes** in this prototype.

To compare the earlier ball-control sandbox, run `love legacy/physics_lab_01`.

## Controls

| Key | Action |
| --- | --- |
| **1 / 2 (before match)** | Choose blue **goalkeeper #1** / **midfielder #10** |
| WASD / arrows | Move your selected blue disc |
| Space | Shoot using contact geometry |
| C | Toggle instant / charged kick |
| E | Ask an AI teammate for a pass (not guaranteed) |
| N / M | Decrease / increase disc maximum speed |
| J / K | Decrease / increase ball friction |
| [ / ] | Decrease / increase kick strength |
| P | Pause / resume |
| R | Restart match, keeping the selected role |
| TAB | End the current match and open a new role selection |
| F1 | Toggle tactical debugging |
| Esc | Quit |

**2D view:** Football Manager 27 classic-style top-down presentation, with small numbered discs, feet-based orientation, more visible ball shadow and semi-transparent nets. Original renderer and UI; no Football Manager artwork is included.

**Prototype rules:** 5v5 including keepers, open play with goals and a countdown clock. A designated kicker starts play; **the top/bottom touchlines temporarily bounce the ball back into the field instead of producing throw-ins**. The side goal-lines still award a simplified restart when there is no goal. **Pass actions retain the 1.35 impulse multiplier; open-play AI now chooses power and lead from the actual physics. Normal shots/manual kicks are unchanged.** Offside and fouls remain out of scope. There is no multiplayer and no player switching.

## Passing and receiving

AI passes account for distance, ball drag, the ball's existing velocity and the receiver's movement. Unreachable targets are rejected; a bad contact angle makes the passer reposition. The designated AI receiver moves toward the incoming trajectory while teammates maintain support. There is no ball attachment or automatic human movement.

A turquoise ring identifies the intended blue receiver. When the pass is for you, a small cross marks the planned meeting point and the HUD prompts you to meet the ball. **E requests a pass** and shows a brief confirmation; it does not force an unsafe pass or kick the ball yourself.

The HUD shows each team's **Ricevuti: completed/attempts**, **Intercettati** and **Persi**. These count physical pass actions, including kickoff and goal-line restarts. A reception is the first subsequent teammate contact or valid kick, not guaranteed possession; an opponent's first touch is an interception. Retouches by the passer, expired passes, exits, goals without a receiver and fulltime resolve as lost. A pass in flight remains pending in the denominator. Manual kicks are not classified automatically as passes. R resets all counters.

## Architecture

- `main.lua`: LÖVE entry point, input, fixed 120 Hz simulation tick.
- `src/sim.lua`: pitch coordinates, player/ball bodies, collisions, goals, match flow; no LÖVE dependencies.
- `src/ai.lua`: pressing, tactical passing, lane-risk evaluation and back-passing.
- `src/passing.lua`: shared kick prediction, reachable pass planning, receiving targets and per-team outcome accounting.
- `src/tactics.lua`: dynamic five-a-side support lanes, attacking/defensive rotation and human-lane avoidance.
- `src/view.lua`: resolution-independent FM27-inspired classic 2D field, feet-oriented players, Etrusco ball, shadow, nets and compact HUD.
- `assets/etrusco_unico.png`: small transparent texture prepared from user-supplied 1990 Etrusco Unico reference image.
- `tests/test_sim.lua`: headless match regressions for kickoff, steering, passes, four boundaries, scoring and determinism.
- `tests/test_tactics.lua`: support triangles, rotation, coverage and back-pass scenarios.
- `tests/test_roles.lua`: goalkeeper/midfielder model invariants.
- `tests/test_main_roles.lua`: actual prematch input callbacks for fixed role selection.
- `tests/test_view.lua`: mocked 2D rendering smoke tests at 3 resolutions; not a visual substitute.
- `tests/test_passing.lua`: actual trajectories, moving receivers, interceptions, lifecycle and human-control regressions.
- `tests/test_match_passing.lua`: full 180-second matches with scripted GK/RM input, repeated for determinism and pass accounting.
- `legacy/physics_lab_01/main.lua`: earlier physics lab, kept for comparison.

## Testing

Run each `tests/test_*.lua` file in a separate process with Lua 5.4 or LuaJIT, for example `luajit tests/test_passing.lua` and `luajit tests/test_match_passing.lua`. The CI workflow covers both runtimes, syntax and all eight suites. Local v0.2.3 verification passed all eight suites using the installed LÖVE LuaJIT library and rendered the actual HUD at 920×610, 1280×800 and 1920×1080. Human game feel and tactical balance still require a playtest in LÖVE.

## Roadmap

1. Field/physics foundation with decoupled world coordinates.
2. Team intelligence and one-disc interactions (initial prototype in v0.2).
3. Playable match loop (simplified in v0.2).
4. Gameplay refinement: dribbling, passing, tactics, collision robustness, balancing.
5. Career foundation: individual footballer, persistent clubs, seasons and player ratings.

Planning: see `PLANNING.md` and `.paul/`.

## Asset and rights note

The Etrusco Unico design and marks appear in a user-provided reference. This is a **prototype asset**, not a claim of ownership or a grant of commercial redistribution rights. Verify or replace it before public/commercial distribution.

## Tactical guide

See [TacticalPlayGuide.md](docs/TacticalPlayGuide.md) for the adapted 5v5 principles from the user-supplied positioning and off-ball guide.
