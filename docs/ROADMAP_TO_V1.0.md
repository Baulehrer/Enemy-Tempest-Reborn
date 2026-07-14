# Roadmap zu Enemy: Tempest Reborn 1.0

Stand: 2026-07-11

## Ziel

Version 1.0 liefert Enemy 1 und Enemy 2 sowie das vollstaendige Enemy-1-Intro
auf Linux x64 und Windows x64 als selbstaendige, reproduzierbar gebaute Pakete.
macOS bleibt bis zu einer nativen Laufzeitpruefung als Preview gekennzeichnet.
Ein eigener FS-UAE-Fork, Pause-Overlay und experimentelle Grafikverfahren sind
bewusst fuer 1.x vorgesehen.

## P0: Release-Blocker

- Die eingebetteten Introvideos DE und EN auf vollstaendige Szenenfolge,
  synchronen Ton, saubere Schnitte ohne Workbench und Rueckkehr zum Launcher
  pruefen.
- Enemy 1 DE/EN und Enemy 2 DE/EN vom Launcher bis Hauptmenue, Levelstart,
  Eingabe und kontrolliertem Beenden auf frischen Linux- und Windows-Systemen
  pruefen.
- Gebuendeltes FS-UAE muss ohne Systeminstallation laufen. Linux-Pakete muessen
  auch die benoetigten Laufzeitbibliotheken abdecken; Windows-Pakete enthalten
  das vollstaendige FS-UAE-Laufzeitverzeichnis.
- Lizenz- und Herkunftsnachweise fuer Enemy-Medien, Artwork, AROS, FS-UAE und
  Shader vervollstaendigen. Fehlende Distributions- oder Quellcode-Nachweise
  blockieren 1.0.

## P1: Launcher und Pakete

- FS-UAE als verwalteten Prozess starten, Doppelstarts sperren, fruehe Fehler
  und Exit-Codes anzeigen und nach Prozessende in den Bereitschaftszustand
  zurueckkehren.
- Diagnoseansicht mit Launcher-/FS-UAE-Version, Pfaden, aktivem Ziel,
  Runtime-Konfiguration sowie Aktionen fuer Logordner und Diagnosekopie.
- Einstellungen versionieren, atomar speichern und unlesbare oder alte Dateien
  sicher auf gueltige Defaults zurueckfuehren.
- Eine zentrale Versionsquelle fuer Launcher, Paketnamen, Installer und CI
  verwenden. Tag, sichtbare Version und Artefaktnamen muessen uebereinstimmen.
- macOS-Artefakte als Preview benennen; `universal` erst nach einem
  Architektur-Nachweis fuer Launcher und FS-UAE verwenden.

## P1: Automatische Gates

- Bei Pull Requests und auf `main`: `flutter analyze`, Flutter-Tests,
  Skript-Syntax, Versionskonsistenz, Paketstruktur und Patch-Manifeste pruefen.
- Unit-Tests fuer Konfigurationsparser/-writer, Pfadauflosung, Preflight,
  Settings-Migration, Prozessstart und Prozessende ergaenzen.
- Widget-Matrix fuer DE/EN, alle Ziele, Einstellungen, Info/Diagnose,
  Tastaturbedienung und 480x800 bis 1600x900 beibehalten.
- Release-Gate auf frischen Linux- und Windows-Installationen: alle sechs Ziele
  im Original-Preset; zusaetzlich alle Grafik-, Anzeige- und Steuerungsoptionen
  mindestens einmal pro Zielplattform.

## Releasefolge

### 0.9 Beta

- Vollstaendige eingebettete Introvideos DE und EN mit Capture-Nachweis.
- Verwalteter FS-UAE-Prozess und Diagnoseansicht.
- Zentrale Versionierung und gruenes CI-Qualitaetsgate.

### 1.0 RC

- Funktionsumfang eingefroren.
- Linux- und Windows-Clean-System-Matrix gruen.
- Lizenz-, Herkunfts- und Paketmanifeste vollstaendig.
- Keine bekannten Abstuerze oder blockierenden Eingabefehler.

### 1.0 Final

- Build ausschliesslich vom 1.0-Tag.
- Alle Artefakte mit SHA-256 und Inhaltsmanifest.
- Release-Checkliste von einer zweiten Person gegengeprueft.
- README DE/EN, Steuerung, Diagnose, Systemanforderungen, Upgrade-Hinweise und
  bekannte Einschraenkungen entsprechen exakt den ausgelieferten Paketen.

## Nicht Teil von 1.0

- Nativer Port, Android und Auto-Updater.
- Telemetrie oder verpflichtender Netzwerkzugang.
- FS-UAE-Pause-Overlay, Live-Filterwechsel und Emulator-Fork.
- 100/120-Hz-Interpolation, KI-Upscaling und Asset-Reinjektion.

## Aktueller Nachweis

Die eingebetteten Introvideos ersetzen fuer Reborn den bisherigen
AROS-Intro-Lauf; der eigenstaendige Enemy-Port bleibt davon unberuehrt. Analyse,
Tests und die Paket-/Spielbarkeitstore muessen vor 1.0 weiterhin gruen sein.
