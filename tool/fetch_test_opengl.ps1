# Puts a software OpenGL beside a copy of the Windows app that is only
# tried, never released, so the app can start on a system without one:
#
#   powershell -ExecutionPolicy Bypass -File tool\fetch_test_opengl.ps1 -Into <folder>
#
# Flutter's engine loads OPENGL32.dll at start. Every desktop Windows has
# it; the release runner (Windows Server 2022, a server image) doesn't, so
# the app can't start there and tool\windows_smoke_test.ps1 can't try it.
# This downloads Mesa's build for Windows (mesa-dist-win) and 7-Zip's small
# extractor, both pinned by version and SHA-256, and copies Mesa's
# opengl32.dll and the library it needs into the folder.
#
# For tests only: the project's rule against third parties is about what's
# released, and these files must never be in a released package. The
# release job gives them to the copy it tries, then builds and packages the
# released app afresh.
param([Parameter(Mandatory = $true)][string]$Into)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$downloads = @(
  @{ Name = 'mesa.7z'
     Url = 'https://github.com/pal1000/mesa-dist-win/releases/download/26.2.4/mesa3d-26.2.4-release-msvc.7z'
     Sha256 = '351fc8c8b695878ffb3eaa044b3ead08672a48b1a045e3c3e3975811df0f6695' },
  @{ Name = '7zr.exe'
     Url = 'https://github.com/ip7z/7zip/releases/download/26.04/7zr.exe'
     Sha256 = '256feca8e274e5da655e2a284fabafd9f554365eb164862089dacd4e8276d282' }
)
$libraries = 'opengl32.dll', 'libgallium_wgl.dll'

if (-not (Test-Path $Into)) { Write-Output "no folder $Into"; exit 1 }
$work = 'build\test-opengl'
New-Item -ItemType Directory -Force $work | Out-Null
foreach ($d in $downloads) {
  $file = Join-Path $work $d.Name
  if (-not (Test-Path $file) -or (Get-FileHash $file -Algorithm SHA256).Hash -ne $d.Sha256) {
    Invoke-WebRequest -UseBasicParsing -Uri $d.Url -OutFile $file
  }
  $hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $d.Sha256) {
    Remove-Item $file
    Write-Output "$($d.Name) is not the pinned file (SHA-256 $hash): refusing it"
    exit 1
  }
}
$out = Join-Path $work 'x64'
& (Join-Path $work '7zr.exe') e (Join-Path $work 'mesa.7z') "-o$out" -y ($libraries | ForEach-Object { "x64\$_" }) | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Output 'could not unpack Mesa'; exit 1 }
foreach ($l in $libraries) { Copy-Item (Join-Path $out $l) $Into }
Write-Output "for testing only: Mesa 26.2.4's $($libraries -join ' and ') are in $Into"
