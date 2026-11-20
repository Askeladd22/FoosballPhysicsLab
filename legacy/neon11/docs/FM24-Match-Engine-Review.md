# FM24: analisi mirata e adattamento al Match Lab

Data: 2026-11-19. Installazione esaminata: `S:/Epic Games/FootballManager24`.
FootballPhysicsLab baseline: `ec81c18`. Rigore: analisi statica mirata delle risorse e confronto con documentazione ufficiale, non ricostruzione completa del motore.

## Prove locali osservate

REA ha identificato `fm.exe` come PE x86_64, 489128448 byte, SHA-256 `33e8a2e48c4986f2a15e11c4c93aca1199029d66b19bd765403eb22dea265378`. Sessione chiusa dopo l'identificazione. Non sono state decompilate funzioni né eseguito FM24; il formato dell'eseguibile non dimostra la sua architettura logica.

Inventario e hash delle sette risorse effettivamente lette: [fm24-local-evidence.json](fm24-local-evidence.json). L'installazione è rimasta in sola lettura.

| Osservazione | Cosa stabilisce | Cosa non stabilisce |
| --- | --- | --- |
| `simatch/systems.cfg`, XML analizzato, dichiara competition, camera, sound, kit, appearance, pressing factory e stats extractor | Esistono nomi di sistemi distinti nella configurazione distribuita | Non prova ECS, ordine di aggiornamento o implementazione del pressing |
| `physics/physical_constraints.jsb` contiene etichette leggibili relative ad accelerazione, decelerazione, velocità e turning rate | Il file include concetti fisici distinti | Formato JSB, unità, valori attivi e formule non decodificati |
| `expected_goals/models/configs/coefficient_output_regular.jsb` contiene distanza dalla porta, porzione di porta visibile, occlusori e angoli | Variabili nominali presenti in una risorsa di configurazione xG | Non prova che xG determini i gol o sia usato dalla scelta del tiro |
| `tactics/styles.xml`, XML analizzato, include control possession, gegenpress e altri stili con template | Stili e preferenze sono descritti in dati separati | Le preferenze non rivelano l'algoritmo che le applica |
| `weights.jsb` include etichette TEAM_PICKING_STYLE | Parte dei pesi riguarda selezione della squadra | Non è una tabella universale dei pesi decisionali durante il match |
| Cartelle e archivi simatchviewer distinti dalle risorse simatch | Separazione nel packaging | La separazione runtime simulazione/render resta un'inferenza, non una prova da nomi di file |

## Comportamenti documentati da Sports Interactive

- [Feature ufficiale FM24: motion, autenticità e positional play](https://www.footballmanager.com/features/truer-football-motion-match-authenticity-positional-play): rotazioni coordinate in risposta ai compagni, spazi liberati e coperture; Motion Matching e IK per l'animazione; aggiornamenti separati alla fisica del pallone. Non pubblica formule o sorgenti.
- [Manuale FM24: Players](https://community.sports-interactive.com/sigames-manual/football-manager-2024/players-r4958/): distingue percezione dell'opportunità (Vision), decisione ed esecuzione tecnica. Per il nostro gioco significa poter distinguere decisione sensata da gesto fisico riuscito.
- [Manuale FM24: Tactics](https://community.sports-interactive.com/sigames-manual/football-manager-2024/tactics-r4960/): transizioni dopo perdita/recupero e compattezza delle linee sono scelte esplicite.

La frequenza di decisione di 0,25 secondi citata nell'[articolo FM21](https://www.footballmanager.com/news/match-engine-ai-fm21) non è stata verificata per FM24. Nessuna frequenza, struttura dati o formula interna viene attribuita al binario locale.

## Miglioramento implementato: coordinamento degli appoggi

Nel nostro codice ogni `supportPoint` derivava principalmente dal ruolo e dalla palla, con evitamento della corsia umana. Più obiettivi potevano convergere vicino alle sponde e mancava un sostituto esplicito quando il difensore andava in pressione.

Ora `Tactics.teamTargets` calcola una mappa di appoggi per squadra per ogni aggiornamento IA. Riserva la posizione umana e il punto del passaggio in corso, esclude il ricevente dal normale supporto e assegna prima un giocatore di copertura. Gli altri ricevono obiettivi vicini alla propria posizione tattica ma separati. `AI.update` usa questa mappa; movimento, collisioni, pallone e input umani restano fisici.

È un algoritmo originale, ispirato al comportamento pubblicamente descritto. Distanza di separazione 8 e arretramento 16 sono parametri del Match Lab, non coefficienti FM24. Non sono stati copiati asset, coefficienti o codice del gioco installato.

## Verifica e limiti

Nove suite PASS nel LuaJIT di LÖVE. Nuovi scenari: appoggi separati al centro e presso entrambe le sponde, copertura sostitutiva per entrambe le squadre, priorità al ricevente, determinismo e input umano intatto. Le partite scriptate da 180 secondi RM/GK finiscono entrambe 0–0 e ripetono il risultato; è prova di esecuzione deterministica, non di maggior divertimento. Non è stato svolto un playtest umano di questa modifica.

Analisi risorse: completata per i sette file elencati. Comportamenti ufficiali: documentati. Algoritmo interno di FM24, integrazione fra modelli xG e scelte, formato completo JSB e traiettorie runtime: non ricostruiti. LuaLS assente; revisione manuale e test LuaJIT.

## Sviluppi successivi, non implementati qui

1. Distinguere ultimo tocco, controllo della palla e palla contesa prima di introdurre contropressing/transizioni.
2. Valutare conclusioni con distanza, angolo e spazio libero nella porta, con una nostra euristica esplicitamente diversa da un xG calibrato.
3. Aggiungere personalità e limiti di percezione solo dopo una base tattica stabile. Motion Matching e complessità 3D non servono alla presentazione a dischi.

Prossimo passo: playtest RM/GK per verificare se la maggiore copertura lascia abbastanza opportunità offensive e se gli appoggi restano leggibili.
