# SUMMARY 02-01/02-02 — Match Lab stabilization + 2D camera

**Risultato PAUL:** DONE_WITH_CONCERNS / PARTIAL. Modifiche al branch PR #5; test Lua automatici superati, prova manuale LÖVE da eseguire.

## PLAN → APPLY
| Modulo | Modifiche | Test | Stato |
| --- | --- | --- | --- |
| `src/sim.lua` | Throttle non normalizzato, set piece separati per calcio d'inizio e quattro lati, pass/shot counters | Regressioni headless | PASS nel test automatico |
| `src/ai.lua` | Steering con arresto, pressing stabile, valutazione linee e preparazione corretta del calcio | Regressioni di scenari | PASS nello scenario automatico |
| `src/view.lua` | Vista top-down in stile FM27 2D Classic, piedi, palla con ombra, reti trasparenti, HUD essenziale | Smoke view finto-LÖVE a 3 risoluzioni | PASS strutturale; resa visiva NOT_RUN |
| `tests/`, CI | Nuovi scenari su kickoff, rimesse, passaggi, movimento IA e renderer | Workflow Lua | PASS (run 44551540530) |

## Acceptance criteria
- AC-1 velocità input analogici: PASS in test headless.
- AC-2 ancoraggio/pressing stabile: PASS nei test di scenario; fluidità reale NOT_RUN.
- AC-3 kickoff con battitore: PASS in test headless.
- AC-4 4 rimesse orientate al campo: PASS in test headless.
- AC-5 passaggio IA eseguibile: PASS in scenario controllato, qualità tattica globale NOT_RUN.
- AC-6 identità disco, gol, timer e determinismo: PASS in test headless.
- AC-7 partita completa e leggibile in LÖVE: NOT_RUN.
- V-1 camera alle tre risoluzioni: PASS nel mock, verifica visiva NOT_RUN.
- V-2 dettagli grafici FM27-inspired: implementati, verifica visiva NOT_RUN.
- V-3 evidenziazione del protagonista: implementata, verifica visiva NOT_RUN.
- V-4 rendering originale senza asset FM: verificato da sorgente, texture della palla proviene dalla reference dell'utente.

## Non risolto / rischi
I test headless con scenari specifici non garantiscono che una partita completa risulti credibile. La routine di rimesse è un modello semplificato: non implementa vere rimesse calcistiche né le regole arbitrali complete.
Un asset utente raffigura marchi/decori Etrusco Unico; per la distribuzione serve verifica dei diritti o sostituzione.

## UNIFY
Documentazione e stato vengono aggiornati, ma il ciclo di qualità resta aperto finché non arriva il playtest del Match Lab.
**Prossimo passo unico:** giocare una partita completa sul branch PR #5 in LÖVE2D e annotare bug visivi/tattici.
