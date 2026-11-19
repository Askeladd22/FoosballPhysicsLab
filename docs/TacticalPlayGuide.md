# Football Physics Lab — Mini guida tattica 5v5

Queste regole sono una **traduzione progettuale** delle quattro slide fornite dall'utente. Le slide analizzano il 3v3 e il 4v4 di HaxBall; qui vengono adattate al nostro calcio single-player 5v5. Non sono un regolamento ufficiale né una replica 1:1.

## Formazione di prova

Una squadra schiera **GK, DF, LM, RM, ST**. Il giocatore controlla **un solo disco** scelto prima del match: il portiere blu **#1** oppure il centrocampista blu **#10**. Tutti gli altri agiscono tramite IA.

## Principi implementati

| Idea della guida | Comportamento del Match Lab |
| --- | --- |
| Triangoli e rombi | I centrocampisti cercano corsie laterali distinte, il difensore offre sostegno arretrato e la punta profondità |
| Ruoli non rigidi | I target seguono la palla e cambiano in attacco, neutralità e difesa |
| Rotazione nei vuoti | Quando #10 occupa la corsia di un compagno, il compagno sceglie un supporto alternativo |
| Anticipare l'azione | Il supporto tiene conto della posizione della palla prima dell'arrivo del passaggio |
| Passing / back-passing | Si valuta progresso, rischio di intercettazione, pressione sul ricevente e appoggio arretrato libero |
| Chiama passaggio (E) | #10 è favorito solo se la sua linea è sufficientemente sicura; il compagno non è obbligato |
| Difesa | Un incaricato pressa e gli altri mantengono coperture tra pallone e porta |

Il sistema non garantisce che ogni azione sia tatticamente ottimale: la qualità del calcio collettivo è ancora da verificare durante partite complete.

## Da sperimentare, non ancora implementato

- **Absorbing:** orientare e rallentare un primo tocco mantenendo l'interazione fisica;
- **Body-blocking:** proteggere corridoi e avversari con collisioni leggibili;
- **Baby kick, ghosting:** da definire come tecniche riproducibili prima di implementarle;
- **Wall-to-wall / consecutive wall bounces:** non adatti al campo standard con rimesse laterali; possibile futura modalità arena;
- **Corner tactics:** da affrontare quando saranno introdotti corner, rimesse e regole più realistiche.

## Come provarlo

1. Avvia il gioco, premi **1** per il portiere oppure **2** per il centrocampista.
2. Giocando da centrocampista, smarcati lungo una fascia e premi **E** per richiedere la palla.
3. Segui con **F1** le destinazioni dell'IA: cerca triangoli, ampiezza e sostegno arretrato.
4. Giocando da portiere, muoviti con **WASD** e usa **Spazio** per rinviare. La palla non si aggancia automaticamente.
5. **R** riavvia con lo stesso ruolo; **TAB** abbandona il match e apre una nuova selezione.

**Nota UAT:** la guida documenta l'intenzione delle regole e quanto è presente nel codice. I test automatici verificano scenari deterministici ma non sostituiscono un playtest in LÖVE2D.
