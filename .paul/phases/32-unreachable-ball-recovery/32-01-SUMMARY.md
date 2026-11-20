# SUMMARY 32-01 — Recupero palla irraggiungibile

**Result:** VERIFIED (automated) / UAT Windows NOT_RUN
**Branch:** `fix/foosball-unreachable-ball-recovery` · [Draft PR #30](https://github.com/Askeladd22/FoosballPhysicsLab/pull/30)
**Evidence:** [GitHub Actions 44766380466](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44766380466) — **7/7 jobs PASS** on source commit `845dc7dc38ac78392cbd7cea5a63607fc1e1babb`.

## Planned vs Actual
| Task | Effettivo | Evidenza | Stato |
|---|---|---|---|
| T1 — fisica palla morta | Rimosso il gate di velocità dal timer di irraggiungibilità; mantenuti il controllo geometrico, 2.0 s e le rimesse esistenti | `model.lua` · commit `ba7c5cd` | DONE / PASS |
| T2 — regressioni | Nuovi test per ricochet verticale e fuga orizzontale; regressioni preesistenti inalterate | `tests/test_foosball_deadball.lua` · `845dc7d` · CI 7/7 | DONE / PASS |
| T3 — documentazione | Registrati PLAN/SUMMARY e stato del progetto | `.paul/phases/32-unreachable-ball-recovery/` · `.paul/STATE.md` | DONE / PASS (soggetto a commit finale) |

## Acceptance criteria
- **AC-1 PASS:** il test `test_foosball_deadball.lua` verifica il ricochet verticale in X irraggiungibile e la rimessa entro 2 secondi senza cambi di punteggio.
- **AC-2 PASS:** una palla che avanza orizzontalmente cancella il countdown **quando entra** in una zona raggiungibile; un tiro di passaggio non provoca rimesse premature.
- **AC-3 PASS:** il test preesistente conferma che una palla ferma ma raggiungibile non viene rimessa.
- **AC-4 PASS automatico:** Lua 5.4/LuaJIT, due suite legacy NEON11 e tre job modello/native 3D tutti superati.

## SEED / Game Design Lab decision
La regola dei 2 secondi resta invariata; il timer è ora basato sulla **possibilità reale di contatto** anziché sull'energia cinetica. Evita un deadlock senza manipolare i colpi o generare forze artificiali. L'equità percepita è ancora **UNVERIFIED**, non un risultato ricavabile da unit test.

## Risks / Deferred
- **UAT NOT_RUN:** verificare su Windows un ricochet verticale bloccato, dieci tiri normali e l'assenza di rimesse controintuitive.
- Nessuna modifica alla telecamera, visual 3D, GLB, IA, collisioni fisiche, punteggio o NEON11.

## Next single action
Eseguire la prova pratica Windows/LÖVE con una palla intrappolata fra le aste, confrontando il recupero con un tiro orizzontale regolare.
