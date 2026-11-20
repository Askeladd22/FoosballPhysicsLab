# PAUL 24-01 — UNIFY: camera rialzata e piedi fisici collegati

**Base:** `94ad3862462a76a36b76cd7e90ef3c91dfbf4359`.
**PR:** [#22](https://github.com/Askeladd22/FoosballPhysicsLab/pull/22) (bozza).
**Stato:** IMPLEMENTED / CI VERIFIED / WINDOWS UAT NOT_RUN.

## Risultato PLAN → APPLY
- **AC1:** `camera.lua` aggiunge una camera affine obliqua 2.5D di default. **P** torna al top-down e viceversa, senza cambiare fisica, IA, tiri o punteggi.
- **AC2:** `layout.lua` centra il rettangolo *proiettato* del tavolo incluso il bordo; footer ancorato al bordo inferiore proiettato. Verificati 900×650, 1280×850 e 1920×1080.
- **AC3:** quando è presente il modello Table Soccer renderizzato da PNG locali, ciascuno dei **22 piedi** ha una scarpa colorata nella posizione `Model.footRect` e un collegamento visivo all'asta. Rimossi i marcatori isolati; **F1** continua a mostrare i collider. Indicatore di traslazione sulla stecca selezionata e figura procedurale più alta nella visuale obliqua.
- **AC4:** zero modifiche a `model.lua`, `legacy/neon11/` e modelli/immagini di terzi. Gli sprite 2.5D restano privati e opzionali.
- **AC5:** [GitHub Actions 44712405674](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44712405674) **4/4 PASS**, Foosball e legacy su LuaJIT/Lua5.4. Test camera, layout, geometria visuale, fisica e regressioni storiche.

## SEED
**Osservato:** foto di riferimento con vera prospettiva 3D e bug di una faccia di tiro rossa staccata dallo sprite. **Dedotto:** le immagini delle mesh non condividono automaticamente la forma del collider fisico. **Deciso:** usare ora un primo prototipo obliquo reversibile e scarpe connesse alla vera collisione; **non** dichiarare implementato un rig 3D. **Aperto:** efficacia in playtest e diritti di distribuzione del modello.

## Game Design Lab — prova necessaria
Da Windows con LÖVE, 10 colpi in modalità **rialzata** e 10 in **top-down (P)**, stessa posizione del mouse; usare **V** per confrontare sprite/procedurale e **F1** per la coincidenza tra scarpa e collisione. Raccogliere eventuali errori nel giudicare la posizione degli omini e la riuscita dei colpi. **Playtest nativo NON eseguito**, non si conclude che la nuova visuale sia più divertente solo dalla CI.
