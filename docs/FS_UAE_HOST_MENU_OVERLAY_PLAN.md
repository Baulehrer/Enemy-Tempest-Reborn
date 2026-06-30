# Enemy: Tempest Reborn FS-UAE Host Menu / Overlay Plan

## Ziel

Enemy soll in einem angepassten FS-UAE-Fork wie ein eigenstaendiges Paket
starten. Der Spieler soll zuerst ein Host-seitiges Hauptmenue sehen und dort
Spiel, Sprache, Intro, Grafik und Steuerung waehlen koennen. Im Spiel soll eine
Taste die Emulation pausieren und ein Einstellungs-Overlay oeffnen.

## Design-Skill

Fuer das Launcher-Redesign wurde lokal ein projektspezifischer Codex-Skill
angelegt:

```text
~/.codex/skills/enemy-launcher-design
```

Er basiert auf `frontend-design` aus `anthropics/skills` und ist unter Apache
License 2.0 abgeleitet. Der Skill fokussiert das Design auf Enemy: Tempest
Reborn, Retro-Amiga/AROS-Anmutung, Flutter-Launcher, Known-Good-Profile und
spaetere FS-UAE-Overlay-Settings.

Hinweis: Codex muss neu gestartet werden, damit neu installierte Skills in der
Skill-Liste automatisch auftauchen.

Es wird kein Amiga-seitiges Startmenue gebaut. Auswahl, Pause und Einstellungen
bleiben auf Host-Seite, weil nur FS-UAE selbst Emulatoroptionen wie Skalierung,
Filter, Vollbild, Eingabegeraete und Neustart sauber steuern kann.

## Hauptmenue

Das Host-Hauptmenue erscheint vor dem Start der Emulation und enthaelt diese
festen Eintraege:

- `Enemy 1 DE`
- `Enemy 1 EN`
- `Enemy 2 DE`
- `Enemy 2 EN`
- `Intro DE`
- `Intro EN`
- `Einstellungen`
- `Beenden`

Wichtige Regel:

- `Enemy 1 DE` und `Enemy 1 EN` starten direkt das Spiel ohne Intro.
- Das Intro ist nur ueber die separaten Menueeintraege `Intro DE` und `Intro EN`
  erreichbar.
- Ein Wechsel zwischen Spiel, Sprache und Intro darf die Emulation neu starten.

## Medien und Boot-Profile

Die Original-ADFs liegen unter `assets/adf/` und bleiben unveraendert:

- `ENEMY1_V2_DE_A.adf`
- `ENEMY1_V2_DE_B.adf`
- `ENEMY1_V2_EN_A.adf`
- `ENEMY1_V2_EN_B.adf`
- `ENEMY2_V2_DE_A.adf`
- `ENEMY2_V2_DE_B.adf`
- `ENEMY2_V2_EN_A.adf`
- `ENEMY2_V2_EN_B.adf`

Fuer jedes Host-Menueziel gibt es ein internes Preset:

- `enemy1_de_game`
- `enemy1_en_game`
- `enemy2_de_game`
- `enemy2_en_game`
- `enemy1_de_intro`
- `enemy1_en_intro`

Die Presets laden jeweils Laufwerk 0 und 1:

- `enemy1_de_game`: Enemy 1 DE Disk A/B, Spielstart ohne Intro
- `enemy1_en_game`: Enemy 1 EN Disk A/B, Spielstart ohne Intro
- `enemy2_de_game`: Enemy 2 DE Disk A/B
- `enemy2_en_game`: Enemy 2 EN Disk A/B
- `enemy1_de_intro`: Enemy 1 DE Disk A/B, nur Intro-Pfad
- `enemy1_en_intro`: Enemy 1 EN Disk A/B, nur Intro-Pfad

Die bereits gepruefte AROS-Konfiguration bleibt die Standardbasis:

- Amiga-Modell: A1200
- Chip RAM: 2 MB
- Fast RAM: 2 MB
- Slow RAM: 0 MB
- Kickstart: AROS ROM + AROS EXT ROM
- Floppy Speed: Turbo (`floppy_drive_speed = 0`)
- Floppy Sounds: aus (`floppy_drive_volume = 0`, Drive-Sounds `off`)
- Writable Floppies: aus

