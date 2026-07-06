# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projektüberblick

**BattleRacer** ist ein LAN-Party-Kart-Racer (Mario-Kart-64-Mechanik, moderner Comic-Look) für bis zu 16 Spieler, entwickelt mit **Godot 4.x** und **GDScript**. Zielplattformen: Windows + Linux. Kein Internet-Matchmaking, kein Anti-Cheat — reines LAN-Spiel für eine Freundesgruppe.

Die `README.md` ist das verbindliche Konzept- und Architekturdokument: Sie legt Engine-Wahl, Netzwerk-Architektur, Physik-Ansatz, Art-Direction und die Meilenstein-Roadmap (M1–M7) fest. Bei Architektur-Fragen zuerst dort nachschlagen; Änderungen an Grundsatzentscheidungen gehören auch dort hinein.

**Aktueller Stand:** Konzeptphase. Das Repo enthält noch kein Godot-Projekt (`project.godot` existiert nicht). Der erste Implementierungs-Meilenstein ist M1 (Fahrgefühl): ein Kart auf einer Testfläche mit Gamepad-Steuerung, Drift und Mini-Turbo. Beim Anlegen des Godot-Projekts: `project.godot` ins Repo-Root, Struktur wie in README Abschnitt 8.

## Kommandos

Godot wird als CLI-Binary `godot` vorausgesetzt (Godot 4.x, Standard-Build mit .NET ist nicht nötig — reines GDScript-Projekt).

```bash
# Assets importieren (nach frischem Clone / neuen Assets nötig, sonst schlagen headless-Läufe fehl)
godot --headless --import

# Spiel starten (Hauptszene)
godot

# Bestimmte Szene starten (z. B. Physik-Testfläche)
godot res://tracks/test_area.tscn

# Alle Unit-Tests ausführen (GUT-Framework, liegt unter addons/gut/)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

# Einzelne Testdatei ausführen
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_lap_counter.gd -gexit

# Formatierung & Lint (gdtoolkit: pip install "gdtoolkit==4.*")
gdformat src/ tests/
gdlint src/ tests/

# Export-Builds (Export-Presets in export_presets.cfg)
godot --headless --export-release "Windows" build/battleracer-windows.exe
godot --headless --export-release "Linux" build/battleracer-linux.x86_64
```

**Multiplayer lokal testen:** Im Godot-Editor *Debug → Customize Run Instances* → mehrere Instanzen aktivieren (eine als Host, weitere als Clients). Netzwerk-Code niemals nur mit einer Instanz "getestet" nennen — jede Änderung an `src/net/` oder an replizierten Eigenschaften mit mindestens Host + 2 Clients verifizieren.

## Architektur

### Netzwerk (src/net/) — das fehleranfälligste Subsystem

- **Listen-Server, Host-autoritativ:** Ein Spieler hostet. Der Host simuliert die einzige "wahre" Spielwelt: Physik aller Karts, Item-Treffer, Rundenzählung, Platzierung. Clients senden ausschließlich Inputs (Lenkung, Gas, Drift, Item-Knopf), nie Zustand.
- **Client-Side Prediction nur fürs eigene Kart:** Der lokale Spieler simuliert sein eigenes Kart sofort und wird bei Abweichung vom Host-Snapshot korrigiert (Reconciliation).
- **Snapshot-Interpolation für fremde Karts:** Fremde Karts werden ~100 ms in der Vergangenheit zwischen Snapshots interpoliert, nie direkt auf den letzten Snapshot gesetzt.
- **Kanäle:** Bewegungs-Snapshots unreliable (Verlust ist okay, der nächste kommt), Spiel-Events (Item-Pickup, Treffer, Rundenende, Zieleinlauf) reliable.
- **Tickraten entkoppelt:** Fahrphysik 120 Hz (`physics/common/physics_ticks_per_second`), Netzwerk-Snapshots 20–30 Hz. Snapshot-Rate nie an die Framerate koppeln.
- **Godot-Bausteine:** `ENetMultiplayerPeer` + High-Level-API (`MultiplayerSpawner`, `MultiplayerSynchronizer`, `@rpc`). LAN-Discovery über UDP-Broadcast (Host kündigt sich im Subnetz an, Clients zeigen eine Serverliste).

**Eiserne Regel:** Jede Funktion, die Spielzustand verändert (Treffer, Punkte, Runden, Item-Vergabe), prüft die Autorität (`multiplayer.is_server()` bzw. `is_multiplayer_authority()`) und läuft nur auf dem Host; Clients bekommen das Ergebnis repliziert. Keine Ausnahmen "weil es lokal funktioniert" — genau daraus entstehen Desyncs.

### Fahrphysik (src/kart/)

