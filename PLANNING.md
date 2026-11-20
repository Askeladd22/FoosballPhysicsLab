---
project: Foosball Lab
project_type: custom/game-development
status: implementing
plan_version: "phase20-foosball-primary"
last_updated: 2026-11-20
---

# Foosball Lab — SEED

**Product hypothesis:** an expressive, learnable mouse motion makes a quick solo foosball match worth replaying.

## DECIDED
- Foosball Lab is the primary executable at `love .`; frozen NEON 11 still runs with `love . --legacy`.
- LÖVE 11.5, 120 Hz physical simulation, 1–2–5–3 constrained rods, one mouse and four basic AI opponent rods.
- Mouse Y slides the rod; mouse X turns the rod into a physical strike.
- Neon Glass theme (smoky glass, cyan/coral figures, limited glow), G comparison toggle.
- Keep all NEON 11 original code, tests, history and the [old SEED plan](legacy/neon11/PLANNING.md).
- Project Folio remains a separate main project.

## ASSUMED — must playtest
- Two-axis mouse input is intuitive and learnable.
- Players can visually predict which side of a flat foot strikes the ball.
- A two-second recovery of an unreachable slow ball is fair.

## OPEN
- Does the mechanic make players want another 3–5 minute match without career?
- Would a **static pre-rendered** table from the supplied GLB improve legibility without obstructing the live rods?
- Are redistribution rights for the STEP available? None are stated in the file.

## EXCLUDED / DEFERRED
- Foosball career, rankings, online modes and excessive UI.
- Further NEON 11 tactical/match features; game is frozen.
- New 3D physics engine, STEP runtime load, static 3D players baked into the physical rod view.

## Game Design Lab acceptance gate
Ten deliberately aimed strikes, three trapped-ball recoveries, five quick ball-identification trials with glow ON/OFF; log wrong-rod errors, missed contacts and perceived control. Compare 2D vs any **optional** 2.5D static-table greybox before changing the renderer.

See [asset intake](docs/asset-intake/foosball-models.md).
