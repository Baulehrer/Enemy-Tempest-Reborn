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

The current launcher profiles use the `cli-splash` ADF variants. These are
rebuilt from the prepared patched ADFs by `scripts/build_cli_splash_adfs.py`.
They add only a clean AmigaDOS startup message and do not modify AROS.

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

Included AROS ROM files:

- `roms/aros/aros-rom.bin`
- `roms/aros/aros-ext.bin`
- `roms/aros/aros-rom.20250816.bin`

## FS-UAE

Release packages are built to include FS-UAE when the platform build runner can
install or locate it. FS-UAE is GPL-2.0-only in the tested package metadata.
Packages that bundle FS-UAE include the bundled emulator files under
`bin/fs-uae/`.

## Shader Presets

The package includes FS-UAE shader preset files under
`configs/fs-uae-data/Shaders/`.

- `super-xbr-3p.shader` contains upstream copyright and permission notices from
  Hyllian directly in the file. Keep those notices with the shader.
- `hq2x-hard-light-bloom.shader` is a local combined FS-UAE shader preset used
  by the Enhanced Plus profile. No separate upstream notice header is present in
  the file; keep this provenance note with redistributed packages.

The built-in FS-UAE shader names referenced by the launcher, such as
`crt-hyllian`, `crt-lottes`, `scalefx`, and `scale4xhq`, are FS-UAE runtime
shader choices rather than files authored by this launcher.

## Launcher Assets

Launcher artwork under `launcher/assets/images/` is used for the menu, launch
splash, and About dialog. The Enemy/Anachronia artwork is included for this
package with the same project permission context as the Enemy ADFs above.

The German and English videos under `launcher/assets/video/` are derived
captures of the Enemy 1 intro running with a locally owned original Kickstart
ROM. The ROM itself is not included. The videos contain only Enemy/Anachronia
presentation material and are distributed under the same project permission
context as the Enemy ADFs.

The launcher uses `media_kit`, `media_kit_video`, and
`media_kit_libs_video` for cross-platform playback. These packages are MIT
licensed; their packaged notices remain part of the Flutter dependency output.

## Repository Scripts and Documentation

The remaining scripts are for packaging and rebuilding the prepared ADF
variants used by the launcher.

## Important Distinction

This repository does not claim that AROS itself was patched. The successful
workaround currently patches the Enemy `c/closewb` helper inside the Enemy ADF.
The AROS ROMs are included so AROS developers can reproduce the behavior against
the exact ROM binaries used in the tests.

## Version 1.0 gate

The remaining corresponding-source and written-permission requirements are
tracked in `docs/THIRD_PARTY_SOURCE.md`. They are release blockers until the
exact shipped artifacts have been reviewed; this file does not declare them
complete merely because a development package can be built.
