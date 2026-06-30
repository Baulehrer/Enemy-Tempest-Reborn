# CloseWB-NOP-Fix - Deutsche technische Notizen

## Problem

Enemy V2 bootet unter AROS, aber der originale Startpfad verhielt sich je nach
emuliertem Amiga-Modell und Speicherausstattung unterschiedlich.

Die originale Startup-Sequence auf Disk A lautet:

```text
ENEMY_A:enif/enintro  >nil:
ENEMY_A:c/closewb
ENEMY_A:ef/enemy >nil:
```

Auf AROS-A500-nahen Konfigurationen crashte der Lauf zuerst bzw. kam nicht
sauber bis zum Hauptspiel. Nachdem der `CloseWindow()`-Aufruf umgangen wurde,
kam der A500-Pfad immerhin bis zum spaeteren LoadSeg-Versuch von `ef/enemy`.
AROS meldete dort:

```text
ENEMY_A:ef/enemy: file is not executable
```

Die statische Hunk-Analyse zeigte danach aber, dass `ef/enemy` weiterhin ein
normales LoadSeg-Executable ist. Die Meldung wurde daher nicht als Beweis fuer
ein kaputtes Hunk-Format gewertet, sondern als AROS-/Umgebungs-/Ressourcen-
Symptom.

## Wie der Patch entstanden ist

Die Runtime-Analyse konzentrierte sich auf den kleinen Helper `c/closewb`. Die
relevante Sequenz laedt Intuitions `ActiveWindow`, legt den Wert auf den Stack,
ruft `CloseWindow()` und bereinigt danach den Stack.

Wichtige Runtime-Adressen im AROS-A500-Capture:

```text
Callsite-Bereich:              0x0006c428 .. 0x0006c444
beobachtetes ActiveWindow-Arg: 0x000625b8
Rueckkehr nach Call/Cleanup:   0x0006c444
```

Weitere Traces zeigten, dass dieses Schliessen des Fensters unter AROS in
spaetere Graphics-/Exec-Speicherprobleme fuehren konnte. Deshalb wurde nicht
der ganze Helper uebersprungen, sondern nur der einzelne `CloseWindow()`-Call
neutralisiert.

## Exakter Binary-Patch

Quelle:

```text
media/enemy-adfs/original/ENEMY1_V2_DE_A.adf
sha256=f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e
```

Patch:

```text
Datei-Offset im ADF: 0x053068
Original-Bytes:      4eba0718
Patch-Bytes:         4e714e71
Effekt:              JSR CloseWindow -> NOP; NOP
Checksum-Block:      0x053000
alte Checksumme:     0x3756ae9a
neue Checksumme:     0x379f6741
```

Gepatchtes ADF:

```text
media/enemy-adfs/patched/ENEMY1_V2_DE_A.closewb-nop.adf
sha256=a685d1c2d3f24ba70a96ed02f7e6385e463e3acf9d285de3e39d68f24597ea75
```

Das Patch-Skript:

```text
scripts/build_closewb_nop_adf.py
```

Es prueft den SHA-256 der Quell-ADF, prueft eine eindeutige Signatur am
erwarteten Offset, ersetzt den Call durch zwei NOPs und berechnet die
AmigaDOS-Block-Checksumme neu.

## Getesteter Erfolgspfad

```text
AROS-ROM: gebaut 2026-06-21, Git f8e1bic2e
Maschine: A1200
Speicher: 2 MB Chip RAM
ADF A:    ENEMY1_V2_DE_A.closewb-nop-diag.adf
ADF B:    ENEMY1_V2_DE_B.adf
Ergebnis: Intro laeuft, Maus/Feuer bricht Intro ab, Hauptmenue rendert korrekt
```

Kontrollbeobachtung:

```text
Gleiche AROS-A1200/2-MB-Umgebung, aber originale ADF ohne closewb-NOP:
das Spiel erreicht Enemy-Videomodi, im manuellen Test fehlten aber Grafiken.
```

A500-Beobachtung:

```text
AROS-A500-nahe Umgebung kann `ef/enemy: file is not executable` melden.
Die Hunk-Analyse spricht nicht fuer ein defektes Hunk-Format.
```

## Nutzen fuer AROS-Entwickler

Das ist ein enger Kompatibilitaets-Reproducer:

- Er isoliert einen einzelnen Intuition-nahen Call in einem kleinen Helper.
- Der eigentliche Patch ist nur vier Bytes gross und laesst die umgebende
  Startlogik intakt.
- Dasselbe `ef/enemy`-Hunk-Executable wird unter AROS A1200/2 MB akzeptiert und
  laeuft, wenn dieser Call vermieden wird.
- Ohne Patch kommt AROS zwar in Enemy-Videomodi, aber der Grafikzustand war im
  manuellen Test nicht korrekt.

Wahrscheinliche AROS-Untersuchungspunkte:

- Verhalten von `CloseWindow()`, wenn es von diesem alten AmigaDOS-Startup-
  Helper aufgerufen wird.
- Ob das Schliessen des aktiven Shell-/Workbench-Fensters Intuition-/Gfx-
  Zustand oder Speicherlisten so hinterlaesst, dass spaetere Spielgrafik
  beeinflusst wird.
- Warum AROS-A500-nahe Umgebungen fuer ein gueltiges LoadSeg-File
  `file is not executable` melden, moeglicherweise weil ein Speicher-/
  Ressourcenfehler als irrefuehrender DOS-Fehler sichtbar wird.

