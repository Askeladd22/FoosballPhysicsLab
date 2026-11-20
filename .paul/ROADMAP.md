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

## Fase 36 — Camera REALMENTE frontale come la foto del biliardino
- [x] Diagnosticato il no-op della PR #33 già merged: proteggeva l'inquadratura diagonale sbagliata.
- [x] Camera GAMEPLAY centrata frontalmente sul lato lungo, bordi orizzontali: target `{500,-200,280}`, offset `{0,+1100,±915}`, FOV43 (~50° dal piano).
- [x] Tavolo completo + 4 supporti y=-740 dentro viewport a 900×650, 1271×874, 1280×850, 1650×895, 1920×1080, entrambi i lati e yaw 0/180; indicatori fisici non scollegati.
- [x] Vista ESPOSIZIONE F4 originale preservata; nessuna modifica a IA, dinamica, rampette, score, input o NEON11.
- [x] [GitHub Actions #44789804738](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44789804738) **7/7 PASS** sul codice iniziale, modello CC BY GLB vero con **4/4 gambe** e **62/99** campioni verdi in PARTITA, 67/99 in ESPOSIZIONE. [Due screenshot GPU nativi](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44789804738/artifacts/14655132976).
- [x] [CI 44790760084](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44790760084) **7/7 PASS** su codice `185a59e`, compreso gate GAMEPLAY >55% verde, 4/4 supporti real GLB nativo, Foosball Lua5.4/LuaJIT e NEON11.
- [ ] UAT Windows: confronto alla foto di riferimento e dieci tiri con mouse, controllando visibilità e risposta della pallina.

## Phase 37 — Double rod input (Difesa + Attacco) and closer default GAMEPLAY camera
- [x] Separate `dual` mode bound to **D**; 1-packet mouse controls both human rods 2/4 with independent clamps and real 120Hz physical contact.
- [x] Restore AUTO/MANUALE and prior selected slot on D-off; TAB into AUTO, number/wheel into MANUALE, C neutralizes both target angles. No AI rods under human input.
- [x] Highlight two human rods in 2D and 3D with 5 physical toe markers. Show DOPPIA/HUD and D shortcut without replacing controls.
- [x] GAMEPLAY defaults to distance 0.78 (~128%) vs 1.00; min 0.70 (~143%), true perspective preserved; SHOWCASE visually remains at original reset fit 100%.
- [x] Focused tests: `tests/test_foosball_dual_rods.lua`, 3D marker mock, root HUD D key, camera/zoom and F4 regressions.
- [x] CI: [run 44798062408](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44798062408) **7/7 PASS** on code commit `153522d`, including real CC BY GLB native smoke and frozen NEON11. Prior failed CI runs were due to restrictive/inaccurate test expectations and have been corrected; no unresolved failing job in referenced green run.
- [ ] Native Windows UAT: 10 parate + 10 attacchi in DOPPIA, comparison AUTO, check false simultaneous shots and readability at default 128% vs the original screenshot at 125%, with max zoom 143%.
