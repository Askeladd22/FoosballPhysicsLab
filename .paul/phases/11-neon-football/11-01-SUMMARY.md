# 11-01 — NEON 11

Implementazione locale sulla working tree preesistente, nessun commit/push.
SEED/PAUL applicati all'incremento, senza ripianificare l'intero prodotto.

## Criteri e prove

- AC-1 PASS: snapshot fuorigioco per squadra, entrambe le direzioni, in linea,
  propria meta campo/dietro palla, ricezione e contrasto, esenzioni, deviazioni,
  parate (anche su tiro manuale), giocata deliberata e punizione indiretta.
- AC-2 PASS: 300 secondi dal kickoff; riprese incluse, pausa esclusa,
  fischio finale e reset verificati.
- AC-3 PASS per i difetti riprodotti: veto del portiere sui tiri centrali,
  approccio attraverso la palla, abbandono dopo conduzione. Nuovi test su
  tiro fisico che segna sul lato libero, aggiramento entro tre secondi,
  seguito del tocco e supporti dietro la linea. Bilanciamento umano NOT_RUN.
- AC-4 PASS: renderer neon e HUD reali a 920x610,1280x800,1920x1080;
  nove frame (carica/corner/fuorigioco), ispezione visiva a920 e1280.
- AC-5 PASS: quattro angoli x due routine, distanze9.15, nessun overlap,
  ricezione fisica con IA congelata e ritorno ai target di gioco aperto.
- AC-6 PASS: callback LÖVE effettive per tap/hold, carica crescente/cap,
  ripetizione tasto, pausa/focus e rinvio manuale GK.

Metodo: tutte le 19 suite test_*.lua in stati LuaJIT separati tramite la
libreria installata con LÖVE; renderer reale eseguito in processo nascosto
con canvas fuori schermo e uscita RUN OK. Nessun LuaLS/CI remoto dichiarato.
Diff whitespace check PASS.

Partite300s, ciascuna ripetuta: RM2-0 (blu26/29, rossi30/64), GK3-1
(blu32/37, rossi35/43). Sono prove di determinismo/contabilita; non sono
un confronto quantitativo col prodotto precedente o una misura di divertimento.

Una review indipendente ha riprodotto e fatto correggere due errori:
parate sui tiri manuali e fasi simultanee dopo deviazione avversaria.

## Cambi di scope autorizzati

L'utente ha chiarito che tutti e tre i problemi IA contano e ha chiesto
corner piu calcistici; poi ha richiesto Spazio breve=passaggio e lungo=tiro.
Incorporati nel piano/implementazione, mantenendo il controllo fisso.

## Limiti e direzione

DONE_WITH_CONCERNS / UNIFY_PARTIAL: UAT umano NOT_RUN. Fuorigioco sui centri
dei dischi, senza ostruzione visiva del portiere; cross sul piano, senza
colpi di testa; marcature/supporti euristici, falli/cartellini ancora assenti.
La disposizione dei corner avviene a palla ferma; il lancio e la ricezione
sono fisici. Le routine alternate evitano ripetizioni identiche, non forzano gol.

Prossimo incremento proposto: primo controllo e protezione, poi uno-due,
sovrapposizioni e valutazione delle azioni utili al ruolo. Documento:
docs/Football-Identity.md. Prossima azione: playtest umano con tap/hold e Shift.
