// An address's page: opened from a marked starred person, it marks what they
// wrote since the row was last read, with a line under it; opened any other
// way, it doesn't. Its picture shows larger when tapped.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';

import 'support/messages.dart';

/// The block time `txAt` gives height `h`.
int _time(int h) => 1790208000 + h * 2;

/// A chain that lists an address's history from what it was given.
class _History extends FakeChain {
  _History(this._views) : super(_views);

  final List<TxView> _views;

  @override
  Iterable<TxView> activityOf(String address) =>
      _views.reversed.where((v) => v.tx.fromAddress == address || creditedBy(v.tx) == address);

  @override
  bool historyPending(String address) => false;

  @override
  bool historyHasEarlier(String address) => false;
}

void main() {
  final old = txAt(TxKind.orphan, 10, from: bob, text: 'An old thread');
  final first = txAt(TxKind.orphan, 30, from: bob, text: 'First new thread');
  final second = txAt(TxKind.orphan, 40, from: bob, text: 'Second new thread');
  final chain = _History([old, first, second]);

  Future<AppLocalizations> pump(WidgetTester tester, AddressPage page) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: WalletController(),
      prefs: Preferences()..unreadFrom = 0,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ));
    await tester.pumpAndSettle();
    return tester.element(find.byType(AddressPage)).l10n;
  }

  ListTile row(WidgetTester tester, String text) =>
      tester.widget<ListTile>(find.ancestor(of: find.text(text), matching: find.byType(ListTile)));
  double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

  testWidgets('opened from a marked starred person, what they wrote since is marked, with a line under it',
      (tester) async {
    final l = await pump(tester, AddressPage(address: toHex(bob), newSince: _time(25)));
    expect(find.text(l.newAboveLastVisit), findsOneWidget);
    final line = top(tester, l.newAboveLastVisit);
    expect(top(tester, 'First new thread'), lessThan(line));
    expect(top(tester, 'Second new thread'), lessThan(line));
    expect(top(tester, 'An old thread'), greaterThan(line));
    expect(row(tester, 'Second new thread').tileColor, isNotNull);
    expect(row(tester, 'First new thread').tileColor, isNotNull);
    expect(row(tester, 'An old thread').tileColor, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a new message opened from there is no longer marked when back; the line stays', (tester) async {
    final l = await pump(tester, AddressPage(address: toHex(bob), newSince: _time(25)));
    await tester.tap(find.text('Second new thread'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(row(tester, 'Second new thread').tileColor, isNull);
    expect(row(tester, 'First new thread').tileColor, isNotNull);
    expect(find.text(l.newAboveLastVisit), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('opened any other way, nothing is marked', (tester) async {
    final l = await pump(tester, AddressPage(address: toHex(bob)));
    expect(find.text(l.newAboveLastVisit), findsNothing);
    expect(row(tester, 'Second new thread').tileColor, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap on the picture shows it larger', (tester) async {
    final l = await pump(tester, AddressPage(address: toHex(bob)));
    await tester.tap(find.byTooltip(l.pictureLarger));
    await tester.pumpAndSettle();
    final large = tester.widgetList<AddressAvatar>(find.byType(AddressAvatar)).map((a) => a.size).reduce((a, b) => a > b ? a : b);
    expect(large, greaterThan(100));
    // A tap closes it.
    await tester.tap(find.byType(Dialog));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
