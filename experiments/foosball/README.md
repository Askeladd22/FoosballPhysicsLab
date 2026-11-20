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


## End-stop and striking-face tuning
The **square/flat shoe** is both the drawn impact surface and the physical collision rectangle. Its bright leading edge points toward the opponent's goal, and the currently selected figure shows a short yellow attack arrow. The rod travels to the figure-to-cushion limit, or the goalkeeper's mechanical bearing. On contact with the upper/lower stop, its velocity is zeroed and the end-guide bumper compresses visibly. `F1` displays the exact foot collision rectangle. Try the two ends of rod 4 and 10 deliberate flat-face strikes.


## Visual clarity pass (PAUL 17)
The player figure now inclines with the same physically projected foot position used for collision, with the pivot still on the vertical rod. Team colors remain visible when selected; only the active foot edge receives an outline and one central arrow. The HUD uses readable **DESTRA/SINISTRA** labels rather than Unicode arrow glyphs unavailable in some default fonts. The wood rim is fitted below a dedicated title strip and above a footer at 900×650 and larger windows. Try `F1` to inspect the collision rectangle and compare screenshots at 900×650 and 1280×850. This is an optical model of axial rotation, not full 3D body rendering.


## Neon Glass identity (PAUL phase 18)
The Foosball Lab default look now uses a **dark graphite chassis**, **smoked teal tempered-glass playfield**, layered translucent highlights, selectively illuminated cyan-white etched lines and goals, cyan human figures, warm coral opponents, amber active-rod accents, and a crisp high-contrast warm-white ball. This is **stylized 2D glass**, not a physically refractive surface. The glow uses cheap additive primitive passes: there are no required textures, shaders, downloaded assets, career menus or new gameplay systems.

Press **G** to toggle neon glow **ON/OFF** without altering the physics or controls. Compare each setting when tracking a moving ball or reading which foot can make contact. `F1` continues to show exact collision geometry. This is a **visual experiment**: check the native LÖVE result and manual control feel before considering the art direction validated. Launch unchanged: `love experiments/foosball`.


## Automatic dead ball (PAUL 19)
If the ball slows down in an area no rod can physically reach, a 2-second **PALLA IRRAGGIUNGIBILE** countdown appears in the existing bottom HUD. The simulation examines the possible foot contact envelope using real rod X positions, maximum legal rotation, shoe/ball radii and rod sliding travel; a moving ball or a merely parked *reachable* ball does not restart. After the countdown the ball is re-served near a reachable **midfield rod**; the opposite team to the last striker gets the restart, or teams alternate when no striker is recorded. Score, rods and match state are preserved. This is a simple prototype **house rule for dead balls**, not a magnet or a hidden kick. The 11vs11 frozen project is not modified.
