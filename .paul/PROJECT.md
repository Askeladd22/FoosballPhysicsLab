# FoosballPhysicsLab — PAUL Project

**Tipo:** videogame single-player in LÖVE2D/Lua.
**Core value:** controllo delle stecche tramite gesti del mouse e sfida contro un'IA semplice in partite brevi.

## Vincoli
- Movimento verticale = scorrimento, orizzontale = rotazione, colpo fisico.
- Geometria collisioni 2D reale, senza magnetismo o tiri scriptati.
- Sele­zione AUTO stabilizzata, alternativa MANUALE sticky.
- Glow e pose 2.5D devono aiutare a leggere pallina e faccia di tiro.
- Nessun asset derivato dalle mesh Table Soccer può essere distribuito senza licenza idonea.
- Nessun nuovo sviluppo NEON 11: conservato in `legacy/neon11/` con test e vecchie fasi PAUL.

## Architettura
Root: `main.lua`, `model.lua`, `rod_selector.lua`, `theme.lua`, `mesh_art.lua`, `layout.lua`; test `tests/test_foosball*.lua`.
NEON 11: `legacy/neon11/main.lua`, `legacy/neon11/src/`, `legacy/neon11/tests/`.

## Gates
Suite distinte Lua 5.4 e LuaJIT, avvio LÖVE nativo, playtest delle aste e della grafica; la CI non dimostra divertimento.
