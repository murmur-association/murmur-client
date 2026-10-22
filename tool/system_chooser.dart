// What a test inside the app can't do on a desktop: work the system's file
// dialog. The acceptance runner (tool/acceptance_test.dart) does it from
// outside the app, when the app asks (integration_test/support/
// acceptance_protocol.dart): it picks a file in the dialog the app opens, or
// cancels it, as a user would.
//
// - Windows: the common file dialog, through Windows' UI Automation (in
//   PowerShell, which every Windows has): the file's path in its "File name"
//   box, then Open; or Cancel. Only with a desktop: a CI runner's service
//   session has none.
// - Linux: GTK's "Open File" dialog, with xdotool, inside the session
//   tool/linux_session.sh makes: Ctrl+L for a location, the path, Enter; or
//   Escape.
// - Not on macOS (a Mac's dialogs answer only a process the user has given
//   Accessibility, which a runner hasn't), nor iOS (the photo picker is
//   another process, that only XCUITest can reach): the tests hand over a
//   file in the chooser's place there.

// ignore_for_file: avoid_print

import 'dart:io';

/// The system's file dialog on this desktop, worked from outside the app.
abstract class SystemChooser {
  /// The chooser for this machine, or null with why not.
  static Future<(SystemChooser?, String)> here() async {
    if (Platform.isWindows) return (_WindowsChooser(), 'Windows UI Automation');
    if (Platform.isLinux) {
      final xdotool = await Process.run('which', ['xdotool']);
      return xdotool.exitCode == 0 ? (_LinuxChooser(), 'xdotool') : (null, 'no xdotool');
    }
    return (null, 'no way to work ${Platform.operatingSystem}\'s file dialog from outside the app');
  }

  /// Picks `file` (a full path) in the dialog the app opens; whether it did.
  Future<bool> pick(String file);

  /// Cancels the dialog the app opens; whether it did.
  Future<bool> cancel();
}

class _WindowsChooser extends SystemChooser {
  /// Waits for the app's file dialog (a visible "#32770" window of
  /// murmur_client), runs `then` with its handle as `$window`, and checks
  /// the dialog then closed; whether all of that happened.
  Future<bool> _withDialog(String then) async {
    final script = '''
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
# Through the dialog's own controls, as its buttons do: the path in its
# file name box (control 1148), then the OK or Cancel command. Whatever the
# system's language and wherever the focus is. (UI Automation's tree of the
# dialog doesn't hold its buttons.)
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class MurmurDialog {
  [DllImport("user32.dll")] static extern IntPtr GetDlgItem(IntPtr dialog, int id);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string name);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr window, int message, IntPtr w, string l);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr window, int message, IntPtr w, StringBuilder l);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr window, StringBuilder name, int most);
  [DllImport("user32.dll")] static extern int GetDlgCtrlID(IntPtr window);
  delegate bool EachChild(IntPtr window, IntPtr data);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr parent, EachChild each, IntPtr data);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr window, int message, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
  const int SetText = 0x000C, GetText = 0x000D, Command = 0x0111;
  // A control's text, also in another process (GetWindowText reads only
  // the caller's own).
  static string TextOf(IntPtr window) {
    var text = new StringBuilder(1024);
    SendMessage(window, GetText, (IntPtr)1024, text);
    return text.ToString();
  }
  // The dialog's controls, for a failure's report: class, id and text.
  public static string Controls(IntPtr dialog) {
    var all = new StringBuilder();
    EnumChildWindows(dialog, (w, _) => {
      var name = new StringBuilder(256);
      GetClassName(w, name, 256);
      all.Append(name).Append(" #").Append(GetDlgCtrlID(w)).Append(" [").Append(TextOf(w)).Append("]")
          .Append(IsWindowVisible(w) ? "" : " (hidden)").Append("; ");
      return true;
    }, IntPtr.Zero);
    return all.ToString();
  }
  static IntPtr NameBox(IntPtr dialog) {
    IntPtr box = GetDlgItem(dialog, 1148);
    if (box == IntPtr.Zero) return IntPtr.Zero;
    IntPtr combo = FindWindowEx(box, IntPtr.Zero, "ComboBox", null);
    return FindWindowEx(combo != IntPtr.Zero ? combo : box, IntPtr.Zero, "Edit", null);
  }
  public static string Pick(IntPtr dialog, string path) {
    IntPtr edit = NameBox(dialog);
    if (edit == IntPtr.Zero) return "no file name box";
    SendMessage(edit, SetText, IntPtr.Zero, path);
    // A dialog still setting itself up clears the box: then not yet.
    System.Threading.Thread.Sleep(300);
    if (NameText(dialog) != path) return "the file name box didn't keep the path";
    PostMessage(dialog, Command, (IntPtr)1, IntPtr.Zero);
    return null;
  }
  public static void Cancel(IntPtr dialog) { PostMessage(dialog, Command, (IntPtr)2, IntPtr.Zero); }
  public static string NameText(IntPtr dialog) { return TextOf(NameBox(dialog)); }
}
'@
\$A = [System.Windows.Automation.AutomationElement]
\$scope = [System.Windows.Automation.TreeScope]
\$isDialog = New-Object System.Windows.Automation.PropertyCondition(\$A::ClassNameProperty, '#32770')
\$app = @(Get-Process -Name murmur_client -ErrorAction SilentlyContinue | ForEach-Object { \$_.Id })
function Visible(\$e) { \$e -and [MurmurDialog]::IsWindowVisible([System.IntPtr]\$e.Current.NativeWindowHandle) }
\$dialog = \$null
\$deadline = (Get-Date).AddSeconds(90)
while (-not \$dialog -and (Get-Date) -lt \$deadline) {
  # A dialog the app's window owns shows under that window; else on its
  # own. Only a visible one: one just closed may linger hidden.
  foreach (\$w in \$A::RootElement.FindAll(\$scope::Children, [System.Windows.Automation.Condition]::TrueCondition)) {
    if (\$app -notcontains \$w.Current.ProcessId) { continue }
    if (\$w.Current.ClassName -eq '#32770' -and (Visible \$w)) { \$dialog = \$w; break }
    \$inside = \$w.FindFirst(\$scope::Children, \$isDialog)
    if (Visible \$inside) { \$dialog = \$inside; break }
  }
  if (-not \$dialog) { Start-Sleep -Milliseconds 300 }
}
if (-not \$dialog) {
  \$seen = foreach (\$w in \$A::RootElement.FindAll(\$scope::Children, [System.Windows.Automation.Condition]::TrueCondition)) {
    if (\$app -contains \$w.Current.ProcessId) { "'" + \$w.Current.Name + "' (" + \$w.Current.ClassName + ")" }
  }
  Write-Output ("no file dialog; the app's windows: " + (\$seen -join ', ') + "; its processes: " + (\$app -join ', '))
  exit 1
}
Start-Sleep -Milliseconds 500
\$window = [System.IntPtr]\$dialog.Current.NativeWindowHandle
$then
# Closed, as a dialog is once it has its answer.
\$closing = (Get-Date).AddSeconds(15)
while ([MurmurDialog]::IsWindowVisible(\$window) -and (Get-Date) -lt \$closing) { Start-Sleep -Milliseconds 200 }
if ([MurmurDialog]::IsWindowVisible(\$window)) {
  Write-Output ("the dialog stayed open; it holds: " + [MurmurDialog]::Controls(\$window))
  exit 1
}
Write-Output 'done'
''';
    final result = await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
    final said = '${result.stdout}${result.stderr}'.trim();
    if (!said.endsWith('done')) print('windows: the file dialog: $said');
    return said.endsWith('done');
  }

