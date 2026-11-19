# Football Physics Lab — NEON 11

Prototype of a **single-player, top-down tactical football game** built in LÖVE2D (Lua). One disc is permanently under player control; ten teammates and eleven opponents are controlled by tactical AI. Before kickoff, choose whether to play as the **goalkeeper #1** or the **midfielder #10**. A full individual career is the long-term goal, not yet implemented.

## Run

Install LÖVE 11.x and launch the repository folder with LÖVE (e.g. `love .`). The match starts after a short kickoff countdown. A match lasts **5 minutes** in this prototype.

To compare the earlier ball-control sandbox, run `love legacy/physics_lab_01`.

## Controls

| Key | Action |
| --- | --- |
| **1 / 2 (before match)** | Choose cyan **goalkeeper #1** / **midfielder #10** |
| WASD / arrows | Move your selected cyan disc |
| Hold left/right Shift | Sprint: 40% more acceleration and maximum speed; release to run normally |
| Tap Space | Pass to a physically reachable teammate, or into space |
| Hold and release Space | Charge and shoot (0.18s threshold, maximum at 0.75s) |
| Hold left/right Ctrl near the ball | Cushion a real contact and protect the ball at reduced speed; direction input orients the touch |
| Hold Q while releasing a Space tap | Request a physical one-two; move your own player to offer the return |
| E | Ask an AI teammate for a pass (not guaranteed) |
| N / M | Decrease / increase disc maximum speed |
| J / K | Decrease / increase ball friction |
| [ / ] | Decrease / increase kick strength |
| P | Pause / resume |
| T | Inspect the AI coach's tactical report; simulation pauses while it is open |
| R | Restart match, keeping the controlled player and tactical configuration |
| TAB | Outside tactics: end the match and open new role selection; inside: switch section |
| F1 | Toggle tactical debugging |
| F11 | Toggle desktop fullscreen; the window starts maximized |
| Esc | Close tactics; outside the panel, quit |

**2D view:** original dark neon arena with cyan/orange teams, clear selected-player markings and a compact countdown HUD, inspired by the user's Tron art direction. No film or Football Manager artwork is included.

The camera fits the unchanged **105 x 68** pitch into the window. At 920 x 610, 1280 x 800 and 1920 x 1080, the field occupies approximately **714 x 462**, **980 x 635** and **1372 x 889** pixels respectively. A larger view does not change the simulation scale or player speed.

**Prototype rules:** 11 versus 11, on a 105 x 68 field with 7.32-wide goals. The AI coach assigns formations, roles, duties and instructions automatically. The whole ball must cross a line: touchlines award throw-ins to the opponents of the last toucher; goal-line exits award corners or goal kicks. Soft deflections count as touches. A direct throw-in cannot score. AI takes throw-ins/corners; the human goalkeeper takes goal kicks with Space. Sprint has no stamina meter yet.

**Match clock:** five minutes from kickoff, including restarts; pause stops the clock. Offside is sampled at teammate touches and enforced on involvement, with exemptions for direct throw-ins, goal kicks and corners. Deliberate opponent play resets the phase; deflections and saves preserve it.

**Current pace:** base player speed is capped at 7.2 units/s, sprint at 10.08, with acceleration 54 and player drag 7.5. Base kick speed is 26 and ball drag 1.0. These slower physical defaults replace the previous fast tuning; the five-minute clock and 120 Hz simulation rate remain unchanged. They are prototype values awaiting human playtesting.

**Still simplified:** physical discs with enlarged collision radii, ground-plane throws/crosses without overhead or heading animations, no fouls, penalties, cards, substitutions or second-touch sanctions. Offside uses disc centres and does not model goalkeeper sight obstruction. This is not yet the complete football rulebook. No multiplayer or player switching.

## Passing and receiving

AI passes account for distance, ball drag, the ball's existing velocity and the receiver's movement. Unreachable targets are rejected; a bad contact angle makes the passer reposition. The designated AI receiver moves toward the incoming trajectory while teammates maintain support. There is no ball attachment or automatic human movement.

