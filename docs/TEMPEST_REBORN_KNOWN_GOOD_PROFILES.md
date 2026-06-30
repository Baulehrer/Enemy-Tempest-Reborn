# Enemy: Tempest Reborn Known-Good Profiles

Stand: 2026-06-30

## Ergebnis

Die aktuelle AROS-/FS-UAE-Basis gilt fuer die sechs Launcher-Ziele als
spielbar beziehungsweise startfaehig:

| Ziel | Config | Ergebnis |
| --- | --- | --- |
| Enemy 1 DE | `configs/fs-uae/tempestreborn_enemy1_de_a1200.fs-uae` | Sichtgeprueft: startet direkt ins Spiel ohne Intro |
| Enemy 1 EN | `configs/fs-uae/tempestreborn_enemy1_en_a1200.fs-uae` | Sichtgeprueft: startet direkt ins Spiel ohne Intro |
| Enemy 2 DE | `configs/fs-uae/tempestreborn_enemy2_de_a1200.fs-uae` | Sichtgeprueft: startet problemlos |
| Enemy 2 EN | `configs/fs-uae/tempestreborn_enemy2_en_a1200.fs-uae` | Sichtgeprueft: startet problemlos |
| Intro DE | `configs/fs-uae/tempestreborn_intro_de_a1200.fs-uae` | Sichtgeprueft: Intro startet, Eingabe beendet FS-UAE |
| Intro EN | `configs/fs-uae/tempestreborn_intro_en_a1200.fs-uae` | Sichtgeprueft: Intro startet, Eingabe beendet FS-UAE |

Der automatische Smoke-Test-Lauf vom 2026-06-30 liegt unter:

```text
work/launcher-smoke/20260630T203830+0200
```

Die Spielprofile wurden im automatischen Lauf nach Zeitlimit beendet. Die
Intro-Profile wurden durch simulierte Eingabe beendet und kehrten dadurch zum
Host-Kontext zurueck. Einzelne automatische Screenshots der Spielprofile trafen
schwarze Zwischenframes zwischen Sequenzen; das wurde durch manuelle
Sichtpruefung als Timing-Artefakt bewertet, nicht als Boot- oder
Spielstartfehler.

## Standardbasis

Alle sechs Known-Good-Profile verwenden:

- FS-UAE mit A1200-Modell
- AROS ROM plus AROS EXT ROM
- 2 MB Chip RAM
- 2 MB Fast RAM
- 0 MB Slow RAM
- Turbo-Floppy (`floppy_drive_speed = 0`)
- Laufwerksgeraeusche aus
- schreibgeschuetzte Floppy-Images

## ADF-Varianten

Die Original-ADFs unter `assets/adf/` bleiben unveraendert. Die Launcher-Profile
verwenden abgeleitete Images unter `work/kickstart-deps/patches/`:

- Enemy 1 Game DE/EN: `closewb`-NOP, No-Intro-Bootpfad, Level-Unlock
- Enemy 1 Intro DE/EN: Intro-only-Bootpfad
- Enemy 2 Game DE/EN: `closewb`-NOP, Level-Unlock

Der `closewb`-NOP ist ein Patch am Enemy-ADF, nicht an AROS.

## Reproduzierbarer Test

Alle sechs Ziele koennen mit dem Smoke-Test-Werkzeug gestartet werden:

```bash
./scripts/smoke_tempestreborn_profiles.sh all
```

Einzelne Profile:

```bash
./scripts/smoke_tempestreborn_profiles.sh enemy1-de
./scripts/smoke_tempestreborn_profiles.sh enemy1-en
./scripts/smoke_tempestreborn_profiles.sh enemy2-de
./scripts/smoke_tempestreborn_profiles.sh enemy2-en
./scripts/smoke_tempestreborn_profiles.sh intro-de
./scripts/smoke_tempestreborn_profiles.sh intro-en
```

Bei visuellen Regressionen ist die manuelle Sichtpruefung weiterhin massgeblich,
weil Sequenzwechsel und schwarze Frames automatische Einzel-Screenshots
verfaelschen koennen.

## Naechste Arbeit

Diese sechs Profile sind die stabile Basis fuer die naechste Projektphase:

- Launcher-Design verbessern
- Settings-Menue funktional machen
- FS-UAE-Fork fuer Pause-Overlay, Skalierung und Filter vorbereiten
- Tastatur-/Gamepad-Profile sauber paketieren
- Windows/macOS/Linux/Android-Startpfade getrennt definieren
