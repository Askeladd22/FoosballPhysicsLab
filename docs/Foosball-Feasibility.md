# SEED / Game Design Lab — Realistic Foosball: Feasibility & Testable Vertical Slice

**Status:** CANDIDATE — design comparison only. **No decision to replace 11v11 FootballPhysicsLab.**
**Reference rules:** [International Table Soccer Federation](https://www.tablesoccer.org/rules/).
**Comparables (not sources of copied code/art):** [Foosball Manager](https://store.steampowered.com/app/2607570/Foosball_Manager/) (AI and management); [Dirty Kicker](https://store.steampowered.com/app/5515750/Dirty_Kicker_A_Foosball_Game/) (arcade physics skill).

## Why this is *not* a HaxBall reskin
A realistic tabletop game uses **8 constrained rods**, 4 per side: goalie (1 figure), defense (2), midfield (5), forwards (3). These are constrained mechanical figures, not 22 freely roaming football agents. Rods translate across the table width and rotate about their axes. Collisions depend on foot contact, angular velocity, ball linear velocity, table friction, wall reflection, and possibly spin. There is no offside or throw-in. A player controls a *rod*, not a solitary free-running disc. The long-term solo career is that of a table-football competitor, not a footballer.
 
## Game Design Lab — mechanism chain
Goal: build and finish a scoring opportunity using manual rod timing.
- **WHAT:** Ball position + linear/angular velocity, rod displacement and angle, possession pressure, score.
- **HOW:** Translate rod → align foot/contact lane → time a controlled rotational strike → ball deflects/rebounds → reposition another rod.
- **WHERE:** Core interaction and opponent response, visible directly in a top-down 2.5D camera.
- **Critical failure mode:** Fast rod switching and two-axis input can feel less readable than the single-disc controller; automated rod selection may undermine skill agency.

## Prototype A — one manual attack rod vs AI goalkeeper
Playable smallest slice, separate module/repository branch, not merged into 11v11:
- A physical table surface with side walls, goal aperture and rounded corners.
- A constrained 3-figure forward rod: drag mouse vertically to slide it, mouse-held horizontal action to rotate it through a limited angle; no unlimited spin exploit. Show rod angle and ball motion precisely.
- AI goalkeeper rod predicts intersection of a freely moving ball at the goal line and translates with a reaction delay; it does not teleport.
- One central ball serve, shoot/deflect/save/rebound, score, instant reset. Use 120Hz fixed simulation and swept ball-vs-foot collision or adequate substeps for speed.
- Touch/aim audio & visual feedback, physics debug overlay; 2D shapes first, visual art later.
- Excluded: career, rosters, elaborate tactics, 45 roles, stores, upgrades, online multiplayer, licensed clubs.

## Prototype B — four rods per side after A
Player can switch among goalkeeper, defense, midfield and attack rods (keys 1–4 or contextual selection); AI controls the other four rods. Rod motion uses controlled interpolation and angular inertia. Keep ITSF-inspired rules in a *selectable realism preset*; start with simple matches to 5 goals. Favor predictable, physically meaningful movement.

## Comparison to existing NEON 11
| Dimension | Current 11v11 | Realistic foosball |
|---|---|---|
| Core player skill | single-disc movement + pass/shot direction + teamwork | rod selection, sliding, timing, rotating, rebounds |
| AI difficulty | 21 footballer agents + tactics + rules | 4 opponent rods, interception and shot timing |
| Physics challenge | moving circles, intercepts, free-ball control | rotations/contact geometry, fast ball, CCD, wall damping |
| Career fantasy | individual footballer's season | tabletop competitor climbing leagues/cups |
| Main risk | tactics overwhelm agency | controls overwhelm player without intuitive rod manipulation |
| Existing code reuse | most 11v11 architecture | fixed step/ball integration/render patterns only; physics and AI are different |

## Cheapest decisive playtest
Test same participant on the existing directed-pass recovery and Prototype A, at least two sessions each, ideally also with someone unfamiliar with the code.
Observe *before asking preferences*: attempts until accurate directional shot, intentional bank shots, skipped actions, misunderstood input, repeated voluntary attempts, ability to predict ball paths and recover from misses.
- **Support foosball pivot** when rod interactions are clear and produce repeatable, expressive choices without constant fighting the UI.
- **Revise controls** when the ball is plausible but rod translation/rotation is confusing.
- **Remain 11v11** when footballer agency proves stronger after fixes; do not let development investment substitute for play evidence.

## Reversible decision gate
Do **not** replace `src/sim.lua`, `src/ai.lua`, or `main.lua` with foosball assumptions. Prototype under `experiments/foosball/` or a separate repository and compare; project naming/rebrand only after a user decision and playtest.
