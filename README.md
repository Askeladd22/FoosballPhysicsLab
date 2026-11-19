# Football Physics Lab — Match Lab v0.2

Prototype of a **single-player, top-down tactical football game** built in LÖVE2D (Lua). One disc is permanently under player control; four teammates and five opponents are controlled by simple tactical AI. A full individual career is the long-term goal, not yet implemented.

## Run

Install LÖVE 11.x and launch the repository folder with LÖVE (e.g. `love .`). The match starts after a short kickoff countdown. A match lasts **3 minutes** in this prototype.

To compare the earlier ball-control sandbox, run `love legacy/physics_lab_01`.

## Controls

| Key | Action |
| --- | --- |
| WASD / arrows | Move your blue #10 disc |
| Space | Shoot using contact geometry |
| C | Toggle instant / charged kick |
| E | Ask an AI teammate for a pass (not guaranteed) |
| N / M | Decrease / increase disc maximum speed |
| J / K | Decrease / increase ball friction |
| [ / ] | Decrease / increase kick strength |
| P | Pause / resume |
| R | Restart match |
| F1 | Toggle tactical debugging |
| Esc | Quit |

**Prototype rules:** 5v5 including keepers, open play with goals and a countdown clock. Out-of-bounds restarts are simplified, without full fouls/offside/throw-ins. There is no multiplayer and no player switching.

## Architecture

- `main.lua`: LÖVE entry point, input, fixed 120 Hz simulation tick.
- `src/sim.lua`: pitch coordinates, player/ball bodies, collisions, goals, match flow; no LÖVE dependencies.
- `src/ai.lua`: basic five-a-side roles, pressing, support, goalkeeper coverage, passing decisions.
- `src/view.lua`: camera, stadium field, player labels and HUD, ball image.
- `assets/etrusco_unico.png`: small transparent texture prepared from user-supplied 1990 Etrusco Unico reference image.
- `tests/test_sim.lua`: deterministic headless simulation checks.
- `legacy/physics_lab_01/main.lua`: earlier physics lab, kept for comparison.

## Testing

Run `lua tests/test_sim.lua` with Lua 5.4. GitHub Actions performs a syntax check and headless tests. Rendering and game feel still require manual playtests in LÖVE.

## Roadmap

1. Field/physics foundation with decoupled world coordinates.
2. Team intelligence and one-disc interactions (initial prototype in v0.2).
3. Playable match loop (simplified in v0.2).
4. Gameplay refinement: dribbling, passing, tactics, collision robustness, balancing.
5. Career foundation: individual footballer, persistent clubs, seasons and player ratings.

Planning: see `PLANNING.md` and `.paul/`.

## Asset and rights note

The Etrusco Unico design and marks appear in a user-provided reference. This is a **prototype asset**, not a claim of ownership or a grant of commercial redistribution rights. Verify or replace it before public/commercial distribution.
