# PAUL 17-01 — UNIFY: Foosball figure articulation and HUD recovery

**Status:** APPLY_DONE; VERIFIED (scripted tests); DONE_WITH_CONCERNS (native LÖVE and human visual UAT not run). **Branch:** `fix/foosball-visual-rotation-and-hud`. **PR:** [#15](https://github.com/Askeladd22/FootballPhysicsLab/pull/15) (draft, not merged).

## PLAN → APPLY → verification

| AC | Implementation | Evidence |
| --- | --- | --- |
| AC1 — Avoid field/HUD overlap | New pure `experiments/foosball/layout.lua`: reserve 132px title, 146px footer, fit the field **and its 46-unit wood rim** between them | `tests/test_foosball_layout.lua` checks 1280x850, 1279x881, 1024x768, 900x650: **PASS** |
| AC2 — Make body rotation visually physical | `Model.figurePose` derives torso/head inclination from the exact existing `Model.foot` position; geometry collision `Model.footRect` is unchanged | headless pose+shoe consistency: **PASS** |
| AC3 — Fix team identity and missing glyphs | Keep selected player's team blue/red and only outline its shoe gold; one arrow on middle figure, white strike face; replace unsupported Unicode arrows with DESTRA/SINISTRA text | modified LÖVE mock smoke and glyph check: **PASS** |
| AC4 — Regressions | All pre-existing 11v11 and foosball Lua tests, plus new screen geometry and mocked view checks | GitHub Actions [run 44638356874](https://github.com/Askeladd22/FootballPhysicsLab/actions/runs/44638356874): Lua5.4 **PASS**, LuaJIT **PASS** |
| AC5 — Human perception / gameplay | No new gameplay mechanics and no physics control changes | **NOT_RUN**, still requires fresh Windows/LÖVE screenshot and deliberate strike playtest |

## SEED evidence ledger
- **Observed:** screenshot shows yellow selected figures instead of team-colored figures, direction text missing its font glyphs, and a table rim competing with the instruction line.
- **Derived:** a torso anchored to the shaft while shoe moves in X causes visual disconnection. Coupling body lean to projected shoe X removes that inconsistency without changing collision impulses.
- **Assumed:** these presentation changes help players predict contact and make the active rod recognizable; human perception has not been measured.
- **Unknown:** whether the screenshot also intended an unrelated bug (the original user did not annotate the problem); whether the graphical rotation is sufficiently lifelike for the desired realism.

## Game Design Lab next decisive experiment
Play `love experiments/foosball` from this PR at 1280x850 and optionally 900x650. Confirm subtitle and rim never overlap; selected human rod stays blue; direction text has no squares. Use F1 to show shoe collider and make ten aimed mouse strokes. Record whether the player can name the physical strike face before kicking, without seeing the debug overlay.

**Next single step:** user tests native LÖVE visual result on this branch; do not merge until that check is complete.
