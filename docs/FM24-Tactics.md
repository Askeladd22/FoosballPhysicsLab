# Allenatore IA — ruoli, compiti e istruzioni automatici

L'allenatore IA decide automaticamente modulo, ruoli, compiti e istruzioni.
Il giocatore controlla il proprio calciatore e non deve configurare tattiche.
Il modello comprende **45 ruoli**, **cinque moduli**, **19 istruzioni di squadra**
e **16 individuali** attive. Le scelte guidano le decisioni IA senza spostare
istantaneamente i corpi o cambiare la fisica dei calci manuali.

## Come decide l'allenatore

L'allenatore parte da un piano equilibrato e osserva andamento dei passaggi,
avanzamento, disposizione avversaria, risultato e tempo. Può scegliere fra sei
piani: equilibrato, possesso, attacco sulle fasce, transizione diretta, protezione
del vantaggio e ricerca del gol. Il rapporto mostra il piano e la ragione della
scelta, senza chiedere al giocatore di applicarla.

Il controllo ordinario avviene ogni 12 secondi di simulazione. Per cambiare
servono due osservazioni concordi e almeno 24 secondi di permanenza nel piano;
un cambiamento urgente del risultato nel finale può anticipare la scelta dopo
un intervallo minimo di 4 secondi. Le soglie sono scelte originali del prototipo,
pensate per evitare continui cambi di tattica: non sono regole estratte da FM24.
Pausa e rapporto aperto fermano anche questo tempo. R conserva il piano corrente
e la configurazione, pulendo osservazioni e cronologia della partita precedente.

## Utilizzo

Premere **T** dopo la scelta iniziale per consultare il rapporto dell'allenatore.
È **di sola lettura**: nessun comando del pannello modifica le tattiche.
Mentre è aperto la simulazione e il cronometro sono fermi. **T o Esc** lo chiude; Esc
fuori dal pannello esce dal gioco. Cariche e comandi di calcio pendenti vengono
puliti per evitare azioni involontarie alla ripresa.

| Comando nel pannello | Effetto |
|---|---|
| 1 / 2 | Mostra squadra ciano / arancio |
| [ / ] | Mostra il calciatore della rosa |
| Tab | Cambia sezione: ruoli, squadra, calciatore |
| Su / giù; pagina su / giù; rotella | Seleziona una voce |
| Sinistra / destra; Invio | Non modificano le scelte dell'allenatore |
| Clic su squadra, calciatore o scheda | Cambia la selezione |
| Clic sul nome della voce | Seleziona senza cambiare valore |
| Clic sul valore | Seleziona la voce senza modificarla |
| T / Esc / pulsante di chiusura | Riprende la situazione precedente |

Il modello supporta **4-4-2, 4-3-3, 4-2-3-1, 3-5-2 e 5-2-3**. Modulo e posizione
definiscono i riferimenti di partenza: i calciatori raggiungono nuove zone tramite
il movimento ordinario. L'API interna usata dall'allenatore valida ogni combinazione:
se un ruolo non è compatibile con la nuova posizione ne assegna uno valido; se
il nuovo ruolo non ammette il compito corrente ne sceglie uno disponibile.
Ogni squadra mantiene un portiere. Queste sono operazioni interne, non controlli
di configurazione esposti al giocatore.

**R** ricomincia la partita conservando il calciatore controllato e la configurazione
attuale; l'allenatore può continuare ad adattarla durante il gioco.
**Tab fuori dal pannello** apre invece una nuova scelta iniziale. Le impostazioni
non sono ancora salvate tra avvii del gioco.

Il ritmo generale è stato rallentato fisicamente: velocità base 7,2 unità/s,
sprint ×1,4, accelerazione 54, attrito del giocatore 7,5, impulso base di calcio
26 e attrito della palla 1,0. Il cronometro resta di cinque minuti e il tick a
120 Hz. L'istruzione tattica Ritmo opera entro queste condizioni; non modifica
la velocità del tempo. I valori sono provvisori, da validare giocando.

## Ruoli e controllo individuale

Posizione, ruolo e compito sono distinti. Un centrale può restare nella linea,
uscire prima sul portatore o coprire più profondo. Terzino invertito, Esterno
invertito, Libero e Centromediano Metodista hanno rotazioni differenti. Ala,
Attaccante esterno, Falso 9 e Uomo d'area hanno preferenze diverse per ampiezza,
ricezione, conduzione e finalizzazione. I compiti modulano avanzamento, rischio
e inserimenti; Automatico segue la mentalità.

La libreria supporta tutti i 45 profili; i sei piani automatici usano combinazioni
definite di questi ruoli. Non tutte le varianti del catalogo vengono scelte dai
piani attuali, e non esiste ancora una valutazione di abilità individuali per
scegliere fra tutte le alternative.

