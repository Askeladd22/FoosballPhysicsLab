# Catalogo ruoli FM24

Il catalogo contiene **45 ruoli**, con nomi inglesi, etichette italiane e ID di localizzazione verificati nell'installazione locale di Football Manager 2024. Le tabelle linguistiche sono state lette applicando gli aggiornamenti di `shared/languages/changes` alle tabelle base. L'evidenza e gli hash degli artefatti sono in [fm24-roles-evidence.json](fm24-roles-evidence.json).

Le descrizioni italiane sintetiche, i profili numerici e le regole di risoluzione in [football_roles.lua](../src/football_roles.lua) sono **implementazione originale di FootballPhysicsLab**. Non sono coefficienti estratti dal match engine di FM24 e non garantiscono una riproduzione identica delle sue decisioni. Il modulo espone dati indipendenti da LÖVE e da `Sim`; il movimento effettivo dipende dai consumatori di questi profili.

## Qualità dell'evidenza

- **Nomi e traduzioni:** verificati contro i record LTC locali. `sourceId` identifica la stringa, non un enum interno del motore. `sourceKey = 268435456 + sourceId` è la chiave LTC indicizzata.
- **Compiti:** quasi tutti hanno descrizioni linguistiche esplicite. Ogni ruolo conserva le relative chiavi in `provenance.dutyKeys`. La presenza di una stringa non dimostra che quella combinazione sia ancora attiva nel selettore di FM24: gli archivi contengono anche testi storici.
- **Posizioni:** matrice ricostruita della tassonomia FM24, non estratta dal codice né verificata interamente nell'interfaccia in esecuzione. La posizione `DC` raggruppa i centrali: l'eventuale requisito di essere il centrale esterno di una difesa a tre non è codificato dal solo filtro di posizione.
- **Istruzioni bloccate:** la matrice completa di compatibilità e blocchi non è verificata. Il catalogo non pubblica una proprietà `locked` inventata. `hold`, `roam` e gli altri campi sono comportamenti del nostro simulatore, non una dichiarazione sui blocchi del pannello di FM24.
- **Parametri nascosti:** pesi decisionali, dipendenze da attributi individuali, animazioni, gioco aereo e logica completa del match engine non sono recuperati da queste fonti.

Due casi richiedono attenzione. Per il **Libero**, i vecchi record `268735564` e `268735565` descrivono Supporto/Attacco, mentre il nuovo record `269032970` descrive il centrale che sale in mediana. L'[annuncio ufficiale FM24 del 21 giugno 2024](https://store.steampowered.com/news/app/2252570/view/4165345869849416401) conferma il comportamento con **Difesa o Supporto**. Il catalogo usa questi due compiti e non il vecchio Attacco. La [presentazione ufficiale del motore FM24](https://www.footballmanager.com/features/truer-football-motion-match-authenticity-positional-play) conferma il suo impiego nella difesa a quattro e nelle tre posizioni centrali della difesa a tre, e distingue il Terzino invertito che entra in difesa dall'Esterno invertito che entra in mediana.

Per l'**Ala che pressa**, Difesa e Supporto hanno record `268792471` e `268735584`. Esiste anche un vecchio testo Attacco `268735585`: è escluso dalla matrice ricostruita attuale, ma questa esclusione rimane da confermare direttamente nel selettore FM24. La provenienza del ruolo segnala questa limitazione.

## Ruoli, posizioni e compiti

Abbreviazioni: **D** Difesa, **S** Supporto, **A** Attacco, **Au** Automatico, **M** Marcatura/Stopper, **C** Copertura. Le etichette dei compiti sono verificate nei record LTC `268732917`–`268732921` e `268736419`. Le posizioni sono slot tattici, separati dal ruolo scelto.

