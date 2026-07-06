# Tests (GUT)

Dieses Projekt nutzt [GUT](https://github.com/bitwes/Gut) für deterministische Unit-Tests (Rundenzählung, Checkpoint-Sequenzen, Item-Verteilung, Platzierung — siehe CLAUDE.md).

**GUT ist noch nicht installiert** (A-003 offen). Einmalig im Godot-Editor nachholen:

1. Godot-Editor öffnen → Tab **AssetLib**
2. Nach "Gut" suchen → **Gut - Godot Unit Testing** installieren
3. Editor neu starten, danach ist `addons/gut/` vorhanden und muss unter **Project → Project Settings → Plugins** aktiviert werden

Danach Tests wie in CLAUDE.md beschrieben ausführen:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Testdateien folgen der Konvention `test_<name>.gd` und erben von `GutTest`.
