# Foosball Mouse Rod Lab — LÖVE2D

Independent **greybox / first playable**, inside FootballPhysicsLab but **not part of the 11v11 game**. Four manually selectable rods (1 / 2 / 5 / 3 figures) face four basic AI rods. The immediate training serve places the ball next to your forward rod (4). No career or multiplayer.

## Play

Install **LÖVE 11.5**. From the repository root, run:

```sh
love experiments/foosball
```

Alternatively, open the `experiments/foosball` folder with the LÖVE executable (Windows drag & drop supported), or run `cd experiments/foosball && love .`.

### Mouse is the controller

| Input | Effect |
|---|---|
| Move mouse **up / down** | Slide the whole selected rod upward / downward |
| Move mouse **left / right** | Rotate the selected rod backward / forward (aim & **physical strike**, no shoot button) |
| **Left click** | Capture mouse movement, enabling endless strokes without hitting the screen edge |
| **Esc** / **M** | Release / toggle mouse capture |
| **1 2 3 4** or **scroll wheel** | Select human goalkeeper / defenders / midfielders / attackers |
| **C** | Return selected rod toward neutral angle |
| **- / +** | Decrease / increase horizontal-rotation sensitivity |
| **R** | Restart game |
| **F1** | Physics vectors debug |

**Try first:** select **4**, line up the middle figure with the ball using vertical mouse movement, pull the mouse **left** to wind up and sweep **right** to strike. Click to capture the pointer when you need a full rotation stroke. The rod will not teleport: its sliding/turning acceleration determines the final contact.

The rod's position has a bounded travel range, rotation is limited to avoid infinite spin, and foot velocity (angular velocity + translation) pushes a freely moving ball. Ball friction, wall rebounds and a goal aperture are simulated; first to 5 wins. The opponent simply follows a predicted ball position and swings on a delay; it is **not** a sophisticated foosball AI.

## Limits / test questions

- **Prototype physics, not hardware-accurate foosball**: foot contact uses circles and simplified impulses, no spin, airborne balls, pinning or legal-tournament refinements.
- Mouse calibration: does simultaneous vertical and horizontal motion allow deliberate passing/shooting, or do axes interfere? Can shots be repeated intentionally?
- Mouse lock and sensitivity may change perceived control substantially.
- For game feel, compare **captured vs released** mouse and try 3 sensitivity settings. Count purposeful hits, accidental strikes, missed contacts and successful aimed shots.
- A passing automated test is not evidence that this is fun, realistic or accessible.

Headless verification from repo root: `lua5.4 tests/test_foosball.lua` or `luajit tests/test_foosball.lua`.

## Next design decision

Only after a human playtest, decide whether the mouse mapping needs inertia/snap-to-contact assistance, whether the player should control 1 or 4 rods, and whether a career-focused foosball game deserves a standalone repository. Never fold the foosball logic into existing `src/sim.lua` without a separate decision.
