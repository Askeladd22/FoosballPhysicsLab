---
project: Foosball Lab
project_type: custom/game-development
status: implementing
plan_version: phase22-directory-split
last_updated: 2026-11-20
---

# SEED — Foosball Lab

**Promessa:** una partita breve in cui il gesto mouse SU/GIÙ per scorrere e SINISTRA/DESTRA per ruotare le aste è controllabile, leggibile e ripetibile.

## DECIDED
- Foosball occupa direttamente la **root**: `love .`; nessun modulo runtime in `experiments/`.
- NEON 11 è **frozen, preserved** sotto `legacy/neon11/`: codice `src/`, test, asset, documenti e fasi PAUL; lancio `love legacy/neon11`, scorciatoia `love . --legacy`.
- 120 Hz, quattro aste per squadra (1–2–5–3), controllo manuale fisico, AUTO/MANUALE solo per selezione della stecca, recupero della palla morta e Neon Glass restano invariati.
- Le pose Table Soccer derivate da mesh di terzi stanno soltanto in `local_assets/` sul computer dell'utente (diritti di redistribuzione da ottenere).
- Project Folio resta indipendente.

## ASSUMED / UNVERIFIED
- AUTO non cambia asta durante una frustata volontaria.
- Resa 2.5D non confonde la faccia di contatto, né peggiora troppo gli FPS.
- Regola dei due secondi è percepita come equa.

## OPEN
- Licenza di distribuzione del modello VERTX3D, attualmente non autorizzata.
- Riscontri reali di leggibilità e divertimento.

## OUT OF SCOPE
Carriera, ranking, multiplayer, sistemi tattici 11vs11, migrazione alla fisica 3D.

## Game Design Lab
Dieci tiri intenzionali in AUTO, tre in MANUALE, tre blocchi di palla morta e confronto V con due risoluzioni. Registrare scelte errate, perdite di contatto e FPS; nessuna conclusione sul divertimento dalla sola CI.

**Next:** playtest Windows/LÖVE della root e del vecchio titolo lanciato dalla sua cartella.
