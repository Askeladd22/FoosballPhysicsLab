# Table Soccer — asset solo locali

Dalla root del repository:

```sh
python -m pip install Pillow
python tools/bake_table_soccer.py "C:/percorso/Table_Soccer.zip"
love .
```

Gli 8 gruppi di aste (9 pose ciascuno) e il tavolo vengono salvati in `local_assets/`, ignorata da Git. L'app usa quei PNG se il pacchetto è completo, altrimenti disegna il biliardino Neon Glass procedurale; **V** passa tra le due visuali.

Se avevi già la cartella non tracciata `experiments/foosball/local_assets/`, spostala nella root come `local_assets/`. Il loader offre una compatibilità temporanea con il vecchio percorso, se i file sono ancora lì.

**Licenza:** il README di Hend Z./VERTX3D vieta la redistribuzione del modello in tutto o in parte. Non pubblicare mesh originali, ZIP, FBX, OBJ, PNG derivati senza autorizzazione. Il baker elabora soltanto il file privato presente sul tuo PC.


### Aggiornamento visuale, PAUL 23
Il renderer conserva compatibilità con i precedenti 9 fotogrammi per asta, ma non ne sovrappone più due (effetto fantasma). Il nuovo baker produce **25 pose per asta**, per un totale di **201 PNG** compresa la tavola. Per migliorare la fluidità grafica, rigenera localmente usando la tua copia originale dello ZIP. Nessun asset derivato viene caricato automaticamente su GitHub, né è consentito redistribuirlo senza i diritti necessari.


## MODALITÀ REALE 3D (Phase 25)
Le vecchie immagini `local_assets/rods/*.png` NON sono il modello 3D. Per usare la **geometria vera** converti la tua copia di `Table_Soccer.zip` con `py -3 tools\import_table_soccer_3d.py "C:\percorso\Table_Soccer.zip"` dalla root: verrà creata `local_assets/3d/` con 11 buffer delle mesh originali, materiali semplificati, e un manifesto dei diritti. Il renderer 3D si attiva automaticamente all'avvio se tutti i file sono validi, altrimenti rimane il top-down procedurale 2D. Premi **P** o **V** per confrontare. Il nuovo importer usa soltanto Python standard library; non può recuperare il modello originale da uno sprite né scaricare file online. NON distribuire i binari derivati: la licenza VERTX3D lo vieta senza un permesso adeguato.
