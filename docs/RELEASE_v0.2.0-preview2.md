# Enemy: Tempest Reborn v0.2.0-preview2

Date: 2026-07-01

This Linux preview supersedes `v0.2.0-preview1`. The package contents are the
same player-facing bundle, but the `.sha256` release asset is now generated with
a relative archive filename instead of an absolute local build path.

## Contents

- host-side Flutter launcher
- Enemy 1 and Enemy 2 DE/EN launch targets
- separate Enemy 1 Intro DE/EN launch targets
- prepared AROS ROM runtime used by the project tests
- prepared closewb-NOP and level-unlock Enemy ADF variants
- unmodified FS-UAE 3.2.35 binary
- FS-UAE runtime data under `bin/share/fs-uae/`

## Runtime Defaults

- fullscreen launch path
- `zoom = auto` for all Tempest Reborn FS-UAE profiles
- floppy drive speed at maximum
- floppy sounds disabled
- A1200 profile with 2 MB Chip RAM and 2 MB Fast RAM

`F12` opens the internal FS-UAE menu. `F11` cycles FS-UAE zoom modes.

## Packaging Fix Since preview1

`v0.2.0-preview1` uploaded a valid archive, but its `.sha256` file contained an
absolute local build path. `scripts/package_linux_x64.sh` now writes the
checksum from inside the output directory, so users can verify the downloaded
archive directly:

```bash
sha256sum -c Enemy-Tempest-Reborn-v0.2.0-preview2-linux-x64.tar.gz.sha256
```

Expected checksum-file shape:

```text
<sha256>  Enemy-Tempest-Reborn-v0.2.0-preview2-linux-x64.tar.gz
```

## Verification

Package build command:

```bash
VERSION=v0.2.0-preview2 OUT_DIR=/tmp/enemy-v020-preview2 \
FS_UAE_BUNDLE_BIN=/usr/bin/fs-uae ./scripts/package_linux_x64.sh
```

Extracted package checks:

```text
bin/fs-uae/fs-uae reports FS-UAE 3.2.35
all Tempest Reborn profiles contain zoom = auto
enemy1-de package smoke reached the planned timeout without FS-UAE crash
```

Relevant smoke evidence:

```text
fs_uae_bin=.../bin/fs-uae/fs-uae
zoom = auto
[I18N] Using data dir ".../bin/fs-uae/../share/fs-uae/share-dir"
loaded sub-texture "sidebar.png"
loaded sub-texture "pause_indicator.png"
```

## Known Preview Limitations

- Linux x64 only.
- FS-UAE is bundled from the local system package for this preview.
- This is not yet the future patched FS-UAE fork; graphics/filter work still
  belongs to later v0.2.x milestones.
- Automated long-run screenshot capture is still less reliable than manual
  visual checks because it depends on host window focus.
