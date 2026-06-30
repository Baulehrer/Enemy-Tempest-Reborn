# Enemy: Tempest Reborn FS-UAE Graphics Enhancement Plan

## Ziel

Wir nehmen FS-UAE als technische Basis und bauen zunaechst einen Enemy-spezifischen
Enhanced-Modus. Enemy soll mit dem funktionierenden AROS/`closewb`-NOP-Pfad
starten, waehrend Grafik und spaeter optional Sound im Ausgabe-Layer verbessert
werden.

Wichtig: Die Amiga-Emulation bleibt korrekt bei PAL/50 Hz. Verbesserungen duerfen
das Spiel nicht schneller machen und sollen zuerst nur im Rendering-/Ausgabeweg
passieren.

## Grundprinzipien

- Gameplay, CPU-Timing, Blitter-Timing, Audio-Timing und Disk-I/O bleiben
  unveraendert.
- Enhancements sind abschaltbar.
- Jeder neue Modus wird mit Screenshots vom Intro, Hauptmenue und Gameplay
  verglichen.
- Der originale Pixeloutput bleibt als Referenzmodus erhalten.
- Enemy-spezifische Presets duerfen existieren, sollen aber nicht die allgemeine
  FS-UAE-Emulation verschlechtern.

## Phase 1: Saubere Basis

1. FS-UAE-Fork/Branch anlegen
   - Branchname: `enemy-enhanced`
   - Basis: der aktuell funktionierende FS-UAE-Stand
   - Enemy-ADF mit `closewb`-NOP als Standard-Testmedium
   - AROS-ROM-Konfiguration dokumentieren
   - Startprofil: `Enemy AROS A1200 2MB`

2. Reproduzierbare Testpunkte definieren
   - AROS-Shell nach Boot
   - Enemy Intro
   - Sternen-/Schiffsequenz
   - Hauptmenue
   - erster Gameplay-Screen
   - automatische Screenshots pro Testpunkt

3. Neue Konfigurationsoptionen planen
   - `enemy_enhanced = 0|1`
   - `enemy_display = fullscreen|window`
   - `enemy_filter = nearest|linear|hq2x|hq3x|hq4x|xbrz|crt|scalefx|epx|supereagle`
   - `enemy_motion = off|double|blend|smooth`
   - `enemy_aspect = 4_3|pixel|stretch`
   - `enemy_crop = off|auto|manual`

## Phase 2: Aufloesung und Scaling

1. Integer Scaling
   - 2x, 3x, 4x
   - keine krummen Pixel
   - optional automatische Fenstergroesse
   - keine wandernden Pixel bei Bewegung

2. Aspect Ratio
   - Original-Amiga-Pixel-Seitenverhaeltnis
   - korrigiertes 4:3
   - Pixel-perfect-Modus
   - Stretch nur optional

3. Sharp/Smooth Modes
   - `nearest`: original scharf
   - `linear`: weicher
   - optional getrennt fuer X/Y, falls das Amiga-Pixelverhaeltnis sonst unschoen
     wirkt

4. Overscan und Crop
   - schwarze Raender erkennen
   - automatische Crop-Presets fuer Enemy
   - kein Abschneiden von Menue, HUD oder Gameplay

## Phase 3: Filter und Shader

1. Basisfilter
   - nearest/integer
   - linear
   - bilinear mit korrektem Aspect Ratio

2. Pixel-Art-Scaler
   - hq2x
   - hq3x
   - hq4x
   - xBRZ 2x/3x/4x
   - Scale2x/Scale3x
   - EPX/AdvMAME
   - SuperEagle/Super2xSaI
   - ScaleFX, falls praktikabel

3. CRT-/Monitor-Shader
   - Scanlines
   - Shadow mask
   - dezenter Glow
   - leichte Phosphor-Nachleuchte
   - optionale Bildschirmkruemmung
   - keine uebertriebenen VHS-/Blur-Effekte als Standard

4. Farbaufwertung
   - Gamma-Regler
   - Kontrast-Regler
   - Saettigung leicht anhebbar
   - Palette-preserving Mode fuer exakte Farben
   - Enhanced Mode fuer moderne Darstellung

5. Dithering und Debanding
   - optional leichter Debanding-Filter fuer grosse Flaechen
   - nicht aggressiv auf Fonts/Sprites anwenden
   - Menueschrift muss lesbar bleiben

6. Presets
   - `Original`
   - `Sharp 4x`
   - `Smooth Pixel Art`
   - `xBRZ Clean`
   - `CRT Monitor`
   - `Soft Retro`
   - `Screenshot/Archive`

## Phase 4: 100/120-Hz-Ausgabe

