# Clean Clone Release Test

Date: 2026-07-01

This test verifies that the GitHub repository can be cloned into a fresh
directory and started without paths from the original development workspace.

## Clone

```bash
git clone https://github.com/Baulehrer/Enemy-Tempest-Reborn.git /tmp/enemy-tempest-reborn-clean.z0IFBB
cd /tmp/enemy-tempest-reborn-clean.z0IFBB
```

Tested commit:

```text
fec35ce Add Tempest Reborn launcher and portable profiles
```

## File Presence

The fresh clone contains the required runtime files:

- `roms/aros/aros-rom.bin`
- `roms/aros/aros-ext.bin`
- `assets/adf/ENEMY1_V2_DE_A.adf`
- `assets/adf/ENEMY1_V2_DE_B.adf`
- `assets/adf/ENEMY1_V2_EN_A.adf`
- `assets/adf/ENEMY1_V2_EN_B.adf`
- `assets/adf/ENEMY2_V2_DE_A.adf`
- `assets/adf/ENEMY2_V2_DE_B.adf`
- `assets/adf/ENEMY2_V2_EN_A.adf`
- `assets/adf/ENEMY2_V2_EN_B.adf`
- prepared level-unlock ADFs under `work/kickstart-deps/patches/level-unlock/`

The Tempest Reborn FS-UAE configs no longer contain absolute development paths.

## Flutter Launcher Check

From the fresh clone:

```bash
cd launcher
flutter analyze
flutter test
flutter build linux
```

Result:

```text
flutter analyze: pass
flutter test: pass
flutter build linux: pass
```

## FS-UAE Smoke Check

Short boot check:

```bash
GAME_DURATION=10 GAME_SHOTS=5 FS_UAE_BIN=fs-uae \
  scripts/smoke_tempestreborn_profiles.sh enemy1-de
```

Result:

```text
enemy1-de  timeout_terminated
```

This confirmed that FS-UAE starts from the clone, enters fullscreen mode, loads
the AROS ROMs, and inserts both Enemy ADFs.

Longer visual check:

```bash
GAME_DURATION=45 GAME_SHOTS='20 40' FS_UAE_BIN=fs-uae \
  scripts/smoke_tempestreborn_profiles.sh enemy1-de
```

Result:

```text
enemy1-de  timeout_terminated
```

The 40-second FS-UAE crop screenshot reached the Enemy 1 main menu. The internal
FS-UAE screenshot path worked; desktop screenshots were unavailable in this
Wayland session, which is expected for this capture method.

Relevant log evidence:

```text
fullscreen = 1
setting (fullscreen) video mode 1680 1050
set option "kickstart_rom_file" to "./roms/aros/aros-rom.bin" (result: 1)
set option "kickstart_ext_rom_file" to "./roms/aros/aros-ext.bin" (result: 1)
set option "floppy0" to "./work/kickstart-deps/patches/level-unlock/ENEMY1_V2_DE_A.game-nointro.level-unlock.adf" (result: 1)
set option "floppy1" to "./assets/adf/ENEMY1_V2_DE_B.adf" (result: 1)
```

## Assessment

The release repository is self-contained enough for the current Linux/FS-UAE
path:

- clone works
- launcher source builds
- configs are portable
- AROS ROMs and Enemy ADFs resolve from the clone
- Enemy 1 DE reaches the main menu from the clean clone

Remaining next checks:

- repeat the 45-second smoke for Enemy 1 EN, Enemy 2 DE/EN, Intro DE/EN
- add launcher preflight errors for missing `fs-uae`, ROMs, ADFs, or configs
- add a screenshot hash/non-black assertion to the smoke script
