# PAUL State — FoosballPhysicsLab

**Prodotto principale:** Foosball Lab — codici e moduli LÖVE nella root.
**Frozen / conservato:** NEON 11 (11vs11) — `legacy/neon11/`.
**Fase:** 22, separazione fisica repository.
**Branch:** `refactor/foosball-root-neon11-legacy`.
**Stato:** APPLY/VERIFY; UAT grafica e mouse Windows NOT_RUN.

## Decisioni SEED
- `love .` apre direttamente Foosball; `love legacy/neon11` l'originale NEON 11.
- I moduli e test originali del 11vs11 vengono spostati con gli stessi blob; nessuna logica di gioco riscritta.
- I vecchi documenti PAUL e le ricerche FM24 sono nella stessa cartella legacy.
- Le pose 2.5D restano facoltative e ignorate da Git in `local_assets/`.
- La suite CI Foosball e quella 11vs11 hanno due job distinti su Lua5.4 e LuaJIT.

## PAUL
[PLAN 22](phases/22-directory-split/22-01-PLAN.md).
I risultati verificati vanno nel SUMMARY al termine della CI; nessun playtest umano dichiarato.
**Next:** Windows/LÖVE `love .` e `love legacy/neon11` + dieci tiri con AUTO.
