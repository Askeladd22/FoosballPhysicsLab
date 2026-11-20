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

## Fase 31 — Leggibilità gameplay 3D
- [x] Camera PARTITA predefinita, camera ESPOSIZIONE completa con F4, senza reset della partita.
- [x] Evidenziazione asta selezionata e tutti i veri punti dei piedi `Model.foot`.
- [x] Pallina fisica resa più leggibile con bordo bianco e traiettoria breve.
- [x] Regressioni Lua 5.4/LuaJIT, renderer 3D/GLB, legacy NEON11, entrambe le viste native PASS.
- [ ] UAT Windows: 10 colpi mirati, capacità di leggere contatto/tiro, cambi stecca accidentali e FPS.

## Fase 32 — Palla irraggiungibile in ricochet
- [x] Recupero dopo 2 secondi di irraggiungibilità geometrica anche quando la palla rimbalza verticalmente.
- [x] Regressione: tiro orizzontale raggiunge una stecca prima della scadenza senza false rimesse.
- [x] CI Lua5.4/LuaJIT, NEON11 e smoke GPU/GLB: 7/7 PASS.
- [ ] UAT Windows: palla incastrata in corridoio, 10 tiri ordinari, percezione di equità della rimessa.

## Fase 33 — Micro-gesti mouse con selezione AUTO
- [x] Somma di piccoli eventi entro una finestra da 60ms; soglia di 3px, mantenendo il gesto attivo con il blocco già previsto di 200ms.
- [x] Reset dei contatori dopo riavvio partita e cambio modalità AUTO/MANUALE.
- [x] Test automatici: 4 eventi da 1px, jitter isolato, sblocco AUTO e cambio modalità.
- [ ] UAT Windows: 10 gesti lenti e intenzionali, pausa del mouse, contare cambi asta inattesi.
- [ ] Verificare il risultato finale dello smoke test GLB nativo sulla PR #31.
