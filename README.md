# FoosballPhysicsLab

**Foosball Lab** è il progetto attivo, un biliardino per **LÖVE 11.5** con controllo fisico delle stecche tramite mouse, IA elementare, partite rapide, estetica Neon Glass e pose 2.5D locali opzionali.

## Avvio

Dalla root: `love .` oppure `run-foosball.bat` su Windows. La root ora contiene **il vero controller** `main.lua`, assieme a `model.lua`, `rod_selector.lua`, `theme.lua`, `mesh_art.lua`, `layout.lua` e `conf.lua`. Non è più un launcher che richiama `experiments/foosball`.

Il **vecchio 11vs11 NEON 11**, congelato ma integro, è un progetto indipendente: `love legacy/neon11` oppure `run-neon11-legacy.bat`. Il comando preesistente `love . --legacy` resta una scorciatoia (l'avvio diretto dalla cartella legacy conserva anche i percorsi degli asset originali).

## Comandi di gioco

| Input | Effetto |
| --- | --- |
| Mouse su/giù | Scorrimento dell'asta selezionata |
| Mouse sinistra/destra | Rotazione e tiro fisico |
| TAB | AUTO / MANUALE |
| Rotella o 1–4 | Seleziona e blocca una stecca in modalità manuale |
| Click sinistro / Esc | Cattura o sblocca il mouse |
| C | Neutrale |
| G | Glow ON/OFF |
| V | Visuale 2.5D locale / procedurale |
| F1 | Collider di debug |
| R | Ricomincia |
| - / + | Sensibilità |

**AUTO non tira al posto del giocatore**: cambia solo la stecca suggerita dalla posizione prevista della pallina, con protezione dai cambi durante una frustata. Contatti 2D a 120 Hz; una pallina realmente irraggiungibile viene recuperata dopo due secondi.

## File principali

```text
FoosballPhysicsLab/
  main.lua                 # vero Foosball
  model.lua                # fisica e regole
  rod_selector.lua         # AUTO / MANUALE
  theme.lua, layout.lua    # Neon Glass
  mesh_art.lua             # renderer 2.5D facoltativo
  tests/test_foosball*.lua # regressioni Foosball
  local_assets/            # non tracciata, modelli privati
  tools/                   # baker e verifica dei modelli
  legacy/neon11/
    main.lua, conf.lua     # vecchia applicazione LÖVE
    src/                   # 16 moduli di gioco conservati
    tests/                 # 32 test storici
    assets/                # pallone Etrusco Unico
    docs/, scripts/        # ricerca FM24, tattiche, strumenti
    .paul/                 # planning/roadmap e fasi 11vs11
```

Anche `legacy/neon11/physics_lab_01/` conserva l'originale laboratorio preliminare. I due set di test vengono eseguiti **separatamente in CI**. Non sono state riscritte le logiche di gioco del 11vs11.

## Modelli Table Soccer — solo locali

Dall'archivio originale dell'utente, il baker produce 72 pose 2.5D e una tavola di riferimento, tutte in `local_assets/`, cartella ignorata da Git:

```sh
python -m pip install Pillow
python tools/bake_table_soccer.py "C:/percorso/Table_Soccer.zip"
love .
```

Se possiedi ancora `experiments/foosball/local_assets/` del vecchio branch, spostala in `local_assets/`. Il loader riconosce temporaneamente anche il vecchio percorso. Per ragioni di licenza **non pubblicare** i file originali o i PNG derivati dalle mesh VERTX3D; leggi [LOCAL_ASSETS.md](LOCAL_ASSETS.md) e [attribuzione](docs/asset-intake/ATTRIBUTION.md).

## Ambito e qualità

**Attivo:** fisica, mouse, IA basilare, leggibilità dei colpi, partite rapide. **Congelato:** ulteriore sviluppo NEON 11. **Non previsto:** carriera, classifiche, multiplayer, nuovi motori fisici 3D. Project Folio non viene toccato.

Consulta [SEED](PLANNING.md), [PAUL](.paul/STATE.md) e [la cronologia 11vs11](legacy/neon11/README.md). I test automatici non sostituiscono il playtest reale su Windows.


## Rod response and Table Soccer sprites — PAUL 23

The human rods now follow the physical mouse target with a **fast, speed-limited servo** instead of the original heavily damped spring (which is preserved for the opponent AI). The contact physics still uses real rod velocities, 120 Hz fixed stepping and two collision microsteps; this is not mouse-triggered scripted shooting. AUTO switches less readily during repeated small mouse movements; TAB and wheel/1–4 still provide a guaranteed MANUALE lock.

The source Table Soccer geometry is **not a runtime 3D mesh**: local images are perspective-projected 2.5D sprites. Older nine-angle packs still work, but no longer double-expose adjacent angles. To reduce visible angle steps, regenerate from your own original ZIP with `python tools/bake_table_soccer.py C:/path/Table_Soccer.zip`: the current offline baker makes **25 poses per rod (200 pose PNGs + 1 table)** in ignored `local_assets/`. The table render is more visible; physical foot/collision markers are de-emphasized on inactive rods but stay fully visible on the selected one and with F1. **Neither source meshes nor derived PNGs are committed or distributed.** For a truly three-dimensional rig we would need a separate renderer, independent rig pivots and an explicit licensing check.
