# Enemy: Tempest Reborn

Dieses Repository buendelt die aktuelle AROS/UAE-Kompatibilitaetsarbeit fuer
Enemy: Tempest Reborn. Enthalten sind die fuer dieses Projekt bereitgestellten
originalen Enemy-ADFs, die verwendeten AROS-ROMs, reproduzierbare
ADF-Patch-Skripte, vorbereitete gepatchte Enemy-ADF-Varianten,
FS-UAE-Konfigurationen und der erste hostseitige Flutter-Launcher.

## Aktueller Stand

- Enemy V2 startet unter AROS, wenn als A1200 mit 2 MB Chip RAM und 2 MB Fast
  RAM ausgefuehrt.
- Der sauberste getestete Pfad nutzt eine Enemy-ADF-Variante, in der der Helper
  `c/closewb` seine Vorbereitung und Stack-Bereinigung beibehaelt, aber den
  einzelnen `CloseWindow()`-Aufruf durch zwei 68k-NOP-Instruktionen ersetzt.
- Mit diesem `closewb`-NOP-Patch laesst sich die Intro per Maus/Feuer abbrechen,
  und das Hauptmenü rendert korrekt.
- Enemy 1 ist in getrennte Startziele fuer Spiel und Intro aufgeteilt. Das
  Spielziel ueberspringt das Intro; das Intro-Ziel kehrt nach Eingabe/Ende zum
  Host-Launcher zurueck.
- Enemy 1/2 DE/EN nutzen vorbereitete Level-Unlock-Images: Im Menue steht
  weiter Level 1, die hoechste Levelauswahl ist aber ohne Passwort freigeschaltet.
- Der Launcher startet standardmaessig im Fullscreen. Fensteraufloesungen und
  2x/3x/4x-Pruefungen bleiben als Debug-/Messpfad erhalten, sind aber nicht der
  normale Spielerpfad.

Siehe:

- `docs/CLOSEWB_NOP_FIX_DE.md`
- `docs/CLOSEWB_NOP_FIX_EN.md`
- `docs/TECHNICAL_ARTIFACTS.md`
- `docs/CLEAN_CLONE_RELEASE_TEST.md`
- `LICENSES.md`

## Schnelltest

Host-Launcher unter Linux starten:

```bash
cd launcher
flutter run -d linux
```

Oder ein Profil direkt mit FS-UAE starten:

```text
configs/fs-uae/tempestreborn_enemy1_de_a1200.fs-uae
```

Die Tempest-Reborn-Konfigurationen nutzen relative Pfade ab Repository-Wurzel.
Der Launcher schreibt Runtime-Konfigurationen nach `work/launcher-runtime/` und
setzt die gewaehlten Anzeige-/Aspect-/Filter-/Steuerungsoptionen vor dem
FS-UAE-Start.
Vor dem Start prueft der Launcher `fs-uae`, das gewaehlte Basisprofil, die
AROS-ROMs und die benoetigten Enemy-Diskettenimages. Fehlende Laufzeitdateien
werden im Statusbereich des Launchers gemeldet.

Aktuelle Launcher-Einstellungen:

- `Anzeige`: `Fullscreen` oder `Window`
- `Aspect`: `4:3`, `Pixel` oder `Stretch`
- `Pixel`: `Sharp`, `Smooth` oder `CRT`
- `Steuerung`: `Keyboard`, `Gamepad` oder `Joystick`

Das Launcher-Menue ist zweisprachig. Bei Umschaltung auf Englisch wechseln auch
die Menue-Texte.

## Verifikation

Aktuelle lokale Pruefungen:

```bash
cd launcher
flutter analyze
flutter test
flutter build linux
```

Alle drei Pruefungen waren am 2026-07-01 nach Einbau der Launcher-Preflight-
Checks erfolgreich.
