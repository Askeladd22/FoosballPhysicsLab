# SUMMARY 05-01 — Passaggi e ricezione

**Data:** 2026-11-19. **Risultato:** DONE_WITH_CONCERNS — implementazione e verifiche automatiche PASS; UAT umano NOT_RUN.
**Baseline:** main `41de0a8`. Modifiche locali, nessun commit/push o esecuzione CI remota dichiarati.

## Previsto ed effettivo
| Task | Implementazione | Verifica | Esito |
| --- | --- | --- | --- |
| T1: raggiungibilità | src/passing.lua con impulso condiviso, trascinamento discreto a 120 Hz, ricerca limitata del tempo di volo, anticipo e controllo geometrico prima del calcio; integrazione AI/sim | test_passing.lua e suite esistenti sulla forza | DONE / PASS |
| T2: ricezione | Stato temporaneo del destinatario IA, punto d'incontro aggiornato sulla traiettoria reale, supporto degli altri, nessun intervento sul disco umano | Riceventi fermi/in corsa, squadra rossa, umano, intercetto immediato, timeout/uscita/gol/fulltime/pausa/reset | DONE / PASS |
| T3: feedback/verifiche | Contatori per squadra, marker e messaggi di richiesta/ricezione, CI a due runtime, documenti aggiornati | Otto suite LuaJIT, partite complete scriptate, renderer mock e reale | DONE_WITH_CONCERNS / PASS automatico, UAT NOT_RUN |

## Criteri
- **AC-1 PASS:** traiettorie reali `Sim.step` per distanze 8/12/20/30/40 con velocità iniziali (0,0), (12,0), (-10,5), (0,-10). La combinazione 40 + (-10,5) viene scartata perché oltre il limite fisico. Le altre 19 combinazioni raggiungono il punto previsto con errore < 0.00001 unità in volo libero. Il caso originario a 40 unità viene anche lanciato dall'IA e ricevuto. Alto attrito e cattivo angolo vengono rifiutati. Regressione pass-only 1.35 e calci manuali/tiri PASS.
- **AC-2 PASS:** ricezione fisica e assegnazione esclusiva del ricevente per entrambe le squadre; nessun aggancio del pallone e nessuna sostituzione degli input umani. Gli intenti si chiudono agli esiti e alle interruzioni previste; pausa conserva l'intento e R lo azzera.
- **AC-3 PASS automatico:** tentativi = ricevuti + intercettati + persi + eventuale passaggio in corso, per ciascuna squadra e a ogni tick. Render reale alle tre risoluzioni, HUD controllato a 920 e 1280. **UAT umano NOT_RUN**: non dichiarata la qualità soggettiva del gioco.

## Metodo e prove locali
- Otto file `tests/test_*.lua` eseguiti ciascuno in uno stato Lua separato, con Python/ctypes e la libreria `C:/Program Files (x86)/LOVE/lua51.dll`: `luaL_newstate`, `luaL_openlibs`, `luaL_loadfile`, `lua_pcall`, `lua_close`. Runtime rilevato LuaJIT 2.1.1700008891 / Lua 5.1. Tutti PASS.
- Comandi equivalenti con interprete disponibile: `luajit tests/test_passing.lua`, `luajit tests/test_match_passing.lua` e ogni altra suite in un processo separato.
- `test_match_passing.lua`: due ruoli, 180 secondi per partita, due esecuzioni identiche per ruolo. Output: RM 0–1, blu 6/9 ricevuti, 3 intercettati; rossi 3/21, 18 intercettati. GK 0–1, blu 27/33, 6 intercettati; rossi 20/23, 3 intercettati. Nessun perso nei due scenari. Questi dati verificano il funzionamento e non sono una stima di bilanciamento né un confronto prima/dopo.
- LÖVE nativo: harness isolato che carica i moduli reali, crea un passaggio e disegna su Canvas alle tre risoluzioni. Log `RUN OK: real LOVE renderer at 920, 1280, 1920`. Artefatti nella cartella visualizzazioni della chat: `passing-920.png`, `passing-1280.png`, `passing-1920.png`, `passing-render.log`, sorgenti di verifica in `render-check/`.
- I primi tentativi di rendering usavano una directory temporanea non persistente fra chiamate: timeout, processi terminati; verifiche finali riuscite dalla cartella artefatti persistente. Nessun errore del gioco occultato.
- LuaLS non installato: revisione manuale con annotazione mirata PassPlan. Nessuna diagnostica inventata. La CI Lua 5.4/LuaJIT è configurata, non ancora eseguita sul remoto.

## Decisioni e confini
- Stessa formula fisica dei calci, spostata in un modulo condiviso per evitare divergenza tra previsione ed esecuzione. Conservato il moltiplicatore 1.35; potenza dei passaggi IA variabile entro i limiti esistenti.
- Una ricezione è il primo contatto di un compagno o un calcio valido, anche se il compagno non era il destinatario originario; non equivale a possesso stabile. Anche kickoff e riprese contribuiscono ai tentativi. Calci manuali non reinterpretati come passaggi.
- Nuovo impulso interrompe l'azione precedente senza doppio conteggio. Esiti non riusciti includono tocco ripetuto del battitore, timeout e interruzioni.
- HUD ampliato di 24 px per separare ruolo, contatori per squadra e comandi alla risoluzione minima. Versione finestra/README 0.2.3. Corrette le sequenze letterali `\\n` nei documenti aggiornati.
- Invariati controllo permanente, fisica libera, 5v5, sponde, tiri, asset e carriera rinviata. Nessun nuovo comando di passaggio manuale.

## Stato e prossimo passo
STATE, ROADMAP, PLANNING, README e guida tattica aggiornati. Il prossimo passo è un unico UAT umano della build: una partita RM e una GK, annotando ricezioni mancate, smarcamenti utili e chiarezza del feedback. Primo tocco assistito e carriera restano fuori da questa fase.
