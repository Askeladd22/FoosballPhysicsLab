# PAUL 35-01 — UNIFY: screenshot-accurate GAMEPLAY camera

**Result:** DONE_WITH_CONCERNS · automated verification PASS · human Windows UAT NOT_RUN.
**Draft PR:** [#33](https://github.com/Askeladd22/FoosballPhysicsLab/pull/33) · branch `fix/foosball-gameplay-camera-composition` · `main` untouched by this PR.

## What changed after the user clarified their reference
An earlier assistant iteration (commit `6aec31c`) proposed a symmetrical ~70° nearly overhead camera with FOV33, assuming it would improve gameplay. The user then explicitly supplied their intended 1271×874 screenshot showing the **original oblique three-quarter shot from a long edge**. The near-overhead assumption was rejected and the photo became authoritative.
- **Final GAMEPLAY:** same as the user's photo, `target={500,10,280}`, `eye={target.x-100*distance,target.y+1060*distance,target.z+side*780*distance}`, FOV35, scene yaw 180° by default and `front` viewpoint. This matches the repository's photo-era default; the patch **prevents the pending PR from replacing it**, rather than inventing a different angle.
- **Preserved:** SHOWCASE F4's exact camera and FOV35, F2 opposite side, F3 yaw rotation, Home reset, PageUp/PageDown zoom, current HUD size, original GLB and physical ball/foot contact positions.
- **Hardened:** `currentFovDegrees()` is shared by CPU projector and GPU shader, guarding against overlay offset if preset logic changes later.
- **Added test:** `tests/test_foosball_camera_framing.lua` uses seven photographed screen landmarks of the field at 1271×874 — centre, four corners and both goal midpoints — plus five viewport sizes, both sides, yaw0/180 and reversible F4, with no changes to gameplay state. Renderer mock checks GPU FOV35 during mode changes.

## Evidence and acceptance criteria
**Verified code commit:** `d38f2096f24683202bdc7a1e3279d796addbca3e`.
**CI:** [GitHub Actions run 44786693825](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44786693825) **7/7 PASS** (Foosball Lua5.4/LuaJIT; frozen NEON11 Lua5.4/LuaJIT; real CC BY GLB native LÖVE; synthetic GPU; GLB importer).
- **AC-1B PASS:** 1271×874 screenshot reference landmarks preserved within 1.2 px for projected physical field.
- **AC-2B PASS:** camera side, yaw, F4, marker positions and field cropping remain functional.
- **AC-3B PASS:** FOV35 GPU/CPU match on both presets, all seven CI jobs pass.
- **AC-4B UNVERIFIED:** player perception on Windows and subjective quality, not proven by CI or prior screenshot.

## Game Design Lab / SEED
**Observed:** user specifically wants a three-quarter view, not top-down. The previous angle-vs-playability assumption contradicted this.
**Decided:** honor photo and keep gameplay camera reproducible. No engine replacement.
**Assumed / unknown:** stable screen anchors will produce the desired perceived composition on the user's Windows GPU; playtest still needed.
**Next single action:** user launches `love .` at 1271×874 and compares a new frame with their supplied photo, checking ten controlled foot-ball contacts; capture outcome for UAT.

## Guardrails
No edits to `legacy/neon11/`, physics, 3D source assets, ramp intensity, scoring, UI layout, AI, gameplay controls or audio. All reference code commits verified by actual GitHub CI; documentation-only follow-up commits may start new jobs without changing the tested source.