  @override
  Future<bool> pick(String file) => _withDialog('''
# Again until the dialog takes it: one still setting itself up may clear
# the box, or let the command go by.
for (\$try = 0; \$try -lt 20 -and [MurmurDialog]::IsWindowVisible(\$window); \$try++) {
  \$why = [MurmurDialog]::Pick(\$window, '${file.replaceAll("'", "''")}')
  \$taken = (Get-Date).AddSeconds(3)
  while ([MurmurDialog]::IsWindowVisible(\$window) -and (Get-Date) -lt \$taken) { Start-Sleep -Milliseconds 200 }
}
if (\$why -and [MurmurDialog]::IsWindowVisible(\$window)) {
  Write-Output (\$why + '; the dialog holds: ' + [MurmurDialog]::Controls(\$window))
  exit 1
}
''');

  @override
  Future<bool> cancel() => _withDialog(r'[MurmurDialog]::Cancel($window)');
}

class _LinuxChooser extends SystemChooser {
  /// The app's "Open File" dialog, once it's shown; null after 90 s.
  Future<String?> _dialog() async {
    final found = await Process.run('timeout', ['90', 'xdotool', 'search', '--sync', '--onlyvisible', '--name', '^Open File\$']);
    final id = '${found.stdout}'.trim().split('\n').first;
    if (found.exitCode != 0 || id.isEmpty) {
      print('linux: no "Open File" dialog: ${found.stderr}');
      return null;
    }
    await Process.run('xdotool', ['windowactivate', '--sync', id]);
    return id;
  }

  Future<bool> _keys(List<List<String>> commands) async {
    for (final command in commands) {
      final r = await Process.run('xdotool', command);
      if (r.exitCode != 0) {
        print('linux: xdotool ${command.join(' ')}: ${r.stderr}');
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return true;
  }

  @override
  Future<bool> pick(String file) async {
    if (await _dialog() == null) return false;
    return _keys([
      ['key', '--clearmodifiers', 'ctrl+l'],
      ['type', '--delay', '20', file],
      ['key', '--clearmodifiers', 'Return'],
    ]);
  }

  @override
  Future<bool> cancel() async {
    if (await _dialog() == null) return false;
    return _keys([
      ['key', '--clearmodifiers', 'Escape'],
    ]);
  }
}
