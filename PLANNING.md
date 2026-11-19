---
project: Football Physics Lab
project_type: custom/game-development
status: implementing
plan_version: "phase-13-implemented"
last_updated: 2026-11-19
---

# Football Physics Lab — SEED

> Single-player arcade-tactical football where one permanently controlled disc plays in an AI team, leading eventually to an individual career.

## Audience and outcome
Players who want simple direct controls, emergent ball physics, tactical movement without the ball, and eventually a personal football career.

## Decided
- LÖVE2D/Lua for the native desktop prototype.
- Offline single-player only.
- One disc permanently controlled by the human, chosen **before the match**: blue GK #1 or blue RM #10; no live switching.
- Top-down, readable field inspired by the supplied tactical match screenshot.
- **NEON 11 2D match view:** original dark arena, cyan/orange teams, numbered discs, feet-based facing, ball shadow and transparent nets. The earlier bright-turf view is historical.
- Physical ball: no magnetic possession or automatic dribbling.
- Football boundary rules: throw-ins, corners and goal kicks; no arena walls.
- Pass-only physical kick impulse multiplier set to **1.35**, shot/manual kick strength unchanged; provisional playtest value.
- Individual player career as a later milestone.

## Prototype assumptions (to validate)
- **DECIDED (user):** 11v11 including goalkeepers; 4-4-2 is the initial formation.
- 105×68 simulation units and a field-fitting camera give readable space.
- Fixed 120 Hz simulation and independent view coordinates provide useful consistency.
- Team AI with dynamic support lanes, pressure-aware passing, physically reachable trajectories and coordinated reception is enough for a tactical playtest. Scenario and scripted full-match tests pass; human match quality remains unverified.
- Ball and player movement parameters remain provisional, adjustable in game.

## In scope for Match Lab v0.2
- Field, camera, 22 discs, physics, initial tactical AI.
- Autonomous opponent and teammates, human pass request.
- 5-minute match, goals, simple restarts and HUD.
- Debug toggles, reproducible headless tests.
- User-provided Etrusco Unico image as prototype ball texture.

## Out of scope
Multiplayer, full career, transfer markets, data persistence, complex substitutions, complete officiating, official branded assets or licensed leagues.

## Risks and tests
| Risk | Test |
| --- | --- |
| Ball control difficult or too elastic | Repeated close-touch playtests, compare with legacy lab |
| Teammates cluster or oscillate | Sticky press assignment, velocity steering, dynamic support slots, flank separation and regression scenarios |
| Input or physics depends on resolution | Run fixed-step simulation independent of drawing and vary window size |
| Kickoff or goal-line restart loops | Designated taker and endline regressions; LÖVE UAT |
| Excessive rebounds or long passes | Whole-ball crossing and pass-only physics tests; adjust multiplier based on manual playtest |
| Sprite rights unclear | Prototype only; verify rights or replace for release |

## Milestones
1. Field + physics foundation: playable disc and ball in world coordinates.
2. Team intelligence: 5v5 roles, pressing, support, passing.
3. Playable match: goals, time, scoreboard and restarts.
4. Gameplay refinement: tactical triangles, off-ball rotation, safer passing and playable GK, with UAT pending.
5. Career foundation: persistent player, clubs, roles and seasonal loop.

## Quality gate
WARN: phase 12 passes all **25 local LuaJIT suites** after the runner-on-ball and short-carry fixes, including trajectories, input callbacks and 300-second scripted GK/RM matches. Actual LÖVE rendering was checked at three resolutions. UAT, tactical balance and game feel remain unverified; scripted scores/receptions do not establish fun or stable possession. No new remote CI or LuaLS run is claimed.

## Next action
Complete the phase 13 final regression/rendering gate, then playtest contrasting roles and instructions as RM and GK. Keep manual player agency and distinguish the verified FM24 vocabulary from the original simulation coefficients.

## Current decision log — phase 13

