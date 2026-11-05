// The Microsoft Store package's manifest (windows/msix/AppxManifest.xml),
// against the code and the installer it must agree with. What only Windows
// can check (packing, installing, running packaged, certification) is
// tool/msix_package.ps1's, in the regression's smoke-windows.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/notifier.dart';

void main() {
  final manifest = File('windows/msix/AppxManifest.xml').readAsStringSync();
  final installer = File('windows/installer/murmur.iss').readAsStringSync();

  test("notifications are clicked back through the package's own activator, not the installer's", () {
    // Both copies may be installed side by side: a click must start the
    // copy that showed it.
    expect(storeToastActivator, isNot(installerToastActivator));
    expect(RegExp('ToastActivatorCLSID="$storeToastActivator"').hasMatch(manifest), isTrue);
    expect(RegExp('<com:Class Id="$storeToastActivator"').hasMatch(manifest), isTrue);
    expect(manifest, isNot(contains(installerToastActivator)));
    expect(installer, contains('AppUserModelToastActivatorCLSID: "$installerToastActivator"'));
    expect(installer, isNot(contains(storeToastActivator)));
  });

  test('the COM server is the app itself, started with full trust', () {
    expect(manifest, contains('Executable="murmur_client.exe" EntryPoint="Windows.FullTrustApplication"'));
    expect(manifest, contains('<com:ExeServer Executable="murmur_client.exe"'));
    expect(manifest, contains('<rescap:Capability Name="runFullTrust" />'));
  });

  test('the identity is left for tool/msix_package.ps1 to fill in', () {
    for (final placeholder in ['{IDENTITY_NAME}', '{PUBLISHER}', '{PUBLISHER_DISPLAY_NAME}', '{VERSION}']) {
      expect(manifest, contains(placeholder));
    }
  });

  test("the package lists the app's languages, and every logo it names is drawn", () {
    final arb = [
      for (final f in Directory('lib/l10n').listSync())
        if (RegExp(r'app_(\w+)\.arb$').firstMatch(f.path) case final m?) m[1]!,
    ];
    final listed = [for (final m in RegExp(r'<Resource Language="([\w-]+)" />').allMatches(manifest)) m[1]!];
    expect(listed.first, 'en-us', reason: 'English first: the default');
    expect(listed.map((l) => l.split('-').first).toSet(), arb.toSet());
    for (final m in RegExp(r'Assets\\(\w+)\.png').allMatches(manifest)) {
      final drawn = Directory('windows/msix/Assets')
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('${m[1]}.scale-100'));
      expect(drawn, isNotEmpty, reason: '${m[1]} (tool/render_brand.dart)');
    }
  });
}
