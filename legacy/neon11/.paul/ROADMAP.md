# Roadmap — Football Physics Lab

## Stato corrente — 19 novembre 2026

Fase 13: 45 ruoli, cinque moduli e 19 istruzioni di squadra / 16 personali attive.
L'ultima richiesta affida le scelte all'allenatore automatico; T è un rapporto di
sola lettura. Ritmo fisico rallentato mantenendo il cronometro di cinque minuti.
Gate finale di 31 suite e rendering aggiornato in corso. UAT NOT_RUN.

## Milestone v0.2 — Top-Down Match Lab

- [x] Campo e fisica con coordinate indipendenti dalla vista.
- [x] Loop di partita, punteggio, cronometro e riprese.
- [x] Ruolo umano fisso scelto prima della partita: GK #1 oppure RM #10.
- [x] Passaggi raggiungibili, ricezione fisica e contabilità degli esiti.
- [x] Coordinamento degli appoggi e copertura sostitutiva (fase 06).
- [x] Calcio a 11, 4-4-2 iniziale, campo 105×68 e scatto Shift (fase 10).
- [x] Rimesse, rinvii e corner senza sponde; fuorigioco modellato e partite di cinque minuti.
- [x] Arena NEON 11 originale, Spazio breve/lungo, routine corner e tiri su varchi (fase 11).
- [x] Primo controllo, protezione e movimento contestuale (fase 12, dettagli sotto).
- [x] Ruoli/compiti/istruzioni con lessico FM24 e comportamento originale (fase 13).
- [ ] UAT umano RM/GK: controllo, lettura degli appoggi, riprese e qualità delle decisioni.
- [ ] Chiudere il bilanciamento del match prima della carriera.

## Fase 12 — Controllo e movimento collettivo

- [x] Ctrl: primo controllo orientato al contatto e protezione contendibile.
- [x] Q + passaggio: uno-due fisici senza guida automatica del giocatore umano.
- [x] Inserimenti esterni/interni secondo i varchi; pressione può interrompere la combinazione.
- [x] Supporti sensibili alle corsie, CM6 di copertura, terzino lontano prudente, marcature locali.
- [x] Scelta tra conduzione/passaggio/tiro e memoria contro scambi stagnanti.
- [x] Runner sulla palla torna a giocarla; potenza 0,32 della conduzione rispettata dalla fisica.
- [x] Campo più presente nella vista, F11 desktop e avvio massimizzato; mondo 105×68 invariato.
- [x] 25 suite LuaJIT PASS e verifica del rendering a tre risoluzioni.
- [ ] UAT e taratura dei valori provvisori; test automatici non chiudono questo punto.

## Fase 13 — Ruoli, compiti e istruzioni FM24

- [x] Ricerca locale in sola lettura e fonti ufficiali; nomi/ID verificati, limiti espliciti.
- [x] Catalogo di 45 ruoli e compiti; matrice di posizioni e validazione.
- [x] Cinque moduli; configurazioni isolate per due squadre e 22 calciatori.
- [x] Rapporto tattico T di sola lettura con tastiera/mouse, pausa e conservazione della partita.
- [ ] Gate dell'allenatore IA: scelte automatiche, osservazioni, stabilità e reset.
- [x] 19/16 istruzioni attive e 6/2 disabilitate per sistemi mancanti.
- [x] Profili consumati da IA, movimenti, marcature e combinazioni; umano manuale.
- [x] Riduzione del ritmo tramite velocità e impulsi fisici, cronometro invariato.
- [ ] Chiusura gate finale di 31 suite e rendering dopo l'ultima modifica.
- [ ] UAT sulle differenze osservabili tra istruzioni.

I profili cambiano decisioni e movimenti; fonti e limiti sono registrati in
[FM24-Role-Catalog.md](../docs/FM24-Role-Catalog.md). Non è dichiarata una
ricostruzione completa del match engine di Football Manager.

## Milestone v0.3 — Career Foundation (non avviata)

- Identità persistente del calciatore, rosa e club.
- Mini-stagione, classifica, risultati e salvataggi.
- Valutazione individuale di appoggi, coperture e occasioni create.
- Sviluppo del calciatore da validare con partite umane.

## Differito e rischi

Arbitraggio completo (falli, rigori, cartellini, doppio tocco), quota della palla
e colpi di testa, sostituzioni, multiplayer e licenze ufficiali restano fuori
dal prototipo attuale. I conteggi delle fasi storiche sono nei loro SUMMARY.
Una simulazione deterministica e fisicamente coerente non prova da sola che
le decisioni siano convincenti o divertenti.
