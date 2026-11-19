# Football Physics Lab — Match Lab v0.2.1

Prototype of a **single-player, top-down tactical football game** built in LÖVE2D (Lua). One disc is permanently under player control; four teammates and five opponents are controlled by tactical AI. Before kickoff, choose whether to play as the **goalkeeper #1** or the **midfielder #10**. A full individual career is the long-term goal, not yet implemented.

## Run

Install LÖVE 11.x and launch the repository folder with LÖVE (e.g. `love .`). The match starts after a short kickoff countdown. A match lasts **3 minutes** in this prototype.

To compare the earlier ball-control sandbox, run `love legacy/physics_lab_01`.

## Controls

| Key | Action |
| --- | --- |
| **1 / 2 (before match)** | Choose blue **goalkeeper #1** / **midfielder #10** |\n| WASD / arrows | Move your selected blue disc |
| Space | Shoot using contact geometry |
| C | Toggle instant / charged kick |
| E | Ask an AI teammate for a pass (not guaranteed) |
| N / M | Decrease / increase disc maximum speed |
| J / K | Decrease / increase ball friction |
| [ / ] | Decrease / increase kick strength |
| P | Pause / resume |
| R | Restart match, keeping the selected role |\n| TAB | End the current match and open a new role selection |
| F1 | Toggle tactical debugging |
| Esc | Quit |

**2D view:** Football Manager 27 classic-style top-down presentation, with small numbered discs, feet-based orientation, more visible ball shadow and semi-transparent nets. Original renderer and UI; no Football Manager artwork is included.

**Prototype rules:** 5v5 including keepers, open play with goals and a countdown clock. A designated kicker now starts and restarts play with a physical pass directed into the field; restarts are intentionally simplified, without full fouls/offside/throw-ins. There is no multiplayer and no player switching.

## Architecture

- `main.lua`: LÖVE entry point, input, fixed 120 Hz simulation tick.
- `src/sim.lua`: pitch coordinates, player/ball bodies, collisions, goals, match flow; no LÖVE dependencies.
- `src/ai.lua`: pressing, tactical passing, lane-risk evaluation and back-passing.\n- `src/tactics.lua`: dynamic five-a-side support lanes, attacking/defensive rotation and human-lane avoidance.
- `src/view.lua`: resolution-independent FM27-inspired classic 2D field, feet-oriented players, Etrusco ball, shadow, nets and compact HUD.
- `assets/etrusco_unico.png`: small transparent texture prepared from user-supplied 1990 Etrusco Unico reference image.
- `tests/test_sim.lua`: headless match regressions for kickoff, steering, passes, four boundaries, scoring and determinism.\n- `tests/test_tactics.lua`: support triangles, rotation, coverage and back-pass scenarios.\n- `tests/test_roles.lua`: goalkeeper/midfielder model invariants.\n- `tests/test_main_roles.lua`: actual prematch input callbacks for fixed role selection.
- `tests/test_view.lua`: mocked 2D rendering smoke tests at 3 resolutions; not a visual substitute.
- `legacy/physics_lab_01/main.lua`: earlier physics lab, kept for comparison.

## Testing

Run `lua tests/test_sim.lua`, `lua tests/test_tactics.lua`, `lua tests/test_roles.lua`, `lua tests/test_main_roles.lua` and `lua tests/test_view.lua` with Lua 5.4. GitHub Actions performs syntax, simulation and mocked rendering smoke checks. Real 2D appearance and game feel still require a manual playtest in LÖVE.

## Roadmap

1. Field/physics foundation with decoupled world coordinates.
2. Team intelligence and one-disc interactions (initial prototype in v0.2).
3. Playable match loop (simplified in v0.2).
4. Gameplay refinement: dribbling, passing, tactics, collision robustness, balancing.
5. Career foundation: individual footballer, persistent clubs, seasons and player ratings.

Planning: see `PLANNING.md` and `.paul/`.

## Asset and rights note

The Etrusco Unico design and marks appear in a user-provided reference. This is a **prototype asset**, not a claim of ownership or a grant of commercial redistribution rights. Verify or replace it before public/commercial distribution.
\n## Tactical guide\n\nSee [TacticalPlayGuide.md](docs/TacticalPlayGuide.md) for the adapted 5v5 principles from the user-supplied positioning and off-ball guide.\n