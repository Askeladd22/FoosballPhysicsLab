# PAUL SUMMARY 34-01 — Rampe fisiche lungo sponde e angoli

**Status:** VERIFIED_AUTOMATED / WINDOWS_UAT_NOT_RUN
**Branch:** `feat/foosball-edge-corner-ramps` · [PR #32](https://github.com/Askeladd22/FoosballPhysicsLab/pull/32) in bozza, non fusa in `main`.
**CI:** [GitHub Actions 44778209050](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44778209050) **7/7 PASS** sul commit di codice `3c64bbd70475886cdeb07bc7b945c70078a0ea22`. La CI 44777240157 era fallita per una **asserzione di test troppo severa**, poi corretta e rieseguita: il successivo run di riferimento è verde.

## PLAN → APPLY
- **T1 (DONE):** `ramps.lua` definisce le stesse pendenze quadratiche per accelerazione 2D, quota 3D, 6 segmenti e triangolazione. `model.lua` applica la forza in ciascun microstep, preservando goal, controllo, contatti, dead ball e integrazione deterministica a 120Hz. Risolto anche lo sleep della pallina a velocità zero sulla pendenza.
- **T2 (DONE):** `theme.lua` e `main.lua` disegnano fasce visibili Neon Glass. `renderer3d.lua` genera mesh GPU con normali, geometria prospettica e depth testing. La pallina visualizzata viene alzata esattamente secondo `Ramps.heightAt`.
- **T3 (DONE):** `tests/test_foosball_ramps.lua` testa risalita da fermo sui due lati, le due testate, i quattro angoli, goal mouth, vero dislivello mesh, assenza forza al centro, determinismo; aggiornati mock del renderer 3D, test della palette e sintassi CI. PAUL/SEED documentati.

### Follow-up — true 3D ramp alignment
A code review of the perspective view exposed a separate rendering mismatch: ramp GPU triangles originally started at a hardcoded **Y=7.2**, irrespective of the CC BY model's ball height. Now the triangle floor baseline is derived from `ThreeD.ballHeight - Model.BALL_RADIUS` so the ball remains tangent to the ramp geometry and the ramp cannot visually float above it. The gameplay indicator now projects `ThreeD.ballHeight + 5 + Ramps.heightAt(...)` and includes the corresponding predicted-height change in its trajectory.
**Additional automated proof:** `tests/test_foosball_renderer3d.lua` checks mesh baseline equals actual ball contact altitude and tracking overlay matches the elevated corner ball. [CI 44778209050](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44778209050) **7/7 PASS**, including native CC BY GLB rendering.
**Separate camera diagnosis:** camera FOV35, reserved top=112/bottom=140 viewport, rigid world yaw180, and default perspective mean projection readability still requires distinct UI camera work and native screenshots. The ramp task does not silently change FOV/eye positions.

## Acceptance criteria
- **AC-1 PASS:** palline ferme nelle fasce vicino a lati lunghi e testate si spostano gradualmente verso il campo.
- **AC-2 PASS:** in ciascuno dei quattro angoli accelerazione X/Y e altezza risultante superano i contributi singoli.
- **AC-3 PASS:** gola di entrambe le porte e centro sono piatti e senza forza; regole di scoring e recupero precedente superano le regressioni.
- **AC-4 PASS:** mesh inclinata GPU creata dalla stessa geometria; entrambi i percorsi 2D/3D e i test di rendering nativo LÖVE superati.
- **AC-5 PASS automatizzato:** Foosball Lua5.4 + LuaJIT, legacy NEON11 Lua5.4 + LuaJIT, depth shader nativo, importazione GLB sintetico, **vero GLB CC BY** nativo: 7/7.

## Game Design Lab — reality check
**Goal:** togliere fermate arbitrarie ai margini senza sottrarre la precisione dei colpi.
**Means:** bassa pendenza visibile (altezza 7 per lato; al vertice due contributi) con equivalente accelerazione in piano non istantanea; i tiri e i rimbalzi restano fisici.
**Evidence:** regressioni headless più smoke 3D; non esiste evidenza di gioco umano o della piacevolezza. Il campione fissato prova posizioni riproducibili, non un tasso statistico reale di punti morti.
**Counterexample aperto:** un tiro lento intenzionale lungo la sponda potrebbe essere deviato troppo; diversa sensibilità dei mouse e prospettiva potrebbe far sembrare disallineato il bordo.
**Next:** Windows `love .`: 4 angoli e 4 segmenti terminali, 10 tiri lungo sponda e 5 in porta; confrontare movimenti, fairness e leggibilità, poi eventualmente tarare `R.DEPTH` e `R.MAX_ACCEL` nello stesso file.

## Scope guard
Nessuna modifica a `legacy/neon11/`, contenuti proprietari, camerawork, IA, goal rule, mouse, core collision/shooting geometry. PR lasciata draft, `main` invariato dalla fase 34.
