# SUMMARY 07-01 — Sponde e angoli

Richieste: due screenshot con affollamento presso sponda inferiore e angolo destro; correggere e migliorare continuità del gioco.
Risultato: DONE_WITH_CONCERNS, regressioni automatiche PASS, riproduzione esatta della partita fotografata non disponibile.

La geometria di avvicinamento per un calcio verso l'interno può richiedere un punto esterno al campo, mentre i dischi sono confinati al suo interno. A palla lenta l'IA ora sceglie un calcio fisico contro la sponda, ottenendo un rimbalzo. Presso il fondo, fuori dalla bocca della porta, privilegia un calcio verso l'esterno che attiva la ripresa già prevista dalle regole. Nessun teletrasporto o possesso magnetico.

- AC-1 PASS: alto/basso per entrambe le squadre, palla liberata; quattro angoli, uscita fisica e ripresa assegnata alla squadra corretta, nessun gol spurio.
- AC-2 PASS: tutte le dieci suite nel LuaJIT di LÖVE, eseguite con stati separati tramite Python/ctypes. Partite complete ripetute per determinismo: RM 1–0, GK 0–0. Nessuna deduzione sul divertimento da questi risultati.
- CI include test_touchline_escape.lua. LuaLS non eseguito; revisione manuale e regressioni runtime.

Estensione del piano: secondo screenshot arrivato durante il lavoro, aggiunta copertura dei quattro angoli. Restano fuori ambito tiro più intelligente e nuove meccaniche di possesso.
Prossimo passo: riavviare la finestra LÖVE e verificare nel gioco reale gli stessi punti del campo. Un'immagine statica non stabilisce da sola durata e causa di ogni blocco.
