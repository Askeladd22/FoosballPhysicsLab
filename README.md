## Gameplay Readability — PAUL 31 (20 novembre 2026)

Il 3D reale del biliardino è finalmente orientato correttamente. La visuale
precedente mostrava sempre il **mobile intero**, sacrificando la leggibilità
delle azioni. Ora il gioco avvia **PARTITA**, una camera prospettica più vicina
alla superficie, e offre **ESPOSIZIONE** per vedere tutto il tavolo e le gambe.

**F4** cambia le due visuali a partita in corso (senza cancellare il punteggio).
**Home** ripristina la visuale PARTITA e la rotazione orizzontale originale a
180°. F2 cambia lato, F3 l'orientamento del tavolo, P/V alterna 2D/3D.
Mouse su/giù trasla la stecca; mouse sinistra/destra la ruota.

Nella visuale PARTITA: **oro** = asta selezionata e punti di contatto
dei suoi piedi calcolati con `Model.foot`; **bianco** = posizione e breve
traiettoria della pallina fisica. Gli indicatori sono soltanto visivi e
**non cambiano collisioni, velocità o IA**. Il modello GLB CC BY, le aste
1–2–5–3 e il gioco 11vs11 congelato restano invariati.

**Verificato:** [CI #44761457020](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020)
**7/7 PASS**, inclusi due render reali LÖVE dello stesso GLB: Esposizione
con 4 gambe visibili, e Partita con 207/255 campioni di scena visibili
(contro 56/255 in Esposizione). [Screenshot GPU di entrambe le modalità](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44761457020/artifacts/14641711806).
Il risultato dei test non costituisce ancora un playtest umano: valuta
10 tiri reali, direzione dei colpi e selezione della stecca prima del merge.

---

## PAUL 30: vero fix del biliardino 3D capovolto (20 novembre 2026)

**Il difetto principale non era il modello:** il vertex shader personalizzato
disegnava la scena con **Y invertita sul Canvas di LÖVE**, mentre il proiettore
CPU dell'indicatore la considerava dall'altro verso. Questo faceva apparire
**gambe sopra e campo sotto** anche se il GLB era correttamente orientato.

**Correzione:** l'asse verticale dello shader ora usa
`-dot(delta,uUp)*uFocal` per compensare il passaggio al Canvas.
La camera inquadra finalmente **il biliardino completo**, prendendo come
punto di mira il centro del mobile a **Y=-305** (gambe Y=-740,
campo Y≈-4, bordo alto Y=130), in prospettiva reale **tre quarti**.
Il modello non è stato capovolto, né riscalato o alterato.
Le otto aste, la pallina, la fisica e il controllo mouse sono invariati.

**Verifica sul GLB CC BY originale:** prima della correzione lo stesso test
vedeva solo **2/99** campioni verdi, dopo la correzione **67/99**, con
**4/4 gambe visibili sotto** il campo. [CI nativa 7/7](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687)
e [screenshot GPU LÖVE effettivo](https://github.com/Askeladd22/FoosballPhysicsLab/actions/runs/44756697687/artifacts/14639560551).
La verifica non consiste più nel mero avvio di 12 frame: controlla la visibilità
separata di terreno verde e supporti inferiori.

Da provare: `git switch fix/foosball-show-real-legs-3quarter-camera`, quindi `love .`.
**F2** cambia il lato della camera, **F3** la rotazione orizzontale del tavolo
0°/180°, **PagSu/PagGiù** avvicinano/allontanano, **Home** resetta e **P/V**
torna al 2D. Non servono g3d né modifiche alle mesh CC BY.
Il feedback Windows sui colpi è ancora necessario per considerare chiusa la UAT.

---

## Fase 29 — Il biliardino è diritto: gambe SOTTO, campo SOPRA

L'immagine di Windows mostrava un campo coperto dalla grande sponda. Il problema
**non era che i vertici 3D fossero capovolti**: il GLB originale aveva già
gambe sotto il campo (quota delle gambe −740; campo −4) e parti delle aste che
fuoriescono dal tavolo. Fare una rotazione verticale di 180° avrebbe messo le
gambe proprio verso l'alto.

**Correzione implementata:** ripresa 3D prospettica dall'alto (~79° rispetto
all'orizzonte) con FOV35 e camera sopra la sponda, mantenendo la richiesta
rotazione di 180° attorno all'asse verticale. Nessuna modifica alla fisica,
alle mesh, ai materiali, ai controlli o al vecchio progetto 11vs11.

La CI include ora **due controlli reali**:
1. `tools/test_foosball_model_upright.py` verifica nei file GPU del vero GLB
   che le gambe si trovino sotto il piano verde.
2. `--verify-3d-field` analizza 99 punti del framebuffer di LÖVE nei luoghi
   del campo verde, non solo la presenza di qualsiasi pixel del tavolo.
   Nel test nativo con il GLB originale sono risultati verdi **73/99 punti**,
   comprese entrambe le estremità del campo.

**Prova:** `git switch fix/foosball-upright-playable-pitch` e `love .`.
F2 cambia lato della camera, F3 confronta 0°/180° del tavolo e Home
ripristina la vista. La conferma della qualità visuale e dei colpi su Windows
rimane aperta: i test non garantiscono divertimento o perfetto allineamento
dei piedi ai collider.

---

## Correzione orientamento: modello 3D ruotato di 180° (PAUL 28)

Il modello completo — **tavolo, campo, otto aste e pallina** — è ora ruotato
**di 180° attorno all'asse verticale Y**, al centro del biliardino.
È una rotazione rigida delle **vere mesh 3D**, non una rotazione della sola
camera e non un'inversione della fisica. Il gioco resta alla risoluzione
dell'originale, con collisioni, IA e mouse immutati.

**Nuovo tasto F3:** alterna orientamento 180° (default richiesto) e
orientamento originale 0° per confrontarli nella stessa partita.
**F2:** cambia *solo la camera*, non il tavolo. **Home** ripristina
camera e orientamento del tavolo a 180°. L'indicatore di selezione
viene proiettato attraverso la stessa trasformazione delle mesh, quindi
non rimane scollegato dalle aste.

Il renderer esistente basato su `love.graphics.newMesh` e shader GPU
supporta questa rotazione senza aggiungere g3d: introdurre un secondo
framework non risolverebbe il problema dell'orientamento e creerebbe
due pipeline geometriche difficili da mantenere. La visuale 2D
procedurale resta disponibile con P/V, invariata.

*Game Design Lab:* il flip intorno a Y è verificabile nel codice, ma
solo un nuovo screenshot può confermare se elimina anche la sponda
che copriva il campo. Se la sponda continua a ostruire, occorrerà
intervenire separatamente su altezza/angolo di ripresa, non sulla fisica.

---

## Fase 27 — camera 3D corretta (2026-11-20)

La precedente visuale era ripresa dal lato non desiderato, troppo vicina al campo:
la barriera superiore occupava parte dell'immagine, le aste si tagliavano e
il tavolo sembrava sottosopra. **Non è un problema del modello GLB né della fisica.**

La nuova vista 3D parte dall'**altro lato lungo** del tavolo, è rialzata e
allontanata; i bordi sono adattati automaticamente alla dimensione della
finestra. Campo, aste, pallina, punteggio e IA rimangono immutati.

**Controlli camera:** **F2** inverte il lato (due viste entrambe in prospettiva
reale), **PagSu** avvicina, **PagGiù** allontana, **Home** ripristina la vista.
**P/V** rimane il confronto tra 3D e 2D; la rotella del mouse continua a
cambiare asta, non zoom. I comandi di rotazione/traslazione sono gli stessi.

Criterio di qualità: l'intera superficie e i bordi superiori del biliardino
devono restare visibili senza HUD sovrapposto, compresi 900×650, 1280×850,
1650×895 e 1920×1080. La CI testa matematicamente queste proiezioni e il
renderer nativo verifica che i pixel GPU non siano neri. La preferenza
estetica della camera richiede ancora un playtest Windows.

---

## Correzione 3D — PAUL 26 (2026-11-20)

**Corretto lo schermo nero.** Il renderer inizializzava il depth buffer a 0
mentre usava `lequal`, impedendo a tutti i triangoli di essere disegnati.
Adesso viene inizializzato a 1. La CI verifica anche i **pixel realmente visibili**,
non soltanto l'avvio di LÖVE e il caricamento delle mesh.

**Nuovo asset raccomandato:** `foosball_table (2).glb` allegato dall'utente,
di **3D Content Online**, CC BY 4.0: **103 mesh separate, 73.636 triangoli,
otto aste riconoscibili**, utilizzabile con attribuzione anche in progetti
commerciali. È preferibile all'asset VERTX3D precedente (redistribuzione
vietata) e ai due Marble (CC BY-NC: uso commerciale non consentito).

### Usare il nuovo modello

1. Copia il tuo `foosball_table (2).glb` in `assets/models/foosball_table.glb`
   (questo **GLB CC BY può essere versionato in Git**, lasciando i crediti).
2. Avvia `install-foosball-ccby.bat` dalla root oppure:
   `py -3 -m pip install trimesh numpy`
   e `py -3 tools/import_foosball_glb_ccby.py "assets/models/foosball_table.glb"`.
3. Avvia `love .`. Il gioco utilizzerà **la geometria 3D effettiva**,
   mantenendo i colpi fisici 2D. `P/V` torna al vecchio 2D.

L'importatore mette le 11 mesh renderizzabili in `local_assets/3d/`
(ignorata da Git); a differenza dei GLB fusi, usa i componenti separati e
riorganizza gli omini secondo la fisica 1-2-5-3. Per crediti, fonte e
modifiche: [assets/models/ATTRIBUTION.md](assets/models/ATTRIBUTION.md).
Per la validazione: [piano PAUL 26](.paul/phases/26-depth-ccby/26-01-PLAN.md).

---

# FoosballPhysicsLab — Table Soccer 3D REALE

**Foosball Lab** ora utilizza **vere mesh tridimensionali** del modello Table Soccer (LÖVE 11.5), non screenshot o sprite 2.5D: tavolo, campo, pallina e otto aste 3D separate, renderizzati in prospettiva con profondità e illuminazione. Il mouse governa la traslazione e la rotazione delle aste; la fisica esistente resta l'unica fonte di verità.

**PR Fase 25:** per usare il modello devi installare localmente i buffer 3D della tua copia di `Table_Soccer.zip`. Questi file NON possono essere pubblicati in GitHub per i limiti di licenza del modello originale. Il gioco conserva un fallback 2D se non sono presenti.

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
| **P oppure V** | Attiva/disattiva le vere mesh 3D; ritorno al 2D procedurale |
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


## Camera rialzata sperimentale — PAUL 24

**La camera obliqua 2.5D è ora la visuale iniziale.** Premi **P** per passare al tradizionale top-down e viceversa durante la partita. Il riferimento dell'utente era una camera tridimensionale reale: questa è per ora una *proiezione affine rialzata* che aumenta la leggibilità visiva senza riscrivere la fisica, introdurre un renderer 3D o redistribuire mesh private. La fisica, l'IA, il punteggio e il gesto del mouse continuano a lavorare nello stesso mondo 2D: campo, pallina, omini e collider sono proiettati **insieme**. Il tavolo rimane dentro la viewport anche alle dimensioni minime.

**Fix dell'omino/segno di tiro staccato:** quando è attiva la grafica 2.5D ricavata da Table Soccer, ogni sprite è accompagnato dal piede *fisicamente vero* con il relativo braccio di collegamento all'asta. Il contorno del piede in F1 coincide col contatto della pallina. Sulla stecca selezionata compare anche un indicatore del suo scorrimento effettivo in verticale. Queste correzioni sono necessarie perché le immagini pre-renderizzate non condividono ancora una rig 3D/collisione geometricamente unica con `model.lua`. Per un 3D vero servirà un passaggio distinto.


## Installazione del vero modello 3D (PAUL 25)

Un solo comando, dalla root del repository dopo aver selezionato il branch Fase 25:

```powershell
py -3 tools\import_table_soccer_3d.py "C:\percorso\Table_Soccer.zip"
love .
```

Oppure su Windows usa `install-table-soccer-3d.bat`, che cerca il tuo archivio originale nella cartella Download. Lo script usa **solo Python standard library**, analizza l'OBJ originale del tuo ZIP e converte **11 mesh effettive** (261.576 triangoli dell'intero modello, segnapunti compresi) in `local_assets/3d/`. Non carica né pubblica alcun file online. Puoi anche usare il pacchetto privato convertito fornito nella conversazione: estrai `local_assets/` direttamente nella root.

Il 3D richiede le mesh installate localmente; non è possibile ottenere il modello dalle 201 vecchie immagini del baker. Il renderer usa `love.graphics.newMesh`, un vero vertex shader prospettico, depth test e normali illuminate. La pallina e tutte le otto aste mantengono i movimenti provenienti da `model.lua` (120 Hz, fisica 2D). **P/V** consente un confronto 3D/2D senza riavviare la partita. Leggi [l'architettura e i limiti](docs/TRUE-3D.md).

L'opera originale di Hend Z. / VERTX3D (2014) **non autorizza la redistribuzione del modello, neppure parziale**. I buffer convertiti restano nella tua installazione privata e sono esclusi da Git; prima di creare un gioco distribuibile che li contiene serve una licenza idonea. Per avviare un test sintetico del renderer senza possedere il modello: `python tools/import_table_soccer_3d.py --fixture` (genera solo 11 piccoli triangoli di test **originali**, non l'aspetto del biliardino).