Hold **Ctrl** to cushion an incoming physical contact and use movement direction to orient the first touch. Protection slows movement and disables sprint while close to the ball; body position matters and an opponent can still win it. **Q + a Space tap** asks for a one-two, with a real outgoing pass, run and return pass. Pause freezes the match and its intentions; restarts clear them.

AI compares passing, carrying and shooting using pressure and space. Support players seek usable passing lanes, retain midfield cover and track local threats when defending. Recent stagnant pass exchanges receive a temporary penalty; pressure can still make a return pass the best choice. Runs can go outside or inside, and a runner who reaches a loose ball resumes playing it. See [Control and tactics](docs/Control-and-Tactics.md) for behavior, constraints and evidence.

A turquoise ring identifies the intended blue receiver. When the pass is for you, a small cross marks the planned meeting point and the HUD prompts you to meet the ball. **E requests a pass** and shows a brief confirmation; it does not force an unsafe pass or kick the ball yourself.

The HUD shows each team's **Ricevuti: completed/attempts**, **Intercettati** and **Persi**. These count physical pass actions, including kickoff and restarts. A reception is the first subsequent teammate contact or valid kick, not guaranteed possession; an opponent's first touch is an interception. Retouches by the passer, expired passes, exits, goals without a receiver and fulltime resolve as lost. A pass in flight remains pending in the denominator. A Space tap is counted as a pass; a held/released Space is counted as a shot. R resets all counters.

## Architecture

- `main.lua`: LÖVE entry point, input, fixed 120 Hz simulation tick.
- `src/sim.lua`: pitch coordinates, player/ball bodies, collisions, goals, match flow; no LÖVE dependencies.
- `src/ai.lua`: pressing, contextual pass/carry/shot choices and short pass history.
- `src/passing.lua`: shared kick prediction, reachable pass planning, receiving targets and per-team outcome accounting.
- `src/ball_control.lua`: contact-only cushioning and a contestable shielding stance.
- `src/combinations.lua`: physical one-twos, contextual outside/inside runs and their lifecycle.
- `src/space.lua`: shared corridor risk and opponent clearance; pressure behind a passer does not block a forward lane.
- `src/tactics.lua` / `src/marking.lua`: coordinated support, holding midfield, replacement cover and local zonal assignments.
- `src/football_roles.lua`: 45 FM24 role names with verified local source IDs and original behaviour profiles.
- `src/tactical_settings.lua`: formation, position, role, duty and team/player instruction validation and effective profiles.
- `src/coach.lua`: automatic tactical planning from match observations, with review intervals and safeguards against rapid changes.
- `src/tactics_panel.lua`: read-only keyboard/mouse report of the AI coach's choices, paused by the main controller.
- `src/view.lua`: resolution-independent neon 2D field, feet-oriented players, Etrusco ball, shadow, nets and compact HUD.
- `assets/etrusco_unico.png`: small transparent texture prepared from user-supplied 1990 Etrusco Unico reference image.
- `tests/test_sim.lua`: headless match regressions for kickoff, steering, passes, four boundaries, scoring and determinism.
- `tests/test_tactics.lua`: support triangles, rotation, coverage and back-pass scenarios.
- `tests/test_roles.lua`: goalkeeper/midfielder model invariants.
- `tests/test_main_roles.lua`: actual prematch input callbacks for fixed role selection.
- `tests/test_football_roles.lua`, `tests/test_tactical_settings.lua`, `tests/test_tactics_panel.lua`: catalog integrity, isolated internal configuration changes, retained restarts and read-only report callbacks.
- `tests/test_view.lua`: mocked 2D rendering smoke tests at 3 resolutions; not a visual substitute.
- `tests/test_passing.lua`: actual trajectories, moving receivers, interceptions, lifecycle and human-control regressions.
- `tests/test_match_passing.lua`: full 300-second matches with scripted GK/RM input, repeated for determinism and pass accounting.
- `legacy/physics_lab_01/main.lua`: earlier physics lab, kept for comparison.

## Testing

