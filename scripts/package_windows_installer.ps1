param(
  [string]$Version = $(if ($env:VERSION) { $env:VERSION } else { "v0.6.1" }),
  [string]$OutDir = $(if ($env:OUT_DIR) { $env:OUT_DIR } else { "" }),
  [string]$FsUaeBundleBin = $(if ($env:FS_UAE_BUNDLE_BIN) { $env:FS_UAE_BUNDLE_BIN } else { "" }),
  [string]$Iscc = $(if ($env:ISCC) { $env:ISCC } else { "" })
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $Root "dist"
}

$PackageArgs = @{
  Version = $Version
  OutDir = $OutDir
}
if (-not [string]::IsNullOrWhiteSpace($FsUaeBundleBin)) {
  $PackageArgs.FsUaeBundleBin = $FsUaeBundleBin
}
& (Join-Path $PSScriptRoot "package_windows_x64.ps1") @PackageArgs

$Pkg = "Enemy-Tempest-Reborn-$Version-windows-x64"
$Stage = Join-Path $OutDir $Pkg
if (-not (Test-Path $Stage)) {
  throw "Windows package stage not found: $Stage"
}

if ([string]::IsNullOrWhiteSpace($Iscc)) {
  $Candidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
  )
  $Iscc = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($Iscc) -or -not (Test-Path $Iscc)) {
  throw "ISCC.exe not found. Install Inno Setup 6 or set ISCC."
}

$InstallerName = "Enemy-Tempest-Reborn-$Version-windows-x64-setup"
$Installer = Join-Path $OutDir "$InstallerName.exe"
$Sum = "$Installer.sha256"
$Iss = Join-Path $OutDir "enemy-tempest-reborn-$Version.iss"
$Icon = Join-Path $Root "launcher/windows/runner/resources/app_icon.ico"

@"
#define MyAppName "Enemy: Tempest Reborn"
#define MyAppVersion "$Version"
#define MyAppPublisher "Stephan Kaufmann"
#define MyAppExeName "launcher.exe"

[Setup]
AppId={{0DE23F2D-0384-46C4-8208-0AB0FE8D5E50}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Enemy Tempest Reborn
DefaultGroupName=Enemy Tempest Reborn
DisableProgramGroupPage=yes
OutputDir=$OutDir
OutputBaseFilename=$InstallerName
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
SetupIconFile=$Icon

[Files]
Source: "$Stage\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Enemy Tempest Reborn"; Filename: "{app}\run-windows.bat"; WorkingDir: "{app}"
Name: "{autodesktop}\Enemy Tempest Reborn"; Filename: "{app}\run-windows.bat"; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
Filename: "{app}\run-windows.bat"; Description: "Launch Enemy: Tempest Reborn"; Flags: nowait postinstall skipifsilent
"@ | Set-Content -Encoding ASCII $Iss

& $Iscc $Iss
$Hash = (Get-FileHash -Algorithm SHA256 $Installer).Hash.ToLowerInvariant()
"$Hash  $(Split-Path -Leaf $Installer)" | Set-Content -Encoding ASCII $Sum

Write-Output $Installer
Write-Output $Sum