| Nome italiano | Nome inglese | Posizioni | Compiti | ID stringa |
|---|---|---|---|---:|
| Portiere | Goalkeeper | GK | D | 297433 |
| Portiere-libero | Sweeper Keeper | GK | D, S, A | 297445 |
| Difensore centrale | Central Defender | DC | D, M, C | 297434 |
| Difensore che imposta | Ball Playing Defender | DC | D, M, C | 297448 |
| Difensore senza fronzoli | No-Nonsense Centre-Back | DC | D, M, C | 468615 |
| Terzino senza fronzoli | No-Nonsense Full-Back | DL, DR | D | 466769 |
| Braccetto di difesa | Wide Centre-Back | DC | D, S, A | 540030 |
| Libero che avanza | Libero | DC | D, S | 297447 |
| Terzino | Full-Back | DL, DR | D, S, A, Au | 297435 |
| Terzino fluidificante | Wing-Back | DL, DR, WBL, WBR | D, S, A, Au | 297436 |
| Esterno completo | Complete Wing-Back | DL, DR, WBL, WBR | S, A | 355286 |
| Esterno invertito | Inverted Wing-Back | DL, DR, WBL, WBR | D, S, A, Au | 376495 |
| Terzino invertito | Inverted Full-Back | DL, DR | D | 596934 |
| Centrocampista difensivo | Defensive Midfielder | DM | D, S | 297437 |
| Regista arretrato | Deep Lying Playmaker | DM, MC | D, S | 297449 |
| Incontrista | Ball Winning Midfielder | DM, MC | D, S | 297450 |
| Mediano incontrista | Anchor | DM | D | 540032 |
| Centromediano Metodista | Half Back | DM | D | 355384 |
| Regista | Regista | DM | S | 355634 |
| Regista mobile | Roaming Playmaker | DM, MC | S | 376566 |
| Secondo Mediano | Segundo Volante | DM | S, A | 438384 |
| Centrocampista centrale | Central Midfielder | MC | D, S, A, Au | 297438 |
| Centrocampista di quantità | Box To Box Midfielder | MC | S | 297451 |
| Regista avanzato | Advanced Playmaker | MC, AML, AMR, AMC | S, A | 297452 |
| Mezzala | Mezzala | MC | S, A | 438380 |
| Carrilero | Carrilero | MC | S | 438382 |
| Centrocampista laterale | Wide Midfielder | ML, MR | D, S, A, Au | 297439 |
| Ala | Winger | ML, MR, AML, AMR | S, A | 297440 |
| Ala che pressa | Defensive Winger | ML, MR | D, S | 297457 |
| Regista largo | Wide Playmaker | ML, MR | S, A | 376664 |
| Ala invertita | Inverted Winger | ML, MR, AML, AMR | S, A | 438378 |
| Centrocampista offensivo | Attacking Midfielder | AMC | S, A | 297442 |
| Rifinitore | Enganche | AMC | S | 355331 |
| Trequartista | Trequartista | AML, AMR, AMC, ST | A | 297459 |
| Attaccante di sostegno | Shadow Striker | AMC | A | 355654 |
| Attaccante esterno | Inside Forward | AML, AMR | S, A | 297441 |
| Trovaspazi | Raumdeuter | AML, AMR | A | 376559 |
| Fulcro del gioco largo | Wide Target Forward | AML, AMR | S, A | 539146 |
| Seconda punta | Deep Lying Forward | ST | S, A | 297443 |
| Centravanti | Advanced Forward | ST | A | 297444 |
| Fulcro del gioco | Target Forward | ST | S, A | 538908 |
| Uomo d'area | Poacher | ST | A | 297454 |
| Punta completa | Complete Forward | ST | S, A | 297455 |
| Attaccante che pressa | Pressing Forward | ST | D, S, A | 468617 |
| Falso 9 | False Nine | ST | S | 355345 |

## Contratto Lua

```lua
local Roles = require("src.football_roles")
local role = Roles.get("inverted_full_back")
local choices = Roles.forPosition("DL")
local profile = Roles.resolve("full_back", "automatic", "balanced")
-- profile.roleId == "full_back"
-- profile.requestedDuty == "automatic"
-- profile.duty == "support"
```

`R.list` è la lista ordinata; `R.byId` è la mappa per ID testuale stabile in inglese con underscore. Ogni definizione contiene `id`, `name` italiano, `nameEn`, `sourceId`, `sourceKey`, `positions`, `duties`, `defaultDuty`, `profile`, `dutyProfiles`, `description` e `provenance`. `R.get(id)` restituisce la definizione condivisa, oppure `nil`. Queste definizioni vanno trattate come dati di sola lettura. `R.forPosition(position)` restituisce ogni volta una nuova lista di definizioni condivise; per una posizione sconosciuta restituisce una lista vuota.

