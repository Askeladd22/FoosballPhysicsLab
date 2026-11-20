# SEED — Foosball Mouse Rod Lab

**Type:** game prototype / validation. **Status:** experimental, not the main product.

## Target interaction
A single player physically simulates hands-on-rod actions with one mouse: vertical displacement = rod translation; horizontal displacement = rod rotation. The rod is an inertia-driven constrained body. Ball contacts follow foot velocity and ball state; there is no teleport possession or on-key shooting.

**Decided:** LÖVE2D, offline, 4 selectable human rods + 4 simple AI rods, 1-2-5-3 figure layout, a tutorial serve near forward rod and first-to-five local match.

**Assumed, awaiting human playtesting:** mouse movement alone can express fast, deliberate throws and subtle contact without unintentional axial motion.

**Unknown:** best sensitivity/inertia, perceived realism, first-shot learning curve, camera readability across laptop sizes, competitive AI quality.

**Out of scope:** career, multiplayer, licensing, sophisticated opponents, complex ball spin, authentic tournament regulations.

## Evidence gates
- AC-1 orthogonal mouse movement + manual selection: scripted test.
- AC-2 rod angular velocity drives the foot/ball impulse: scripted test.
- AC-3 rails/goals and five-to-win: scripted test.
- AC-4 automatic opponent slide remains finite and delayed: scripted test.
- AC-5 deterministic simulation and CI, human UAT later.

**First manual scenario:** start with the ball near the middle figure of rod 4. Compare a deliberately aimed 3-shot volley with randomized sweeping; does timing improve outcomes? Measure first successful directed strike, not just raw score.
