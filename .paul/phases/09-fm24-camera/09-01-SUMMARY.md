# 09-01 — Risultato

Estratta la risorsa `cameras_match.jsb` dall'indice FMF compresso Zstandard;
frame completo e lunghezza dichiarata verificati. Camera `two_d_classic`
ortografica, bordi 10/14, limiti di zoom 0.7/1.1.

Renderer aggiornato con bordi proporzionali al mondo. Script di analisi
in sola lettura e rapporto in `docs/FM24-2D-Camera-Analysis.md`.

Undici suite LuaJIT PASS. Rendering reale LÖVE a 920x610, 1280x800,
1920x1080; controllo visivo dell'immagine 1280x800 PASS.

UNIFY_PARTIAL: implementazione e controlli automatici conclusi; UAT umano
NOT_RUN. Formula di fit nostra; equivalenza pixel per pixel con FM24 non verificata.
