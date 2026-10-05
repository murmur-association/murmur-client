# Tries the built Windows app as a user would start it. Run after
# `flutter build windows --release` and `dart run tool/bundle_node.dart`:
#
#   powershell -ExecutionPolicy Bypass -File tool\windows_smoke_test.ps1 [-WalletStorage] [-Bundle <folder>]
#
# 1. The app starts, shows its window, and runs its own node as a child
#    when that's switched on; closing the window stops both.
# 2. After the app is killed, its node is left running; the next start
#    stops that one and runs a new one.
# 3. With -WalletStorage (needs flutter, in the project folder): a wallet is
#    saved through Windows' own secure storage, found again, unlocked and
#    removed (integration_test/wallet_storage_test.dart, inside the app).
#
# The same checks as tool/linux_smoke_test.sh. Windows has no throwaway
# session to give the app: its settings, wallet and node data go under the
# user's own %APPDATA%. So this refuses to run where the app has been used
# (its folders exist), and removes them again when it's done. A release
# runner starts clean. Build with --dart-define=MURMUR_LOCAL_NODE_SPEC=demo
# to keep the node off the public network.
param(
  [switch]$WalletStorage,
  [string]$Bundle = 'build\windows\x64\runner\Release'
)
$ErrorActionPreference = 'Stop'

$exe = Join-Path (Resolve-Path $Bundle) 'murmur_client.exe'
$nodeExe = Join-Path (Resolve-Path $Bundle) 'murmur-node.exe'
foreach ($f in $exe, $nodeExe) { if (-not (Test-Path $f)) { Write-Output "missing ${f}: build the app and bundle the node first"; exit 1 } }

# Where the app keeps its settings and wallet, and its node's data.
$settings = Join-Path $env:APPDATA 'Murmur Association'
$data = Join-Path $env:APPDATA 'murmur-client'
foreach ($d in $settings, $data) {
  if (Test-Path $d) { Write-Output "${d} exists: the app has been used here, and this test would change its settings. Nothing was touched."; exit 1 }
}

function Fail($what) { Write-Output "FAILED: $what"; throw 'smoke test failed' }
function Wait-For($seconds, $what, [scriptblock]$check) {
  for ($i = 0; $i -lt $seconds * 2; $i++) { if (& $check) { return }; Start-Sleep -Milliseconds 500 }
  Fail $what
}
function Alive($id) { $null -ne (Get-Process -Id $id -ErrorAction SilentlyContinue) }
# The app's own node: the bundled program, started by this app.
function Node-Of($appId) {
  Get-CimInstance Win32_Process -Filter "Name='murmur-node.exe' AND ParentProcessId=$appId" | Select-Object -First 1
}
function Bundled-Nodes { @(Get-CimInstance Win32_Process -Filter "Name='murmur-node.exe'" | Where-Object { $_.ExecutablePath -eq $nodeExe }) }

# Starts the app and waits for its window and its node.
function Start-App {
  $script:app = Start-Process -PassThru $exe
  Wait-For 30 'no window titled Murmur appeared' { (Get-Process -Id $script:app.Id -ErrorAction SilentlyContinue).MainWindowTitle -eq 'Murmur' }
  Wait-For 30 "the node didn't start as the app's child" { $null -ne (Node-Of $script:app.Id) }
  $script:node = (Node-Of $script:app.Id).ProcessId
}
function Close-App {
  (Get-Process -Id $script:app.Id).CloseMainWindow() | Out-Null
  Wait-For 20 "the app didn't exit after its window was closed" { -not (Alive $script:app.Id) }
  Wait-For 10 'the node kept running after the app closed' { -not (Alive $script:node) }
}

$ok = $false
try {
  # The app's settings (shared_preferences): its own node switched on, as
  # the Chain tab's switch would.
  New-Item -ItemType Directory -Force (Join-Path $settings 'Murmur') | Out-Null
  '{"flutter.run_local_node":true}' | Out-File -Encoding ascii (Join-Path $settings 'Murmur\shared_preferences.json')

  Write-Output '== 1. start, and stop with the window'
  Start-App
  Write-Output "window: Murmur"
  Write-Output "node: pid $node, child of the app ($($app.Id))"
  Write-Output "node options: $((Get-CimInstance Win32_Process -Filter "ProcessId=$node").CommandLine -replace '^("[^"]*"|\S+)\s+', '')"
  Close-App
  Write-Output 'closing the window stopped the app and its node'

  Write-Output '== 2. a node left by a killed app is replaced'
  Start-App
  $left = $node
  Stop-Process -Id $app.Id -Force
  Wait-For 10 'the killed app is still there' { -not (Alive $app.Id) }
  if (-not (Alive $left)) { Fail "the node died with the killed app, so there's nothing to clean up" }
  Start-App
  Wait-For 15 'the node left by the killed app is still running' { -not (Alive $left) }
  if ((Bundled-Nodes).Count -ne 1) { Fail 'more than one node is running' }
  Write-Output "node $left was left behind; the next start stopped it and runs $node"
  Close-App

  if ($WalletStorage) {
    Write-Output '== 3. a wallet through the real secure storage'
    flutter test integration_test/wallet_storage_test.dart -d windows 2>&1 | Select-Object -Last 12
    if ($LASTEXITCODE -ne 0) { Fail 'the wallet storage test' }
  }
  $ok = $true
  Write-Output 'OK'
} catch {
  if ("$_" -ne 'smoke test failed') { Write-Output "FAILED: $_" }
} finally {
  if ($app -and (Alive $app.Id)) { Stop-Process -Id $app.Id -Force -ErrorAction SilentlyContinue }
  Bundled-Nodes | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Seconds 1
  # Only what this run created: both folders were absent when it began.
  Remove-Item -Recurse -Force $settings, $data -ErrorAction SilentlyContinue
}
if (-not $ok) { exit 1 }
