# PAUL 18-01 — UNIFY: Tempered Glass / Neon Glow

**Project:** FootballPhysicsLab, Foosball Lab only. **Date:** 2026-11-20.
**Status:** `APPLY_DONE / VERIFIED_AUTOMATED / DONE_WITH_CONCERNS` (native LÖVE screenshot and human UAT have not yet run).
**Branch:** `feature/foosball-tempered-glass-neon`. **Draft PR:** [#16](https://github.com/Askeladd22/FootballPhysicsLab/pull/16).
**Baseline:** `4f6078a84e253d926d40a15e5e1bfc5a032a06bb`.

## PLAN → APPLY → evidence

| AC | Result | Status |
|---|---|---|
| AC-1 Glass material | Added `experiments/foosball/theme.lua`: layered graphite frame, smoked teal glass, bevel, oblique highlights, goal wells and etched lines; no downloaded images, no shader | Code applied; native look **NOT_RUN** |
| AC-2 Neon hierarchy | Scoped additive geometric glow; cyan human and coral opponent; amber active rod trim; white flat foot retained | Automated view and theme tests **PASS**, perception UAT **NOT_RUN** |
| AC-3 Ball visibility | Bright warm-white ball core, small halo, shadow and bounded speed streak; physical `Model.footRect` and `model.lua` unchanged | Palette contrast test **PASS**; actual moving-ball perception **NOT_RUN** |
| AC-4 UI | Graphite/glass title, score, optical bottom glass plate and readable text, fixed screen-space HUD/layout | Mock LÖVE view tests **PASS**; native screenshot **NOT_RUN** |
| AC-5 Glow toggle | G toggles neon emission on/off; crisp field remains rendered, input and scoring unaffected | Mock UI toggle and pure Theme fallback tests **PASS** |
| AC-6 Regressions | Existing 11vs11 and Foosball test suites plus theme & view tests | [CI run 44639942695](https://github.com/Askeladd22/FootballPhysicsLab/actions/runs/44639942695): **LuaJIT PASS / Lua5.4 PASS** at code commit `313e3e8f92bdbc15d57a839669a33126d6577d7a` |
| AC-7 Product scope | Root README, foosball README, `.paul/STATE.md`, `docs/Project-Direction-Foosball.md` updated; 11vs11 FROZEN but preserved | Verified GitHub diff: no files in `src/`, `model.lua` or root `main.lua` were modified |

## SEED decision record
- **DECIDED:** Foosball Lab remains the small experimental side project; Project Folio remains separate; no new 11vs11 gameplay development.
- **DECIDED:** Tempered-glass **illusion**, not full physically accurate real-time refraction. Light uses small additive geometry passes and a G-toggle.
- **UNVERIFIED:** Eye comfort, visual accessibility at actual monitor settings, subjective fun, Windows/LÖVE GPU performance. CI only tests callbacks and the model.
- **NOT IMPLEMENTED:** career, rankings, advanced AI, additional match modes, shader-based bloom, external textures/sound.

## Game Design Lab — next decisive test
From this branch run `love experiments/foosball`, compare G ON and OFF for 10 deliberately aimed shots plus three bumper / goal interactions, and inspect whether ball and selected foot stay easy to identify at 1280x850 and 900x650. Record perceived brightness, lost ball events and whether halos obscure the flat striking edge.

**Next single action:** native LÖVE visual review and user feedback; keep the PR draft until native results are observed.
