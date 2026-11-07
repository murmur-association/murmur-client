# Builds the Windows installer (windows/installer/murmur.iss) from a folder
# tool/package_desktop.dart staged, and with -Check installs it silently, as
# winget does, checks what's installed and uninstalls it. Run by the
# regression (smoke-windows, on every push) and the release (build-windows):
#
#   powershell -File tool\windows_installer.ps1 -Version 0.10.4 `
#     -Source build\desktop-package\murmur-client-v0.10.4-windows-x64 `
#     -Output dist\murmur-client-v0.10.4-windows-x64-setup.exe -Check
#
# Installs Inno Setup with Chocolatey when it's missing (CI runners).
param(
  [Parameter(Mandatory)][string]$Version,
  [Parameter(Mandatory)][string]$Source,
  [Parameter(Mandatory)][string]$Output,
  [switch]$Check
)
$ErrorActionPreference = 'Stop'

$iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $iscc)) {
  choco install innosetup -y --no-progress
  if ($LASTEXITCODE -ne 0) { throw "could not install Inno Setup" }
}
$out = [IO.Path]::GetFullPath($Output)
$src = (Resolve-Path $Source).Path
New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
& $iscc "/DAppVersion=$Version" "/DSourceDir=$src" "/DOutputDir=$(Split-Path $out)" `
  "/DOutputName=$([IO.Path]::GetFileNameWithoutExtension($out))" "$PSScriptRoot\..\windows\installer\murmur.iss"
if ($LASTEXITCODE -ne 0) { throw "ISCC failed ($LASTEXITCODE)" }
Write-Output "wrote $out"
if (-not $Check) { exit 0 }

# Into a folder of its own, never over a Murmur installed on this machine.
$dir = Join-Path ([IO.Path]::GetTempPath()) "murmur-installer-check-$PID"
$p = Start-Process -Wait -PassThru $out -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR=`"$dir`""
if ($p.ExitCode -ne 0) { throw "setup exited with $($p.ExitCode)" }
foreach ($f in 'murmur_client.exe', 'murmur-node.exe', 'flutter_windows.dll', 'data\flutter_assets', 'LICENSE', 'NOTICE') {
  if (-not (Test-Path (Join-Path $dir $f))) { throw "$f is missing from the installed app" }
}
$p = Start-Process -Wait -PassThru (Join-Path $dir 'unins000.exe') -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
if ($p.ExitCode -ne 0) { throw "the uninstaller exited with $($p.ExitCode)" }
# The uninstaller finishes from a copy of itself in the temp folder.
for ($i = 0; $i -lt 20 -and (Test-Path (Join-Path $dir 'murmur_client.exe')); $i++) { Start-Sleep -Seconds 1 }
if (Test-Path (Join-Path $dir 'murmur_client.exe')) { throw "the uninstaller left the app behind" }
Write-Output "installed into $dir and removed"
