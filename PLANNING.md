---
project: Foosball Lab
project_type: custom/game-development
status: implementing
plan_version: phase35-gameplay-camera-composition
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

## SEED Phase 30 — Root cause Canvas Y / full tabletop
**OBSERVED**: despite an upright GLB (field Y=-4, support legs Y=-740), Windows screenshots repeatedly showed an apparent upside-down foosball. Earlier camera changes targeted only the pitch, hiding the legs.
**VALIDATED**: rendered all 11 actual user CC BY meshes independently using VTK. A three-quarter camera aimed at the **whole body center Y=-305** visibly shows the full green field and four support legs underneath.
**CRITICAL ROOT CAUSE**: manual clip-space GPU vertex shader failed to compensate for LÖVE's offscreen Canvas Y orientation. Before correction, native GPU screenshot ASCII was vertically mirrored from the reference; projected green field probes **2/99**. Fixed `-dot(delta,uUp)*uFocal`, preserving the CPU's projected Y logic; same native GLB now **67/99** green, **4/4** leg supports visible.
**DECIDED**: retain genuine source meshes + the 180° horizontal yaw; 3/4 perspective camera on full table; explicit full-body camera tests at 4 resolutions and native GPU screenshot capture. No g3d dependency or physics migration.
**EVIDENCE**: [all 7 CI jobs successful](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687), [native screenshot artifact](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687/artifacts/14639560551); prior failures on branch were intentionally diagnosed rather than concealed.
**OPEN**: human Windows UAT — verify exact appearance on display and ten intentional strikes; do not infer playability from software GPU checks.

## SEED Phase 31 — Gameplay Readability
**OBSERVED:** user screenshot after real 3D orientation fix: correct upright cabinet, but action/colored figures/ball small in a pitch occupying only part of the viewport. Only one gold selection circle.
**DECIDED:** two separate 3D cameras: GAMEPLAY as default on full field; SHOWCASE unchanged for the full four-leg table; F4 switch without gameplay reset; Home to GAMEPLAY. Project highlighted human rod shaft, all selected physical feet directly from `Model.foot`, ball and short velocity cue from `match.ball`; maintain original GLB and 2D simulation.
**VERIFIED:** [7/7 CI](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020) on Foosball/NEON11 Lua5.4+LuaJIT and two real GPU GLB modes; SHOWCASE 4/4 legs and 56/255 scene probes, GAMEPLAY 207/255 scene probes, green 74/99.
**UNVERIFIED:** perceived player silhouette and foot impact clarity on the actual Windows display and 10-shot human outcome. Do not call the game finished until UAT.

## SEED Phase 32 — Physics: unreachable vertical ricochet
**OBSERVED:** `model.lua` originally gated dead-ball recovery on the *total* ball velocity falling below 6, even in X corridors where no shoe can ever contact the ball. Persistent vertical ricochets can keep the ball unplayable without ever triggering the timer.
**DECIDED:** use two seconds of uninterrupted **geometric non-reachability** as the condition; a horizontal escape resets the timer at the first reachable step, not merely because it gained speed.
**DECIDED:** preserve the neutral re-serve team alternation, 120 Hz simulation, physical rod contacts and 3D presentation unchanged. No forced artificial ball impulses or extra buttons.
**VERIFIED:** [7/7 CI jobs](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44766380466), including new bouncing/escape tests and existing score/false-deadball regressions; frozen NEON11 untouched.
**ASSUMED:** the existing two-second house rule is a good player-facing compromise.
**UNVERIFIED / NEXT:** Windows playtest to assess perceived fairness when vertically ricocheting and when shooting across the midfield corridor.