Slow RAM bleibt im Standardprofil bewusst aus. 2 MB Fast RAM ist fuer A1200
unkritischer und nuetzlicher; Slow RAM kann spaeter als separate
Kompatibilitaetsvariante getestet werden, falls ein Spiel oder Loader davon
profitiert.

## No-Intro-Regel fuer Enemy 1

Enemy 1 soll beim Spielstart nicht mehr ueber das Intro laufen. Der No-Intro-Pfad
wird reproduzierbar als ADF-/Boot-Patch umgesetzt, nicht durch simulierte
Mausklicks oder Tastendruecke.

Vorgehen:

1. Startup-Pfad auf Disk A fuer DE und EN analysieren.
2. Intro-Aufruf eindeutig identifizieren.
3. Spielstart direkt auf den Hauptprogramm-Pfad umbiegen.
4. Patch fuer DE und EN getrennt erzeugen.
5. Original-ADF, gepatchte ADF, Offset, alte Bytes, neue Bytes und SHA256 in
   einem Manifest dokumentieren.
6. Gepatchte ADFs separat ablegen, Original-ADFs nicht veraendern.

Fuer Enemy 1 DE wird die bereits erfolgreiche `closewb`-NOP-Aenderung als
Pflichtbestandteil des AROS-Spielstarts behandelt. Fuer Enemy 1 EN wird dieselbe
Art Fix nur nach separater Pruefung uebernommen.

## FS-UAE-Konfigurationsoptionen

Neue Enemy-spezifische Optionen:

```ini
enemy_launcher = 1
enemy_target = enemy1|enemy2|intro
enemy_language = de|en
enemy_preset = enemy1_de_game|enemy1_en_game|enemy2_de_game|enemy2_en_game|enemy1_de_intro|enemy1_en_intro
enemy_overlay_hotkey = f12
enemy_autostart = 1
enemy_skip_intro = 0|1
enemy_display = fullscreen|window
enemy_aspect = 4_3|pixel|stretch
enemy_filter = nearest|linear|hq2x|hq3x|xbrz|crt
enemy_control_profile = keyboard|gamepad|joystick
```

Defaults:

```ini
enemy_launcher = 1
enemy_overlay_hotkey = f12
enemy_display = fullscreen
enemy_aspect = 4_3
enemy_filter = nearest
enemy_control_profile = keyboard
```

## Pause-Overlay

`F12` ist der Standard-Hotkey.

Verhalten:

- Wenn die Emulation laeuft, pausiert `F12` die Emulation und oeffnet das
  Overlay.
- Wenn das Overlay offen ist, schliesst `F12` das Overlay und setzt die Emulation
  fort.
- Waehrend der Pause duerfen Spiel, Audio und emulierte Zeit nicht weiterlaufen.

Overlay-Eintraege:

- `Fortsetzen`
- `Grafik`
- `Steuerung`
- `Sound`
- `Zurueck zum Enemy-Hauptmenue`
- `Neustart`
- `Beenden`

Live aenderbar:

- Anzeige: `Fullscreen`, `Window`
- Seitenverhaeltnis: `4:3`, `Pixel Perfect`, `Stretch`
- Filter: `Nearest`, `Linear`, `hq2x`, `hq3x`, `xBRZ`, `CRT`
- Vollbild/Fenster
- Lautstaerke
- Steuerungsprofil, falls das aktive Eingabegeraet verfuegbar ist

Neustart erforderlich:

- Enemy 1 gegen Enemy 2
- Deutsch gegen Englisch
- Intro gegen Spiel
- ADF-Satz wechseln
- Amiga-Modell, RAM oder Kickstart aendern

## Implementierung im FS-UAE-Fork

Vorhandene FS-UAE-Strukturen werden erweitert, nicht ersetzt:

- Menue-API: `libfsemu/src/emu/menu.c`
- Input-Actions: `src/fs-uae/input.c`
- Pause/Mainloop: `src/fs-uae/main.c`
- Rendering/Scaling: libfsemu Video-/Render-Pfad

Umsetzungsschritte:

1. Enemy-Launcher-Modus einbauen, der vor dem Emulationsstart ein Host-Menue
   zeigt.
2. Preset-Auswahl in konkrete FS-UAE-Konfiguration uebersetzen.
3. ADF-Pfade aus `enemy_preset` ableiten und Laufwerke 0/1 setzen.
4. `F12` als Enemy-Overlay-Hotkey registrieren.
5. Overlay-Oeffnen an Pause-Funktion koppeln.
6. Grafikoptionen zuerst auf vorhandene FS-UAE-Optionen mappen.
7. Steuerungsprofile als feste, testbare Presets definieren.
8. Einstellungen persistent speichern und beim naechsten Start laden.

