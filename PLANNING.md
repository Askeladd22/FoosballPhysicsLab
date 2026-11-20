---
project: Foosball Lab
project_type: custom/game-development
status: implementing
plan_version: phase22-directory-split
last_updated: 2026-11-20
---

# SEED — Foosball Lab

**Promessa:** una partita breve in cui il gesto mouse SU/GIÙ per scorrere e SINISTRA/DESTRA per ruotare le aste è controllabile, leggibile e ripetibile.

## DECIDED
- Foosball occupa direttamente la **root**: `love .`; nessun modulo runtime in `experiments/`.
- NEON 11 è **frozen, preserved** sotto `legacy/neon11/`: codice `src/`, test, asset, documenti e fasi PAUL; lancio `love legacy/neon11`, scorciatoia `love . --legacy`.
- 120 Hz, quattro aste per squadra (1–2–5–3), controllo manuale fisico, AUTO/MANUALE solo per selezione della stecca, recupero della palla morta e Neon Glass restano invariati.
- Le pose Table Soccer derivate da mesh di terzi stanno soltanto in `local_assets/` sul computer dell'utente (diritti di redistribuzione da ottenere).
- Project Folio resta indipendente.

## ASSUMED / UNVERIFIED
- AUTO non cambia asta durante una frustata volontaria.
- Resa 2.5D non confonde la faccia di contatto, né peggiora troppo gli FPS.
- Regola dei due secondi è percepita come equa.

## OPEN
- Licenza di distribuzione del modello VERTX3D, attualmente non autorizzata.
- Riscontri reali di leggibilità e divertimento.

## OUT OF SCOPE
Carriera, ranking, multiplayer, sistemi tattici 11vs11, migrazione alla fisica 3D.

## Game Design Lab
Dieci tiri intenzionali in AUTO, tre in MANUALE, tre blocchi di palla morta e confronto V con due risoluzioni. Registrare scelte errate, perdite di contatto e FPS; nessuna conclusione sul divertimento dalla sola CI.

**Next:** playtest Windows/LÖVE della root e del vecchio titolo lanciato dalla sua cartella.


## SEED Phase 25 — TRUE 3D
**DECIDED:** rendere il vero OBJ Table Soccer con 11 buffer GPU, shader prospettico e depth buffer. Otto aste e pallina ereditano le trasformazioni della fisica 2D esistente; nessun nuovo sistema di collisione e niente vecchi sprite sovrapposti alla vista 3D.
**DECIDED:** importer Python locale da ZIP di proprietà dell'utente; il repository pubblico distribuisce solo codice, non asset o mesh derivate. **P/V:** 3D/2D istantaneo. **NEON11:** legacy completamente congelato.
**ASSUMED:** proporzioni del modello autore e pivot ricostruiti (l'OBJ perde i pivot Maya) rendono visivamente leggibili i colpi. **OPEN:** prestazioni native e precisione delle scarpe 3D rispetto ai collider 2D in un playtest reale. **UNVERIFIED:** il modello è visivamente convincente prima di prova reale su LÖVE.

## SEED Phase 26 — Black-frame gate + openly licensed model
**OBSERVED:** the previous 3D depth clear value was 0 under `lequal`, causing a black screen despite successful mesh initialization.
**DECIDED:** clear to 1; fail native CI if actual canvas pixels contain no geometry. Select 3D Content Online's `foosball_table (2).glb` (103 primitives, 73,636 triangles, CC BY 4.0), not the single-mesh or Marble NC models. Re-rig players to 1-2-5-3 rather than changing game collisions to match the asset.
**DECIDED:** original CC BY GLB can live at `assets/models/foosball_table.glb` with source/attribution; converted GPU buffers are generated locally from it and need not be versioned.
**OPEN:** Windows user visual review and camera/pivot feel. **OUT OF SCOPE:** changes to frozen 11vs11 or career.

## SEED Phase 27 — Camera correction
**OBSERVED:** real user screenshot: upside-down-looking perspective, dark rear wall dominating top screen, cut rods/frame, camera too close.
**DECIDED:** default 3D viewpoint from the **opposite long edge**, higher and farther, FOV42, automatically fit to window aspect; F2 flips viewpoint, PageUp/PageDown adjust distance, Home restores.
**DECIDED:** mouse wheel still switches rods; no physics/mesh rescale or hidden gameplay changes. P/V remains 2D fallback.
**UNVERIFIED:** perceived player/foot clarity and comfort at the user's resolution; only actual screenshot/playtest can confirm subjective quality.
**GATE:** camera projected outer board rim remains in 3D viewport at 900×650, 1280×850, 1650×895 and 1920×1080, plus non-black GPU smoke and Lua regressions.

## SEED Phase 28 — Rotate the 3D world by 180°
**DECIDED:** user requested rotation of the **whole foosball table**, not merely a camera-side switch. Default is a 180° rigid yaw about the world-up Y-axis at table center (500, *, 280): field, table, eight rods, ball and their shading normals transform together.
**DECIDED:** authoritative 2D physics and mouse input remain unchanged. World turn is a single GPU shader transform after the individual rig movements, with matching CPU selection-marker projection. F3 compares 0°/180°, Home restores 180° and camera defaults; F2 changes camera only.
**DECIDED:** no g3d library is added; the existing LÖVE GPU renderer supports real 3D meshes, depth and rigid model transforms already.
**ASSUMED:** "180 degrees" means horizontal yaw about the table's world-up axis, not flipping the table over or rolling the user's screen.
**UNVERIFIED:** whether near-wall occlusion and subjective playing orientation improve on user's Windows monitor; the actual screenshot and 10 deliberate strikes are the next gate.

## SEED Phase 29 — Leg truth / pitch readability
**OBSERVED:** true GLB source field at Y≈0.736; supports at Y≈0.040, i.e. the table is already physically UPRIGHT. In-game screenshot looked "sottosopra" because the low camera showed the back of a raised rail and rod handles.
**DECIDED:** do **not** rotate source mesh upside down; move camera high above the field, keeping genuine 3D perspective and the requested 180° horizontal yaw. Add native green-field pixel test and imported geometry leg-height test.
**VERIFIED:** 7/7 CI jobs passed; genuine CC BY GPU scene 73 of 99 selected field probes green, legs Y=-740 field Y≈-4, rim Y=+130.
**NOT VERIFIED:** user's Windows look/feel and actual ball-foot match. Human screenshot and 10-shot playtest remain the next decision gate.
