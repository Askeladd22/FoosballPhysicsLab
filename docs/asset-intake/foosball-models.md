# Supplied foosball models — technical and rights assessment

**Sources:** user-provided `foosball_table.glb` and `Stoni_fudbal_1.stp`, inspected directly on 2026-11-20.
**Status:** reference only; neither user upload is bundled or loaded by the running game.

## A. foosball_table.glb (glTF 2.0)
- Valid GLB version **2**, 10,863,860 bytes.
- **1 merged mesh**, 1 material, **19,936 vertices**, **22,855 triangles**; **3 embedded PNG textures**, each **2048×2048**, 0 animations, 0 skins and no separately named rod or figure nodes.
- Scene bounds (in the file's imported coordinates) approximately 124.55 × 77.43 × 140.38. Do not equate this with physical centimetres without a scale reference.
- Embedded metadata: title **Foosball Table**, author **owestgate**, license **CC BY 4.0**, original <https://sketchfab.com/3d-models/foosball-table-1303a318d4584639acef729b9fd296fc>.
- **Useful:** static geometry/material reference; *after processing* could be an optional static visual tabletop. Live rods must be rebuilt as independent pieces and their pivots aligned to Foosball's authoritative 2D collision model.
- **Not ready:** one merged mesh cannot represent eight independent rod rotations and translations, the existing LÖVE2D app cannot natively load GLB, and the baked-in figures would visibly conflict with the active figures. Rendering performance with 3×2048² textures has not been measured.
- CC BY 4.0 permits adaptation and commercial redistribution with proper attribution, license link and modifications notice. This statement is grounded in GLB metadata; the Sketchfab live page was not independently retrievable due to its access challenge. See [attribution](ATTRIBUTION.md) and <https://creativecommons.org/licenses/by/4.0/>.

## B. Stoni_fudbal_1.stp (CAD/BREP)
- Valid ISO-10303-21 STEP; CATIA V5 Release 18, AP203 / CONFIG_CONTROL_DESIGN; export header timestamp **2013-04-02**.
- 1,885,176 bytes, **41 PRODUCT definitions**; OpenCascade successfully transferred 1 assembly containing **199 solids** and **4,965 BREP faces**. Approximate CAD import envelope 1566.69 × 1400.00 × 922.00 in source units (do not assume mm without CAD author verification).
- Several independently identifiable assembly parts: `Sipka`, `Sipka2`, `Sipka3`, `Sipka5` (shafts), `Igrac` (figure), `Loptica` (ball), `Teren` (field), supports and hardware.
- **Useful:** mechanical proportions, permitted travel, shaft positions and potential extraction of player geometry for **offline** triangulation.
- **Not ready:** STEP is a CAD interchange format, not a real-time triangle asset. Need isolate parts, choose tessellation, fix pivot/orientation, UV/material strategy, reduce detail and export independent GLB meshes.
- **Legal gate:** no license or copyright permission appears in the supplied STEP. No rights are inferred from its availability, age, origin, or upload. Do not put it or any derived geometry in a public repo or shipped build without authorization.

## SEED decision
**DECIDED:** Foosball stays 2D/fixed-step for gameplay. The models are optional input for an *offline art comparison*, not a new game engine. Store local original files under `assets/reference/` (ignored) pending rights/rigging decisions. No GLB, STEP or extracted textures were committed in this phase.

**ASSUMED:** a separate pre-render of a STATIC, uncluttered table could improve premium material expression. **Unverified:** 2.5D camera, collisions projected correctly, FPS, model rights on its live host, human readability.

**OPEN:** whether the GLB author's licensing still matches embedded CC BY metadata, who owns STEP redistribution, and whether any 2.5D rendering looks better in real gameplay.

## Game Design Lab: smallest decisive experiment
1. In Blender or another offline app, open a **copy** of the GLB and remove/replace the baked-in rods/figures; do **not** display them underneath live 2D rods.
2. Render a single static table without the ball/players at the current foosball game's screen aspect ratio; line it up with the top-down 1000×560 physical playfield. Keep bright goal mouths but subdued floor highlights.
3. Compare with Neon Glass 2D using ten intentional mouse strikes and fast ball tracking. Check foot readability, 2D collider projection, missed-ball incidents and frame time. No core physics changes before the comparison.
4. Separately use STEP as a **private dimensions reference only** until rights are clear; if authorized, separate and simplify rod/player CAD assemblies.

### Local metadata inspection (Python standard library only)
```sh
python tools/inspect_foosball_models.py assets/reference/foosball_table.glb assets/reference/Stoni_fudbal_1.stp
```

The script reports exact GLB counts, embedded author/license and STEP entity counts without external dependencies. For exact STEP solid counts, a BREP reader such as OpenCascade is necessary; the above 199 was verified in the upload review, not fabricated by the stdlib parser.
