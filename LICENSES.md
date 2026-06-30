# Licenses and Provenance

## Enemy ADFs

The Enemy ADFs are included because the project owner stated that Enemy is
freeware and that permission from the developer exists to distribute these ADFs
for this compatibility/porting work.

Included files:

- `media/enemy-adfs/original/ENEMY1_V2_DE_A.adf`
- `media/enemy-adfs/original/ENEMY1_V2_DE_B.adf`
- `media/enemy-adfs/original/ENEMY2_V2_DE_A.adf`
- `media/enemy-adfs/original/ENEMY2_V2_DE_B.adf`

Patched ADFs are binary derivatives of `ENEMY1_V2_DE_A.adf` and are documented
with exact offsets, original bytes, replacement bytes, source SHA-256, and
patched SHA-256 in `docs/TECHNICAL_ARTIFACTS.md`.

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

## Repository Scripts and Documentation

The patch scripts, capture helpers, and documentation in this repository may be
used for reproducing, auditing, and improving the AROS compatibility result.
They are provided as research/compatibility material.

## Important Distinction

This repository does not claim that AROS itself was patched. The successful
workaround currently patches the Enemy `c/closewb` helper inside the Enemy ADF.
The AROS ROMs are included so AROS developers can reproduce the behavior against
the exact ROM binaries used in the tests.

