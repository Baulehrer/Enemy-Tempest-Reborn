# Enemy: Tempest Reborn v0.2.0 Roadmap

Date: 2026-07-01

The v0.1.0 release proves the current Linux/FS-UAE/AROS path and ships a
launcher package that expects `fs-uae` in `PATH`. The next package line should
move toward a self-contained runtime.

## Priority 1: Bundled FS-UAE

Goal:

- ship FS-UAE with the package instead of requiring a system installation
- keep the launcher able to fall back to system `fs-uae` during development
- use the bundled binary from `bin/fs-uae/fs-uae` when present

Reason:

- users should be able to extract the package and start it without separately
  installing an emulator
- later graphics, input, pause-overlay, and timing work will likely require a
  project-specific FS-UAE patch set

Initial launcher support is already prepared:

```text
bin/fs-uae/fs-uae
```

If that executable exists, the launcher uses it. Otherwise it falls back to
`fs-uae` from `PATH`.

The detailed Linux x64 bundling plan is documented in
`docs/FS_UAE_BUNDLING_STRATEGY.md`. The first bundle target is unmodified
FS-UAE 3.2.35; project-specific FS-UAE patches should start only after that
bundle is proven against the existing smoke matrix.

## Priority 2: About And Version Surface

The launcher now has an `ABOUT` button with:

- project name
- launcher version
- included targets/features
- current FS-UAE packaging status
- planned bundled/patched FS-UAE note

Before a v0.2.0 release, update the visible version from `0.2.0-dev` to the
final release tag.

## Priority 3: Package Builder

Create a repeatable package script that builds:

```text
Enemy-Tempest-Reborn-v0.2.0-linux-x64.tar.gz
Enemy-Tempest-Reborn-v0.2.0-linux-x64.tar.gz.sha256
```

The package should include:

- Flutter launcher bundle
- bundled FS-UAE runtime under `bin/fs-uae/`
- AROS ROMs
- Enemy ADFs
- prepared patched ADFs
- FS-UAE configs
- docs and evidence screenshots
- `run-linux.sh`

## Out Of Scope For v0.2.0

- native game port
- deep renderer rewrite
- final Windows/macOS packages
- AI frame interpolation
