# 10-01 — Scatto e calcio a 11

Baseline cefb520; implementazione locale, nessun commit/push. Rigore minimal,
esteso con scenari speculari e partite complete per il rischio sulle riprese.
Input FOUND: main.lua, src/{sim,ai,tactics,passing,view}.lua, test, screenshot
utente, README, PLANNING, stato/roadmap PAUL. conf.lua ABSENT.

## Risultato e accettazione

- AC-1 PASS: Shift sinistro/destro tenuto, accelerazione e velocita x1.45;
  rilascio, diagonale, pausa/reset e isolamento del controllato verificati.
- AC-2 PASS: sponde rimosse, pallone completamente oltre la linea, primo
  attraversamento nelle uscite diagonali, rimesse assegnate dall'ultimo tocco.
- AC-3 PASS: corner/rinvii/rimesse speculari, GK manuale, deviazioni lente,
  divieto di gol diretto da rimessa (rinvio avversario o corner in caso di autogol).
- AC-4 PASS: 14 suite LuaJIT locali; rendering LÖVE a tre risoluzioni.
  CI configurata per tutte le suite, esecuzione remota NOT_RUN.
- AC-5 PASS: 22 giocatori, numeri unici, due portieri, kickoff senza overlap,
  controllo fisso e supporto 4-4-2. Campo 105x68, porte 7.32, aree ridisegnate.

Cambio scope autorizzato dall'utente: 5v5 -> 11v11. Gli scenari isolati storici
usano esplicitamente fixture 5v5; partite complete, input e renderer usano
il default 11v11. Il gioco non offre un selettore 5v5.

Due partite scriptate da 180 secondi, ciascuna ripetuta: RM 1-0, GK 0-0.
RM passaggi blu 19/23 e rossi 19/42; GK blu 25/35 e rossi 15/23.
Sono controlli di determinismo e contabilita, non metriche di divertimento.

## Limiti

UNIFY_PARTIAL / DONE_WITH_CONCERNS: UAT umano NOT_RUN. LuaLS non eseguito;
verifica manuale e runtime LuaJIT effettivo. Sprint senza stamina, corpi fisici
ingranditi, rimesse astratte sul piano, durata 3 minuti attivi. Mancano ancora
fuorigioco, falli/rigori/cartellini, sanzioni per doppio tocco, sostituzioni e
tempi regolamentari. Nessuna dichiarazione di regolamento IFAB completo.

Fonti IFAB 1/9/15/16/17 collegate nel README. Screenshot utente usati per
proporzioni di campo/dischi, senza attribuire dati non verificati al secondo gioco.

Prossima azione: playtest umano RM/GK con Shift e uscite sui quattro lati,
annotando leggibilita, controllo del pallone e densita dei 22 giocatori.
