# 🏁 BattleRacer

**Ein LAN-Party-Kart-Racer im Comic-Stil für bis zu 16 Spieler** — inspiriert von Mario Kart 64, mit Charakteren im Stil der Anime- und Zeichentrickserien der 80er und 90er Jahre.

> Dieses Dokument ist die technische Grundlage für die Entwicklung. Es fasst die recherchierten Best Practices (Stand 2026) zusammen und legt die Architektur-Entscheidungen fest.

---

## 1. Vision

- **Spielgefühl:** Arcade-Kart-Racing wie Mario Kart 64 — leicht zu lernen, Drift-Boosts, Items, Chaos, Spaß in der Gruppe. Kein Simulations-Anspruch.
- **Grafik:** Moderner Comic-/Cel-Shading-Look (Toon-Shader, Outlines, kräftige Farben) statt N64-Low-Poly — die *Spielmechanik* orientiert sich am Klassiker, die Optik nicht.
- **Charaktere:** Eigene, originelle Figuren, die den Stil und die Archetypen der 80er/90er-Animes und -Zeichentrickserien aufgreifen (Mecha-Pilot, Magical Girl, Turtle-artiger Mutant, Space-Bounty-Hunter, sprechendes Auto …).
  ⚠️ **Wichtig:** Keine 1:1-Übernahme geschützter Charaktere (Son Goku, Sailor Moon, He-Man etc.) — auch bei einem Hobbyprojekt riskant, sobald es verteilt wird. Stattdessen *Hommagen* mit eigenem Namen und eigenem Design.
- **Zielplattform:** Windows- und Linux-PCs auf einer LAN-Party. Kein Internet-Matchmaking, kein Anti-Cheat, keine Accounts.
- **Spieler:** 1–16 Spieler über LAN, Bedienung primär per **Gamepad** (Tastatur als Fallback).

---

## 2. Technologie-Entscheidung: Engine

### ✅ Gewählt: **Godot 4.x** (aktuelle stabile Version, GDScript)

| Kriterium | Bewertung |
|---|---|
| Kosten / Lizenz | Komplett frei (MIT) — keine Gebühren, kein Vendor-Lock-in |
| Multiplayer | Eingebaute High-Level-Multiplayer-API (ENet/UDP) — für 2–16 Spieler im LAN ideal und ausdrücklich der empfohlene Sweet Spot |
| 3D + Stylized Rendering | Vulkan-Renderer, Cel-/Toon-Shading gut dokumentiert, viele fertige Shader |
| Gamepad | SDL-Gamecontroller-Datenbank eingebaut → Xbox-, PlayStation- und die meisten anderen Pads funktionieren out of the box |
| Lernkurve / Teamgröße | Leichtgewichtig, schnelle Iteration, ideal für Solo-/Hobby-Entwicklung |
| Export | Ein Klick für Windows + Linux, kleine Binaries, keine Installer nötig — perfekt für "Zip auf den LAN-Share legen" |

**Warum nicht Unity/Unreal?**
- *Unity*: Stärken liegen bei Mobile, großen Spielerzahlen und Cloud-Services (Unity Gaming Services) — brauchen wir alles nicht. Lizenz-/Runtime-Fee-Historie ist ein Risiko.
- *Unreal*: Grafisch top, aber schwergewichtig, C++-lastig und für ein Hobby-Kart-Spiel Overkill; Toon-Look ist in Unreal eher gegen den Strich gebürstet.