`R.resolve(roleId, duty, mentality)` restituisce un **nuovo profilo indipendente**, senza modificare il catalogo. Il compito omesso usa `defaultDuty`: Supporto se disponibile, altrimenti il primo della lista. Ruoli sconosciuti e compiti incompatibili generano un errore. Il chiamante verifica separatamente la compatibilità della posizione; `resolve` non riceve uno slot. I modificatori numerici generici del compito vengono sommati al profilo base, poi gli override specifici del ruolo sostituiscono i campi indicati, infine tutti i numeri vengono limitati a `[-1,1]`.

Automatico è ammesso soltanto per i ruoli che lo elencano. La mentalità può essere:

- Una stringa inglese: `very_defensive`, `defensive`, `cautious` → Difesa; `balanced`, `positive` → Supporto; `attacking`, `very_attacking` → Attacco.
- L'equivalente italiano: `molto_difensiva`, `difensiva`, `prudente`, `equilibrata`, `positiva`, `offensiva`, `molto_offensiva`. Maiuscole, spazi e trattini vengono normalizzati. Sono ammessi anche `defend`, `support`, `attack`.
- Un numero normalizzato in `[-1,1]`: sotto `-1/3` → Difesa, sopra `1/3` → Attacco, altrimenti Supporto. Questa scala e le soglie sono nostre scelte implementative, non valori interni di FM24.
- `nil` → Supporto. Una stringa sconosciuta o un numero non finito/fuori intervallo genera un errore. La mentalità non viene consultata per compiti espliciti.

## Significato dei profili

I valori esprimono preferenze relative per la simulazione: non sono probabilità, metri o abilità dei giocatori. Il lato del campo va ricavato dallo slot del calciatore.

| Campo | Valori e significato |
|---|---|
| `depth` | Da più arretrato `-1` a più avanzato `1`, relativo alla posizione naturale. |
| `width` | Da più stretto `-1` a più largo `1`, rispetto al proprio corridoio. |
| `pressing` | Frequenza/intensità relativa della pressione. |
| `passing` | Da passaggio corto `-1` a più diretto/lungo `1`; non frequenza dei passaggi. |
| `risk` | Propensione a cercare filtranti e soluzioni ambiziose. |
| `dribbling` | Propensione a portare palla e saltare l'avversario. |
| `shooting` | Propensione alla conclusione quando esiste una scelta valida. |
| `runs` | Propensione agli inserimenti senza palla. |
| `crossing` | Propensione al cross quando il contesto lo consente. |
| `roam` | Libertà di cercare spazio fuori dal corridoio assegnato. |
| `hold` | Preferenza per conservare la zona di riferimento. |
| `playmaker` | Riferimento creativo per costruzione e ricezione. |
| `target` | Riferimento di ricezione diretta; non implica un sistema aereo. |
| `holdUp` | Preferenza per proteggere il possesso e attendere appoggi. |
| `gkRush` | Portiere autorizzato a coprire fuori dalla zona ordinaria. |
| `carryDirection` | `mixed`, `inside`, `wide`: direzione preferita di conduzione. |
| `rotation` | `none`, `invert_defence`, `invert_midfield`, `libero`, `half_back`, `drop_forward`, `false_nine`. |

Le differenze mirano a decisioni riconoscibili: il Mediano incontrista conserva la zona mentre l'Incontrista esce a pressare; l'Ala cerca ampiezza e cross mentre l'Attaccante esterno si accentra e conclude; il Falso 9 viene incontro mentre l'Uomo d'area minaccia la porta. Il Rifinitore offre un riferimento più stabile del Trequartista, e Terzino invertito, Esterno invertito, Libero e Centromediano Metodista hanno rotazioni distinte.

## Verifica

[test_football_roles.lua](../tests/test_football_roles.lua) controlla 45 ID e nomi unici, provenienza, schema dei profili, intervalli numerici, compatibilità interna, liste di posizione indipendenti, copie indipendenti e deterministiche, compiti automatici e differenze fra ruoli principali. È stata verificata separatamente la corrispondenza di tutti i 45 nomi inglesi/italiani e ID con il JSON locale. Questi controlli verificano il catalogo; i test del simulatore devono verificare che i suoi consumatori traducano i profili in movimento e decisioni effettivi.