- **IMPLEMENTED:** 45 roles with verified local English/Italian labels and source IDs; compatible positions and duties validated before application. Modern Libero uses Defend/Support, supported by the official FM24 announcement.
- **IMPLEMENTED:** five formations; independent settings for both teams and all players; 19 active team instructions and 16 active individual instructions. Six team and two player rows are visibly disabled for systems not simulated.
- **DECIDED (latest user instruction):** the AI coach owns formation, role, duty and instruction choices automatically; the human does not edit tactics.
- **IMPLEMENTED:** T opens an original read-only keyboard/mouse report and pauses simulation; T/Esc closes it. Navigating the report never changes configuration. Coach changes affect future AI decisions and anchors without teleporting bodies, resetting the clock/score or replacing the controlled player.
- **IMPLEMENTED:** roles/instructions feed support depth/width, positional rotations, pressing, passing, carrying, shooting, ground crosses, transitions and distribution. The human's movement and manual ball actions remain direct.
- **DECIDED / IMPLEMENTED (latest pace request):** slower physical defaults: speed cap 7.2, sprint ×1.4 (10.08), acceleration 54, player drag 7.5, kick speed 26 and ball drag 1.0. The five-minute wall-clock match and 120 Hz simulation remain unchanged; game feel still needs human validation.
- **VERIFIED:** catalog names/IDs match all 45 local source records; dedicated catalog, settings and actual controller/panel callback regressions pass. Full phase 13 gate is recorded in `.paul/phases/13-fm24-roles/13-01-SUMMARY.md`.
- **LIMIT:** FM24 was not inspected live in its tactics UI. Position/duty availability is qualified in the catalog; full locked player-instruction compatibility and hidden engine weights remain unknown. Coefficients are original and provisional.
- **UNVERIFIED:** human UAT, comparative tactical quality and final difficulty/balance. Ground-only physics, incomplete officiating and career work remain open.

## Previous decision log — phase 12

- **DECIDED / IMPLEMENTED:** Ctrl gives a bounded, oriented first touch only at physical contact; shielding slows the player and remains contestable. Q plus a Space tap requests a physical one-two. Human movement remains direct.
- **IMPLEMENTED:** contextual outside/inside runs, support corridors, CM6 holding cover, covering midfield rotations, far-side fullback restraint and local zonal marking.
- **IMPLEMENTED:** pressure/space utility compares passes, carries and shots; bounded history discourages stagnant pass exchanges. Rivals behind a pass origin no longer count as forward-lane interceptors. A runner reaching a loose ball resumes playing it; advance power 0.32 is applied physically while ordinary kick/pass/shot floors stay 0.45.
- **IMPLEMENTED:** startup maximization and F11 desktop fullscreen; world field stays 105 x 68. Approximate field pixels are 714 x 462, 980 x 635 and 1372 x 889 at the three tested window sizes.
- **VERIFIED:** 25 suites in separate LÖVE LuaJIT states; geometry/rendering at 920 x 610, 1280 x 800 and 1920 x 1080. Evidence and limitations: `.paul/phases/12-control-movement/12-01-SUMMARY.md`.
- **ASSUMED:** utility weights, memory duration, spacing, contact impulse/cooldown and movement scaling are prototype tuning values, not FM24 or IFAB coefficients.
- **UNVERIFIED:** human UAT, comparative tactical quality, final difficulty and balance. The later phase 13 implementation is described above.

## Historical decisions

The dated/versioned sections below record earlier increments. Their suite counts and deferred lists describe that historical build; the current state is above.

## SEED decision update — v0.2.2
- **DECIDED:** GK #1 and RM #10 prematch role selection; a single human-controlled disc remains fixed through the match.
- **IMPLEMENTED (scenario-tested):** dynamic support targets, lateral lanes, lane rotation, pressure-aware back-pass selection, safe E requests.
- **UNVERIFIED:** full-match tactical quality, goalkeeper experience and real LÖVE render/UI behavior.
- **DEFERRED:** wall-based techniques, complex corner tactics, career progression and skill assists.

## SEED decision update — v0.2.3
- **DECIDED:** implement the approved passing/reception/feedback increment; retain the physical ball and fixed human role.
- **IMPLEMENTED:** variable AI pass power and lead, physical contact-angle check, temporary receiving intent, per-team pass outcomes and visible call/receiver feedback.
- **ASSUMED:** constant receiver velocity is a useful short-term lead estimate; arrival speed near 8 simulation units/s is a provisional tuning target.
- **VERIFIED:** isolated trajectories, original 40-unit pass, moving receivers, both teams, interceptions and lifecycle; deterministic 180-second scripted matches for both human roles.
- **UNVERIFIED:** human enjoyment, difficulty and practical completion rates. No inference of improved completion rates from different scripted scenarios.
- **DEFERRED:** assisted first touch, new manual passing controls and career systems. Details: `.paul/phases/05-pass-reception/05-01-SUMMARY.md`.