Il calciatore umano resta **lo stesso oggetto controllato direttamente** anche
se cambia posizione o ruolo. Nessuna istruzione gli assegna corse automatiche,
conduzioni o tiri: WASD, Shift, Ctrl e Spazio restano manuali. La sua posizione
tattica può cambiare l'organizzazione dei compagni e la disposizione alle riprese.
Un'etichetta di ruolo sul calciatore umano non equivale a un assistente che lo
muove o gioca il pallone al suo posto.

## Istruzioni attive

Le preferenze sono combinate con ruolo e compito, mantenendo i valori entro
limiti definiti. Le scelte esplicite personali di direzione, mantenimento della
posizione o libertà di movimento prevalgono sulle corrispondenti preferenze
generali. Passaggi e cross devono comunque essere fisicamente raggiungibili.

| Squadra: 19 voci | Effetto nel prototipo |
|---|---|
| Mentalità | Compiti automatici, profondità e rischio |
| Ampiezza | Distanza laterale degli appoggi |
| Passaggi diretti | Preferenza per distanze corte o lunghe |
| Ritmo | Velocità di sostegno e rilascio del pallone |
| Passa negli spazi | Preferenza per riceventi che attaccano spazio libero |
| Sviluppo del gioco | Preferenza per fascia sinistra, destra o centro |
| Costruisci dalla difesa | Appoggi più corti per portiere e difensori |
| Ultimi metri | Portare palla in area, cercare prima il tiro o il cross |
| Dribbling | Frequenza relativa della conduzione |
| Libertà creativa | Libertà di movimento rispetto alla posizione |
| Corse di sostegno | Sovrapposizioni o corse interne sul lato scelto |
| Persa la palla | Contropressing, equilibrio o ripiegamento |
| Recuperata la palla | Contropiede, equilibrio o mantenimento delle posizioni |
| Distribuzione portiere | Preferenza per corto, lungo, fasce, regista o riferimento |
| Linea difensiva | Profondità della copertura |
| Linea di pressione | Zona da cui iniziare la pressione |
| Intensità pressing | Propensione collettiva a uscire sul portatore |
| Impedisci rinvio corto | Prima pressione più vicina al portiere avversario |
| Indirizza la pressione | Approccio orientato verso centro o esterno |

| Calciatore: 16 voci | Effetto nel prototipo |
|---|---|
| Movimento verticale | Avanzare o conservare la posizione |
| Posizione laterale | Allargarsi o stringere |
| Libertà di movimento | Libertà individuale rispetto alla zona |
| Muoviti negli spazi | Frequenza degli inserimenti |
| Intensità pressing | Propensione individuale alla pressione |
| Marca più stretto | Distanza dal riferimento di zona |
| Marca una posizione | Priorità verso un tipo di avversario nella propria zona |
| Frequenza tiri | Propensione a scegliere una conclusione valida |
| Dribbling | Propensione alla conduzione |
| Direzione dribbling | Portare palla dentro o fuori |
| Passaggi diretti | Preferenza individuale per la distanza del passaggio |
| Rischio passaggi | Tolleranza per soluzioni ambiziose |
| Proteggi e aspetta | Attendere appoggi senza agganciare la palla |
| Frequenza cross | Preferenza per il traversone rasoterra |
| Origine cross | Dalla trequarti o dal fondo |
| Destinazione cross | Zona vicina, centrale, lontana o riferimento |

## Opzioni disabilitate e fedeltà alle fonti

Sei voci di squadra restano disabilitate: altezza dei cross, aggressività dei
contrasti, rilascio dalle mani del portiere, perdita di tempo, ricerca di calci
piazzati e impedire/invitare cross. Due voci personali sono disabilitate:
contrasti più/meno duri e marcatura di un preciso avversario. Richiedono sistemi
che il prototipo non possiede: palla alta, gioco aereo, presa del portiere,
arbitraggio o marcatura individuale persistente. Il pannello ne spiega il limite.

La verifica locale di FM24 ha letto FMF/Zstandard e tabelle LTC inglesi/italiane
con aggiornamenti, dopo l'identificazione del binario con REA. I 45 nomi e le
traduzioni sono verificati; descrizioni sintetiche, interfaccia e coefficienti
comportamentali sono originali. Non è stata osservata la UI di FM24 in esecuzione
e non è stata ricostruita la sua matrice completa di istruzioni bloccate né il
motore nascosto. Il [catalogo dei ruoli](FM24-Role-Catalog.md) distingue l'evidenza
dei singoli campi e documenta la correzione del Libero di FM24.

I test verificano compatibilità dell'API interna, isolamento fra squadre/calciatori,
assenza di teletrasporti e reset, callback reali di tastiera/mouse che non alterano
le scelte dell'allenatore e differenze di comportamento in scenari controllati.
Il rendering viene controllato separatamente nelle tre
risoluzioni previste. I risultati tecnici e i limiti sono nel
[resoconto fase 13](../.paul/phases/13-fm24-roles/13-01-SUMMARY.md).
UAT, divertimento e bilanciamento umano restano da verificare.
