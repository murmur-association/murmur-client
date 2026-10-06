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

# The libraries the app's programs load at start that are neither beside
# them nor in this system: with any missing, Windows won't start the app
# (exit code -1073741515). Read from the files with dumpbin (the build
# tools'), so nothing is started; without dumpbin, nothing is known.
$bundleDir = Split-Path $exe
function Missing-Libraries {
  $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (-not (Test-Path $vswhere)) { return @() }
  $vs = & $vswhere -latest -products * -property installationPath
  $dumpbin = Get-ChildItem "$vs\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1
  if (-not $dumpbin) { return @() }
  # From the two programs, through the libraries beside them that they
  # load: not every library in the folder (a plugin ships one for Java,
  # dartjni.dll, that nothing loads on Windows).
  $missing = @{}
  $seen = @{}
  $queue = New-Object System.Collections.Queue
  $queue.Enqueue($exe); $queue.Enqueue($nodeExe)
  while ($queue.Count -gt 0) {
    $file = $queue.Dequeue()
    if ($seen[$file.ToLower()]) { continue }
    $seen[$file.ToLower()] = $true
    foreach ($line in & $dumpbin.FullName /nologo /dependents $file) {
      $name = $line.Trim()
      # API sets (api-ms-win-…, ext-ms-…) are names the system resolves, not files.
      if ($name -notmatch '^[\w.+-]+\.dll$' -or $name -match '^(api|ext)-ms-') { continue }
      $beside = Join-Path $bundleDir $name
      if (Test-Path $beside) { $queue.Enqueue($beside); continue }
      if (Test-Path (Join-Path $env:SystemRoot "System32\$name")) { continue }
      $missing[$name.ToLower()] = "$name (for $(Split-Path $file -Leaf))"
    }
  }
  @($missing.Values | Sort-Object)
}
$missing = Missing-Libraries
if ($missing.Count -gt 0) {
  Write-Output "this system lacks libraries the app needs, so the app can't start here and nothing was tried:"
  $missing | ForEach-Object { Write-Output "  $_" }
  Write-Output "system: $((Get-CimInstance Win32_OperatingSystem).Caption)"
  # 3: not a failure of the app, but not a pass either.
  exit 3
}

# Where the app keeps its settings and wallet, and its node's data.
$settings = Join-Path $env:APPDATA 'Murmur Association'
$data = Join-Path $env:APPDATA 'murmur-client'
foreach ($d in $settings, $data) {
  if (Test-Path $d) { Write-Output "${d} exists: the app has been used here, and this test would change its settings. Nothing was touched."; exit 1 }
}

# The app's windows, shown or not. A release runner has no desktop to show
# a window on, but the app still makes its window there, and takes a close
# request on it: so the window is looked up and closed by its handle, not
# through the visible "main window" PowerShell knows of.
Add-Type @"
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public class AppWindows {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
  // Each top-level window of the process: handle, title, class, shown.
  public static List<object[]> Of(int pid) {
    var found = new List<object[]>();
    EnumWindows((h, l) => {
      uint owner; GetWindowThreadProcessId(h, out owner);
      if (owner == (uint)pid) {
        var t = new StringBuilder(256); GetWindowText(h, t, 256);
        var c = new StringBuilder(256); GetClassName(h, c, 256);
        found.Add(new object[] { h, t.ToString(), c.ToString(), IsWindowVisible(h) });
      }
      return true;
    }, IntPtr.Zero);
    return found;
  }
  public static IntPtr Titled(int pid, string title) {
    foreach (var w in Of(pid)) if ((string)w[1] == title) return (IntPtr)w[0];
    return IntPtr.Zero;
  }
  public static void Close(IntPtr h) { PostMessage(h, 0x0010 /* WM_CLOSE */, IntPtr.Zero, IntPtr.Zero); }
}
"@

# What the app is doing, for a failure's report.
function Describe-App {
  if (-not $script:app) { return 'the app was not started' }
  $p = Get-Process -Id $script:app.Id -ErrorAction SilentlyContinue
  $state = if ($p) { 'running' } else { "exited with code $($script:app.ExitCode)" }
  $windows = @([AppWindows]::Of($script:app.Id) | ForEach-Object { "'$($_[1])' ($($_[2]), $(if ($_[3]) { 'shown' } else { 'hidden' }))" }) -join '; '
  $n = Node-Of $script:app.Id
  "app $($script:app.Id): $state; its windows: $(if ($windows) { $windows } else { 'none' }); its node: $(if ($n) { $n.ProcessId } else { 'none' }); " +
    "session $([Diagnostics.Process]::GetCurrentProcess().SessionId), a desktop to show windows on: $([Environment]::UserInteractive)"
}
# The app's own words (the engine says on its error output why it gave up),
# and the graphics libraries this system has: the engine draws through
# Direct3D, and a server system may lack parts of it.
$appLog = Join-Path $env:TEMP "murmur-smoke-$PID"
function Describe-System {
  foreach ($stream in 'out', 'err') {
    $text = Get-Content "$appLog.$stream" -ErrorAction SilentlyContinue | Select-Object -Last 25
    if ($text) { "the app's $stream`put:"; $text | ForEach-Object { "    $_" } }
  }
  "graphics libraries in the system: " + ((@('d3d11.dll', 'dxgi.dll', 'd3dcompiler_47.dll', 'd3d10warp.dll', 'dcomp.dll', 'dwmapi.dll', 'opengl32.dll') | ForEach-Object {
    "$_ $(if (Test-Path (Join-Path $env:SystemRoot "System32\$_")) { 'yes' } else { 'NO' })" }) -join ', ')
}
function Fail($what) {
  Write-Output "FAILED: $what"; Write-Output "  $(Describe-App)"
  Describe-System | ForEach-Object { Write-Output "  $_" }
  throw 'smoke test failed'
}
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
  $script:app = Start-Process -PassThru $exe -RedirectStandardOutput "$appLog.out" -RedirectStandardError "$appLog.err"
  # Keeps its exit code readable: with redirected output PowerShell drops it otherwise.
  $null = $script:app.Handle
  Wait-For 60 'the app made no window titled Murmur' { [AppWindows]::Titled($script:app.Id, 'Murmur') -ne [IntPtr]::Zero }
  Wait-For 60 "the node didn't start as the app's child" { $null -ne (Node-Of $script:app.Id) }
  $script:node = (Node-Of $script:app.Id).ProcessId
}
function Close-App {
  [AppWindows]::Close([AppWindows]::Titled($script:app.Id, 'Murmur'))
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
  Write-Output "window: $((@([AppWindows]::Of($app.Id) | Where-Object { $_[1] -eq 'Murmur' } | ForEach-Object { "Murmur ($(if ($_[3]) { 'shown' } else { 'hidden: no desktop here' }))" }) -join ', '))"
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
    # This builds and runs a debug app, which needs the debug runtime: on a
    # machine with only the build tools, that's in their folders, not the
    # system's. Make it findable (and the release one, from the package).
    $extra = @($bundleDir)
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
      $vs = & $vswhere -latest -products * -property installationPath
      $extra += @(Get-ChildItem "$vs\VC\Redist\MSVC\*\debug_nonredist\x64\Microsoft.VC*.DebugCRT" -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
    }
    $extra += @(Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\ucrt" -Directory -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1 | ForEach-Object FullName)
    Write-Output "also searching for libraries in: $($extra -join '; ')"
    $env:Path = ($extra -join ';') + ';' + $env:Path
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
  Remove-Item "$appLog.out", "$appLog.err" -ErrorAction SilentlyContinue
}
if (-not $ok) { exit 1 }