Run each `tests/test_*.lua` file in a separate process, for example `luajit tests/test_runner_ball.lua` and `luajit tests/test_match_passing.lua`. **All 25 suites passed locally on 2026-11-19**, using separate states in the installed LÖVE LuaJIT library, after the runner and short-carry fixes. Coverage includes actual contact/flight, controls, tactical scenarios and deterministic 300-second RM/GK matches. Older isolated passing/tactical fixtures retain 5v5 explicitly. The existing CI configuration targets Lua 5.4 and LuaJIT; no new remote CI run or LuaLS diagnostics are claimed. Real LÖVE rendering was checked at 920 x 610, 1280 x 800 and 1920 x 1080; screenshots do not establish tactical quality. Human game feel and tactical balance remain unverified by UAT.

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

## Team coordination

AI teammates share a support map with separate outlets, receiver-space reservation and replacement cover. Attacking outlets respond to opponents screening a lane, with continuity to avoid reacting to every tiny movement. See [FM24 comparison and evidence](docs/FM24-Match-Engine-Review.md) for the earlier limited analysis and [Control and tactics](docs/Control-and-Tactics.md) for the current implementation. Human tactical balance remains unverified.

## Goal kicks and classic 2D view

After an attacker last touches the ball over the opposing endline outside the goal, the defending goalkeeper takes a goal kick from the goal area. AI keepers restart automatically; as the human goalkeeper, tap Space after the short countdown (hold and release for greater power). Opponents are moved outside the area. Defender-last-touch exits now award a corner at the nearest corner area.

The earlier bright-turf experiment is historical. The current renderer uses the original NEON 11 palette, regulation-shaped markings, distinct keepers and ball contrast; no FM assets were imported.

## Rule references and remaining work

Restart logic follows the relevant subset of [IFAB Law 9](https://www.theifab.com/laws/latest/the-ball-in-and-out-of-play/), [Law 15](https://www.theifab.com/laws/latest/the-throw-in/), [Law 16](https://www.theifab.com/laws/latest/the-goal-kick/) and [Law 17](https://www.theifab.com/laws/latest/the-corner-kick/). Pitch markings use [Law 1](https://www.theifab.com/laws/latest/the-field-of-play/). The simplifications above are deliberate outstanding work, not a claim of full IFAB compliance.

## NEON 11: rules, AI and controls

Space tap passes; hold/release shoots, with a visible charge bar. Corners arrange box runners, goal-side defenders and cover, then launch a planned physical delivery. AI aims at available goal openings, goes around the ball to reach the correct side, follows progressive touches and avoids selecting offside receivers. These are tested mechanisms, not a claim of complete football AI.

See [Football-Identity.md](docs/Football-Identity.md) for the design direction and outstanding work. Offside follows the supported subset of [IFAB Law 11](https://www.theifab.com/laws/latest/offside/).

## Tactical centre

The **AI coach decides formations, roles, duties and instructions automatically**. You control your footballer. Press **T** to inspect the coach's report: **1 / 2** selects the team being viewed, **[ / ]** the player, **Tab** the section and **up/down** the row. Mouse selection and the wheel are supported. The report is read-only: arrows, Enter and clicks on values do not change tactics. **T or Esc** resumes. Pending kicks and charges are cleared when opening or closing it.

The tactical model provides **45 roles**, their available duties, **five formations** (4-4-2, 4-3-3, 4-2-3-1, 3-5-2, 5-2-3), **19 active team instructions** and **16 active individual instructions**. Six team rows and two individual rows remain unavailable because their required systems are absent. The coach's choices affect AI support, pressing, passing, carrying, shooting and ground crosses. They do not automate the human player's movement or Space decisions. Tactical changes preserve live bodies, score, clock and the controlled object.

FM24 names and Italian labels were verified in local language resources; the behaviour coefficients and interface are original. Active position compatibility and the full locked-instruction matrix were not extracted from the FM24 engine. See [tactical centre usage and limits](docs/FM24-Tactics.md) and [role catalog and source confidence](docs/FM24-Role-Catalog.md). Human tactical balance remains unverified.