Quellen: [Godot vs Unity 2026 (rocketbrush)](https://rocketbrush.com/blog/godot-vs-unity), [Godot vs Unity für Indies (dev.to)](https://dev.to/linou518/godot-vs-unity-in-2026-which-engine-should-indie-developers-choose-50g4), [Engine-Vergleich 2026 (oceanviewgames)](https://oceanviewgames.co.uk/blog/posts/what-game-engine-is-right)

---

## 3. Netzwerk-Architektur (LAN, 16 Spieler)

### Grundmodell: **Listen-Server (Host = Spieler 1), autoritativer Server**

Ein Rechner auf der LAN hostet das Spiel und spielt selbst mit. Alle anderen verbinden sich als Clients. Im LAN gibt es kein NAT-/Port-Forwarding-Problem und Latenzen von < 5 ms — die Hauptprobleme von Internet-Netcode entfallen.

```
        ┌─────────────┐
        │  Host (P1)   │  ← autoritative Simulation (Physik, Items, Platzierung)
        │  Listen-     │
        │  Server      │
        └──────┬──────┘
    ENet/UDP   │   Snapshots (unreliable, 20–30 Hz)
   ┌─────┬─────┼─────┬─────┐
   │ P2  │ P3  │ ... │ P16 │  ← Clients senden nur Inputs
   └─────┴─────┴─────┴─────┘
```

### Best Practices, die wir umsetzen

| Technik | Zweck |
|---|---|
| **Server-autoritative Simulation** | Host berechnet Physik, Item-Treffer, Rundenzählung → keine Desyncs, ein einziger "Wahrheits-Zustand" |
| **Client-Side Prediction** für das *eigene* Kart | Eigene Eingaben wirken sofort (kein Input-Lag), Server korrigiert bei Abweichung (Reconciliation) |
| **Snapshot Interpolation** für *fremde* Karts | Fremde Karts werden ~100 ms in der Vergangenheit zwischen zwei Snapshots interpoliert → butterweich trotz Paketverlust |
| **Inputs statt Zustand senden** (Client → Server) | Clients schicken nur Lenkung/Gas/Drift/Item-Knopf → minimale Bandbreite, Host bleibt Autorität |
| **Unreliable UDP für Bewegung, Reliable für Events** | Positions-Snapshots dürfen verloren gehen (der nächste kommt eh), Item-Pickup/Treffer/Rundenende laufen über den Reliable-Kanal |
| **Fixed Tickrate** | Simulation mit fester Physik-Tickrate (60 Hz), Netzwerk-Snapshots mit 20–30 Hz — entkoppelt von der Framerate |
| **LAN-Discovery per UDP-Broadcast** | Host broadcastet "hier läuft ein Spiel" ins Subnetz → Clients zeigen Server-Liste, niemand muss IPs abtippen |

**Godot-konkret:** `ENetMultiplayerPeer` + High-Level-API (`MultiplayerSpawner`, `MultiplayerSynchronizer`, `@rpc`). Die eingebaute API ist laut Community-Benchmarks für 2–16 Spieler genau richtig dimensioniert; erst ab ~32 Spielern werden Bandbreite/CPU zum Thema. Sync-Intervall der `MultiplayerSynchronizer` bewusst auf ~20–30 Hz drosseln und clientseitig interpolieren, statt jeden Physik-Frame zu senden.

**Explizit NICHT nötig** (weil LAN + Freundesgruppe):
- ❌ Anti-Cheat, Verschlüsselung, Server-Validierung gegen Manipulation
- ❌ Relay-Server / NAT-Punchthrough / Matchmaking
- ❌ Lag-Kompensation für hohe Pings (LAN-Pings sind vernachlässigbar) — Prediction + Interpolation reichen völlig

Quellen: [Gabriel Gambetta: Fast-Paced Multiplayer](https://www.gabrielgambetta.com/entity-interpolation.html), [Valve: Source Multiplayer Networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking), [SnapNet: Snapshot Interpolation](https://snapnet.dev/blog/netcode-architectures-part-3-snapshot-interpolation/), [Godot High-Level Multiplayer Docs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html), [Godot 4 Multiplayer Best Practices (ziva.sh)](https://ziva.sh/blogs/godot-multiplayer)

---

## 4. Fahrphysik: Arcade-Kart

### Ansatz: **Raycast-basierter Kart-Controller auf `RigidBody3D`** — *nicht* `VehicleBody3D`

Best Practice für Arcade-Racer: Godots eingebautes `VehicleBody3D` ist auf realistische Autos ausgelegt und schwer auf "Mario-Kart-Gefühl" zu tunen. Stattdessen:

- **`RigidBody3D` + 4 Raycasts als Federung** (oder die noch einfachere "Kugel-Physik + Kart-Mesh obendrauf"-Methode): Die Physik fährt eine unsichtbare Kugel/Box, das sichtbare Kart wird nur optisch nachgeführt. So fühlt es sich sofort "arcadig" an und bleibt stabil.
- **Physik-Tickrate erhöhen** (120 Hz für die Fahrphysik), sonst wird Raycast-Federung bei hohen Geschwindigkeiten instabil.
- **Handling-Parameter datengetrieben** (Resource-Dateien pro Kart/Charakter): Topspeed, Beschleunigung, Lenkwinkel, Drift-Grip — so lassen sich Charakter-Klassen (leicht/mittel/schwer wie in MK64) rein über Daten balancen.

### Mario-Kart-64-Mechaniken (Muss-Liste)

- **Drift + Mini-Turbo:** Drift-Knopf, Funken-Stufen, Boost beim Lösen ("MT" — das Herzstück des MK64-Handlings)
- **Slipstream/Windschatten** (moderne Ergänzung, seit MK8 Standard)
- **Boost-Pads & Sprungschanzen** auf der Strecke
- **Items** mit positionsabhängiger Wahrscheinlichkeit (hinten = bessere Items → natürliches Rubber-Banding)
- **Rubber-Banding nur über Items**, nicht über KI-Speed-Hacks — fühlt sich fairer an
- **Rundenzählung über Checkpoints** (unsichtbare Trigger-Sequenz, verhindert Abkürzungs-Cheese und Falschrunden)
- **Respawn-System** (Lakitu-Äquivalent) beim Rausfallen: zurück zum letzten Checkpoint

Quellen: [KidsCanCode: Arcade-Style Car (Kugel-Methode)](https://kidscancode.org/godot_recipes/4.x/3d/3d_sphere_car/index.html), [Godot Easy Vehicle Physics (Raycast)](https://github.com/DAShoe1/Godot-Easy-Vehicle-Physics), [Godot Advanced Vehicle](https://github.com/Dechode/Godot-Advanced-Vehicle)

---

## 5. Grafik: Moderner Comic-Look

### Rendering-Stack

- **Cel-/Toon-Shading** für Charaktere und Karts: harte Licht-/Schatten-Bänder (2–3 Stufen), Rim-Light für "Anime-Glanz"
- **Outlines**: Inverted-Hull-Methode (zweites, invertiertes Mesh) für Charaktere; Screen-Space-Outline-Pass als Alternative für die ganze Szene
- **Handgemalte / flat-kolorierte Texturen** statt PBR-Realismus; kräftige, gesättigte Palette
- **Low-/Mid-Poly-Assets** mit starken Silhouetten — liest sich bei hoher Geschwindigkeit besser und hält die Performance bei 16 Karts + Splitscreen locker bei 60+ FPS
- **Stilisierte VFX**: Comic-Speedlines beim Boost, "POW!"-Sprites bei Item-Treffern, Cell-Shaded-Explosionen — hier darf die 80er/90er-Ästhetik (Retro-Schriftzüge, VHS-Vibes im Menü, Synthwave-Soundtrack) voll durchschlagen

### Asset-Pipeline

- **Blender** für Modelle/Rigs/Animationen → glTF-Export nach Godot
- **Git LFS** für Binärdateien (Modelle, Texturen, Audio) von Anfang an einrichten
- Charaktere: ein gemeinsames Basis-Rig, damit Fahr-/Jubel-/Treffer-Animationen wiederverwendbar sind

Quellen: [Godot 4 Cel-Shading Guide (supermatrix.studio)](https://supermatrix.studio/blog/creating-a-stylized-3D-cel-shader-in-godot-4-from-scratch), [Complete Cel Shader für Godot 4](https://godotshaders.com/shader/complete-cel-shader-for-godot-4/), [Stylized Toon Shaders (baldurgames)](https://baldurgames.com/posts/stylized-shaders-godot)

---

## 6. Eingabe: Gamepad first

- Godot nutzt die **SDL-Gamecontroller-Datenbank** → gängige Pads (Xbox, DualShock/DualSense, Switch Pro, 8BitDo) werden ohne Konfiguration erkannt
- **Input-Map über Aktionen** (`accelerate`, `brake`, `steer`, `drift`, `use_item`, `look_back`) — nie Tasten hart verdrahten
- Analoge Lenkung mit einstellbarer Deadzone; Tastatur als vollwertiger Fallback
- **Lokaler Splitscreen (2–4 Spieler pro PC)** als Stretch Goal: Godot unterstützt mehrere Gamepads pro Gerät (`device`-Index) und mehrere Viewports — auf einer LAN-Party Gold wert, wenn jemand keinen Rechner mitbringt

---

## 7. Spielmodi (Scope für Version 1)

| Modus | Beschreibung | Priorität |
|---|---|---|
| **Grand Prix / Einzelrennen** | 3 Runden, 4–16 Fahrer, Punktewertung über mehrere Strecken | ⭐ Muss |
| **Battle-Modus** | Ballon-Kampf in Arenen (der MK64-LAN-Klassiker) | ⭐⭐ Soll |
| **Zeitfahren + Geister** | Solo-Training zwischen den LANs, lokale Ghost-Replays | ⭐⭐⭐ Kann |
| **KI-Fahrer** | Füllen freie Slots auf, einfache Waypoint-KI mit 3 Schwierigkeitsgraden | ⭐⭐ Soll |

**Items (Startset, ~8 Stück reichen):** Panzer-Äquivalent (gerade/zielsuchend), Bananen-Äquivalent, Boost, Unverwundbarkeits-Stern-Äquivalent, Blitz, Fake-Itembox, Geist (Item klauen) — jeweils mit eigenem 80s/90s-Skin (z. B. zielsuchende "Mecha-Drohne" statt rotem Panzer).

---

## 8. Projektstruktur (geplant)

```
BattleRacer/
├── project.godot
├── addons/                  # Plugins (z. B. Debug-Tools)
├── src/
│   ├── core/                # Game-Loop, Szenen-Management, Settings
│   ├── net/                 # Lobby, LAN-Discovery, Snapshots, Prediction
│   ├── kart/                # Kart-Controller, Handling-Resources
│   ├── items/               # Item-Logik (eine Szene/Klasse pro Item)
│   ├── track/               # Checkpoints, Item-Boxen, Boost-Pads, Respawn
│   ├── ai/                  # Waypoint-KI
│   └── ui/                  # Menüs, HUD, Lobby-Screen, Ergebnis-Screen
├── assets/
│   ├── characters/          # Modelle, Rigs, Animationen (Git LFS)
│   ├── karts/
│   ├── tracks/
│   ├── shaders/             # Toon-Shader, Outline, VFX
│   ├── audio/               # Musik (Synthwave!), SFX
│   └── ui/
├── tracks/                  # Strecken-Szenen (.tscn)
└── tests/                   # GUT-Unit-Tests für Kernlogik
```

---

## 9. Roadmap / Meilensteine

1. **M1 — Fahrgefühl (der wichtigste Meilenstein):** Ein Kart auf einer Testfläche, Gamepad-Steuerung, Drift + Mini-Turbo. *So lange iterieren, bis es sich gut anfühlt — alles andere baut darauf auf.*
2. **M2 — Netzwerk-Skelett:** Lobby, LAN-Discovery, 16 Karts synchronisiert (Prediction + Interpolation), Test mit mehreren Rechnern
3. **M3 — Rennen:** Erste echte Strecke, Checkpoints, Runden, Platzierung, Ziel-Wertung, Respawn
4. **M4 — Items & Chaos:** Itemboxen, 4–5 Items, Treffer-Feedback
5. **M5 — Comic-Look:** Toon-Shader, Outlines, erster eigener Charakter, HUD im 80s/90s-Stil
6. **M6 — Content & Polish:** 3–4 Strecken, 8+ Charaktere, Battle-Modus, Musik/SFX, Menü-Polish
7. **M7 — LAN-Generalprobe:** Playtest mit der echten Gruppe, Bugfixing, Balancing

**Qualitätssicherung ("technisch rund, keine großen Bugs"):**
- Ab M2 regelmäßig mit mehreren Instanzen/Rechnern testen (Godot kann mehrere Debug-Instanzen gleichzeitig starten: *Debug → Run Multiple Instances*)
- Unit-Tests (GUT-Framework) für deterministische Kernlogik: Rundenzählung, Item-Verteilung, Platzierungsberechnung
- Vor jeder LAN: ein "Release-Kandidat"-Build als Zip für Windows + Linux, auf frischen Rechnern getestet

---

## 10. Referenzprojekte zum Lernen

- **[SuperTuxKart](https://supertuxkart.net/)** — Open-Source-Kart-Racer mit LAN-Multiplayer; Gold wert, um Item-Balancing und Netcode-Entscheidungen nachzulesen
- **[Godot Easy Vehicle Physics](https://github.com/DAShoe1/Godot-Easy-Vehicle-Physics)** — Raycast-Kart als Startpunkt/Referenz
- **[Gabriel Gambettas Netcode-Serie](https://www.gabrielgambetta.com/client-server-game-architecture.html)** — der Standard-Lesestoff für Prediction/Interpolation

---

## Lizenz

Noch festzulegen (Vorschlag: MIT für den Code; Assets separat betrachten).
