# PAUL State — Football Physics Lab

**Project:** Football Physics Lab
**Milestone:** v0.2.3 — Passaggi e ricezione
**Phase:** 05 — Pass reception
**Plan:** 05-01, approvato dall'utente con «Implementa»
**Loop:** UNIFY_PARTIAL — implementazione e verifiche automatiche PASS; UAT umano NOT_RUN
**Working tree:** main, modifiche locali sulla baseline `41de0a8`; nessun commit o push in questa fase
**Updated:** 2026-11-19

## Verificato
- Tutte le otto suite locali passano nel LuaJIT installato con LÖVE (LuaJIT 2.1.1700008891 / Lua 5.1).
- Passaggio originale a 40 unità eseguito dall'IA e ricevuto fisicamente; traiettorie a 5 distanze e 4 velocità iniziali, con rifiuto esplicito della combinazione irraggiungibile.
- Riceventi fermi/in corsa, entrambe le squadre, rispetto del controllo umano, intercetti precoci e cancellazione degli intenti verificati.
- Partite da 180 secondi con input scriptato RM e GK, ciascuna ripetuta per determinismo; contabilità dei passaggi coerente a ogni tick.
- Rendering reale LÖVE fuori schermo a 920×610, 1280×800 e 1920×1080; HUD controllato visivamente alle prime due risoluzioni.
- Workflow CI aggiornato per Lua 5.4 e LuaJIT; nuova CI remota non eseguita.

## Non verificato e limiti
- Playtest umano completo da portiere e centrocampista, divertimento e bilanciamento.
- LuaLS assente: revisione manuale del sorgente, nessuna diagnostica LSP dichiarata.
- Le statistiche contano il primo contatto utile, non il possesso stabile. Le frequenze delle partite scriptate non rappresentano il comportamento dei giocatori.
- Anticipo a velocità costante e velocità d'arrivo desiderata restano parametri provvisori.
- Diritti dell'asset Etrusco per distribuzione commerciale: invariati e non verificati.

## Artefatti
- .paul/phases/05-pass-reception/05-01-PLAN.md
- .paul/phases/05-pass-reception/05-01-SUMMARY.md
- README.md, PLANNING.md, docs/TacticalPlayGuide.md
- Le prove storiche delle fasi 03 e 04 restano nei rispettivi SUMMARY.

## Prossima azione unica
Eseguire un playtest umano della build corrente: una partita RM e una GK, annotando ricezioni mancate, smarcamenti utili e chiarezza del feedback.
