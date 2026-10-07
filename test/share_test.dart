// Sharing an address as a QR code that opens its page (lib/ui/share.dart),
// and the link behind it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/main.dart' show routeOfLink;
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/claim_page.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/qr.dart';
import 'package:murmur_client/ui/thread_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final address = 'ab' * 32;

  Future<void> pumpApp(WidgetTester tester, Widget home) => tester.pumpWidget(AppScope(
        client: MurmurClient(),
        wallets: WalletController(),
        prefs: Preferences(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: routeOfLink,
          home: Scaffold(body: Center(child: home)),
        ),
      ));

  test("an address's link, and the address back from it", () {
    final link = addressLink(address);
    expect(link, endsWith('/#/address/$address'));
    expect(addressInRoute('/address/$address'), address);
    for (final bad in ['/address/abc', '/address/${address}0', '/address/${address.toUpperCase()}', '/thread/$address', null]) {
      expect(addressInRoute(bad), isNull, reason: '$bad');
    }
  });

  testWidgets('a link opens its page: an address, a thread, an invitation', (tester) async {
    await pumpApp(tester, const SizedBox());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/address/$address');
    await tester.pumpAndSettle();
    expect(tester.widget<AddressPage>(find.byType(AddressPage)).address, address);
    navigator.pop();
    navigator.pushNamed('/thread/$address');
    await tester.pumpAndSettle();
    expect(find.byType(ThreadPage), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    // An invitation's page judges its code itself.
    expect(routeOfLink(const RouteSettings(name: '/invite/whatever-code-1')), isNotNull);
    expect(routeOfLink(const RouteSettings(name: '/nowhere')), isNull);
    expect(find.byType(ClaimPage), findsNothing);
  });

  testWidgets("an address's share button offers a QR code of its link, to scan or pass on again", (tester) async {
    await pumpApp(tester, HashText(address, qr: addressLink(address), qrCaption: 'scan me'));
    final l = tester.element(find.byType(HashText)).l10n;
    await tester.tap(find.byTooltip(l.share));
    await tester.pumpAndSettle();
    expect(find.text(l.copy), findsOneWidget);
    await tester.tap(find.text(l.qrCode));
    await tester.pumpAndSettle();

    // The code holds the link to the address's page, not the bare address.
    expect(tester.widget<QrView>(find.byType(QrView)).text, addressLink(address));
    expect(find.text('scan me'), findsOneWidget);

    // From the dialog the link can be passed on again: here, copied.
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final again = find.descendant(of: find.byType(Dialog), matching: find.byType(ShareButton));
    await tester.tap(again);
    await tester.pump();
    expect(copied, [addressLink(address)]);
  });

  testWidgets('"Copy" in the menu copies in its own tap, before the menu has closed', (tester) async {
    // A browser lets a page write to the clipboard only while the tap is
    // being handled: an iPhone copied nothing when this waited for the
    // menu's closing.
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpApp(tester, HashText(address, qr: addressLink(address)));
    final l = tester.element(find.byType(HashText)).l10n;
    await tester.tap(find.byTooltip(l.share));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.copy));
    // No frame has passed: the menu is still on screen, closing.
    expect(copied, [address]);
    await tester.pumpAndSettle();
    expect(copied, [address], reason: 'once, not again when the menu is gone');
    expect(find.text(l.copied), findsOneWidget);
  });

  testWidgets('a hash that is not an address keeps its plain copy button', (tester) async {
    await pumpApp(tester, HashText('cd' * 32));
    final l = tester.element(find.byType(HashText)).l10n;
    expect(find.byTooltip(l.copy), findsOneWidget);
    expect(find.byTooltip(l.share), findsNothing);
  });

  testWidgets('the address page and the wallet offer the QR code', (tester) async {
    await pumpApp(tester, const SizedBox());
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/address/$address');
    await tester.pumpAndSettle();
    final hash = tester.widget<HashText>(find.descendant(of: find.byType(AddressPage), matching: find.byType(HashText)));
    expect(hash.qr, addressLink(address));
    expect(hash.qrCaption, isNotEmpty);
  });
}
