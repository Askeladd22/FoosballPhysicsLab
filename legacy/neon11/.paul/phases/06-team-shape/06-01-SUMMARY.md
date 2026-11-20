# SUMMARY 06-01 — Coordinamento della squadra

**Risultato:** DONE_WITH_CONCERNS; AC-1/2/3 automatici PASS, UAT umano NOT_RUN. Data 2026-11-19.

- **AC-1:** identità PE/SHA-256 di fm.exe verificata via REA; sette risorse lette e registrate con hash, XML analizzati, etichette binarie distinte da uno schema decodificato; fonti ufficiali FM24 confrontate. Nessuna decompilazione o osservazione runtime FM24 dichiarata. Sessione REA chiusa.
- **AC-2:** mappa di obiettivi tattici condivisa per squadra, sostituto in copertura, obiettivi separati e spazio riservato al ricevente. Sorgenti originali del nostro progetto, nessuna formula FM importata.
- **AC-3:** nove suite eseguite in stati LuaJIT separati tramite Python ctypes sulla DLL LÖVE, tutte PASS. Nuova suite test_team_shape; vecchi test di fisica, ricezione, ruoli e vista preservati. Partite RM/GK da 180 s ripetute per determinismo: entrambe 0–0. RM: blu 5/9 ricevuti, rossi 5/17; GK: blu 7/10, rossi 8/8. Numeri di scenari sintetici, non valutazione del bilanciamento.

**Limiti:** maggiore copertura potrebbe ridurre occasioni offensive; verificare con input umano. Le fasi tattiche si basano ancora sull'ultimo tocco. LuaLS e UAT umano non eseguiti; CI aggiornata ma non lanciata da questa sessione. Nessun commit/push.

**UNIFY:** analisi, piano, resoconto e stato aggiornati. Le evidenze della fase 05 restano storiche.
**Prossimo passo:** playtest RM/GK di appoggi e copertura, controllando che rimangano sufficienti occasioni di attacco.