## SEED Phase 33 — Input: high-polling AUTO microgestures
**OBSERVED (code):** the old `mouseMoved` accepted any one event with at least 3 px to hold AUTO. A rapid sequence of individually 1px mouse events could change the rod during an intentional stroke because none individually passed the threshold.
**DECIDED:** recognize 3 cumulative px in a continuous sequence with no inter-event gap over 60ms, cap the accumulated value, and reuse the existing 200ms AUTO hold. Clear gesture history on reset and mode toggle. Mouse sensitivity, manual behavior, 120Hz simulation, AI and collision physics are unchanged.
**ASSUMED / DESIGN RISK:** the 60ms window filters sporadic jitter; different mouse devices and player habits may require tuning. Do not claim controller feel is proven by automation.
**EVIDENCE:** targeted Lua5.4/LuaJIT regression suite passing in [GitHub Actions #44772526612](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44772526612); visual/NEON11 check status is tracked on the PR. 
**OPEN:** Windows human input test: 10 light, high-polling gestures near AUTO handoff, idle pointer jitter, count mis-selections and response.

## SEED Phase 34 — Rampe anti-punti morti lungo bordi e angoli
**OBSERVED:** il modello permetteva solo pareti elastiche; la pallina lenta vicino alla sponda poteva fermarsi, senza pendenza che la riportasse verso i piedi.
**DECIDED:** profilo suolo condiviso in `ramps.lua`: 2 rampe lunghe, 4 segmenti sulle testate esterni alle porte, altezza sommata negli angoli. Profondità 44 unità, quota massima di ogni singolo lato 7 unità, accelerazione massima 240 unità/s² con pendenza quadratica; taper di 24 unità nei pressi dei pali.
**DECIDED:** 2D e 3D mostrano la stessa impronta; il 3D genera una mesh con normale illuminata e alza la pallina sul piano inclinato. Nuovo componente `ramps.lua` privo di dipendenze esterne. Nessun contatto piede-palla o IA alterato.
**ASSUMED:** intensità sufficiente a ridurre la permanenza della pallina sul bordo senza accelerare eccessivamente una normale azione di sponda.
**OUT OF SCOPE:** 11vs11 legacy, multiplayer, carriera, modello 3D sorgente, fisica verticale piena; la fisica resta 2D planare con accelerazione equivalente alla pendenza.
**OPEN / GAME DESIGN LAB:** playtest Windows e tuning; riprodurre 4 angoli, 4 tratti di testata, 10 tiri di sponda e 5 conclusioni in porta. Misurare falsi cambi direzione, ritmo e leggibilità, senza scambiare CI per valutazione del divertimento.
**TECHNICAL EVIDENCE:** regressioni dedicate `tests/test_foosball_ramps.lua`, CI collegata alla [PR #32](https://github.com/Askeladd22/FoosballPhysicsLab/pull/32).

## SEED phase 35 — Screenshot-accurate 3/4 GAMEPLAY camera
**OBSERVED:** the user's explicitly chosen 1271×874 image shows the original diagonal 3/4 perspective (from a long rail), with both goals visible, blue/red players and the near cabinet rim. The temporary high/centred 70° camera would NOT resemble the reference. User subsequently clarified that the in-game camera must match their exact photo.
**DECIDED:** preserve its original GAMEPLAY view: `target={500,10,280}`, eye offset `{-100,+1060,side*780}`, FOV35°, default `front`, yaw180°, zoom100%. Keep `ESPOSIZIONE` unchanged and retain `currentFovDegrees()` for matching GPU shader and CPU overlays. Do not change field HUD viewport.
**EVIDENCE:** `tests/test_foosball_camera_framing.lua` checks seven source-world projective reference anchors at 1271×874 (centre, four corners and goal midpoints), plus all 5 resolutions, both sides and yaw0/180, contacts and F4 full-cabinet continuity. Independent renderer mock verifies correct focal uniform.
**REVISED / SUPERSEDED:** prior assumptions about a 70° near-zenith view and 33° FOV are explicitly rejected because the user supplied a visual reference. No speculative redesign of the photo.
**ASSUMED / OPEN:** screenshot reference test guarantees projected placement, not subjective texture lighting, readability on the user's GPU or ease of mouse control. Native Windows human screenshot and ten-shot input UAT still needed.
**OUT OF SCOPE:** modifications to physics, ramps, ball hitboxes, lighting, 3D asset mesh, AI, or frozen NEON11.
**NEXT:** build [PR #33](https://github.com/Askeladd22/FoosballPhysicsLab/pull/33) and compare a 1271×874 native LÖVE screenshot against the user's supplied image; preserve composition when tuning aesthetics later.
