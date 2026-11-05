# Packs the Microsoft Store package (windows/msix/AppxManifest.xml) from the
# folder `dart run tool/package_desktop.dart --store` staged, after a build
# with MURMUR_STORE (no mining, so no murmur-miner in it). Run by the
# regression (smoke-windows) and the release (build-windows):
#
#   powershell -File tool\msix_package.ps1 -Version 0.10.4 `
#     -Source build\desktop-package\murmur-client-v0.10.4-windows-x64-store `
#     -Output dist\murmur-client-v0.10.4-windows-x64.msix -Check
#
# -IdentityName, -Publisher and -PublisherDisplayName (by default from the
# environment's MSIX_IDENTITY_NAME, MSIX_PUBLISHER and
# MSIX_PUBLISHER_DISPLAY_NAME) are what Partner Center shows under Product
# identity once the app's name is reserved; until then
# the placeholders below make a package that installs here but that the
# Store refuses. The package is left unsigned: the Store signs what it
# publishes.
#
# -Check installs the package once and removes it, as the Store would:
# signed with a certificate made for the run and trusted for the run only
# (in the machine's Trusted People, so it needs an administrator: CI's
# runners). It refuses where the package is installed already. With it:
#
# -Certify runs the Windows App Certification Kit (the Store's own tests,
#   appcert.exe from the Windows SDK) on the package first, and fails when
#   the kit does; its report is written beside the package
#   (<name>.wack.xml).
# -Smoke, while the package is installed, starts it as the Start menu does
#   and tries it (tool/desktop_smoke_test.dart --packaged): its node, beside
#   the installer's copy's, its own folder, a notification's click. The app
#   must be a demo build (MURMUR_LOCAL_NODE_SPEC=demo), and a runner without
#   a graphics card needs the software graphics beside it
#   (fetch_test_graphics.ps1), which only -AllowTestGraphics lets in: never
#   in a package for the Store.
param(
  [Parameter(Mandatory)][string]$Version,
  [Parameter(Mandatory)][string]$Source,
  [Parameter(Mandatory)][string]$Output,
  [string]$IdentityName = $env:MSIX_IDENTITY_NAME,
  [string]$Publisher = $env:MSIX_PUBLISHER,
  [string]$PublisherDisplayName = $env:MSIX_PUBLISHER_DISPLAY_NAME,
  [switch]$Check,
  [switch]$Certify,
  [switch]$Smoke,
  [switch]$AllowTestGraphics
)
$ErrorActionPreference = 'Stop'

if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "the version is x.y.z, not $Version" }
# Unset (or set empty, as an unset repository variable is): the placeholders.
if (-not $IdentityName) { $IdentityName = 'MurmurAssociation.Murmur' }
if (-not $Publisher) { $Publisher = 'CN=Murmur Association' }
if (-not $PublisherDisplayName) { $PublisherDisplayName = 'Murmur Association' }

# The Windows SDK's tools, from its newest version here.
$kits = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
$sdk = Get-ChildItem $kits -Directory | Where-Object { Test-Path "$($_.FullName)\x64\makeappx.exe" } |
  Sort-Object { [version]$_.Name } | Select-Object -Last 1
if (-not $sdk) { throw "no Windows SDK with makeappx.exe under $kits" }
$bin = "$($sdk.FullName)\x64"

$src = (Resolve-Path $Source).Path
foreach ($f in 'murmur_client.exe', 'murmur-node.exe', 'flutter_windows.dll', 'data\flutter_assets', 'LICENSE', 'NOTICE') {
  if (-not (Test-Path (Join-Path $src $f))) { throw "$f is missing from $src" }
}
if (Test-Path (Join-Path $src 'murmur-miner.exe')) {
  throw "$src holds murmur-miner.exe: stage it with package_desktop.dart --store"
}
if (-not $AllowTestGraphics) {
  foreach ($f in 'opengl32.dll', 'libgallium_wgl.dll', 'd3d10warp.dll') {
    if (Test-Path (Join-Path $src $f)) { throw "$src holds $f, the tests' software graphics (fetch_test_graphics.ps1)" }
  }
}
if (($Certify -or $Smoke) -and -not $Check) { throw '-Certify and -Smoke go with -Check' }

$work = Join-Path ([IO.Path]::GetTempPath()) "murmur-msix-$PID"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
$layout = Join-Path $work 'layout'
$res = Join-Path $work 'resources'
New-Item -ItemType Directory -Force $layout, $res | Out-Null
Copy-Item -Recurse "$src\*" $layout

function Escape([string]$s) { [Security.SecurityElement]::Escape($s) }
$manifest = (Get-Content -Raw "$PSScriptRoot\..\windows\msix\AppxManifest.xml").
  Replace('{IDENTITY_NAME}', (Escape $IdentityName)).
  Replace('{PUBLISHER_DISPLAY_NAME}', (Escape $PublisherDisplayName)).
  Replace('{PUBLISHER}', (Escape $Publisher)).
  Replace('{VERSION}', "$Version.0")
if ($manifest -match '\{[A-Z_]+\}') { throw "the manifest still holds $($Matches[0])" }

