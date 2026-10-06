# Puts software graphics beside a copy of the Windows app that is only
# tried, never released, so the app can start on a system without them:
#
#   powershell -ExecutionPolicy Bypass -File tool\fetch_test_graphics.ps1 -Into <folder>
#
# Every desktop Windows has what the app's engine needs to draw. The release
# runner (Windows Server 2022, a server image with no graphics card) lacks
# two libraries, so the app can't start there and
# tool\windows_smoke_test.ps1 can't try it:
# - OPENGL32.dll, which the engine loads at start: Mesa's (mesa-dist-win),
#   with the library it needs;
# - d3d10warp.dll, Windows' software Direct3D ("WARP"), the engine's last
#   resort without a graphics card: Microsoft's own package of it
#   (Microsoft.Direct3D.WARP on nuget.org), made to sit beside an app.
# Each download is pinned by version and SHA-256, as is 7-Zip's small
# extractor, which unpacks Mesa.
#
# For tests only: the project's rule against third parties is about what's
# released, and these files must never be in a released package. The
# release job gives them to the copy it tries, then builds and packages the
# released app afresh, and checks that package holds none of them.
param([Parameter(Mandatory = $true)][string]$Into)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$downloads = @(
  @{ Name = 'mesa.7z'
     Url = 'https://github.com/pal1000/mesa-dist-win/releases/download/26.2.4/mesa3d-26.2.4-release-msvc.7z'
     Sha256 = '351fc8c8b695878ffb3eaa044b3ead08672a48b1a045e3c3e3975811df0f6695' },
  @{ Name = '7zr.exe'
     Url = 'https://github.com/ip7z/7zip/releases/download/26.04/7zr.exe'
     Sha256 = '256feca8e274e5da655e2a284fabafd9f554365eb164862089dacd4e8276d282' },
  @{ Name = 'warp.zip'
     Url = 'https://api.nuget.org/v3-flatcontainer/microsoft.direct3d.warp/1.0.21/microsoft.direct3d.warp.1.0.21.nupkg'
     Sha256 = 'ea44b77eb30eec14427193e20f40cdb2e4c31ed11ab39cb880538fdf4bac2681' }
)
# The files a released package must never hold (the release job checks).
$mesa = 'opengl32.dll', 'libgallium_wgl.dll'
$warp = 'd3d10warp.dll'

if (-not (Test-Path $Into)) { Write-Output "no folder $Into"; exit 1 }
$work = 'build\test-graphics'
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

$out = Join-Path $work 'mesa'
& (Join-Path $work '7zr.exe') e (Join-Path $work 'mesa.7z') "-o$out" -y ($mesa | ForEach-Object { "x64\$_" }) | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Output 'could not unpack Mesa'; exit 1 }
foreach ($l in $mesa) { Copy-Item (Join-Path $out $l) $Into }

# The package is a zip; only its x64 library is wanted.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path (Join-Path $work 'warp.zip')))
try {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq "build/native/bin/x64/$warp" }
  if (-not $entry) { Write-Output "no x64 $warp in the WARP package"; exit 1 }
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path (Resolve-Path $Into) $warp), $true)
} finally { $zip.Dispose() }

Write-Output "for testing only, in ${Into}: $(($mesa + $warp) -join ', ') (Mesa 26.2.4, Microsoft WARP 1.0.21)"
