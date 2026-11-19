# Primo controllo e movimento di squadra — fase 12

Implementazione locale verificata il 19 novembre 2026. Il giocatore controlla
sempre lo stesso calciatore; la palla rimane un corpo libero. Questa pagina
documenta l'incremento fase 12. Il successivo centro tattico della fase 13 è
implementato e descritto in [FM24-Tactics.md](FM24-Tactics.md); i profili espliciti
di ruolo/compito sostituiscono le precedenti euristiche legate ai numeri di maglia.

## Comandi e contatto

| Comando | Comportamento |
| --- | --- |
| Spazio breve | Passaggio fisicamente raggiungibile, oppure tocco nello spazio |
| Spazio tenuto/rilasciato | Tiro caricato; soglia 0,18 s, massimo 0,75 s |
| Ctrl sinistro/destro tenuto | Ammortizza un vero contatto; la direzione di movimento orienta il tocco |
| Q tenuto al rilascio di Spazio breve | Chiede un uno-due; il ritorno richiede una corsa e un passaggio reali |
| Shift tenuto | Scatto; disattivato quando si protegge vicino al pallone |
| E | Chiede un passaggio, senza imporlo all'IA |
| P | Congela partita, tempo e intenzioni; riprendendo non cancella la combinazione |
| R / TAB | Ricomincia la partita / torna alla scelta del ruolo, ripulendo gli intenti |
| F11 | Schermo intero desktop; la finestra parte massimizzata |

Il primo controllo agisce soltanto dopo la risoluzione di una collisione reale.
Non attira la palla e non cambia direttamente le posizioni. Il cambiamento di
velocità è limitato a 14 unità/s, con cooldown di 0,22 s. La componente laterale
del movimento orienta il tocco; l'impulso non copia il rinculo all'indietro del
ricevente. Tenere Ctrl lontano dalla palla non la rallenta.

Vicino alla palla la protezione riduce movimento e accelerazione al 55%.
Serve frapporre il corpo: massa e collisioni non diventano invulnerabili, e un
avversario sul lato della palla può sottrarla. Rilascio di Ctrl, riprese e fine
partita ripuliscono lo stato appropriato. Il fuorigioco viene verificato prima
del controllo; una giocata deliberata rispetta l'eccezione delle parate.

## Decisioni contestuali

L'IA confronta utilità di passaggio, conduzione e tiro. Pressione sul portatore,
spazio disponibile, progresso, ricevente e corsia influenzano la scelta.
`Space.laneRisk` considera gli avversari proiettati lungo il segmento, escludendo
quelli dietro l'origine; la loro pressione è valutata separatamente. Il calcolo
è un'euristica spaziale, non un simulatore completo dei tempi d'intercetto.

Gli ultimi sei passaggi conservano per poco tempo mittente, destinatario e
posizione. Scambi ripetuti senza progresso ricevono una penalità che decade
entro otto secondi: non è un divieto di restituire palla. Un'opzione sicura può
ancora prevalere quando le alternative sono schermate. Una breve preferenza
per l'intenzione corrente limita cambiamenti inutili tra decisioni simili.

La conduzione cerca più direzioni; il suo tocco esplicito usa potenza 0,32.
La fisica applica quel valore, mentre passaggi, tiri e calcio normale conservano
il limite inferiore 0,45. Traiettoria e distanza sono verificate contro lo stesso
modello di attrito usato dal pianificatore, senza possesso magnetico.

## Uno-due, inserimenti e coperture

L'uno-due automatico richiede una situazione compatibile di pressione, distanza
e spazio. Quello richiesto con Q rimane intenzionale. Le fasi sono passaggio di
andata, corsa, ricezione della sponda e possibile ritorno; il ritorno può fallire
o essere intercettato. Se aspettare diventa pericoloso, la sponda può uscire dalla
combinazione. La corsa umana non viene mai assegnata dall'IA.

Gli inserimenti scelgono tra corridoi esterni e interni. Una fascia schermata può
produrre una corsa dentro il campo; scadenze, perdita di palla e riprese evitano
intenti permanenti. Un runner che torna entro raggio di gioco su palla libera
interrompe la corsa e rientra nella scelta del portatore. Il breve contatto
residuo dopo il proprio calcio e un passaggio ancora in allontanamento non
annullano un uno-due valido.