## SEED decision update — coordinated team shape
- **DECIDED:** use documented FM24 positional-play principles for an original 5v5 support coordinator.
- **IMPLEMENTED:** shared team targets, receiver-space reservation and replacement cover; tests PASS.
- **ASSUMED:** spacing 8 and cover depth 16 suit this pitch; neither is an FM24 coefficient.
- **UNVERIFIED:** attacking balance after greater defensive cover; two deterministic scripted matches ended 0–0.
- **NEXT:** human RM/GK playtest; retain the physical ball and single controlled disc.

## Continuità presso i bordi
Implementati calci fisici contro la sponda e uscite dal fondo fuori porta per liberare palle lente. Parametri provvisori, dieci suite PASS; verifica umana dei due casi fotografati ancora necessaria.

## Rinvii e vista 2D
Deciso e implementato: rinvio dal fondo al portiere dopo ultimo tocco attaccante; esecuzione manuale per GK umano. Le altre riprese restano semplificate. Vista originale ispirata alla 2D Classic FM24, senza import di asset. Undici suite e rendering reale verificati; UAT umano pendente.

## Fase 10 — Scatto e calcio a 11

- **DECIDED:** richiesta esplicita di 11 contro 11; sostituisce il formato 5v5 e le sponde delle fasi precedenti.
- **IMPLEMENTED:** Shift tenuto (accelerazione/velocita x1.45), formazione 4-4-2, campo 105x68, porte 7.32, rimesse/corner/rinvii, ultimo tocco e divieto di gol diretto da rimessa.
- **ASSUMED:** sprint senza stamina e bonus 45% sono parametri iniziali di gameplay, da provare.
- **VERIFIED:** 14 suite LuaJIT, callback Shift sinistro/destro, quattro partite 11v11 scriptate per determinismo, rendering LÖVE a tre risoluzioni.
- **UNVERIFIED:** UAT e bilanciamento umano. Regolamento completo ancora aperto: fuorigioco, falli/rigori/cartellini, doppio tocco e tempi.
- Le sezioni precedenti sulla sponda descrivono soltanto la storia del prototipo.

## Fase 11 — NEON 11

- **DECIDED (utente):** fuorigioco, durata 5 minuti, identita neon ispirata a Tron, correggere blocchi/ammassamenti/passaggi IA e corner.
- **DECIDED (utente):** Spazio breve passa; Spazio tenuto e rilasciato tira. Rimosso il toggle C.
- **IMPLEMENTED:** snapshot fuorigioco per squadra, esenzioni, deviazioni e parate, coinvolgimento e punizione indiretta; timer300 con riprese incluse.
- **IMPLEMENTED:** tiri su varchi, aggiramento del pallone, seguito del tocco, supporti onside e punte a profondita diverse; routine corner con destinatario e potenza fisica.
- **IMPLEMENTED:** arena neon originale e campo piu grande, conto alla rovescia, indicatore del controllato, barra passaggio/tiro.
- **ASSUMED:** soglia tocco0.18s e carica massima0.75s sono valori iniziali da playtestare.
- **THEN OPEN:** controllo/protezione e uno-due/sovrapposizioni, ora implementati nella fase 12. Valutazione del ruolo ancora aperta; stato corrente in docs/Football-Identity.md.
- **UNVERIFIED:** bilanciamento umano; palle alte/colpi di testa e arbitraggio completo restano da costruire.


## Phase 14 — Gameplay Recovery branch (2026-11-19)
**DECIDED:** 11v11 remains available; physical ball radii and human-pass aiming adjusted in a reversible branch. Temporary arena rails restore the no-throw-ins preference. Tactical auto-coach is opt-in with F2; the existing role catalog and coach remain for comparative tests. No new career features.
**OPEN:** A different realistic *foosball* project would need constrained rods and rotational physics, not the present mobile discs. It is a candidate for a separate small comparison prototype, not an authorized replacement of this game.
**UAT:** human gameplay still NOT_RUN; automated tests cannot prove fun or natural movement.
