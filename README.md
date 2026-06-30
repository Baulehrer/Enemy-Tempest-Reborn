# Enemy: Tempest Reborn

This repository packages the current Enemy: Tempest Reborn AROS/UAE
compatibility work. It contains the original Enemy ADFs provided for this
project, AROS ROMs used for testing, reproducible ADF patch scripts, patched
Enemy ADF variants, FS-UAE configs, and evidence screenshots/manifests.

## Current Result

- Enemy V2 starts on AROS when run as an A1200 with 2 MB Chip RAM.
- The cleanest tested path uses an Enemy ADF variant where the `c/closewb`
  helper keeps its setup/stack cleanup but replaces the single `CloseWindow()`
  call with two 68k NOP instructions.
- With that `closewb` NOP patch, the intro can be skipped by mouse/fire and the
  main menu renders correctly.
- Without that NOP on AROS A1200/2 MB, the game reaches Enemy video modes but
  showed missing graphics during manual testing.
- On AROS A500-class configs, `ef/enemy` can fail with the misleading shell
  message `file is not executable`; static Hunk parsing indicates the file is a
  valid AmigaOS LoadSeg executable, so this appears environment/resource related.

See:

- `docs/CLOSEWB_NOP_FIX_EN.md`
- `docs/CLOSEWB_NOP_FIX_DE.md`
- `docs/TECHNICAL_ARTIFACTS.md`
- `LICENSES.md`

## Quick Test

Use FS-UAE with:

```text
configs/fs-uae/enemy1_arosclosewbnopdiag_a1200.fs-uae
```

That config points at:

```text
media/enemy-adfs/patched/ENEMY1_V2_DE_A.closewb-nop-diag.adf
media/enemy-adfs/original/ENEMY1_V2_DE_B.adf
roms/aros/aros-rom.bin
roms/aros/aros-ext.bin
```

The paths inside the copied FS-UAE configs may need adjustment after cloning,
because the original workspace used absolute local paths.

## Repository Name Note

The project display name is `Enemy: Tempest Reborn`. GitHub repository names
cannot contain `:`, so the technical repository name is intended to be
`Enemy-Tempest-Reborn`.