Gli appoggi usano un reticolo locale attorno al compito di reparto. Pressione e
corsia hanno costi normalizzati; distanza dall'ancora e continuità scoraggiano
grandi spostamenti o oscillazioni. CM6 resta dietro la palla; se un centrocampista
si inserisce, l'altro copre. Il terzino lontano stringe e resta più prudente.
La guardia di copertura e il vincolo di fuorigioco restano attivi; una soluzione
con almeno otto unità di separazione dai punti riservati ha precedenza quando
esiste nel reticolo. In difesa, marcature locali uniche seguono minacce entro
zona senza assegnare il medesimo compito al presser o all'ultima copertura.

## Campo e verifiche

Il mondo resta **105 × 68**, con porte larghe 7,32. Queste misure non sono state
ingrandite per riempire lo schermo; è aumentata la superficie utile della vista.

| Finestra | Campo visibile approssimativo |
| --- | --- |
| 920 × 610 | 714 × 462 px |
| 1280 × 800 | 980 × 635 px |
| 1920 × 1080 | 1372 × 889 px |

**25 suite PASS** in stati separati del LuaJIT installato con LÖVE, dopo gli
ultimi fix. `test_ball_control`, `test_dynamic_team`, `test_role_tactics`,
`test_support_space`, `test_ai_choices` e `test_runner_ball` coprono i nuovi
comportamenti; le altre suite proteggono regole, input, rendering e partite
scriptate RM/GK da 300 secondi. Gli scenari verificano anche più appoggi giocabili
dopo la rotazione, vincoli di copertura e stabilità a piccoli movimenti rivali.

Sono disponibili dodici frame LÖVE reali, quattro scene per tre risoluzioni:
`control-movement-{match,control,one-two,corner}-{920,1280,1920}.png` nella
cartella locale di visualizzazione della sessione. Il lotto iniziale precede
l'ultima iterazione IA; testimonia layout e feedback, non la qualità delle nuove
decisioni. Nessun UAT umano completo, nuova CI remota o diagnostica LuaLS è stato
eseguito. Risultati e percentuali dei match scriptati non misurano divertimento
né dimostrano un miglioramento comparativo del bilanciamento.

## Riferimenti e limiti

Le fonti dell'utente orientano lessico e situazioni; non forniscono i pesi delle
euristiche né dimostrano equivalenza con FM24. I coefficienti sopra sono valori
di prototipo da validare con gioco umano.

- [IFAB, campo di gioco](https://www.theifab.com/laws/latest/the-field-of-play/) e [schema metrico](https://www.theifab.com/static/national-metric-desktop-132232603787c0a1b2a5f21dde7a8708.svg): geometria e limiti regolamentari.
- [FA, Law 1](https://www.thefa.com/football-rules-governance/lawsandrules/laws/football-11-11/law-1---the-field-of-play), [Law 9](https://www.thefa.com/football-rules-governance/lawsandrules/laws/football-11-11/law-9---the-ball-in-and-out-of-play), [Law 11](https://www.thefa.com/football-rules-governance/lawsandrules/laws/football-11-11/law-11---offside): campo, palla fuori e fuorigioco.
- [FA, Law 15](https://www.thefa.com/football-rules-governance/lawsandrules/laws/football-11-11/law-15---the-throw-in), [Law 16](https://www.thefa.com/football-rules-governance/lawsandrules/laws/football-11-11/law-16---the-goal-kick), [Law 17](https://www.thefa.com/football-rules-governance/lawsandrules/laws/football-11-11/law-17---the-corner-kick): riprese.
- [IFAB, positioning, movement and teamwork](https://www.theifab.com/laws/latest/guidelines/positioning-movement-and-teamwork/): riguarda **gli ufficiali di gara**, non prescrive le tattiche dei giocatori.
- Wikipedia: [posizioni](https://en.wikipedia.org/wiki/Association_football_positions), [tattiche](https://en.wikipedia.org/wiki/Association_football_tactics_and_skills), [formazioni](https://en.wikipedia.org/wiki/Formation_(association_football)), [catenaccio](https://en.wikipedia.org/wiki/Catenaccio), [marcatura](https://en.wikipedia.org/wiki/Marking_(association_football)) e [tiki-taka](https://en.wikipedia.org/wiki/Tiki-taka). Sono letture di contesto sui temi indicati dall'utente, non specifiche del match engine FM24 o fonti dei coefficienti implementati.

Restano semplificazioni del calcio: dischi con raggi ampliati, palla sul piano,
fuorigioco sui centri senza ostruzione visiva, assenza di falli/rigori/cartellini,
sostituzioni e sanzioni di doppio tocco. Ruoli/compiti/istruzioni sono stati
aggiunti nella fase 13 con adattamenti originali; valutazione del ruolo e
carriera rimangono successive.
