# FS-UAE Bundling Strategy

Date: 2026-07-01

This document defines the planned Linux x64 FS-UAE bundling path for
Enemy: Tempest Reborn after `v0.1.0`.

## Current Baseline

The current tested system emulator is:

```text
FS-UAE 3.2.35
```

The installed Linux package reports:

```text
Name: fs-uae
Version: 3.2.35-2.1
License: GPL-2.0-only
```

`v0.1.0` requires `fs-uae` to be installed separately and available in `PATH`.
The launcher on `main` is already prepared to prefer a bundled binary at:

```text
bin/fs-uae/fs-uae
```

If that file is missing, it falls back to system `fs-uae`.

## Goal For v0.2.0

Ship a package that includes FS-UAE, so users can extract the archive and start:

```bash
./run-linux.sh
```

without installing FS-UAE separately.

The bundled emulator should initially be unmodified FS-UAE 3.2.35. Project
patches should start only after the unmodified bundled build is proven to behave
like the system FS-UAE baseline.

## Target Package Layout

```text
Enemy-Tempest-Reborn-v0.2.0-linux-x64/
  run-linux.sh
  launcher/
    launcher
    data/
    lib/
  bin/
    fs-uae/
      fs-uae
      COPYING
      source/
      THIRD_PARTY_NOTICES.md
    share/
      fs-uae/
        fs-uae.dat
        share-dir
  configs/
  assets/
  roms/
  work/kickstart-deps/patches/
  docs/
  evidence/
  output/
```

`run-linux.sh` should keep the package root as the working directory. This is
important because the FS-UAE profiles use repository-relative paths.

## Bundle Sources

Use this order of preference:

1. Reproducible source build from FS-UAE `v3.2.35`.
2. If source build is temporarily blocked, copy the system `fs-uae` binary and
   document the exact distro package version and dependency assumptions.

The release-quality path is option 1.

## License Requirements

FS-UAE is GPL-2.0-only according to the installed package metadata. Bundling it
means the package must also provide the corresponding license and source access.

Minimum package requirements:

- include FS-UAE GPL license text as `bin/fs-uae/COPYING`
- include or point to the exact corresponding FS-UAE source used for the binary
- document local patches if the binary differs from upstream FS-UAE 3.2.35
- preserve third-party notices for bundled libraries or copied runtime files

If the package includes only the FS-UAE executable and relies on system shared
libraries, document those dependencies clearly. If it includes shared libraries,
their licenses and source obligations must be checked individually.

## Build Phases

### Phase 1: Unmodified FS-UAE Bundle

- build or collect FS-UAE 3.2.35
- place executable at `bin/fs-uae/fs-uae`
- copy FS-UAE runtime data to `bin/share/fs-uae/`, matching the binary's
  relative lookup path `../share/fs-uae/share-dir`
- package launcher plus runtime data
- run the clean package smoke matrix
- confirm the launcher status does not ask for system `fs-uae`
- confirm `F12` opens FS-UAE's internal menu in the bundled package

Acceptance:

```text
enemy1-de  reaches menu
enemy1-en  reaches menu
enemy2-de  reaches boot/logo or memory screen
enemy2-en  reaches boot/logo or memory screen
intro-de   reaches intro frame and exits
intro-en   reaches intro frame and exits
```

### Phase 2: Project Patch Branch

Start a dedicated FS-UAE branch only after Phase 1 is stable.

Likely patch areas:

- pause/menu return handling
- host-side overlay hooks
- better filter/scale defaults
- input mapping for keyboard/gamepad/joystick
- optional screenshot/smoke-test hooks

Every patch should keep the unmodified FS-UAE baseline available for comparison.

### Phase 3: Patched FS-UAE Bundle

- build patched FS-UAE from documented source
- include patch series or fork URL/commit
- update About dialog from `0.2.0-dev` to release version
- run full clean package smoke matrix
- publish archive and SHA256 file as release assets

## Do Not Do Yet

- do not patch FS-UAE before the unmodified bundle works
- do not vendor arbitrary shared libraries without license review
- do not replace the AROS/ADF compatibility baseline while changing emulator
  packaging
- do not make graphics changes and bundling changes in the same proof step

## Next Concrete Step

Use `scripts/package_linux_x64.sh` to build:

```text
Enemy-Tempest-Reborn-v0.2.0-dev-linux-x64.tar.gz
Enemy-Tempest-Reborn-v0.2.0-dev-linux-x64.tar.gz.sha256
```

The script accepts an optional FS-UAE path:

```bash
FS_UAE_BUNDLE_BIN=/path/to/fs-uae ./scripts/package_linux_x64.sh
```

If `FS_UAE_BUNDLE_BIN` is unset, the script should build the package without a
bundled emulator and keep the current PATH fallback behavior.

## Current Implementation Status

Implemented on `main` after `v0.1.0`:

- launcher prefers `bin/fs-uae/fs-uae`
- `scripts/run_tempestreborn.sh` prefers `bin/fs-uae/fs-uae`
- `scripts/smoke_tempestreborn_profiles.sh` prefers `bin/fs-uae/fs-uae`
- `scripts/package_linux_x64.sh` builds package archives
- `scripts/package_linux_x64.sh` can include a bundled executable via
  `FS_UAE_BUNDLE_BIN`
- bundled builds also copy `/usr/share/fs-uae` to `bin/share/fs-uae`, so the
  internal FS-UAE menu/theme data is available from the same relative path as
  in a system install

Important packaging detail:

```text
System binary path:   /usr/bin/fs-uae
System data path:     /usr/share/fs-uae
Bundled binary path:  bin/fs-uae/fs-uae
Bundled data path:    bin/share/fs-uae
```

The bundled data path is intentional. FS-UAE looks for its data relative to the
executable path via `../share/fs-uae`. Copying only the executable is enough to
boot Enemy, but it can leave FS-UAE's internal `F12` menu without its runtime
data.

Local proof run:

```bash
VERSION=v0.2.0-dev-bundled OUT_DIR=/tmp/enemy-package-script-test \
FS_UAE_BUNDLE_BIN=/usr/bin/fs-uae ./scripts/package_linux_x64.sh
```

The generated bundled package was extracted and tested without setting
`FS_UAE_BIN`:

```bash
./bin/fs-uae/fs-uae --version
GAME_DURATION=10 GAME_SHOTS=5 ./scripts/smoke_tempestreborn_profiles.sh enemy1-de
```

Result:

```text
3.2.35
enemy1-de  timeout_terminated
```

This proves the package fallback path finds and uses the bundled
`bin/fs-uae/fs-uae` binary.

A fuller package probe is documented in
`docs/BUNDLED_FS_UAE_DEV_PACKAGE_TEST.md`. That probe proves bundled launch and
Enemy 1 smoke, but also records that the long automated matrix still depends too
much on host focus/ydotool behavior for screenshots and Intro exit.
