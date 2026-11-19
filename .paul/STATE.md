# PAUL State — Football Physics Lab

**Project:** Football Physics Lab

**Milestone:** NEON 11 — Regole, decisioni e controllo del calciatore

**Phase:** 13 — Ruoli, compiti e istruzioni FM24

**Status:** IMPLEMENTED — verifica finale fase 13 in corso; UAT umano NOT_RUN

**Plan:** [13-01](phases/13-fm24-roles/13-01-PLAN.md)

**Loop:** fase 12 LOOP_CLOSED tecnico; fase 13 APPLY_DONE / VERIFIED

**Working tree:** modifiche locali preesistenti conservate; nessun commit/push in fase 13

**Updated:** 2026-11-19

## Evidenza più recente

Fase 13: catalogo, impostazioni, rapporto di sola lettura e consumatori IA;
allenatore automatico e gate finale in completamento secondo l'ultima richiesta.
Resoconto corrente: [13-01-SUMMARY.md](phases/13-fm24-roles/13-01-SUMMARY.md).

- 45 nomi inglesi/italiani e ID corrispondono alle tabelle LTC locali con changes.
  Fonti e limiti sono registrati nel catalogo e nel JSON di evidenza.
- Suite dedicate a catalogo, impostazioni e callback del pannello PASS su LuaJIT;
  gate complessivo di 30 suite, inclusi allenatore automatico e ritmo fisico, in completamento.
- Verificati isolamento, compatibilità, mantenimento di tempo/punteggio/corpi,
  controllo umano invariato, R che conserva le tattiche e numero 9 riposizionato.
- Dodici acquisizioni LÖVE del rapporto di sola lettura alle tre risoluzioni; tutte le hitbox
  entro la finestra, viste ruoli a 920 e istruzioni personali a 1280 ispezionate.
  Aggiornamento finale del rendering dopo le ultime modifiche ancora in corso.
- Nessuna nuova CI remota o diagnostica LuaLS dichiarata; UAT umano NOT_RUN.

## Decisioni e confini attuali

- Ctrl ammortizza soltanto contatti reali; protezione lenta e contendibile.
- Q + Spazio breve chiede un uno-due fisico; nessuna corsa umana automatica.
- Pausa congela tempo e intenzioni, non cancella la combinazione. Gol, riprese,
  riavvio e fine partita ripuliscono gli stati secondo il ciclo della simulazione.
- 45 ruoli e compiti alimentano profili originali di movimento e decisione.
  Cinque moduli; 19 istruzioni di squadra e 16 personali attive; 6/2 disabilitate.
- L'allenatore IA decide automaticamente modulo, ruoli, compiti e istruzioni.
  T apre un rapporto di sola lettura e ferma la simulazione; T/Esc lo chiude con
  input puliti. La navigazione non modifica tattiche; i cambi automatici non
  teletrasportano i corpi e non sostituiscono il controllato.
- Le istruzioni guidano l'IA; movimento, conduzione e calci del giocatore umano
  rimangono manuali. R conserva la configurazione; nessuna persistenza su disco.
- Ultima richiesta: ritmo più lento tramite parametri fisici, senza rallentare
  i cinque minuti di cronometro. Base 7,2, sprint 10,08, accelerazione 54,
  drag giocatore 7,5, calcio 26 e drag palla 1,0; verifica finale in corso.
- FM24 non osservato nella UI runtime; matrice completa dei blocchi, pesi nascosti
  e corrispondenza esatta del motore restano non verificati. Libero D/S corroborato
  da fonte ufficiale; i testi storici delle tabelle linguistiche sono qualificati.

## Non verificato e lavoro differito

UAT umano RM/GK, divertimento, difficoltà e bilanciamento; arbitraggio completo,
palla alta/colpi di testa, valutazione individuale e carriera. Fuorigioco sui centri
dei dischi e statistiche di primo contatto non rappresentano l'intero calcio o
possesso stabile. Diritti commerciali dell'asset Etrusco non verificati.

## Artefatti

- [Piano 13-01](phases/13-fm24-roles/13-01-PLAN.md) e [summary](phases/13-fm24-roles/13-01-SUMMARY.md).
- [Centro tattico](../docs/FM24-Tactics.md), [catalogo](../docs/FM24-Role-Catalog.md), [evidenza locale](../docs/fm24-roles-evidence.json).
- [Piano 12-01](phases/12-control-movement/12-01-PLAN.md) e [summary](phases/12-control-movement/12-01-SUMMARY.md).
- [Controllo e tattica](../docs/Control-and-Tactics.md), [identità](../docs/Football-Identity.md), README.md, PLANNING.md.
- Storico e prove delle fasi precedenti nei rispettivi SUMMARY, incluso
  [11-01](phases/11-neon-football/11-01-SUMMARY.md); quei conteggi test sono storici.
- L'analisi FM24 precedente resta limitata e documentata in
  [FM24-Match-Engine-Review.md](../docs/FM24-Match-Engine-Review.md).

## Prossima azione unica

Chiudere il gate finale di 30 suite e rendering aggiornato, quindi svolgere
un playtest umano RM/GK confrontando ruoli e istruzioni opposti.


Verifica finale 19 novembre 2026: tutte le 30 suite LuaJIT PASS, incluse due partite complete da 300 secondi e uno-due fisici con il ritmo rallentato. Rendering nativo del rapporto allenatore: 12 catture, tre risoluzioni, con decisione automatica verificata. Il conteggio precedente di 31 includeva una suite ritmo separata non creata: la velocità è coperta dalle regressioni sprint, passaggi e partite. Ricezione IA smorzata solo al contatto, entro il limite di impulso; nessun possesso agganciato. UAT umano e CI remota non eseguiti.


## Phase 14 branch: Gameplay Recovery (not merged)
A separate experimental branch introduces directional human passing, shorter retry buffer with HUD feedback, smaller 11v11 discs/ball, support-intent deadband, F2 coach A/B, and restored top/bottom arena rails. All prior phases on main remain preserved; PR/CI and human UAT must be checked before adopting these changes. Foosball remains a distinct, unimplemented alternative.
