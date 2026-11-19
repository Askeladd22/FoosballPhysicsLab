# SUMMARY 12-01 — Controllo e movimento collettivo

**Result:** VERIFIED tecnico / DONE_WITH_CONCERNS; UAT umano NOT_RUN.

**Date:** 2026-11-19.

**Changes:** working tree locale conservata; nessun commit, push o nuova CI remota.

## Pianificato ed effettivo

| Task | Effettivo | Prova | Qualifica |
| --- | --- | --- | --- |
| Primo controllo/protezione | Ctrl ammortizza il contatto, orientamento tramite movimento, impulso limitato e protezione contendibile | test_ball_control, test_space_actions | PASS |
| Combinazioni e movimento | Uno-due fisici, corse esterne/interne, CM di copertura, marcature locali e scelte contestuali | test_dynamic_team, test_role_tactics, test_support_space, test_ai_choices, test_runner_ball | PASS negli scenari |
| Vista e scala | Fit maggiore, F11 desktop/avvio massimizzato, geometria 105×68 conservata | test_view e dodici frame LÖVE reali | PASS per layout/rendering |

## Criteri di accettazione

| AC | Esito | Evidenza e limite |
| --- | --- | --- |
| AC-1 | PASS | Nessuna attrazione fuori contatto; impulso/cooldown, orientamento, contestabilità, rilascio e collisione reale controllati |
| AC-2 | PASS | Andata/ricezione/ritorno fisici, turnover e riprese; nessuna guida umana. Pausa congela simulazione e scadenze, non cancella la combinazione |
| AC-3 | PASS negli scenari | Appoggi reagiscono a difensori spostati, aumentano corsie giocabili nel caso costruito; copertura CM, guardia, marcature, onside, separazione e stabilità a piccoli spostamenti verificati |
| AC-4 | PASS | Field fit circa 714×462, 980×635, 1372×889 px a 920×610, 1280×800, 1920×1080; campo105×68 invariato |
| AC-5 | PASS | Scelta carry/pass cambia con pressione; corsia libera dietro portatore, memoria breve, combinazioni interrompibili e alternativa interna alla fascia schermata |
| AC-6 | PASS | Sim.step produce un calcio reale del runner; uno-due in uscita e umano preservati; rollio fisico0.32 contro previsione e minimi0.45 degli altri calci |

La qualifica degli scenari non è un'approvazione UAT della qualità complessiva
dell'IA. La fase chiude l'implementazione tecnica; il bilanciamento resta aperto.

## Verifica finale

Tutti i **25 file tests/test_*.lua PASS**, ciascuno caricato in uno stato isolato
del LuaJIT installato con LÖVE, dopo entrambi gli ultimi fix. Esecuzione locale
tramite Python ctypes e luaL_loadstring/lua_pcall; nessun mock della fisica.
Le suite di vista/input usano le rispettive fixture; la verifica del renderer
reale è separata. Diff whitespace check PASS.

Due scenari di partita da300s, ripetuti per determinismo, mantengono contabilità
coerente: RM2–0 (blu13/17 ricevuti, rossi33/66), GK2–2 (blu46/55, rossi24/33).
Sono output della suite attuale, non un confronto controllato con una build
precedente, né una misura di divertimento o qualità tattica.

Dodici frame reali LÖVE sono disponibili in
`C:/Users/Davide/.codex/visualizations/2026/11/19/01a1f4be-74fb-7633-b399-2f810bfce164/`:
`control-movement-{match,control,one-two,corner}-{920,1280,1920}.png`.
Il lotto iniziale precede l'ultima iterazione IA e documenta geometria/HUD;
non viene usato come prova delle decisioni finali. UAT umano completo NOT_RUN;
nessun nuovo esito CI remoto o LuaLS dichiarato.

## Modifiche e correzioni

- `main.lua` / `view.lua`: Ctrl/Q, feedback, fit, fullscreen e avvio massimizzato.
- `ball_control.lua`: contatto limitato, tocco orientato e protezione senza aggancio.
- `combinations.lua`: ciclo fisico degli uno-due e inserimenti su corridoi disponibili.
- `tactics.lua` / `marking.lua`: appoggi contestuali, coperture e marcature locali.
- `space.lua`: rischio sul segmento effettivo e distanza minima dagli avversari.
- `ai.lua`: confronto carry/pass/shot, memoria breve e rientro del runner nel gioco.
- `passing.lua` / `sim.lua`: tocco advance0.32 reale, integrazione contatti, reset e storico.
- Sei nuove suite portano il totale da19 a25; documentazione corrente aggiornata
  in README, PLANNING, Football-Identity e Control-and-Tactics.

Review indipendenti hanno trovato e corretto: presser sospeso rimasto negli
stati condivisi; CM6 spinto oltre palla dall'evitamento del giocatore umano;
runner eletto a giocare ma bloccato nel ramo della corsa; minimo generale0.45
che ignorava la potenza0.32 della conduzione. Ogni caso ha una regressione.

## Decisioni e riconciliazione

Il feedback dell'utente sull'IA ripetitiva ha ampliato il lavoro alle scelte
contestuali, alla memoria degli scambi e agli inserimenti sui varchi. La
variazione deriva da pressione, spazio e storia, non da casualità cosmetica.
Gli automatismi restano euristici e non ricostruiscono il motore FM24.

Corretto l'AC ambiguo sulla pausa: P congela il gioco e le sue intenzioni;
non va trattato come una ripresa o un riavvio che le ripulisce. Campo105×68
e controllo individuale restano invariati. Le fonti IFAB/FA normano geometria
e regole; il documento IFAB movement/teamwork riguarda gli ufficiali di gara.
Le sei letture tattiche Wikipedia fornite dall'utente sono riferimenti di
contesto, non fonti dei coefficienti del prototipo.

## Stato, limiti e prossimo passo

STATE e ROADMAP aggiornati: fase12 verificata, fase13 **IN_PROGRESS ricerca**.
La richiesta successiva di ruoli, compiti e istruzioni FM24 non è dichiarata
implementata. Restano UAT, bilanciamento, arbitraggio completo, palla alta,
valutazione individuale e carriera.

**Prossima azione unica:** concludere la ricerca fase13 e definire il contratto
implementabile per ruoli, compiti e istruzioni, con comportamenti osservabili.
