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
