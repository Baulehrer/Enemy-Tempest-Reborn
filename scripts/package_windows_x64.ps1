param(
  [string]$Version = $(if ($env:VERSION) { $env:VERSION } else { "v0.8" }),
  [string]$OutDir = $(if ($env:OUT_DIR) { $env:OUT_DIR } else { "" }),
  [string]$FsUaeBundleBin = $(if ($env:FS_UAE_BUNDLE_BIN) { $env:FS_UAE_BUNDLE_BIN } else { "" })
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $Root "dist"
}

$Pkg = "Enemy-Tempest-Reborn-$Version-windows-x64"
$Stage = Join-Path $OutDir $Pkg
$Archive = Join-Path $OutDir "$Pkg.zip"
$Sum = "$Archive.sha256"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $Stage, $Archive, $Sum
New-Item -ItemType Directory -Force -Path $Stage | Out-Null

Push-Location (Join-Path $Root "launcher")
flutter build windows --release
Pop-Location

Copy-Item -Recurse -Force (Join-Path $Root "launcher/build/windows/x64/runner/Release") (Join-Path $Stage "launcher")

foreach ($DirName in @("configs", "assets", "roms", "docs")) {
  $Source = Join-Path $Root $DirName
  if (Test-Path $Source) {
    Copy-Item -Recurse -Force $Source (Join-Path $Stage $DirName)
  }
}

$PatchSource = Join-Path $Root "work/kickstart-deps/patches"
if (Test-Path $PatchSource) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Stage "work/kickstart-deps") | Out-Null
  Copy-Item -Recurse -Force $PatchSource (Join-Path $Stage "work/kickstart-deps/patches")
}

foreach ($FileName in @("README.md", "README_DE.md", "LICENSES.md")) {
  Copy-Item -Force (Join-Path $Root $FileName) (Join-Path $Stage $FileName)
}

if (-not [string]::IsNullOrWhiteSpace($FsUaeBundleBin)) {
  if (-not (Test-Path $FsUaeBundleBin)) {
    throw "FS_UAE_BUNDLE_BIN not found: $FsUaeBundleBin"
  }
  $FsUaeDir = Join-Path $Stage "bin/fs-uae"
  New-Item -ItemType Directory -Force -Path $FsUaeDir | Out-Null
  $FsUaeSourceDir = Split-Path -Parent $FsUaeBundleBin
  Copy-Item -Recurse -Force (Join-Path $FsUaeSourceDir "*") $FsUaeDir
  if (-not (Test-Path (Join-Path $FsUaeDir "fs-uae.exe"))) {
    Copy-Item -Force $FsUaeBundleBin (Join-Path $FsUaeDir "fs-uae.exe")
  }
  @(
    "Bundled FS-UAE binary"
    "source_path=$FsUaeBundleBin"
    "source_dir=$FsUaeSourceDir"
  ) | Set-Content -Encoding ASCII (Join-Path $FsUaeDir "BUNDLE_INFO.txt")
}

@"
@echo off
setlocal
cd /d "%~dp0"
start "" "%~dp0launcher\launcher.exe"
"@ | Set-Content -Encoding ASCII (Join-Path $Stage "run-windows.bat")

@"
Enemy: Tempest Reborn $Version Windows x64

Start:
  run-windows.bat

If bin\fs-uae\fs-uae.exe is present, the launcher uses that bundled emulator.
Runtime files are written to the user's application data directory.
"@ | Set-Content -Encoding ASCII (Join-Path $Stage "PACKAGE_README.txt")

Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $Archive -Force
$Hash = (Get-FileHash -Algorithm SHA256 $Archive).Hash.ToLowerInvariant()
"$Hash  $(Split-Path -Leaf $Archive)" | Set-Content -Encoding ASCII $Sum

Write-Output $Archive
Write-Output $Sum