## Steuerungsprofile

Erste Zielprofile:

- `keyboard`: Cursor-Tasten fuer Richtung, rechte Strg-Taste oder Space fuer
  Feuer, zusaetzlicher Start/Fire-Key fuer Menues.
- `gamepad`: D-Pad/Stick fuer Richtung, Button 1 fuer Feuer, Start fuer Overlay
  oder Pause nur optional.
- `joystick`: echtes Joystick-Geraet an Amiga-Port 1.

Die bekannte Beobachtung wird als Testfall aufgenommen: Tastaturbewegung
funktioniert, aber Feuer muss bisher teilweise ueber den Joystick kommen. Das
Keyboard-Profil ist erst fertig, wenn der Spieler vom Enemy-Hauptmenue ohne
echten Joystick ins Level starten kann.

## Testplan

### Known-Good-Basis

Stand 2026-06-30 sind die sechs aktuellen Launcher-Ziele mit den
Tempest-Reborn-A1200-Profilen sichtgeprueft:

- `Enemy 1 DE`: startet direkt ins Spiel ohne Intro.
- `Enemy 1 EN`: startet direkt ins Spiel ohne Intro.
- `Enemy 2 DE`: startet problemlos.
- `Enemy 2 EN`: startet problemlos.
- `Intro DE`: startet das Intro und beendet FS-UAE per Eingabe.
- `Intro EN`: startet das Intro und beendet FS-UAE per Eingabe.

Details und Reproduktionspfade stehen in
`docs/TEMPEST_REBORN_KNOWN_GOOD_PROFILES.md`.

Hauptmenue:

- Alle sechs Startziele sind sichtbar.
- Jeder Eintrag laedt die korrekten A/B-ADFs.
- `Einstellungen` laesst Grafik und Steuerung aendern.
- `Beenden` schliesst sauber.

Enemy 1 Spielstart:

- `Enemy 1 DE` erreicht ohne Intro das Spiel-/Hauptmenue.
- `Enemy 1 EN` erreicht ohne Intro das Spiel-/Hauptmenue.
- Kein Mausklick und kein Feuerknopf ist noetig, um das Intro zu ueberspringen.
- DE-Variante nutzt den geprueften `closewb`-NOP-Fix.

Intro:

- `Intro DE` startet das deutsche Intro.
- `Intro EN` startet das englische Intro.
- Intro-Abbruch per Maus/Feuer bleibt moeglich.

Overlay:

- `F12` pausiert und oeffnet das Overlay.
- `F12` setzt fort.
- Spiel und Audio laufen waehrend Pause nicht weiter.
- `Zurueck zum Enemy-Hauptmenue` fuehrt zu einem kontrollierten Neustart in den
  Launcher.

Grafik:

- `1x`, `2x`, `3x`, `4x` funktionieren ohne verschobene Pixel.
- Aspect-Ratio-Modi schneiden HUD und Text nicht ab.
- Filterwechsel crasht nicht.
- Schrift bleibt in Menues und Code-Eingabe lesbar.

Steuerung:

- Keyboard-Profil kann Intro abbrechen, Menue bedienen und Level starten.
- Gamepad-Profil kann dieselben Schritte.
- Joystick-Profil bleibt als Referenz nutzbar.

Regression:

- Enemy 1 DE AROS A1200 2MB mit `closewb`-NOP erreicht Hauptmenue und Level.
- Diskettenzugriffe bleiben unveraendert.
- Original-ADFs bleiben als Referenz startbar.

## Definition of Done

Der Host-Menue-/Overlay-Schritt ist fertig, wenn:

- FS-UAE mit `enemy_launcher = 1` direkt ins Enemy-Hauptmenue startet.
- Alle Spiel-/Sprach-/Intro-Ziele funktionieren.
- Enemy 1 DE und EN ohne Intro starten.
- `F12` pausiert und zeigt das Overlay.
- Grafik- und Steuerungsoptionen mindestens als erste Presets funktionieren.
- Alle erzeugten ADF-Patches mit Manifest reproduzierbar dokumentiert sind.
- Die bisherigen AROS-Erfolgspfade nicht regressieren.
