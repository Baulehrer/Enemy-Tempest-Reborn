# Release Packaging

This project can produce portable release bundles for Linux, Windows, and
macOS. The bundles contain the Flutter launcher, Enemy ADFs, AROS ROMs,
FS-UAE profiles, documentation, and runtime folders.

## Local Linux build

```bash
VERSION=v0.6 ./scripts/package_linux_x64.sh
```

If `FS_UAE_BUNDLE_BIN` points to an executable FS-UAE binary, the package
includes it as `bin/fs-uae/fs-uae`.

```bash
VERSION=v0.6 \
FS_UAE_BUNDLE_BIN="$(command -v fs-uae)" \
./scripts/package_linux_x64.sh
```

Output:

- `dist/Enemy-Tempest-Reborn-<version>-linux-x64.tar.gz`
- `dist/Enemy-Tempest-Reborn-<version>-linux-x64.tar.gz.sha256`

To also create a Linux AppImage, install `appimagetool` and run:

```bash
VERSION=v0.6 \
FS_UAE_BUNDLE_BIN="$(command -v fs-uae)" \
APPIMAGETOOL=appimagetool \
./scripts/package_linux_appimage.sh
```

Additional output:

- `dist/Enemy-Tempest-Reborn-<version>-linux-x64.AppImage`
- `dist/Enemy-Tempest-Reborn-<version>-linux-x64.AppImage.sha256`

## Windows build

Windows packages must be built on Windows:

```powershell
.\scripts\package_windows_x64.ps1 -Version v0.6
```

If an FS-UAE binary is supplied, it is copied to
`bin\fs-uae\fs-uae.exe`.

```powershell
.\scripts\package_windows_x64.ps1 `
  -Version v0.6 `
  -FsUaeBundleBin "C:\Program Files\FS-UAE\fs-uae.exe"
```

Output:

- `dist/Enemy-Tempest-Reborn-<version>-windows-x64.zip`
- `dist/Enemy-Tempest-Reborn-<version>-windows-x64.zip.sha256`

To create the Inno Setup installer as well, install Inno Setup 6 and run:

```powershell
.\scripts\package_windows_installer.ps1 `
  -Version v0.6 `
  -FsUaeBundleBin "C:\Program Files\FS-UAE\fs-uae.exe"
```

Additional output:

- `dist/Enemy-Tempest-Reborn-<version>-windows-x64-setup.exe`
- `dist/Enemy-Tempest-Reborn-<version>-windows-x64-setup.exe.sha256`

## macOS build

macOS packages must be built on macOS:

```bash
VERSION=v0.6 ./scripts/package_macos_universal.sh
```

If `FS_UAE_BUNDLE_BIN` points to an executable FS-UAE binary, the package
includes it as `bin/fs-uae/fs-uae`.

Output:

- `dist/Enemy-Tempest-Reborn-<version>-macos-universal.zip`
- `dist/Enemy-Tempest-Reborn-<version>-macos-universal.zip.sha256`

## GitHub Actions

`.github/workflows/build-release-packages.yml` builds all platform packages via
GitHub Actions. It can be started manually with `workflow_dispatch` and also
runs for version tags matching `v*`. Linux produces both `.tar.gz` and
`.AppImage`; Windows produces both `.zip` and Inno Setup `.exe` installer.

The workflow attempts to install or locate FS-UAE on each runner. If FS-UAE is
found, it is bundled. If not, the package still builds, but the user must have
`fs-uae`/`fs-uae.exe` installed in `PATH`.

## Current limitation

Linux `.tar.gz` can be built and smoke-tested locally from this repository.
Linux AppImage requires `appimagetool`. Windows and macOS artifacts require
their native build hosts or the GitHub workflow.
