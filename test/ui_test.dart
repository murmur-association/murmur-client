// Widget tests for the localized, paged interface. They run without a node:
// the client stays disconnected, which is enough to check that every
// language builds, that numbers use the locale's grouping, and that the
// paged list fills the screen plus one row and grows by ten at the bottom.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/activity.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/chain_tab.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/invitations_page.dart';
import 'package:murmur_client/ui/messages_tab.dart';
import 'package:murmur_client/ui/paged_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a device in none of the app\'s languages gets English, and one of them its own', () {
    Locale shown(List<Locale> device) => basicLocaleListResolution(device, AppLocalizations.supportedLocales);
    // The first supported language is the fallback: once it was Arabic, the
    // first by its code, on every French or Korean device.
    expect(shown(const [Locale('fr', 'FR')]), const Locale('en'));
    expect(shown(const [Locale('ko')]), const Locale('en'));
    expect(shown(const []), const Locale('en'));
    expect(shown(const [Locale('fr'), Locale('de', 'CH')]), const Locale('de'));
    for (final code in languageNames.keys) {
      expect(shown([Locale(code)]), Locale(code));
    }
  });

  testWidgets('every language builds the tabs', (tester) async {
    for (final code in languageNames.keys) {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(code),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScope(
          client: MurmurClient(),
          wallets: WalletController(),
          prefs: Preferences(),
          child: const Scaffold(body: Column(children: [Expanded(child: ChainTab()), Expanded(child: MessagesTab())])),
        ),
      ));
      await tester.pump();
      final context = tester.element(find.byType(ChainTab));
      expect(context.l10n.localeName, code);
      expect(find.text(context.l10n.statNetwork), findsOneWidget, reason: code);
      expect(find.text(context.l10n.messagesNeedWallet), findsOneWidget, reason: code);
      expect(Directionality.of(context), code == 'ar' ? TextDirection.rtl : TextDirection.ltr);
    }
  });

  testWidgets('counts use the locale digit grouping', (tester) async {
    final seen = <String, String>{};
    for (final code in ['en', 'es', 'de']) {
      await tester.pumpWidget(Localizations(
        locale: Locale(code),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(builder: (context) {
          seen[code] = formatCount(context, 1234567);
          return const SizedBox();
        }),
      ));
      await tester.pump();
    }
    expect(seen, {'en': '1,234,567', 'es': '1.234.567', 'de': '1.234.567'});
  });

  testWidgets('a paged list fills the screen plus one, then loads ten more at the bottom', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final all = List.generate(1000, (i) => i);
    var largestRequest = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PagedList<int>(
          fetch: (n) {
            largestRequest = n > largestRequest ? n : largestRequest;
            return all.take(n).toList();
          },
          itemBuilder: (context, i) => SizedBox(height: 100, child: Text('row $i')),
          dividerIndent: null,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // 800 px of 100 px rows (plus the 88 px end padding): rows 0-8 overflow
    // the screen, and one more is added.
    int shown() => tester.widgetList(find.textContaining('row ')).length;
    final firstPage = largestRequest - 1;
    expect(firstPage, inInclusiveRange(9, 10));
    expect(largestRequest, lessThan(20), reason: 'only a screenful is asked for, not all 1000');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(largestRequest - 1, firstPage + PagedList.pageSize);
    expect(shown(), greaterThan(0));
  });

  testWidgets('a tall screen fills up even when the items arrive after the first build', (tester) async {
    // 2000 px of 100 px rows: about 20 rows, not a first guess of 10.
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final available = ValueNotifier<int>(0); // the chain is still syncing
    int shown() => tester.widgetList(find.textContaining('row ')).length;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: available,
          builder: (context, n, _) => PagedList<int>(
            fetch: (count) => List.generate(count < n ? count : n, (i) => i),
            itemBuilder: (context, i) => SizedBox(height: 100, child: Text('row $i')),
            dividerIndent: null,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(shown(), 0);

    available.value = 5000; // synced
    await tester.pumpAndSettle();
    // 20 rows reach 2000 px; with the 88 px end space the list overflows at
    // 20 rows, and one more is added.
    expect(shown(), greaterThanOrEqualTo(20));
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.maxScrollExtent, greaterThan(0),
        reason: 'there is always something to scroll to, so the next ten can load');
  });

  testWidgets('printing invitations asks for the name, starting from the funding wallet\'s own name', (tester) async {
    final funder = 'ab' * 32;
    final prefs = Preferences();
    await prefs.setAlias(funder, 'Old wallet');
    final records = [
      for (var i = 1; i <= 2; i++) InviteRecord(address: '${i}c' * 32, amount: 5, serial: i, batch: 2, funder: funder),
    ];
    String Function(InviteRecord)? chosen;
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // As in main.dart: the scope above the app, so dialogs see it too.
    await tester.pumpWidget(AppScope(
      client: MurmurClient(),
      wallets: WalletController(),
      prefs: prefs,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => chosen = await askCardName(context, records),
            child: const Text('print'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('print'));
    await tester.pumpAndSettle();
    expect(find.text('Old wallet'), findsOneWidget);
    // The funder published no alias the client knows of.
    expect(find.text('No public name known'), findsOneWidget);
    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();
    expect(chosen!(records.first), 'Old wallet');

    // Other text: empty prints no name.
    await tester.tap(find.text('print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other text'));
    await tester.pump();
    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();
    expect(chosen!(records.first), '');
  });

  testWidgets('a copper name in a row opens its address', (tester) async {
    final address = 'ab' * 32;
    await tester.pumpWidget(AppScope(
      client: MurmurClient(),
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: PersonLine(address, '5 min ago'))),
      ),
    ));
    await tester.tapOnText(find.textRange.ofSubstring(shortHex(address)));
    await tester.pumpAndSettle();
    expect(find.byType(AddressPage), findsOneWidget);
  });

  test('a thread row shows its first line of text', () {
    expect(firstLine('Title\nand the rest'), 'Title');
    expect(firstLine('\n  \n  Title after blanks  \nmore'), 'Title after blanks');
    expect(firstLine('One line only'), 'One line only');
    expect(firstLine(''), '');
  });

  testWidgets('cancelling a card funded by another wallet asks where its tokens go', (tester) async {
    final records = [InviteRecord(address: 'cd' * 32, amount: 5, serial: 1, batch: 1, funder: 'ab' * 32)];
    ReturnTo? to;
    await tester.pumpWidget(AppScope(
      client: MurmurClient(),
      wallets: WalletController(), // no wallet here now: only the funder can take them
      prefs: Preferences(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => to = await askCancel(context, records),
            child: const Text('cancel'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(AlertDialog));
    expect(find.text(context.l10n.cancelReturnTo), findsOneWidget);
    final current = tester.widget<RadioListTile<ReturnTo>>(find.widgetWithText(RadioListTile<ReturnTo>, context.l10n.cancelToCurrent));
    expect(current.enabled, isFalse);
    await tester.tap(find.widgetWithText(FilledButton, context.l10n.cancelInvitation));
    await tester.pumpAndSettle();
    expect(to, ReturnTo.funder);
  });

  test('balance change: the sender pays amount and fee, and whoever is credited gets the amount', () async {
    final a = await MurmurWallet.generate();
    final b = await MurmurWallet.generate();
    final client = MurmurClient();
    addTearDown(client.dispose);
    Future<Transaction> transfer(MurmurWallet from, MurmurWallet to, int amount, int fee) => from.sign(
        networkTag: NetworkInfo.demo.tag, kind: TxKind.raw, nonce: 0, to: to.address, amount: amount, fee: fee);
    final ab = await transfer(a, b, 20000000, 500000);
    expect(client.balanceChange(ab, a.addressHex), -20500000);
    expect(client.balanceChange(ab, b.addressHex), 20000000);
    final self = await transfer(a, a, 20000000, 500000);
    expect(client.balanceChange(self, a.addressHex), -500000, reason: 'paying yourself costs only the fee');
  });

  testWidgets('amounts are shown and read in tokens, with up to six decimals', (tester) async {
    late BuildContext en, es;
    Widget probe(String code, void Function(BuildContext) take) => Localizations(
          locale: Locale(code),
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(builder: (context) {
            take(context);
            return const SizedBox();
          }),
        );
    await tester.pumpWidget(Column(children: [probe('en', (c) => en = c), probe('es', (c) => es = c)]));
    await tester.pumpAndSettle();
    // Units in, tokens out: no trailing zeros, never the units themselves.
    expect(formatAmount(en, 25000000), '25');
    expect(formatAmount(en, 500000), '0.5');
    expect(formatAmount(en, 1234567890123), '1,234,567.890123');
    expect(formatAmount(es, 1234567890123), '1.234.567,890123');
    expect(formatAmount(en, 1), '0.000001');
    expect(formatAmount(en, 0), '0');
    expect(formatSigned(en, -1500000), '-1.5');
    expect(amountText(en, 1500000), '1.5');
    expect(amountText(es, 1234500000), '1234,5');
    // And back: what a field holds, in units.
    expect(parseAmount(en, '0.5'), 500000);
    expect(parseAmount(en, ' 1,234.000001 '), 1234000001);
    expect(parseAmount(es, '1.234,5'), 1234500000);
    expect(parseAmount(es, '0,5'), 500000);
    expect(parseAmount(en, '25'), 25000000);
    for (final context in [en, es]) {
      for (final units in [0, 1, 500000, 999999, 1000000, 25000000, 210000000000000]) {
        expect(parseAmount(context, formatAmount(context, units)), units);
        expect(parseAmount(context, amountText(context, units)), units);
      }
    }
    // Refused rather than guessed: a seventh decimal, a point where the
    // language groups with it, two separators, nothing, a sign.
    expect(parseAmount(en, '0.0000001'), isNull);
    expect(parseAmount(es, '1.5'), isNull, reason: 'in Spanish the point groups thousands: not read as 15');
    expect(parseAmount(en, '1,5'), isNull);
    expect(parseAmount(en, '1.2.3'), isNull);
    expect(parseAmount(en, ''), isNull);
    expect(parseAmount(en, '-1'), isNull);
    expect(parseAmount(en, 'abc'), isNull);
  });

  test('filters: a transfer is never a message, flags are off by default', () {
    expect(MessageFilter.defaults.contains(MessageFilter.flagsSent), isFalse);
    expect(MessageFilter.defaults.contains(MessageFilter.flagsReceived), isFalse);
    expect(WalletFilter.defaults, {WalletFilter.transfersSent, WalletFilter.transfersReceived});
  });
}
