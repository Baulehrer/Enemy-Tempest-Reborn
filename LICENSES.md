# Licenses and Provenance

## Enemy ADFs

The Enemy ADFs are included because the project owner stated that Enemy is
freeware and that permission from the developer exists to distribute these ADFs
for this compatibility/porting work.

Included files:

- `assets/adf/ENEMY1_V2_DE_A.adf`
- `assets/adf/ENEMY1_V2_DE_B.adf`
- `assets/adf/ENEMY1_V2_EN_A.adf`
- `assets/adf/ENEMY1_V2_EN_B.adf`
- `assets/adf/ENEMY2_V2_DE_A.adf`
- `assets/adf/ENEMY2_V2_DE_B.adf`
- `assets/adf/ENEMY2_V2_EN_A.adf`
- `assets/adf/ENEMY2_V2_EN_B.adf`

Prepared patched ADFs are included under `work/kickstart-deps/patches/` and
are used by the launcher profiles.

## AROS ROMs

The AROS ROM binaries included here are the AROS ROMs used for testing. AROS is
licensed under the AROS Public License. The boot screen used during testing
reported:

```text
Licensed under the AROS Public License.
Version Git f8e1bic2e (https://github.com/aros-development-team/AROS)
built on 2026-06-21.
```

No Commodore Kickstart ROMs are included.

## FS-UAE

Release packages are built to include FS-UAE when the platform build runner can
install or locate it. FS-UAE is GPL-2.0-only in the tested package metadata.
Packages that bundle FS-UAE include the bundled emulator files under
`bin/fs-uae/`.

## Repository Scripts and Documentation

The remaining scripts are for packaging and rebuilding the prepared ADF
variants used by the launcher.

## Important Distinction

This repository does not claim that AROS itself was patched. The successful
workaround currently patches the Enemy `c/closewb` helper inside the Enemy ADF.
The AROS ROMs are included so AROS developers can reproduce the behavior against
the exact ROM binaries used in the tests.