# The logos' resource index: built from the logos and the manifest alone, so
# the app's own files (data\flutter_assets) aren't taken for resources.
foreach ($dir in $layout, $res) {
  [IO.File]::WriteAllText("$dir\AppxManifest.xml", $manifest, (New-Object Text.UTF8Encoding $false))
  Copy-Item -Recurse "$PSScriptRoot\..\windows\msix\Assets" "$dir\Assets"
}
& "$bin\makepri.exe" createconfig /cf "$work\priconfig.xml" /dq en-US /pv 10.0.0 /o | Out-Null
if ($LASTEXITCODE -ne 0) { throw "makepri createconfig failed ($LASTEXITCODE)" }
# One index for one package: the default config splits it by scale and
# language, for bundles of resource packages.
$config = [xml](Get-Content -Raw "$work\priconfig.xml")
foreach ($p in @($config.SelectNodes('//packaging'))) { [void]$p.ParentNode.RemoveChild($p) }
$config.Save("$work\priconfig.xml")
& "$bin\makepri.exe" new /pr $res /cf "$work\priconfig.xml" /mn "$res\AppxManifest.xml" /of "$layout\resources.pri" /o | Out-Null
if ($LASTEXITCODE -ne 0) { throw "makepri new failed ($LASTEXITCODE)" }

$out = [IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
& "$bin\makeappx.exe" pack /d $layout /p $out /o /h SHA256 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "makeappx pack failed ($LASTEXITCODE)" }
Write-Output "wrote $out ($([math]::Round((Get-Item $out).Length / 1MB, 1)) MiB) as $IdentityName $Version.0"
if (-not $Check) { Remove-Item -Recurse -Force $work; exit 0 }

if (Get-AppxPackage -Name $IdentityName) { throw "$IdentityName is installed here already: not checking over it" }
$signed = Join-Path $work 'signed.msix'
Copy-Item $out $signed
$cert = New-SelfSignedCertificate -Type Custom -Subject $Publisher -KeyUsage DigitalSignature `
  -FriendlyName 'murmur msix check' -CertStoreLocation Cert:\CurrentUser\My `
  -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
$trusted = $null
try {
  $password = ConvertTo-SecureString -String "check-$PID" -Force -AsPlainText
  Export-PfxCertificate -Cert $cert -FilePath "$work\check.pfx" -Password $password | Out-Null
  & "$bin\signtool.exe" sign /fd SHA256 /f "$work\check.pfx" /p "check-$PID" $signed | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "signtool failed ($LASTEXITCODE)" }
  Export-Certificate -Cert $cert -FilePath "$work\check.cer" | Out-Null
  $trusted = Import-Certificate -FilePath "$work\check.cer" -CertStoreLocation Cert:\LocalMachine\TrustedPeople

  if ($Certify) {
    # The kit installs and removes the package itself, so before ours.
    $appcert = "${env:ProgramFiles(x86)}\Windows Kits\10\App Certification Kit\appcert.exe"
    if (-not (Test-Path $appcert)) { throw "no Windows App Certification Kit at $appcert" }
    $report = [IO.Path]::ChangeExtension($out, '.wack.xml')
    if (Test-Path $report) { Remove-Item $report }
    & $appcert reset | Out-Null
    # What the kit and the test say on stderr is output, not a failure.
    & { $ErrorActionPreference = 'Continue'; & $appcert test -appxpackagepath $signed -reportoutputpath $report }
    if (-not (Test-Path $report)) { throw "the certification kit wrote no report (exit code $LASTEXITCODE)" }
    $xml = [xml](Get-Content -Raw $report)
    $overall = $xml.REPORT.OVERALL_RESULT
    foreach ($t in @($xml.SelectNodes('//TEST'))) {
      $result = "$($t.RESULT.InnerText)".Trim()
      if ($result -and $result -ne 'PASS') {
        Write-Output "  ${result}: $($t.NAME)"
        foreach ($m in @($t.SelectNodes('.//MESSAGE'))) { Write-Output "      $($m.TEXT)$($m.InnerText)" }
      }
    }
    Write-Output "the certification kit's result: $overall (report: $report)"
    if ($overall -eq 'FAIL') { throw "the package fails the Windows App Certification Kit" }
    if (Get-AppxPackage -Name $IdentityName) { throw "the certification kit left the package installed" }
  }

  Add-AppxPackage -Path $signed
  $installed = Get-AppxPackage -Name $IdentityName
  if (-not $installed) { throw "the package did not install" }
  foreach ($f in 'murmur_client.exe', 'murmur-node.exe', 'resources.pri', 'Assets\StoreLogo.scale-100.png') {
    if (-not (Test-Path (Join-Path $installed.InstallLocation $f))) { throw "$f is missing from the installed package" }
  }
  if (Test-Path (Join-Path $installed.InstallLocation 'murmur-miner.exe')) { throw "the installed package holds murmur-miner.exe" }
  Write-Output "installed $($installed.PackageFullName) into $($installed.InstallLocation)"
  if ($Smoke) {
    Push-Location "$PSScriptRoot\.."
    try {
      & { $ErrorActionPreference = 'Continue'; dart run tool/desktop_smoke_test.dart --packaged $installed.PackageFamilyName $installed.InstallLocation }
      if ($LASTEXITCODE -ne 0) { throw "the installed package failed its smoke test ($LASTEXITCODE)" }
    } finally {
      Pop-Location
    }
  }
  Remove-AppxPackage -Package $installed.PackageFullName
  $installed = $null
  if (Get-AppxPackage -Name $IdentityName) { throw "the package was not removed" }
  Write-Output "and removed it"
} finally {
  # Never left installed, even after a failure.
  $left = Get-AppxPackage -Name $IdentityName
  if ($left) { Remove-AppxPackage -Package $left.PackageFullName }
  if ($trusted) { Remove-Item "Cert:\LocalMachine\TrustedPeople\$($trusted.Thumbprint)" }
  Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"
  Remove-Item -Recurse -Force $work
}
