# 📋 BattleRacer — Anforderungsliste

Alle Anforderungen an das Spiel, **sortiert nach empfohlener Abarbeitungsreihenfolge**. Die Reihenfolge folgt zwei Prinzipien:

1. **Risiko zuerst:** Fahrgefühl und Netzwerk sind die beiden Systeme, an denen das Projekt scheitern kann — sie kommen vor allem anderen.
2. **Immer spielbar bleiben:** Nach jeder Phase existiert ein Stand, den man tatsächlich spielen und mit Freunden testen kann.

Die Phasen entsprechen den Meilensteinen M1–M7 aus der [README](README.md#9-roadmap--meilensteine).

**Priorität:** 🔴 Muss (ohne das kein LAN-Release) · 🟡 Soll (stark gewünscht) · 🟢 Kann (Stretch Goal)

**Status-Legende:** ⬜ offen · 🔄 in Arbeit · ✅ fertig

---

## Phase 0 — Projekt-Fundament

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-001** | 🔴 | 🔄 | **Godot-Projekt anlegen:** `project.godot` im Repo-Root, Ordnerstruktur gemäß README Abschnitt 8, Physik-Tickrate auf 120 Hz, Hauptszene = Startmenü-Platzhalter — angelegt, **noch nicht in einem echten Godot-Editor geöffnet/verifiziert** (siehe Hinweis unten) |
| **A-002** | 🔴 | 🔄 | **Input-Map definieren:** Aktionen `accelerate`, `brake`, `steer_left`, `steer_right`, `drift`, `use_item`, `look_back`, `pause` — jeweils mit Gamepad- UND Tastatur-Belegung; analoge Lenkung mit Deadzone — Bindings in `project.godot` hinterlegt, Parsing noch nicht im Editor bestätigt |
| **A-003** | 🔴 | 🔄 | **Tooling einrichten:** `.gitattributes` für Git LFS ✅, `tests/`-Ordner mit Anleitung ✅, gdtoolkit installiert ✅ — **GUT-Framework unter `addons/gut/` fehlt noch** (Installation nur per Godot-Editor-AssetLib möglich, siehe `tests/README.md`) |
| **A-004** | 🟡 | ⬜ | **Export-Presets:** `export_presets.cfg` für Windows + Linux, Build-Skript das beide Zips erzeugt — von Anfang an, damit Builds nie "Überraschung kurz vor der LAN" sind. Erfordert lokal installierte Export-Templates, daher bewusst erst beim ersten echten Editor-Öffnen angelegt |

---

## Phase 1 — Fahrgefühl (M1) 🏎️

*Der wichtigste Teil des Spiels. So lange iterieren, bis es sich gut anfühlt — alles Weitere baut darauf auf.*

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-010** | 🔴 | 🔄 | **Testfläche:** Graue Testszene mit Ebene, Rampen, Kurven-Parcours und einer Steilkurve — dient bis zum Projektende als Physik-Spielwiese. `tracks/test_area.tscn` angelegt (Boden, Rampe, Offroad-Patch, Boost-Pad) — **noch nicht im Editor geöffnet/bespielt** |
| **A-011** | 🔴 | 🔄 | **Raycast-Kart-Controller:** `RigidBody3D` mit Raycast-Federung; Gas, Bremse, Rückwärts, analoge Lenkung; sichtbares Kart-Mesh wird rein optisch nachgeführt (Neigung in Kurven, Federweg). `src/kart/kart.gd` + `kart.tscn` implementiert, GUT-Regressionstest vorhanden — **Fahrgefühl noch nicht mit Gamepad gegengespielt** |
| **A-012** | 🔴 | ✅ | **Handling-Resource:** Alle Fahrparameter (Topspeed, Beschleunigung, Lenkverhalten, Grip, Gewichtsklasse) als `.tres`-Resource; drei Beispielklassen leicht/mittel/schwer — `src/kart/kart_handling.gd` + `handling/{light,medium,heavy}.tres` |
| **A-013** | 🔴 | 🔄 | **Drift + Mini-Turbo:** Drift-Knopf mit Hop, gehaltener Drift lädt Funken-Stufen (2 Stufen wie MK64), Boost beim Lösen; Drift-Richtung unabhängig von Lenk-Feineinstellung — Zustandsmaschine implementiert, **Hop beim Drift-Einstieg fehlt noch** (springt aktuell direkt in den Drift ohne Hüpfer), Timing/Balance ungetestet |
| **A-014** | 🔴 | 🔄 | **Verfolgerkamera:** Weiche Kamera hinter dem Kart, zieht bei Boost leicht auf (FOV), `look_back`-Taste für Rückblick — `chase_camera.gd`/`.tscn` implementiert, ungetestet |
| **A-015** | 🔴 | 🔄 | **Grundlegende Fahr-Umgebungsregeln:** Offroad-Verlangsamung (abseits der Strecke), Wände mit sauberem Abprallen ohne Physik-Explosion, Kart kann nicht auf dem Dach landen (Auto-Aufrichten) — Offroad-Faktor + Auto-Aufrichten implementiert; Wand-Abprallverhalten läuft aktuell nur über Standard-`RigidBody3D`-Kollision, noch nicht gezielt gegen harte Einschläge getestet |
| **A-016** | 🔴 | 🔄 | **Respawn-Grundlage:** Fällt das Kart aus der Welt / in Todeszonen, wird es an definierter Position wieder eingesetzt (kurze Unverwundbarkeit + Geschwindigkeits-Reset) — Fall-unter-Schwellwert löst Respawn zur letzten sicheren Transform aus; **kurze Unverwundbarkeit nach Respawn fehlt noch** |
| **A-017** | 🟡 | 🔄 | **Boost-Pads & Sprungschanzen** auf der Testfläche funktionsfähig — `src/track/boost_pad.gd`/`.tscn` implementiert und in der Testfläche platziert; Sprungschanze bisher nur als statische Rampengeometrie ohne spezielles Tuning |
| **A-018** | 🟢 | ⬜ | **Slipstream/Windschatten:** Hinter anderem Kart fahren lädt kurzen Boost auf (kann erst ab Phase 2 sinnvoll getestet werden) |

**Phase fertig, wenn:** Zwei Personen sich den Controller aus der Hand reißen, weil das Fahren auf der Testfläche allein schon Spaß macht.

---

## Phase 2 — Netzwerk-Skelett (M2) 🌐

*Früh angehen: Netzwerk nachträglich einzubauen ist der teuerste Fehler in Multiplayer-Projekten.*

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-020** | 🔴 | ⬜ | **Host/Join-Grundgerüst:** Spiel als Host starten (Listen-Server) oder als Client einem Host beitreten (`ENetMultiplayerPeer`), bis zu 16 Spieler |
| **A-021** | 🔴 | ⬜ | **LAN-Discovery:** Host kündigt sein Spiel per UDP-Broadcast im Subnetz an; Clients sehen eine Serverliste (Hostname, Spielerzahl) und treten per Klick bei — keine IP-Eingabe nötig (manuelle IP-Eingabe als Fallback trotzdem anbieten) |
| **A-022** | 🔴 | ⬜ | **Spieler-Replikation:** Karts aller Spieler werden gespawnt und synchronisiert; Clients senden nur Inputs, der Host simuliert autoritativ |
| **A-023** | 🔴 | ⬜ | **Client-Side Prediction + Reconciliation** für das eigene Kart: Eingaben wirken sofort, Host-Korrekturen werden weich eingeblendet (kein sichtbares Snapping bei normalem LAN-Betrieb) |
| **A-024** | 🔴 | ⬜ | **Snapshot-Interpolation** für fremde Karts (~100 ms Puffer): fremde Karts bewegen sich auch bei 20–30 Hz Snapshot-Rate butterweich |
| **A-025** | 🔴 | ⬜ | **Verbindungsabbrüche sauber behandeln:** Client-Disconnect entfernt das Kart ohne Crash; Host-Verlust beendet das Rennen mit klarer Meldung (kein Host-Migration nötig) |
| **A-026** | 🔴 | ⬜ | **Namens-Eingabe:** Jeder Spieler setzt einen Spielernamen (persistiert lokal), der über allen fremden Karts und in allen Listen angezeigt wird |
| **A-027** | 🟡 | ⬜ | **Netzwerk-Debug-Overlay:** Ping, Snapshot-Rate, Korrektur-Distanz pro Frame einblendbar — unverzichtbar für die Fehlersuche in Phase 2–4 |

**Phase fertig, wenn:** 3+ Rechner im LAN gemeinsam auf der Testfläche fahren, ohne Ruckeln, Snapping oder Geisterkarts — 30 Minuten Dauertest ohne Absturz.

---

## Phase 3 — Rennlogik (M3) 🏁

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-030** | 🔴 | ⬜ | **Erste echte Strecke:** Rundkurs mit Start-/Ziellinie, Streckenbegrenzung, mindestens einer Abkürzung und einer Gefahrenstelle (Abgrund o. ä.) — Grey-Boxing reicht, Optik kommt in Phase 6 |
| **A-031** | 🔴 | ⬜ | **Checkpoint-System:** Unsichtbare Trigger-Sequenz; Runde zählt nur bei vollständiger Passage in Reihenfolge (Host-autoritativ, GUT-getestet) |
| **A-032** | 🔴 | ⬜ | **Respawn an Checkpoints:** Rausfallen setzt ans zuletzt passierte Checkpoint zurück (ersetzt A-016-Provisorium) |
| **A-033** | 🔴 | ⬜ | **Platzierungsberechnung:** Live-Position aller Fahrer (Runde + Checkpoint + Distanz zum nächsten Checkpoint), GUT-getestet |
| **A-034** | 🔴 | ⬜ | **Rennablauf:** Startaufstellung → Countdown (3-2-1-GO, mit Frühstart-Boost-Fenster wie MK64) → 3 Runden → Zieleinlauf → Ergebnistafel |
| **A-035** | 🔴 | ⬜ | **HUD im Rennen:** Position (z. B. „3/16"), Rundenzähler, Rundenzeit, aktuelles Item (Slot), Minimap mit allen Fahrern |
| **A-036** | 🔴 | ⬜ | **Zieleinlauf-Verhalten:** Nach der Ziellinie übernimmt Auto-Pilot das Kart; Rennen endet für alle X Sekunden nach dem ersten Finisher, Rest wird nach aktueller Position gewertet |
| **A-037** | 🟡 | ⬜ | **Falschfahrer-Warnung** („Falsche Richtung!") bei Fahrt entgegen der Checkpoint-Reihenfolge |

**Phase fertig, wenn:** Ein komplettes 16-Spieler-Rennen von Countdown bis Ergebnistafel ohne manuellen Eingriff durchläuft.

---

## Phase 4 — Menüs & Game-Flow (inkl. Strecken- & Charakterwahl) 📺

*Ab hier fühlt es sich wie ein Spiel an, nicht wie eine Tech-Demo. Alle Menüs sind vollständig mit dem Gamepad bedienbar.*

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-040** | 🔴 | ⬜ | **Hauptmenü:** Titelbildschirm im 80er/90er-Stil mit den Punkten *Mehrspieler (LAN)*, *Einzelspieler*, *Optionen*, *Beenden* — komplett per Gamepad navigierbar (Fokus-Highlights, Bestätigen/Zurück-Tasten) |
| **A-041** | 🔴 | ⬜ | **Lobby-Bildschirm:** Host erstellt Spiel (Name, max. Spielerzahl, Modus); Beitretende sehen Spielerliste mit Namen, gewähltem Charakter und Bereit-Status; Host startet, wenn alle bereit sind; Chat optional (🟢) |
| **A-042** | 🔴 | ⬜ | **Charakterauswahl:** Raster aller Charaktere mit 3D-Vorschau (drehbares Modell), Name und Gewichtsklasse (leicht/mittel/schwer → Fahrverhalten); in der Lobby sieht jeder live, wen die anderen wählen; Doppelwahl erlaubt (Farbvariante zur Unterscheidung) |
| **A-043** | 🔴 | ⬜ | **Streckenauswahl:** Raster aller Strecken mit Vorschaubild, Name, Streckenlänge/Schwierigkeit; wählt der Host; optional Zufalls-Button; Anzeige der zuletzt gefahrenen Strecke |
| **A-044** | 🔴 | ⬜ | **Ergebnis-Bildschirm:** Platzierungen mit Charakter-Portraits, Rundenzeiten, Punktevergabe; danach zurück in die Lobby (Rematch-Flow: gleiche Runde nochmal ODER neue Streckenwahl — ohne Neu-Verbinden!) |
| **A-045** | 🔴 | ⬜ | **Pause-Verhalten im Multiplayer:** Pause-Menü hält NICHT das Spiel an (nur Overlay: Fortsetzen / Optionen / Rennen verlassen) |
| **A-046** | 🔴 | ⬜ | **Optionen:** Lautstärke (Musik/SFX getrennt), Auflösung/Vollbild, Gamepad-Deadzone, Lenkung invertieren, Spielername — persistiert in lokaler Config-Datei |
| **A-047** | 🟡 | ⬜ | **Grand-Prix-Modus:** Cup aus 3–4 Strecken mit Punktewertung über alle Rennen und Gesamtsieger-Ehrung |
| **A-048** | 🟢 | ⬜ | **Lokaler Splitscreen:** 2–4 Spieler an einem PC (mehrere Gamepads, geteilte Viewports), kombinierbar mit LAN-Spiel |

**Phase fertig, wenn:** Kompletter Abend-Loop ohne Spielneustart funktioniert: Lobby → Charakter- & Streckenwahl → Rennen → Ergebnis → nächste Strecke → … 

---

## Phase 5 — Items & Chaos (M4) 🎁

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-050** | 🔴 | ⬜ | **Itembox-System:** Schwebende, rotierende Itemboxen auf der Strecke; respawnen nach kurzer Zeit; Vergabe Host-autoritativ |
| **A-051** | 🔴 | ⬜ | **Positionsabhängige Item-Verteilung:** Wahrscheinlichkeitstabelle pro Platzierungsgruppe (vorne = schwache Items, hinten = starke) als datengetriebene Resource, GUT-getestet — das einzige Rubber-Banding-Instrument |
| **A-052** | 🔴 | ⬜ | **Treffer-Reaktion:** Getroffene Karts wirbeln/stoppen einheitlich (Spin-out), kurze Unverwundbarkeit danach, Item-Verlust-Feedback; alles auf allen Clients sichtbar synchron |
| **A-053** | 🔴 | ⬜ | **Item-Startset (mind. 5):** ① Gerade fliegendes Geschoss ② Zielsuchendes Geschoss (auf Vordermann) ③ Hinterlassbare Falle (Bananen-Äquivalent) ④ Boost ⑤ Unverwundbarkeit + Rammbonus (Stern-Äquivalent) — jeweils mit eigenem 80s/90s-Design |
| **A-054** | 🟡 | ⬜ | **Item-Erweiterung (auf ~8):** ⑥ Blitz (alle anderen schrumpfen/verlangsamen) ⑦ Fake-Itembox ⑧ Geist (klaut Item + kurz unsichtbar) |
| **A-055** | 🟡 | ⬜ | **Items nach hinten abfeuerbar** (halten + zurück) und Falle als Schild hinterm Kart herziehbar |
| **A-056** | 🔴 | ⬜ | **Balancing-Testabend:** Ein dedizierter Playtest nur für Item-Balance mit mind. 4 echten Spielern; Erkenntnisse fließen in die Wahrscheinlichkeitstabelle (A-051) |

**Phase fertig, wenn:** Der Führende nie sicher ist und der Letzte nie hoffnungslos — und alle über den Blitz fluchen.

---

## Phase 6 — Comic-Look & Audio (M5) 🎨

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-060** | 🔴 | ⬜ | **Toon-Shader-Pipeline:** Cel-Shading (2–3 Lichtstufen, Rim-Light) + Outlines (Inverted Hull für Charaktere/Karts); als wiederverwendbares Material für alle Assets |
| **A-061** | 🔴 | ⬜ | **Erster vollwertiger Charakter:** Eigenes Design als 80s/90s-Anime-Hommage, gerigged und animiert (Fahren, Lenken, Treffer, Jubel, Item-Wurf) — dient als Template für alle weiteren |
| **A-062** | 🔴 | ⬜ | **Kart-Modelle:** Mindestens 2 Kart-Designs mit Toon-Look, Charaktere sitzen korrekt |
| **A-063** | 🔴 | ⬜ | **Gameplay-VFX:** Drift-Funken (Stufenfarben!), Boost-Speedlines, Treffer-„POW!"-Sprites, Staubwolken offroad, Respawn-Effekt — Lesbarkeit vor Schönheit: Jeder Effekt muss aus 30 m Distanz erkennbar sein |
| **A-064** | 🔴 | ⬜ | **UI-Skin 80er/90er:** HUD, Menüs und Ergebnistafel im Retro-Stil (VHS-Vibes, kräftige Farben, passende Display-Schrift) |
| **A-065** | 🔴 | ⬜ | **Sound-Effekte:** Motor (drehzahlabhängig), Drift, Boost, Item-Abschuss/Treffer, Checkpoint-/Runden-Jingle, Countdown, UI-Sounds |
| **A-066** | 🔴 | ⬜ | **Musik:** Synthwave-Soundtrack — Menü-Theme + mind. 1 Track pro Strecke + Ergebnis-Theme (lizenzfrei oder selbst produziert, Lizenz dokumentieren) |
| **A-067** | 🟡 | ⬜ | **Ansager-Stimme** („3… 2… 1… GO!", „Letzte Runde!", Zieleinlauf) |
| **A-068** | 🟡 | ⬜ | **Performance-Budget eingehalten:** 60 FPS mit 16 Karts + Effekten auf dem schwächsten erwarteten LAN-Rechner (Referenzgerät definieren und regelmäßig testen) |

**Phase fertig, wenn:** Ein Screenshot des Spiels ohne Erklärung als „moderner Comic-Kart-Racer" durchgeht.

---

## Phase 7 — Content & Zusatzmodi (M6) 📦

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-070** | 🔴 | ⬜ | **3–4 fertige Strecken** mit unterschiedlichen Themes (Ideen: Neon-City bei Nacht, Retro-Strand, Mecha-Fabrik, Weltraum-Highway) — jeweils mit Abkürzung, Gefahrenstelle und eigenem Musik-Track |
| **A-071** | 🔴 | ⬜ | **8+ Charaktere** über die drei Gewichtsklassen verteilt (Archetypen-Ideen: Mecha-Pilot, Magical Girl, mutierte Kampfschildkröte, Space-Bounty-Hunter, sprechendes Auto, Ninja, Barbaren-Prinz, Roboter-Katze) |
| **A-072** | 🟡 | ⬜ | **KI-Fahrer:** Waypoint-basierte Gegner füllen freie Slots auf 16 auf; 3 Schwierigkeitsgrade; nutzen Items; KEIN Speed-Cheating (Rubber-Banding nur über Items) |
| **A-073** | 🟡 | ⬜ | **Battle-Modus:** 2 Arenen, Ballon-System (3 Treffer = raus), Letzter gewinnt; nutzt vorhandenes Item-System |
| **A-074** | 🟢 | ⬜ | **Zeitfahren mit Geistern:** Solo-Modus, beste Runde als lokaler Ghost-Replay |
| **A-075** | 🟢 | ⬜ | **Statistik-Bildschirm** am Ende des LAN-Abends (meiste Siege, meiste Treffer, Pechvogel des Abends …) |

---

## Phase 8 — Polish & LAN-Generalprobe (M7) ✅

| ID | Prio | Status | Anforderung |
|---|---|---|---|
| **A-080** | 🔴 | ⬜ | **Release-Builds:** Windows- + Linux-Zip, startet auf frisch aufgesetztem Rechner ohne Installation/Abhängigkeiten; Versionsnummer im Hauptmenü sichtbar (Host prüft Versions-Match beim Join) |
| **A-081** | 🔴 | ⬜ | **Stabilitäts-Soak-Test:** 2 Stunden Dauerbetrieb mit 16 Teilnehmern (echte + KI + mehrere Instanzen) ohne Crash, Desync oder Memory-Leak |
| **A-082** | 🔴 | ⬜ | **Generalprobe mit der echten Gruppe:** Vollständiger LAN-Abend-Testlauf einige Wochen vor dem Event; alle gefundenen Bugs nach Schwere sortiert abarbeiten (Blocker vor Kosmetik) |
| **A-083** | 🔴 | ⬜ | **Bekannte-Probleme-Liste:** Nicht behobene Kleinigkeiten dokumentiert in `KNOWN_ISSUES.md` — bewusste Entscheidungen statt vergessener Bugs |
| **A-084** | 🟡 | ⬜ | **Gamepad-Kompatibilitätstest:** Alle Pads der Gruppe (Xbox, DualShock/DualSense, Switch Pro, 8BitDo …) einmal real durchgetestet |
| **A-085** | 🟢 | ⬜ | **Turnier-Hilfen:** Einfacher Cup-Modus-Export (Endstand als Screenshot/Textdatei) für die LAN-Rangliste |

---

## Querschnitts-Anforderungen (gelten ab der jeweils ersten betroffenen Phase, dauerhaft)

| ID | Prio | Anforderung |
|---|---|---|
| **Q-001** | 🔴 | **Gamepad first:** Jede neue Interaktion (Spiel UND Menü) ist vom ersten Tag an vollständig per Gamepad bedienbar; Tastatur als Fallback |
| **Q-002** | 🔴 | **Host-Autorität ohne Ausnahme:** Jede Spielzustands-Änderung läuft über den Host (siehe CLAUDE.md, „eiserne Regel") |
| **Q-003** | 🔴 | **Datengetriebenes Balancing:** Fahrverhalten, Item-Wahrscheinlichkeiten, Punktevergabe ausschließlich in `.tres`-Resources — nie im Code |
| **Q-004** | 🔴 | **Deterministische Logik ist GUT-getestet:** Rundenzählung, Platzierung, Item-Verteilung, Punktewertung haben Unit-Tests, bevor die Phase als fertig gilt |
| **Q-005** | 🔴 | **Multiinstanz-Pflichttest:** Jede Änderung an Netzwerk-Code oder replizierten Eigenschaften wird mit Host + min. 2 Clients verifiziert |
| **Q-008** | 🟡 | **Input-Provider-Pattern für Physik-Regressionstests:** Kart-Controller kapselt Eingaben hinter einer austauschbaren Schnittstelle (siehe CLAUDE.md), damit Topspeed/Boost/Beschleunigung headless per GUT gegen die Handling-Resource geprüft werden können — ersetzt nicht das manuelle Gegenspielen des Fahrgefühls |
| **Q-006** | 🔴 | **Urheberrecht:** Alle Charaktere, Namen, Musik und Assets sind Eigenkreationen oder nachweislich frei lizenziert — keine geschützten Originalfiguren, auch nicht als Platzhalter |
| **Q-007** | 🟡 | **60-FPS-Budget:** Neue Features/Assets dürfen die Ziel-Framerate auf dem Referenzgerät nicht unterschreiten |

---

## Bewusst NICHT im Scope (aus README übernommen)

- ❌ Anti-Cheat, Verschlüsselung, Account-System
- ❌ Internet-Matchmaking, Relay-Server, NAT-Punchthrough, Host-Migration
- ❌ Mobile-/Konsolen-Ports
- ❌ In-Game-Streckeneditor
