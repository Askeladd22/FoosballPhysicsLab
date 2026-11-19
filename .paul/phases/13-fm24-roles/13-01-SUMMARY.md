# 13-01 — Ruoli, compiti e istruzioni FM24

**Stato:** IMPLEMENTED / VERIFIED — gate finale in corso.
**Data:** 2026-11-19. **UAT umano:** NOT_RUN. **Commit/push:** nessuno.

## Risultato implementato

- Catalogo dei 45 ruoli verificati, con nome inglese/italiano, ID/chiavi LTC,
  posizioni, compiti, provenienza e coefficienti originali. Libero aggiornato
  a Difesa/Supporto con riferimento ufficiale FM24; testi storici qualificati.
- Cinque moduli: 4-4-2, 4-3-3, 4-2-3-1, 3-5-2, 5-2-3. Impostazioni isolate per
  squadra e calciatore, compatibilità validata, un portiere per squadra.
- L'ultima indicazione dell'utente affida all'allenatore IA le scelte automatiche
  di modulo, ruoli, compiti e istruzioni. Il rapporto è di sola lettura; il giocatore
  controlla il proprio calciatore senza configurare tattiche manualmente.
- Rapporto tattico originale con T, tastiera e mouse. La simulazione si ferma;
  T/Esc o clic di chiusura riprendono. Tab cambia scheda all'interno del pannello.
  La ripetizione di T/Esc e la rotella con delta verticale zero non cambiano stato.
- 19 voci di squadra e 16 personali attive. Sei voci di squadra e due personali
  disabilitate esplicitamente perché mancano i sistemi necessari.
- I profili influenzano appoggi, profondità/ampiezza, rotazioni, pressing,
  marcature di zona, selezione di passaggi, conduzioni, tiri e cross rasoterra,
  transizioni, distribuzione e inserimenti.
- Le modifiche cambiano intenzioni future senza teletrasportare corpi, azzerare
  tempo/punteggio o sostituire il controllato. R conserva le tattiche. Il numero
  9 resta disponibile per la ripresa anche se la sua posizione non è più ST.
- Il calciatore umano rimane manuale: nessuna corsa automatica, possesso magnetico
  o esecuzione automatica della scelta tattica al posto di WASD/Spazio.
- Contratto dell'allenatore: sei piani, osservazioni ogni 12 secondi, due riscontri
  concordi e almeno 24 secondi prima dei cambi ordinari. Urgenze di risultato
  nel finale possono anticiparli con minimo 4 secondi. Queste soglie sono originali.
- Ultima correzione richiesta: rallentare fisicamente il gioco. Nuovi valori:
  velocità base 7,2, sprint ×1,4 (10,08), accelerazione 54, drag giocatore 7,5,
  calcio base 26 e drag palla 1,0. Cronometro di cinque minuti e tick a 120 Hz
  invariati; verifica finale delle traiettorie e del ritmo in corso.

## Evidenza e verifica

REA ha identificato il binario locale; sessione nativa chiusa. FMF, Zstandard e
LTC inglesi/italiane sono stati letti in sola lettura applicando i record changes.
Tutti i 45 nomi e ID del modulo corrispondono al JSON di evidenza. Le descrizioni
sintetiche e il codice comportamentale sono originali.

Le tre suite dedicate a catalogo, configurazione e pannello sono PASS con stati
separati del LuaJIT installato con LÖVE. In particolare:

- tutti i ruoli sono raggiungibili tramite posizioni compatibili;
- compiti automatici coerenti con i sette livelli di mentalità;
- opzioni valide accettate e invalide/disabilitate respinte, incluso giocatore
  inesistente in `setDuty`, ora verificato prima di dereferenziarlo;
- profili indipendenti, impostazioni isolate, nessuna mutazione di corpi,
  pallone, punteggio, tempo o controllato durante gli edit;
- callback reali di tastiera e mouse; tutte le righe, frecce, Invio e clic sui
  valori preservano interamente tattiche e ancore dell'allenatore. Il disegno è
  simulato nei test di controllo; hitbox sintetiche isolano il dispatch;
- input di passaggio, uno-due, chiamata e carica puliti attraverso la pausa;
- Esc chiude senza uscire, R conserva configurazione, pausa preesistente mantenuta.

Il gate complessivo previsto comprende **30 suite**: 25 precedenti più catalogo,
impostazioni, rapporto, scenari comportamentali, allenatore automatico e ritmo
fisico. L'esecuzione finale è in
corso; non viene sostituita dai soli test di configurazione.

Sono state prodotte dodici acquisizioni reali LÖVE del rapporto di sola lettura a 920×610,
1280×800 e 1920×1080. Le hitbox risultano entro la finestra; le viste ruoli a 920
e calciatore a 1280 sono state ispezionate. Aggiornamento finale dopo l'ultima
modifica in corso. Il rendering prova layout/leggibilità, non qualità tattica.

## Limiti e lavoro successivo

La UI di FM24 non è stata osservata in esecuzione. Le stringhe attestano il
lessico e molte descrizioni, non tutta la disponibilità attiva né la matrice
completa di istruzioni bloccate. Coefficienti e soglie sono scelte originali,
non pesi del motore estratti. L'Ala che pressa mantiene una qualificazione
esplicita per il vecchio testo Attacco ancora presente negli archivi.

Palla alta, colpi di testa, presa del portiere, falli/cartellini, marcatura di
un avversario specifico, gestione arbitrale delle perdite di tempo, salvataggi
tattici persistenti e carriera restano fuori da questo incremento. Nessuna
nuova CI remota o diagnostica LuaLS dichiarata. UAT, difficoltà, divertimento e
bilanciamento restano da verificare con gioco umano.

## Artefatti

- `src/football_roles.lua`, `src/tactical_settings.lua`, `src/tactics_panel.lua`, `src/coach.lua`.
- Integrazione in `main.lua`, `src/sim.lua`, `src/ai.lua`, `src/tactics.lua`,
  `src/marking.lua`, `src/combinations.lua` e guida comandi in `src/view.lua`.
- `tests/test_football_roles.lua`, `tests/test_tactical_settings.lua`,
  `tests/test_tactics_panel.lua`, `tests/test_tactical_behaviour.lua`, `tests/test_coach.lua`
  e regressione sul ritmo fisico.
- [Guida centro tattico](../../../docs/FM24-Tactics.md),
  [catalogo e contratto](../../../docs/FM24-Role-Catalog.md),
  [evidenza locale](../../../docs/fm24-roles-evidence.json).

**Prossima azione:** chiudere gate finale e rendering, poi UAT comparativo RM/GK.


Verifica finale 19 novembre 2026: tutte le 30 suite LuaJIT PASS, incluse due partite complete da 300 secondi e uno-due fisici con il ritmo rallentato. Rendering nativo del rapporto allenatore: 12 catture, tre risoluzioni, con decisione automatica verificata. Il conteggio precedente di 31 includeva una suite ritmo separata non creata: la velocità è coperta dalle regressioni sprint, passaggi e partite. Ricezione IA smorzata solo al contatto, entro il limite di impulso; nessun possesso agganciato. UAT umano e CI remota non eseguiti.
