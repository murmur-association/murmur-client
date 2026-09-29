// Widget tests for the localized, paged interface. They run without a node:
// the client stays disconnected, which is enough to check that every
// language builds, that numbers use the locale's grouping, and that the
// paged list fills the screen plus one row and grows by ten at the bottom.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/activity.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/chain_tab.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/invitations_page.dart';
import 'package:murmur_client/ui/messages_tab.dart';
import 'package:murmur_client/ui/paged_list.dart';
import 'package:murmur_client/ui/starred_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('amounts use the locale digit grouping', (tester) async {
    final seen = <String, String>{};
    for (final code in ['en', 'es', 'de']) {
      await tester.pumpWidget(Localizations(
        locale: Locale(code),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(builder: (context) {
          seen[code] = formatAmount(context, 1234567);
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
      for (var i = 1; i <= 2; i++) InviteRecord(code: 'C$i', amount: 5, serial: i, batch: 2, funder: funder),
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
            onPressed: () async => chosen = await askCardName(context, records, const {}),
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

  testWidgets('the Starred page lists what was starred, and a removed star keeps its row', (tester) async {
    final prefs = Preferences();
    Future<void> open() async {
      // A fresh page each time: it lists the stars as they were when opened.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(AppScope(
        client: MurmurClient(),
        wallets: WalletController(),
        prefs: prefs,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StarredPage(),
        ),
      ));
      await tester.pump();
    }

    await open();
    final l = tester.element(find.byType(StarredPage)).l10n;
    expect(find.text(l.noStarred), findsOneWidget);

    // A star on something the client can't fetch (it's offline here).
    await prefs.setStarred('ab' * 32, true);
    await open();
    expect(find.text(l.starredGone), findsOneWidget);
    await tester.tap(find.byTooltip(l.unstar));
    await tester.pump();
    expect(prefs.starred, isEmpty);
    expect(find.byTooltip(l.star), findsOneWidget, reason: 'still listed, to star again');
  });

  testWidgets('cancelling a card funded by another wallet asks where its tokens go', (tester) async {
    final records = [InviteRecord(code: 'C1', amount: 5, serial: 1, batch: 1, funder: 'ab' * 32)];
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
            onPressed: () async => to = await askCancel(context, records, const {}),
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

  test('balance change: the sender pays amount and fee, the recipient gets the amount', () async {
    final a = await MurmurWallet.generate();
    final b = await MurmurWallet.generate();
    Future<Transaction> transfer(MurmurWallet from, MurmurWallet to, int amount, int fee) => from.sign(
        kind: TxKind.raw, nonce: 0, to: to.address, amount: amount, fee: fee, messageHash: null, timestamp: 1790208000);
    final ab = await transfer(a, b, 20, 2);
    expect(MurmurClient.balanceChange(ab, a.addressHex), -22);
    expect(MurmurClient.balanceChange(ab, b.addressHex), 20);
    final self = await transfer(a, a, 20, 2);
    expect(MurmurClient.balanceChange(self, a.addressHex), -2, reason: 'paying yourself costs only the fee');
  });

  test('filters: a transfer is never a message, flags are off by default', () {
    expect(MessageFilter.defaults.contains(MessageFilter.flagsSent), isFalse);
    expect(MessageFilter.defaults.contains(MessageFilter.flagsReceived), isFalse);
    expect(WalletFilter.defaults, {WalletFilter.transfersSent, WalletFilter.transfersReceived});
  });
}
