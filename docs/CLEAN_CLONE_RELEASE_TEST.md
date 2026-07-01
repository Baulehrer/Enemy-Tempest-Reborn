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

## Full Profile Matrix

Date: 2026-07-01

The full six-profile matrix was run from the same clean clone:

```bash
GAME_DURATION=45 INTRO_DURATION=35 GAME_SHOTS='20 40' INTRO_SHOTS='20 30' \
INTRO_INPUT_AT=24 FS_UAE_BIN=fs-uae \
  scripts/smoke_tempestreborn_profiles.sh all
```

Run directory:

```text
/tmp/enemy-tempest-reborn-clean.z0IFBB/work/launcher-smoke/20260701T085847+0200
```

Summary:

```text
enemy1-de  timeout_terminated
enemy1-en  timeout_terminated
enemy2-de  timeout_terminated
enemy2-en  timeout_terminated
intro-de   exited
intro-en   exited
```

The `timeout_terminated` result is expected for game profiles because the smoke
script stops the emulator after the configured observation window. The intro
profiles exited after the scripted input signal.

Visual results:

| Profile | Result | Evidence |
| --- | --- | --- |
| `enemy1-de` | Enemy 1 German main menu reached | `evidence/screenshots/clean-clone-enemy1-de-menu.png` |
| `enemy1-en` | Enemy 1 English main menu reached | `evidence/screenshots/clean-clone-enemy1-en-menu.png` |
| `enemy2-de` | Enemy 2 German path reached boot/logo and memory screen | `evidence/screenshots/clean-clone-enemy2-de-memory.png` |
| `enemy2-en` | Enemy 2 English path reached boot/logo and memory screen | `evidence/screenshots/clean-clone-enemy2-en-memory.png` |
| `intro-de` | Enemy intro German path reached Anachronia intro frame and exited | `evidence/screenshots/clean-clone-intro-de-anachronia.png` |
| `intro-en` | Enemy intro English path reached Anachronia intro frame and exited | `evidence/screenshots/clean-clone-intro-en-anachronia.png` |

Automated crop-image sanity check:

```text
enemy1-de final crop nonblack ratio: 0.4872
enemy1-en final crop nonblack ratio: 0.4867
enemy2-de final crop nonblack ratio: 0.7444
enemy2-en final crop nonblack ratio: 0.7444
intro-de crop nonblack ratio: 0.0209
intro-en crop nonblack ratio: 0.0209
```

The logs for all six profiles confirmed:

- fullscreen desktop mode was selected
- AROS ROM and extension ROM were mapped
- profile-specific ADFs were inserted from relative repository paths
- no Address Error, Guru, or fatal FS-UAE process error was observed during the
  smoke window

Remaining next checks:

- add a screenshot hash/non-black assertion to the smoke script

## Launcher Preflight

Date: 2026-07-01

The launcher now checks the runtime environment before writing and starting the
FS-UAE runtime profile:

- `fs-uae` must be available in `PATH`
- the selected base profile under `configs/fs-uae/` must exist
- `kickstart_file` must resolve to an existing AROS ROM
- `kickstart_ext_file` must resolve to an existing AROS extension ROM
- `floppy_drive_0` and `floppy_drive_1` must resolve to existing disk images

Relative paths are resolved from the repository root, matching how FS-UAE is
started by the launcher. If a preflight check fails, FS-UAE is not launched and
the launcher status line shows a direct error such as:

```text
FS-UAE was not found. Install fs-uae or add it to PATH.
Missing runtime file: Disk image A: work/kickstart-deps/...
```
