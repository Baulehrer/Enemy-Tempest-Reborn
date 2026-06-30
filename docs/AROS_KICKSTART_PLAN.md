# Plan: Enemy mit AROS-Kickstart-Ersatz

## Ziel

Enemy soll in FS-UAE ohne kommerzielles Commodore-Kickstart-ROM gestartet
werden. Verwendet wird `roms/aros/aros-rom.bin` als freier AROS-ROM-Ersatz.

## Testmatrix

- `enemy1 a500`: A500, 512 KB Chip, 512 KB Slow.
- `enemy1 a500plus`: A500+, 1 MB Chip.
- `enemy1 a600`: A600, 1 MB Chip.
- `enemy1 a1200`: A1200, 2 MB Chip.
- Dieselben Profile fuer `enemy2`.

## Abnahme

Eine Variante gilt als brauchbar, wenn:

- FS-UAE startet.
- AROS-ROM geladen wird.
- Disk A gelesen wird.
- Enemy einen sichtbaren Start-, Intro- oder Spielscreeen erreicht.
- kein sofortiger Guru, Resetloop oder dauerhaftes Schwarzbild entsteht.
- Eingabe und, falls noetig, Disk B funktionieren.

## Vorgehen

1. `./scripts/checksum_project.sh > checksums/SHA256SUMS` ausfuehren.
2. `./scripts/run_enemy_aros.sh enemy1 a500` starten.
3. Sichtpruefung und Logpruefung unter `output/logs/`.
4. Falls A500 scheitert, `a500plus`, `a600`, danach `a1200` testen.
5. Dasselbe fuer Enemy 2.
6. Beste funktionierende Konfiguration im README dokumentieren.

## Grenzen

AROS ist kein perfektes Kickstart-ROM fuer alte Spiele. Ein Scheitern dieser
Variante beweist nicht, dass Enemy defekt ist; es zeigt nur, dass der freie
ROM-Ersatz fuer diese Software/Hardware-Kombination nicht ausreicht.
