# Roadmap — Football Physics Lab

## Milestone v0.2 — Top-Down Match Lab
- [x] Initial field + world-coordinate simulation (code written; manual tuning pending).
- [x] Initial 5v5 AI with pressing, supporting movements and pass selection (code written; gameplay UAT pending).
- [x] Initial playable match loop, score, clock and HUD (code written; gameplay UAT pending).
- [x] Code fix proposed for unstable movement, kickoff/restart logic and basic passing (headless CI PASS; LÖVE UAT pending).
- [x] FM27-inspired classic 2D view in code, with mocked renderer smoke PASS (visual UAT pending).
- [x] First tactical-support and back-pass logic with headless scenarios (PR #6, CI PASS; UAT pending).
- [x] Prematch goalkeeper or midfielder selection with fixed control (PR #6, CI PASS; UAT pending).
- [ ] Verify these changes in a real 5v5 game before progressing.
- [ ] Physics and gameplay refinement from actual playtests.
- [x] Reachable AI passes, coordinated reception and per-team outcomes (v0.2.3; eight LuaJIT suites and real renderer checks PASS).
- [ ] Human UAT of v0.2.3 receiving and passing as RM/GK; tune from observed play.
- [ ] Verify all acceptance criteria in LÖVE and close the milestone.

## Milestone v0.3 — Career Foundation (not started)
- Persistent player identity and role.
- Club roster, mini-season, standings and results.
- Contextual individual match evaluation.
- Save/load and development balancing.

## Deferred
11v11, licensed clubs, full fouls/offside, complex tactics screens, advanced stadium rendering.

## Main risk
A physically faithful disc simulator may not automatically produce convincing football tactics. Validate gameplay before adding career systems.

## Phase 06 — Team coordination
- [x] Local FM24 evidence and official-source comparison documented.
- [x] Coordinated support destinations and replacement defensive cover; nine LuaJIT suites PASS.
- [ ] Human playtest of attacking opportunities versus improved cover.
