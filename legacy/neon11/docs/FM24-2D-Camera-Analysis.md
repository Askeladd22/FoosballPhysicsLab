# FM24: reverse engineering della camera 2D

Data: 2026-11-19. Analisi statica e in sola lettura dell'installazione locale.

## Evidenza riproducibile

`scripts/inspect_fm24_camera.py` legge `S:\Epic Games\FootballManager24\data\simatchviewer.fmf`
(310626837 byte). Richiede Python 3.15 con `compression.zstd`; non modifica FM24
e non esporta i suoi asset nel gioco.

L'indice FMF si trova al byte 310573880. La voce `cameras_match.jsb` comincia
al byte 233793 dell'indice decompresso; la risorsa al byte 310419710 dell'archivio.
La decompressione termina correttamente e restituisce i 17147 byte dichiarati.
SHA-256 del contenuto decodificato:
`167669c53001dd8f6248ca74a0e8155e900a5e636fbc049eb4cb260bbc3ada55`.

Nella sezione `two_d_classic`, distinta da `two_d_classic_radar`, risultano:

| Parametro | Valore | Offset del valore nella risorsa decodificata |
| --- | --- | --- |
| proiezione | ortho | stringa nella sezione |
| layer | match_view_2d | stringa nella sezione |
| length_border | 10 | 13631 |
| width_border | 14 | 13711 |
| min_zoom | 0.7 | 13663 |
| max_zoom | 1.1 | 13645 |

Gli interi sono letti come int32 little-endian dopo il tag 0x02;
i limiti di zoom come float64 little-endian dopo il tag 0x07.
Lo script verifica nomi, tag, unicita delle proprieta e integrita del frame.
Non e un parser universale FMF/JSB: rifiuta varianti non corrispondenti.

## Applicazione a FootballPhysicsLab

`src/view.lua` mantiene la proiezione ortografica e adatta il campo con:
`scale = min(windowWidth / (fieldWidth + 10), viewportHeight / (fieldHeight + 14))`.
Il campo resta centrato; il nostro HUD riserva 100 pixel sopra e sotto.
La fisica e le dimensioni del terreno di gioco non cambiano.

Interpretare i bordi come margini totali in unita del mondo e una scelta
implementativa nostra, non una formula FM24 decompilata. I limiti di zoom
sono documentati, ma non viene introdotto uno zoom interattivo non richiesto.

| Finestra | Campo precedente | Campo aggiornato (pixel arrotondati) |
| --- | --- | --- |
| 920 x 610 | 703 x 410 | 586 x 342 |
| 1280 x 800 | 1029 x 600 | 857 x 500 |
| 1920 x 1080 | 1509 x 880 | 1257 x 733 |

## Verifica e limiti

Undici suite LuaJIT PASS. Rendering reale LÖVE fuori schermo alle tre
risoluzioni sopra; immagine 1280 x 800 ispezionata, porte e campo visibili.
Nessuna diagnostica LuaLS dichiarata; playtest umano non eseguito.

Non sono stati ricostruiti il layout dei pannelli FM24, la formula runtime
della camera, lo zoom salvato dall'utente o la scala dei suoi giocatori.
Quindi questa modifica usa parametri autentici della camera, ma non prova
una corrispondenza pixel per pixel e non ricostruisce il match engine.
