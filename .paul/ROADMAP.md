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
- [x] GitHub Actions #44772526612: 7/7 PASS, compreso smoke nativo 3D con GLB CC BY.

## Fase 34 — Rampe agli angoli e lungo i lati
- [x] Geometria condivisa: 2 rampe lungo i lati lunghi e 4 rampe sulle testate fuori dalle porte, con inclinazione risultante negli angoli.
- [x] Accelerazione dolce dentro la zona inclinata, senza impulso scriptato; ball wake-up anche a velocità iniziale zero.
- [x] Pavimentazione visibile in 2D Neon Glass e vera mesh di rampe procedurali nel renderer 3D; palla alzata sulla pendenza.
- [x] Nuove regressioni per gli angoli, sponde, porte, geometria 3D, determinismo e rendering; Lua 5.4/LuaJIT PASS su [run 44777414138](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44777414138).
- [x] [GitHub Actions 44778209050](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44778209050) **7/7 PASS** sul commit `3c64bbd`, compreso vero GLB CC BY e nuova verifica dell'allineamento fisico/rendering delle rampe.
- [ ] UAT Windows: gioco con mouse, rampe/porte visivamente allineate e tiri di sponda non eccessivamente deviati.

## Revisione separata proposta — Camera GAMEPLAY (input screenshot)
- [ ] Audit inquadratura di tutti i punti gioco a 900×650, 1280×850, 1650×895, 1920×1080, senza sacrificare l'HUD.
- [ ] Rivedere altezza/obliquità, distanza, FOV35 e banda viewport fissa 112px top + 140px bottom.
- [ ] Verificare pallina, piedi, sponde e rampette da front/back e yaw 0/180 in un frame reale, non solo test matematica proiezione.
- [ ] Separare le modifiche camera in una nuova PR: questo PR #32 contiene soltanto rampe e loro allineamento GPU.

## Fase 35 — Camera GAMEPLAY fedele alla foto
- [x] Rifiutato il provvisorio angolo quasi zenitale 70° richiesto dal solo ragionamento dell'assistente: il riferimento esplicito utente è una foto del tavolo 3D a tre quarti.
- [x] Confermati l'offset camera sul lato lungo `(-100,+1060,±780)`, FOV35°, yaw180° e il layout HUD della schermata 1271×874, senza alterare la fisica.
- [x] Sette ancore di proiezione foto (centro, quattro angoli, entrambe le porte) verificate alla dimensione 1271×874. Regressioni per altre quattro risoluzioni, due lati F2, yaw0/180 F3, marcatori fisici e F4 SHOWCASE.
- [x] Shader GPU e indicatori CPU hanno lo stesso FOV35 in entrambe le modalità. Nessuna modifica alla camera ESPOSIZIONE.
- [x] [GitHub Actions #44786693825](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44786693825) **7/7 PASS** sul commit di codice `d38f2096`, inclusi i 7 landmark della foto e il GLB CC BY nativo. Commit documentali successivi non modificano il codice verificato.
- [ ] Foto Windows 1271×874 e 10 tiri veri: verifica percettiva degli omini/pallina ancora da completare.
