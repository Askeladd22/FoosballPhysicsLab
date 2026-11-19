# Project direction — 20 November 2026

## DECIDED — active vs paused
**Foosball Lab** is the active small secondary prototype in this repository. The work stays focused on physics, mouse rod feel, basic opposing-rod AI, quick games and clear feedback. No career, ranking, online mode or feature proliferation until the core gesture has passed a real playtest.

**NEON 11 (FootballPhysicsLab 11vs11)** is **FROZEN** at its current implementation: do not add new match, AI, tactical or progression systems while evaluating Foosball Lab. Its source, tests, branches, PRs, history and technical documentation remain available. Continue running existing 11vs11 CI suites to preserve regression coverage; this is not a request to delete, refactor or archive the repository as a whole.

**Project Folio** remains a separate main project; no files in Project Folio are changed by this decision.

## Art direction — Foosball Lab
- Premium showroom mood: dark graphite chassis and smoked blue/teal *tempered-glass illusion*.
- Thin cyan-white etched marking and luminous goal openings, without heavy bright turf.
- Human in electric cyan; opponent in coral-red; active rod accent in warm amber; ball in warm near-white with compact halo.
- Restrained additive primitive glow rather than expensive full-frame bloom; **G** toggles it without affecting play.
- Keep front striking edge flat white, ball and feet sharply legible against every field band; do not flood every figure with gold.
- No external fonts, shader code, texture downloads or new assets.

## Game Design Lab truth-in-evidence
**Hypothesis:** the presentation communicates glass/neon while preserving fast recognition and aiming.
**Not yet observed:** native screenshots and human comparison. In an actual LÖVE session, compare 10 deliberate shots and active-rod identification under glow ON/OFF and check discomfort or ball-loss incidents.
**Decision after evidence:** retain glow if it clarifies rather than distracts, otherwise reduce it before adding any new features.
