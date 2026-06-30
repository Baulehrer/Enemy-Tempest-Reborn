# Enemy - Port (AROS/UAE)

Dieses Repository bündelt die aktuelle Enemy/AROS-Kompatibilitätsanalyse für
FS-UAE. Enthalten sind die für dieses Projekt bereitgestellten originalen Enemy
ADFs, die verwendeten AROS-ROMs, reproduzierbare ADF-Patch-Skripte, gepatchte
Enemy-ADF-Varianten, FS-UAE-Konfigurationen und Beleg-Screenshots/Manifeste.

## Aktueller Stand

- Enemy V2 startet unter AROS, wenn als A1200 mit 2 MB Chip RAM ausgeführt.
- Der sauberste getestete Pfad nutzt eine Enemy-ADF-Variante, in der der Helper
  `c/closewb` seine Vorbereitung und Stack-Bereinigung beibehält, aber den
  einzelnen `CloseWindow()`-Aufruf durch zwei 68k-NOP-Instruktionen ersetzt.
- Mit diesem `closewb`-NOP-Patch lässt sich die Intro per Maus/Feuer abbrechen,
  und das Hauptmenü rendert korrekt.
- Ohne NOP auf AROS A1200/2 MB erreicht das Spiel Enemy-Videomodi, zeigte im
  manuellen Test aber fehlende Grafiken.
- Auf AROS-A500-nahen Konfigurationen kann `ef/enemy` mit der irreführenden
  Shell-Meldung `file is not executable` abbrechen. Die statische Hunk-Prüfung
  zeigt aber ein gültiges AmigaOS-LoadSeg-Executable; die Ursache wirkt daher
  eher wie Umgebung/Ressourcen.

Siehe:

- `docs/CLOSEWB_NOP_FIX_DE.md`
- `docs/CLOSEWB_NOP_FIX_EN.md`
- `docs/TECHNICAL_ARTIFACTS.md`
- `LICENSES.md`

## Schnelltest

FS-UAE mit folgender Konfiguration starten:

```text
configs/fs-uae/enemy1_arosclosewbnopdiag_a1200.fs-uae
```

Diese Konfiguration nutzt:

```text
media/enemy-adfs/patched/ENEMY1_V2_DE_A.closewb-nop-diag.adf
media/enemy-adfs/original/ENEMY1_V2_DE_B.adf
roms/aros/aros-rom.bin
roms/aros/aros-ext.bin
```

Die kopierten FS-UAE-Konfigurationen enthalten noch absolute Pfade aus dem
Analyse-Workspace und muessen nach dem Klonen ggf. angepasst werden.

