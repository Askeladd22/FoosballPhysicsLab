# PAUL 22-01 — UNIFY: Foosball root, NEON 11 legacy

**Data:** 2026-11-20. **Branch:** `refactor/foosball-root-neon11-legacy`.
**Draft PR:** [#20](https://github.com/Askeladd22/FoosballPhysicsLab/pull/20).
**Baseline:** `7fc46da1f9a806f73364c829321992160eeac077`.
**Status:** `DONE_WITH_CONCERNS` — directory relocation and regression CI verified, native LÖVE Windows UAT **NOT_RUN**.

## PLAN → APPLY → evidence

| Criterio | Azione effettiva | Verifica |
|---|---|---|
| AC1 — Foosball nella root | `main.lua` è il vero gioco; `model.lua`, `layout.lua`, `theme.lua`, `rod_selector.lua`, `mesh_art.lua` trasferiti nella root. Test Foosball convertiti alle importazioni root. | Verifica struttura **PASS**, smoke Foosball **PASS** in LuaJIT/Lua5.4. |
| AC2 — 11vs11 completo sotto legacy | `src/` → `legacy/neon11/src/` (16 moduli). Test 11vs11 → `legacy/neon11/tests/` (32 test). Texture Etrusco, docs, script e vecchio physics lab anch'essi spostati. `legacy/neon11/main.lua` originale e nuovo `legacy/neon11/conf.lua`. | Confronto Git object SHA: **tutti i 16 moduli e i 32 test originari sono bitwise-identici; texture PNG invariata**. Suite storica **PASS** in entrambi i runtime. |
| AC3 — archivio PAUL e documenti | Vecchi PAUL project/roadmap e 31 documenti delle fasi 01–14,16-eleven-flow in `legacy/neon11/.paul/`. README e SEED root riscritti per Foosball; launcher Windows legacy diretto. | Struttura Git e collegamenti documentali verificati; nessuna cancellazione storica. |
| AC4 — CI isolata | Due job GitHub Actions indipendenti per Foosball e NEON11, matrice Lua5.4/LuaJIT; self-test baker/GLB metadata e guard di struttura. | [GitHub Actions #44707375249](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44707375249): **Foosball LuaJIT PASS, Foosball Lua5.4 PASS, NEON11 LuaJIT PASS, NEON11 Lua5.4 PASS**. |
| AC5 — natìvo LÖVE | `love .` Foosball direttamente, `love legacy/neon11` vecchio gioco standalone, `love . --legacy` scorciatoia compatibile. | Test headless percorsi **PASS**. Windows/LÖVE native **NOT_RUN**. |

## SEED decisioni
- **DECIDED:** il Foosball è effettivamente il gioco principale anche nella disposizione dei file. Il precedente progetto NEON 11 è frozen e indipendente, con logica non riscritta e test salvati.
- **DECIDED:** Table Soccer mesh derivatives solo locali in `local_assets/` (cartella ignorata da Git); baker emette nella root. `mesh_art.lua` riconosce anche `experiments/foosball/local_assets/` per permettere la migrazione delle immagini non tracciate. Nessun file proprietario pubblicato.
- **NOT_CHANGED:** fisica, regole, selezione AUTO/MANUALE, scoring, IA Foosball; logica completa NEON11.
- **UNVERIFIED:** avvio grafico reale del gioco storico, leggibilità e feeling del biliardino su Windows. I test non sono prova di divertimento.

## Game Design Lab stop rule
Non aggiungere funzionalità finché un giocatore non ha provato in LÖVE il Foosball dalla root e confermato almeno dieci tiri deliberati, leggibilità dei piedi, gestione del mouse e passaggio AUTO/MANUALE. Prova separatamente l'apertura del vecchio 11vs11 dalla sua cartella.

**Prossimo singolo passo:** UAT Windows/LÖVE dei due launcher, con feedback sul controllo del mouse del Foosball.
