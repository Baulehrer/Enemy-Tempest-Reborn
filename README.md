# Enemy: Tempest Reborn

This repository packages the current Enemy: Tempest Reborn AROS/UAE
compatibility work. It contains the original Enemy ADFs provided for this
project, the AROS ROMs used for testing, reproducible ADF patch scripts,
prepared patched Enemy ADF variants, FS-UAE configs, and the first host-side
Flutter launcher.

## Current Result

- Enemy V2 starts on AROS when run as an A1200 with 2 MB Chip RAM and 2 MB
  Fast RAM.
- The cleanest tested path uses an Enemy ADF variant where the `c/closewb`
  helper keeps its setup/stack cleanup but replaces the single `CloseWindow()`
  call with two 68k NOP instructions.
- With that `closewb` NOP patch, the intro can be skipped by mouse/fire and the
  main menu renders correctly.
- Enemy 1 is split into separate game and intro launch targets. The game target
  skips the intro; the intro target exits back to the host launcher.
- Enemy 1/2 DE/EN use prepared level-unlock images: the menu still displays
  level 1, but the highest level is unlocked without password entry.
- The launcher defaults to fullscreen and FS-UAE `zoom = auto`, so the normal
  player path starts full-screen with automatic Amiga viewport cropping.
- The `v0.2.0-preview4` Linux package includes an unmodified FS-UAE 3.2.35
  binary plus its runtime data. Users do not need a separate system FS-UAE for
  that package.

See:

- `docs/CLOSEWB_NOP_FIX_EN.md`
- `docs/CLOSEWB_NOP_FIX_DE.md`
- `docs/TECHNICAL_ARTIFACTS.md`
- `docs/CLEAN_CLONE_RELEASE_TEST.md`
- `docs/ROADMAP_v0.2.0.md`
- `docs/FS_UAE_BUNDLING_STRATEGY.md`
- `docs/BUNDLED_FS_UAE_DEV_PACKAGE_TEST.md`
- `docs/KEYBOARD_CONTROLS.md`
- `docs/RELEASE_v0.2.0-preview1.md`
- `docs/RELEASE_v0.2.0-preview2.md`
- `docs/RELEASE_v0.2.0-preview3.md`
- `docs/RELEASE_v0.2.0-preview4.md`
- `docs/GRAPHICS_BASELINE.md`
- `docs/GRAPHICS_FILTER_CHECK.md`
- `docs/GRAPHICS_FILTER_MATRIX.md`
- `docs/RELEASE_PACKAGING.md`
- `LICENSES.md`

## Quick Test

Run the host launcher on Linux:

```bash
cd launcher
flutter run -d linux
```

For the packaged preview release, extract the Linux archive and run:

```bash
./run-linux.sh
```

Or start a profile directly with FS-UAE:

```text
configs/fs-uae/tempestreborn_enemy1_de_a1200.fs-uae
```

The Tempest Reborn configs use paths relative to the repository root. The
launcher writes runtime configs to `work/launcher-runtime/` and applies the
selected display/aspect/filter/control options before starting FS-UAE.
Before starting, it checks the bundled or system `fs-uae`, the selected base
profile, the AROS ROMs, and the required Enemy disk images. Missing runtime
files are reported in the launcher status area. The launcher prefers a bundled
`bin/fs-uae/fs-uae` binary before falling back to system `fs-uae`.

Launcher settings currently include:

- `Display`: `Fullscreen` or `Window`
- `Aspect`: `4:3`, `Pixel`, or `Stretch`
- `Preset`: `Original`, `Retro`, `Retro Plus`, `Enhanced`, or `Enhanced Plus`
- `Control`: `Keyboard`, `Gamepad`, or `Joystick`

Keyboard control maps cursor keys and WASD to joystick directions. `Space`,
Right `Ctrl`, Right `Alt`, and Right `Shift` act as fire. Joystick keeps the
original Amiga-style direction plus fire control, with `H` mapped to Amiga
`HELP`. Gamepad maps `L1` to pause, `R1` to help, and `L2`/`R2`/`Select` to
replay. The original Enemy keys such as `P`, `R`, `Backspace`, `Delete`, and
`Esc` remain available.

The launcher UI is bilingual. Switching to English also switches the menu text.

## Verification

Current local checks:

```bash
cd launcher
flutter analyze
flutter test
flutter build linux
```

All three passed on 2026-07-01 after adding launcher preflight checks.

## Release Packages

Portable packages are built with:

```bash
VERSION=v0.2.0-dev ./scripts/package_linux_x64.sh
```

Windows and macOS packages are built on their native runners via
`.github/workflows/build-release-packages.yml`. See
`docs/RELEASE_PACKAGING.md`.

## Repository Name Note

The project display name is `Enemy: Tempest Reborn`. GitHub repository names
cannot contain `:`, so the technical repository name is intended to be
`Enemy-Tempest-Reborn`.