1. Frame-Doubling
   - Emulation bleibt 50 Hz
   - Ausgabe zeigt jeden Frame doppelt fuer 100 Hz
   - sehr sicher, aber nicht wirklich fluessiger

2. Frame-Blending
   - Zwischenbild aus aktuellem und vorherigem Frame
   - kann Scrolling weicher wirken lassen
   - kann Ghosting verursachen
   - nur optional

3. Motion-Smoothing
   - einfache Bewegungsanalyse im Ausgabe-Layer
   - Ziel: 50 Hz Emulation, 100/120 Hz Darstellung
   - experimentell
   - Input-Latenz und Artefakte messen

4. KI-Interpolation
   - nicht als Standard fuer Live-Gameplay
   - eher fuer Video-Capture oder Offline-Modus
   - Risiken: Latenz, Pixelart-Artefakte, falsche Zwischenbilder bei Text und
     Sprites

## Phase 5: Enemy-spezifische Verbesserungen

1. Enemy-Profil
   - passende Crop-/Overscan-Werte
   - Hauptmenue korrekt zentriert
   - Intro und Gameplay ohne Skalierungswechsel
   - `closewb`-NOP-ADF als Standard-Testpfad

2. HUD- und Text-Schutz
   - Filter duerfen Schrift nicht zerstoeren
   - optional Text/HUD schaerfer halten, falls technisch moeglich
   - Menue und Code-Eingabe priorisieren

3. Screenshot-Modus
   - verlustfreie PNGs
   - 1x original
   - 2x/3x/4x enhanced
   - Metadaten: Filter, Scale, Shader, Frame-ID

4. Video-Capture-Modus
   - 50-Hz-Originalausgabe
   - 100/120-Hz-Enhanced-Ausgabe
   - optional Frame-Blending
   - spaeter Offline-KI-Upscale moeglich

## Phase 6: Spaetere Asset-Aufwertung

1. Rohdaten-Extraktion untersuchen
   - Logos
   - Fonts
   - BOBs/Sprites
   - Hintergrundgrafiken
   - Menueelemente
   - Paletten

2. Asset-Upscaling experimentell
   - Pixel-Art-Modelle statt Foto-KI
   - Real-ESRGAN/ESRGAN nur vorsichtig testen
   - manuelle Nachbearbeitung fuer Schluesselgrafiken
   - erst Preview/Viewer, noch keine direkte Reinjektion

3. Asset-Reinjektion nur langfristig
   - deutlich schwieriger als Output-Filter
   - Groessen, Koordinaten, Speicherverbrauch und Blitter-Logik koennen brechen
   - erst wenn Formate und Speicherlayout sicher verstanden sind

## Phase 7: Sound-Optionen

1. Sicherer Start
   - besseres Resampling
   - niedrige Latenz
   - Clipping vermeiden
   - Lautstaerke normalisieren

2. Paula-/Retro-Optionen
   - optionaler Lowpass
   - leichte Stereo-Separation
   - kein Reverb als Standard

3. Qualitaetskontrolle
   - Audio darf nicht vom Video driften
   - keine Timing-Aenderung durch Audio-Puffer
   - Vergleich mit Original-Kickstart-Lauf

## Phase 8: Qualitaetssicherung

1. Vergleichsgalerie
   - Hauptmenue
   - Intro
   - erster Level
   - Schriftprobe
   - schnelle Bewegung

2. Performance-Messung
   - CPU-Last
   - GPU-Last
   - Framezeiten
   - Input-Latenz
   - Audio-Sync

3. Regressionstests
   - Enemy startet bis Hauptmenue
   - keine fehlenden Grafiken
   - kein Timing-Speedup
   - kein Audio-Drift
   - Screenshots sind nicht schwarz/leere Frames

## Empfohlene Reihenfolge

1. FS-UAE-Fork/Branch und Enemy-Profil
2. 2x/3x/4x Integer Scaling
3. Aspect Ratio und Crop
4. nearest/linear/xBRZ/hq3x
5. CRT-Shader
6. Presets
7. 100-Hz-Frame-Doubling
8. Frame-Blending
9. Motion-Smoothing experimentell
10. Rohdaten-/Asset-Upscaling als separate Forschungsphase

## Kurzbewertung

Der schnellste sichtbare Gewinn kommt durch:

- Enemy-Profil
- Integer Scaling
- korrektes Aspect Ratio
- xBRZ/hq3x
- saubere CRT- und Clean-Presets

100/120 Hz ist sinnvoll, aber nur wenn die Emulation selbst bei 50 Hz bleibt und
die Zusatzframes ausschliesslich im Ausgabe-Layer entstehen.
