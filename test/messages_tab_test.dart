// The Messages tab's rows: led by their author's picture, which opens the
// author's page, and what others wrote marked until it is opened.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart' show WalletId;
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/messages_tab.dart';

import 'support/messages.dart';

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
  testWidgets('rows show their author, and others\' messages stay marked until opened', (tester) async {
    final thread = txAt(TxKind.orphan, 10, text: 'My thread');
    final mine = replyTo(thread, 25, from: alice, text: 'My own reply');
    final old = replyTo(thread, 12, text: 'An old one');
    final news = replyTo(thread, 30, text: 'Something new');
    final chain = _History([thread, old, mine, news]);
    // Read up to block 20's time.
    final prefs = Preferences()..unreadFrom = 1790208000 + 20 * 2;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: WalletController()..wallet = WalletId(alice, Uint8List(32)),
      prefs: prefs,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MessagesTab()),
      ),
    ));
    await tester.pumpAndSettle();
    ListTile row(String text) => tester.widget<ListTile>(find.ancestor(of: find.text(text), matching: find.byType(ListTile)));

    // Each row leads with its author's picture, not the message's kind.
    expect(find.byType(AvatarLink), findsNWidgets(4));
    expect(tester.widget<AvatarLink>(find.descendant(of: find.byWidget(row('Something new')), matching: find.byType(AvatarLink))).address,
        toHex(bob));
    // Others' since then: marked. One's own, and what came before: not.
    expect(row('Something new').tileColor, isNotNull);
    expect(row('My own reply').tileColor, isNull);
    expect(row('An old one').tileColor, isNull);

    // Opened, it is read.
    await tester.tap(find.text('Something new'));
    await tester.pumpAndSettle();
    expect(prefs.opened[news.tx.id], news.blockTime);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(row('Something new').tileColor, isNull);

    // The picture opens its author's page; the name in the line under the
    // text is the row's like the rest, and opens the message.
    await tester.tapOnText(find.textRange.ofSubstring(shortHex(toHex(bob))).first);
    await tester.pumpAndSettle();
    expect(find.byType(AddressPage), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byWidget(row('An old one')), matching: find.byType(AvatarLink)));
    await tester.pumpAndSettle();
    expect(find.byType(AddressPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Mark all as read" clears every mark at once, without opening any row', (tester) async {
    final thread = txAt(TxKind.orphan, 10, from: alice, text: 'My thread');
    final first = replyTo(thread, 30, text: 'First news');
    final second = replyTo(thread, 31, text: 'Second news');
    final chain = _History([thread, first, second]);
    final prefs = Preferences()..unreadFrom = 1790208000 + 20 * 2;
    await _pump(tester, chain, prefs);
    ListTile row(String text) => tester.widget<ListTile>(find.ancestor(of: find.text(text), matching: find.byType(ListTile)));
    IconButton button() => tester.widget<IconButton>(
        find.descendant(of: find.byType(MarkAllReadButton), matching: find.byType(IconButton)));

    expect(row('First news').tileColor, isNotNull);
    expect(row('Second news').tileColor, isNotNull);
    await tester.tap(find.byType(MarkAllReadButton));
    await tester.pumpAndSettle();
    expect(row('First news').tileColor, isNull);
    expect(row('Second news').tileColor, isNull);
    // Kept apart from the rows opened one by one, and nothing left to mark.
    expect(prefs.opened, isEmpty);
    expect(prefs.readUpTo[Preferences.messagesList(toHex(alice))], second.blockTime);
    expect(button().onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('on a desktop, the name in a row opens its page too', variant: TargetPlatformVariant.desktop(), (tester) async {
    final thread = txAt(TxKind.orphan, 10, from: alice, text: 'My thread');
    final reply = replyTo(thread, 12, text: 'A reply');
    await _pump(tester, _History([thread, reply]), Preferences()..unreadFrom = 0);
    await tester.tapOnText(find.textRange.ofSubstring(shortHex(toHex(bob))).first);
    await tester.pumpAndSettle();
    expect(find.byType(AddressPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _pump(WidgetTester tester, MurmurClient chain, Preferences prefs) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    client: chain,
    wallets: WalletController()..wallet = WalletId(alice, Uint8List(32)),
    prefs: prefs,
    child: MaterialApp(
      theme: lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MessagesTab()),
    ),
  ));
  await tester.pumpAndSettle();
}
