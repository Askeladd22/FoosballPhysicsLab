# Football Physics Lab — PAUL Project

**Type:** game development  
**Core value:** Direct-control one-disc arcade football with tactical teammates and a later individual single-player career.

## Non-negotiables
- LÖVE2D / Lua; native desktop prototype.
- Human controls exactly one disc throughout each match; no player-switching.
- No multiplayer, magnetic possession or scripted dribbling.
- Preserve the older physics lab for comparisons.
- Use the uploaded Etrusco Unico ball reference for the experimental sprite only; review rights before distribution.

## Architecture
Root `main.lua` is the entry point. `src/sim.lua` implements deterministic world physics, `src/ai.lua` tactical decisions, `src/view.lua` rendering. `tests/test_sim.lua` contains headless assertions.

## Quality gates
- Syntax check and headless Lua checks.
- Manual LÖVE playtests of collision/goal/controls.
- Verify stable single-disc control and actual agency without the ball.
- No phase considered complete without relevant evidence.
