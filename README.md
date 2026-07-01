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
- The launcher defaults to fullscreen. Window sizing and 2x/3x/4x checks are
  retained as debug/measurement paths, not as the main player-facing flow.

See:

- `docs/CLOSEWB_NOP_FIX_EN.md`
- `docs/CLOSEWB_NOP_FIX_DE.md`
- `docs/TECHNICAL_ARTIFACTS.md`
- `docs/CLEAN_CLONE_RELEASE_TEST.md`
- `docs/ROADMAP_v0.2.0.md`
- `docs/FS_UAE_BUNDLING_STRATEGY.md`
- `LICENSES.md`

## Quick Test

Run the host launcher on Linux:

```bash
cd launcher
flutter run -d linux
```

Or start a profile directly with FS-UAE:

```text
configs/fs-uae/tempestreborn_enemy1_de_a1200.fs-uae
```

The Tempest Reborn configs use paths relative to the repository root. The
launcher writes runtime configs to `work/launcher-runtime/` and applies the
selected display/aspect/filter/control options before starting FS-UAE.
Before starting, it checks `fs-uae`, the selected base profile, the AROS ROMs,
and the required Enemy disk images. Missing runtime files are reported in the
launcher status area.
For the next package line, the launcher is prepared to prefer a bundled
`bin/fs-uae/fs-uae` binary before falling back to system `fs-uae`.

Launcher settings currently include:

- `Display`: `Fullscreen` or `Window`
- `Aspect`: `4:3`, `Pixel`, or `Stretch`
- `Pixels`: `Sharp`, `Smooth`, or `CRT`
- `Control`: `Keyboard`, `Gamepad`, or `Joystick`

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

## Repository Name Note

The project display name is `Enemy: Tempest Reborn`. GitHub repository names
cannot contain `:`, so the technical repository name is intended to be
`Enemy-Tempest-Reborn`.
