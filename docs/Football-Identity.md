# Football Physics Lab — direzione NEON 11

Un calciatore controllato direttamente, dentro una squadra che costruisce
azioni leggibili. Partite rapide da cinque minuti, calcio a undici e una
veste originale blu notte/ciano/arancio ispirata all'immaginario di Tron.

## Deciso e implementato in questo incremento

- Spazio breve: passaggio verso un compagno raggiungibile dal contatto attuale;
  senza un destinatario compatibile, tocco nello spazio. Spazio tenuto e
  rilasciato: tiro caricato. Shift resta lo scatto.
- Ctrl tenuto: primo controllo orientato al contatto e protezione a velocità
  ridotta, senza aggancio della palla. Q + Spazio breve: richiesta di uno-due;
  il giocatore umano deve offrire personalmente la corsa di ritorno.
- Cinque minuti dal calcio iniziale, riprese comprese; pausa esclusa.
- Fuorigioco fotografato al tocco: ricezione/giocata e contrasto vicino alla
  palla attivano il fischio. Punizione indiretta e relative restrizioni.
- IA: confronto tra passaggio, conduzione e tiro secondo pressione/spazio;
  memoria breve contro scambi ripetuti senza progresso, senza vietare scarichi
  necessari. Appoggi che reagiscono alle corsie schermate, inserimenti esterni
  o interni, mediano di copertura e marcature locali a zona.
- Le combinazioni usano passaggi e corse fisiche. La pressione può interrompere
  l'attesa di un uno-due; un giocatore che raggiunge una palla libera smette di
  seguire una corsa senza palla e torna a giocarla.
- Corner: battitore esterno, destinatario in area, opzione sul palo opposto,
  coperture e difensori tra attaccante e porta. Potenza calcolata dalla fisica.

## Scala e leggibilità

Il campo resta 105 × 68; cambia lo spazio dedicato alla vista, non la scala
della simulazione. Avvio massimizzato e F11 per lo schermo intero desktop.
La vista conserva rapporto, porte e HUD alle tre risoluzioni verificate.
L'ultima taratura rallenta i corpi: velocità base massima 7,2 unità/s, sprint
×1,4 fino a 10,08 e impulso base di calcio 26. Restano cinque minuti di partita
e tick fisico a 120 Hz; non viene rallentato il cronometro per cambiare il ritmo.
Questi valori richiedono ancora una valutazione del controllo in gioco umano.

## Stato e prossima direzione

La fase 12 è implementata con **25 suite locali PASS**, comprese traiettorie,
comandi e partite scriptate da 300 secondi. UAT umano e bilanciamento restano
da verificare. Dettagli: [Controllo e tattica](Control-and-Tactics.md).

La fase 13 affida all'allenatore IA le scelte automatiche di modulo, ruoli,
compiti e istruzioni. T mostra un rapporto di sola lettura: il modello comprende
45 ruoli, cinque moduli, 19 istruzioni di squadra e 16 individuali attive.
Le impostazioni influenzano l'IA, conservando movimento e azioni manuali dell'umano.
I nomi provengono dalle tabelle locali di FM24; profili e coefficienti sono
originali. Fonti, istruzioni disabilitate e limiti: [Centro tattico](FM24-Tactics.md).
La valutazione delle azioni utili al ruolo e la carriera rimangono successive:
appoggi, ricezioni, coperture e occasioni create dovranno essere giudicati anche
con partite umane, senza usare soltanto gol e punteggi automatici.

## Limiti espliciti

Il modello resta bidimensionale: i cross dei corner viaggiano sul piano,
senza quota o colpi di testa. Fuorigioco valutato sui centri dei dischi:
non sono modellati arti e ostruzione visiva del portiere. Falli, rigori,
cartellini e secondo tocco irregolare richiedono ancora arbitraggio dedicato.
Supporti e marcature restano euristici; test automatici e punteggi scriptati
non provano che l'IA sia gia divertente o ben bilanciata.

Riferimenti: screenshot forniti dall'utente; [IFAB, Regola 11](https://www.theifab.com/laws/latest/offside/).
