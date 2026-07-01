# Bundled FS-UAE Dev Package Test

Date: 2026-07-01

This test validates the first `v0.2.0-dev` Linux x64 package prototype with a
bundled FS-UAE binary.

## Build

Command:

```bash
VERSION=v0.2.0-dev OUT_DIR=/tmp/enemy-v020-package \
FS_UAE_BUNDLE_BIN=/usr/bin/fs-uae ./scripts/package_linux_x64.sh
```

Generated files:

```text
/tmp/enemy-v020-package/Enemy-Tempest-Reborn-v0.2.0-dev-linux-x64.tar.gz
/tmp/enemy-v020-package/Enemy-Tempest-Reborn-v0.2.0-dev-linux-x64.tar.gz.sha256
```

The archive checksum verified successfully after extraction.

## Bundle Contents

The package includes:

```text
bin/fs-uae/fs-uae
bin/fs-uae/COPYING
bin/fs-uae/README
bin/fs-uae/BUNDLE_INFO.txt
```

This first prototype copied only the executable and documentation. That was
enough to prove that Enemy could launch through the bundled binary, but it did
not fully mirror the system FS-UAE runtime layout.

`BUNDLE_INFO.txt`:

```text
Bundled FS-UAE binary
source_path=/usr/bin/fs-uae
version=3.2.35
```

## Short Smoke

The package was extracted to:

```text
/tmp/enemy-v020-run/Enemy-Tempest-Reborn-v0.2.0-dev-linux-x64
```

Command:

```bash
./bin/fs-uae/fs-uae --version
GAME_DURATION=10 GAME_SHOTS=5 ./scripts/smoke_tempestreborn_profiles.sh enemy1-de
```

Result:

```text
3.2.35
enemy1-de  timeout_terminated
```

The smoke manifest confirmed that the bundled emulator path was used:

```text
fs_uae_bin=/tmp/enemy-v020-run/Enemy-Tempest-Reborn-v0.2.0-dev-linux-x64/bin/fs-uae/fs-uae
```

FS-UAE loaded the expected AROS ROMs and Enemy disk images from package-relative
paths.

## Full Matrix Probe

Command:

```bash
GAME_DURATION=45 INTRO_DURATION=35 GAME_SHOTS='20 40' INTRO_SHOTS='20 30' \
INTRO_INPUT_AT=24 ./scripts/smoke_tempestreborn_profiles.sh all
```

Summary:

```text
enemy1-de  timeout_terminated
enemy1-en  timeout_terminated
enemy2-de  timeout_terminated
enemy2-en  timeout_terminated
intro-de   timeout_terminated
intro-en   timeout_terminated
```

Interpretation:

- all six profiles launched through bundled `bin/fs-uae/fs-uae`
- all six profiles mapped AROS ROM and extension ROM
- all six profiles inserted the correct package-relative disk images
- no Address Error, Guru, or fatal FS-UAE process error was found in the logs
- Enemy 1 DE/EN produced visible menu screenshots
- the automated screenshot hotkey did not reliably produce copied screenshots
  for Enemy 2 and Intro in this long package run
- the scripted ydotool input was sent for Intro, but FS-UAE did not exit before
  the smoke timeout in this run

This is acceptable as a bundling prototype proof, but not yet a release-quality
matrix pass. The next work item is to make package smoke capture less dependent
on window focus and ydotool behavior, or to add a more deterministic FS-UAE
capture/quit hook.

## Current Status

Bundled FS-UAE package path: **proven for launch and basic Enemy 1 smoke**.

Release-quality v0.2.0 gate still needs:

- reliable screenshots for all six profiles from the packaged runtime
- reliable Intro return/quit behavior, ideally without host focus dependence
- corresponding FS-UAE source/license packaging for the exact bundled binary

## F12 Menu Runtime Data Fix

Follow-up observation:

```text
System FS-UAE: F12 opens the internal FS-UAE menu
Dev bundle:    F12 did not open/show the same menu
```

Cause:

The dev bundle initially copied only `bin/fs-uae/fs-uae`. The installed FS-UAE
binary expects its runtime data at a relative `../share/fs-uae` path. On the
system install this resolves to `/usr/share/fs-uae`; in the bundle it resolves
to `bin/share/fs-uae`.

Fix:

`scripts/package_linux_x64.sh` now copies `/usr/share/fs-uae` into:

```text
bin/share/fs-uae/
```

On this Linux system that directory contains:

```text
fs-uae.dat
share-dir
```

This restores the same relative runtime-data layout that the system binary sees
and is required for bundled menu/theme data such as the internal `F12` menu.

Verification package:

```bash
VERSION=v0.2.0-dev OUT_DIR=/tmp/enemy-v020-package-menu \
FS_UAE_BUNDLE_BIN=/usr/bin/fs-uae ./scripts/package_linux_x64.sh
```

Archive contents now include:

```text
bin/share/fs-uae/fs-uae.dat
bin/share/fs-uae/share-dir
```

Extracted package smoke:

```bash
GAME_DURATION=10 GAME_SHOTS=5 ./scripts/smoke_tempestreborn_profiles.sh enemy1-de
```

Result:

```text
enemy1-de  timeout_terminated
```

Relevant FS-UAE log evidence:

```text
fs_uae_bin=.../bin/fs-uae/fs-uae
[I18N] Using data dir ".../bin/fs-uae/../share/fs-uae/share-dir"
loaded sub-texture "sidebar.png"
loaded sub-texture "pause_indicator.png"
loaded sub-texture "top_background.png"
```

This confirms that the bundled binary no longer relies on the system
`/usr/share/fs-uae` data directory for the internal menu/theme resources.
