# PAUL State — FoosballPhysicsLab

**Gioco attivo:** Foosball Lab direttamente nella root.
**Gioco congelato:** NEON 11 (11vs11), isolato in `legacy/neon11/`.
**Fase:** 22 — migrazione fisica delle cartelle.
**Branch:** `refactor/foosball-root-neon11-legacy`.
**Stato:** `DONE_WITH_CONCERNS` (codice e regressioni PASS; UAT Windows/LÖVE NOT_RUN).
**Data:** 2026-11-20.

## Verifica
[PLAN](phases/22-directory-split/22-01-PLAN.md) · [SUMMARY](phases/22-directory-split/22-01-SUMMARY.md).

- `love .` avvia il vero gioco Foosball dalla root.
- `love legacy/neon11` avvia NEON 11 da un progetto LÖVE indipendente; `love . --legacy` resta opzionale.
- 16 moduli e 32 test storici spostati bitwise-identici, insieme alla texture e alla documentazione.
- I moduli Foosball sono `main.lua`, `model.lua`, `layout.lua`, `theme.lua`, `mesh_art.lua`, `rod_selector.lua`.
- Table Soccer: file privati 2.5D in `local_assets/`, ignorati da Git; baker local-only; nessuna redistribuzione.
- [CI 44707375249](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44707375249): **4 job PASS** (Foosball + NEON11, Lua 5.4 + LuaJIT). Non sono stati dichiarati playtest umani.

## Scopo SEED
Focalizzarsi su fisica, mouse, IA avversaria semplice, leggibilità e sessioni brevi. Nessuna carriera, classifica, espansione 11vs11 o riapertura di Project Folio da questo repo.

## Unica prossima azione
Avviare `love .` e `love legacy/neon11` sul PC Windows e verificare i controlli del biliardino durante dieci tiri.
