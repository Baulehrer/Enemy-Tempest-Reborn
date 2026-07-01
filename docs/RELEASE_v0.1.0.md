# Enemy: Tempest Reborn v0.1.0

Date: 2026-07-01

This is the first cleanly marked public compatibility release of Enemy: Tempest
Reborn for the current Linux/FS-UAE/AROS path.

## Status

The repository is self-contained for the tested Linux FS-UAE workflow:

- AROS ROM and extension ROM are included.
- Enemy 1 and Enemy 2 DE/EN ADFs are included.
- Prepared `closewb` NOP, intro split, and level-unlock ADF variants are
  included.
- The Flutter launcher is included and builds on Linux.
- The Tempest Reborn FS-UAE profiles use relative paths from the repository
  root.

## Verified Targets

Clean-clone smoke evidence from 2026-07-01:

| Target | Result |
| --- | --- |
| Enemy 1 DE | main menu reached |
| Enemy 1 EN | main menu reached |
| Enemy 2 DE | boot/logo and memory screen reached |
| Enemy 2 EN | boot/logo and memory screen reached |
| Intro DE | Anachronia intro frame reached, exits after input |
| Intro EN | Anachronia intro frame reached, exits after input |

Evidence screenshots are stored under `evidence/screenshots/clean-clone-*.png`.

## Launcher

The launcher supports:

- Enemy 1, Enemy 2, Intro, and Cartographer selection
- German/English UI language
- Fullscreen default
- Aspect options: `4:3`, `Pixel`, `Stretch`
- Pixel options: `Sharp`, `Smooth`, `CRT`
- Control options: `Keyboard`, `Gamepad`, `Joystick`
- Runtime preflight checks for `fs-uae`, FS-UAE profiles, AROS ROMs, and Enemy
  disk images

## Checks

The following checks passed before tagging:

```bash
cd launcher
flutter analyze
flutter test
flutter build linux
```

The clean-clone smoke matrix is documented in
`docs/CLEAN_CLONE_RELEASE_TEST.md`.

## Known Scope

- This is not a native port.
- The tested runtime path is Linux with FS-UAE and AROS.
- Window scaling and filter options are early launcher-level settings.
- Deeper graphics enhancement and FS-UAE forking remain future work.