- **Raycast-Kart auf `RigidBody3D`** — bewusst NICHT Godots `VehicleBody3D` (auf Realismus ausgelegt, lässt sich nicht auf Arcade-Gefühl tunen). Die Physik fährt einen unsichtbaren Körper, das sichtbare Kart-Mesh wird rein optisch nachgeführt (Neigung, Drift-Winkel, Federung).
- **Handling ist datengetrieben:** Alle Tuning-Parameter (Topspeed, Beschleunigung, Lenkwinkel, Drift-Grip, Gewichtsklasse) leben in `Resource`-Dateien (`.tres`) pro Kart/Charakter, nicht als Konstanten im Code. Balancing-Änderungen dürfen nie Code-Änderungen erfordern.
- Drift + Mini-Turbo (Funken-Stufen, Boost beim Lösen) ist das Herzstück des Handlings — Änderungen daran immer manuell mit Gamepad gegenspielen, nicht nur Tests laufen lassen.

### Strecken & Rennlogik (src/track/)

- **Rundenzählung über Checkpoint-Sequenzen** (unsichtbare Trigger in fester Reihenfolge). Eine Runde zählt nur, wenn alle Checkpoints in Reihenfolge passiert wurden — verhindert Abkürzungs-Exploits und Falschzählung.
- **Respawn:** Beim Rausfallen zurück zum zuletzt passierten Checkpoint.
- Strecken sind eigenständige Szenen unter `tracks/`, die die Bausteine aus `src/track/` (Checkpoints, Itemboxen, Boost-Pads, Startaufstellung) instanziieren.

### Items (src/items/)

- Ein Item = eine Szene + Skript unter `src/items/`. Item-Vergabe ist positionsabhängig (hinten = bessere Items) — das ist das einzige Rubber-Banding-Instrument; keine Speed-Anpassungen der KI oder Karts.
- Item-Logik (wer wird getroffen, was passiert) läuft ausschließlich auf dem Host.

### Eingabe

- Ausschließlich über Input-Map-Aktionen (`accelerate`, `brake`, `steer_left`, `steer_right`, `drift`, `use_item`, `look_back`) — niemals Tasten/Buttons hart im Code abfragen. Gamepad ist das primäre Eingabegerät, Tastatur vollwertiger Fallback.

## Code-Konventionen (GDScript)

- **Statische Typisierung ist Pflicht** — für Variablen, Parameter und Rückgabetypen (`var speed: float = 0.0`, `func apply_boost(strength: float) -> void:`). Untypisierter Code gilt als Fehler, `gdlint` läuft vor jedem Commit.
- Benennung nach offiziellem GDScript-Styleguide: Dateien/Ordner/Funktionen/Variablen `snake_case`, Klassen (`class_name`) `PascalCase`, Konstanten `SCREAMING_SNAKE_CASE`, Signale in Vergangenheitsform (`lap_completed`, `item_used`).
- Kommunikation zwischen Systemen über **Signale**, nicht über direkte Node-Pfad-Zugriffe quer durch den Szenenbaum (`get_node("../../..")` ist verboten).
- Szenen klein und einzeln instanzierbar halten: Ein Kart, ein Item, ein Checkpoint muss isoliert in einer Testszene funktionieren.
- Magic Numbers fürs Gameplay gehören in `Resource`-Dateien oder exportierte Variablen (`@export`), nicht ins Skript.

## Tests & Verifikation

- **GUT-Tests unter `tests/`** für deterministische Kernlogik: Rundenzählung, Checkpoint-Sequenzen, Item-Verteilung, Platzierungsberechnung, Punktewertung. Diese Logik so schreiben, dass sie ohne laufende Szene testbar ist (reine Klassen/Funktionen, Physik und Rendering entkoppelt).
- Fahrgefühl und Netzwerkverhalten sind **nicht** unit-testbar: Handling-Änderungen mit Gamepad gegenspielen, Netzwerk-Änderungen mit mehreren Instanzen (Host + min. 2 Clients) verifizieren.
- Vor jedem Push: `gdlint` + kompletter GUT-Lauf grün.

## Assets

- Binärdateien (Modelle, Texturen, Audio) laufen über **Git LFS** — beim ersten Asset-Commit `.gitattributes` entsprechend einrichten (`*.glb`, `*.png`, `*.ogg`, `*.blend` etc.).
- 3D-Assets kommen als glTF (`.glb`) aus Blender. Charaktere teilen sich ein gemeinsames Basis-Rig, damit Animationen (Fahren, Jubel, Treffer) wiederverwendbar sind.
- **Urheberrecht:** Charaktere sind eigene Designs als Hommage an 80er/90er-Anime-Archetypen — keine geschützten Originalfiguren oder deren Namen verwenden, auch nicht in Platzhalter-Assets oder Dateinamen.
