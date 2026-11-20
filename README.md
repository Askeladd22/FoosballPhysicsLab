# Foosball Lab

**Mouse-controlled single-player table football** for LÖVE2D 11.5. This is now the primary project in the repository. The older **NEON 11** soccer experiment is preserved, but frozen.

## Launch

Install LÖVE 11.5, then from the repository root:

```sh
love .
```

Windows: `run-foosball.bat`. The original 11vs11 is still available with **`love . --legacy`** or `run-neon11-legacy.bat`. The historical entry point lives at [legacy/neon11/main.lua](legacy/neon11/main.lua) and its original [README](legacy/neon11/README.md), [SEED planning](legacy/neon11/PLANNING.md) and [PAUL state](legacy/neon11/PAUL-STATE.md) are retained. The entire `src/` tree, existing 11vs11 tests and Git history remain intact.

## Controls

| Input | Action |
|---|---|
| Mouse vertical | Slide the currently selected rod |
| Mouse horizontal | Rotate the rod to strike with its physical foot |
| Left click / Esc | Capture / release the mouse |
| 1–4 or mouse wheel | Choose goalkeeper, defense, midfield or forward rod |
| C | Bring selected rod toward a neutral angle |
| - / + | Adjust rotation sensitivity |
| G | Toggle Neon Glass glow |
| F1 | Physical collision overlay |
| R | Reset match |

Four human rods (1–2–5–3 figures) face four basic AI rods. The ball is physical; it can rebound from walls, score goals or trigger a two-second automatic restart when stationary in a genuinely **unreachable corridor**. First team to five wins.

## Scope

**Active:** rod physics, mouse handling, opponent AI, short satisfying matches and clear Neon Glass presentation (smoky tempered-glass look with restrained glow).

**Out of scope for now:** career, rankings, multiplayer and new large gameplay systems. **Frozen, not removed:** all NEON 11 gameplay and tactical expansion. **Project Folio:** unrelated and untouched.

## Supplied 3D and CAD models

I examined the attached `foosball_table.glb` (22,855 triangles, one merged mesh, three 2048² PNG textures, CC BY 4.0 attribution embedded) and `Stoni_fudbal_1.stp` (41 STEP PRODUCT definitions, 199 solids, no embedded license). They are **references, not current in-game assets**. The GLB cannot animate eight rods as currently merged; the STEP needs tessellation and rights confirmation. See [asset assessment](docs/asset-intake/foosball-models.md) and [attribution](docs/asset-intake/ATTRIBUTION.md). Neither binary is added to GitHub in this change.

## Architecture

- `main.lua`, `conf.lua`: Foosball-first LÖVE launch; explicit 11vs11 legacy route.
- `experiments/foosball/`: actual Foosball physics, renderer and controls.
- `legacy/neon11/main.lua`, `src/`: frozen 11vs11 application and original source.
- `tests/test_foosball*.lua`: Foosball regressions; remaining Lua tests preserve legacy.
- `PLANNING.md`, `.paul/`: active SEED/PAUL state and history.

**Automated tests are not proof of fun.** Validate on Windows by comparing ten intentional mouse strikes, ball tracking and stall recovery with glow on/off.
