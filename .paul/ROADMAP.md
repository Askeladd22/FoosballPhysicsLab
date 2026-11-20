# Roadmap — Foosball Lab

**Stato:** attivo; NEON 11 congelato sotto `legacy/neon11/`.

- [x] Fisica pallina e piedi rettangolari.
- [x] Mouse traslazione/rotazione, aste controllate e IA.
- [x] AUTO e blocco MANUALE, protezione gesti.
- [x] Neon Glass e recupero palla irraggiungibile.
- [x] Baker privato per Table Soccer e fallback procedurale.
- [x] Fase 22: runtime biliardino nella root; 11vs11 in `legacy/neon11/`.
- [ ] Test umano: 10 tiri mirati, cambi stecca indesiderati, leggibilità.
- [ ] Test visivo 2.5D/procedurale e frame time Windows.

**Esclusi:** carriera, ranking, multiplayer e nuove tattiche 11vs11. Storico PAUL nel legacy.


## Fase 25 — 3D vero
- [x] Importer locale OBJ → 11 buffer GPU con materiale per componente e normali.
- [x] Renderer prospettico LÖVE, depth buffer e aste 3D mobili guidate dalla fisica 2D.
- [x] Fallback procedurale 2D e commutazione P/V senza reset.
- [ ] Confermare avvio LÖVE nativo con modello originale, FPS e allineamento piedi/collider.
- [ ] Eventuale integrazione delle texture originali e affinamento pivot solo dopo playtest.
