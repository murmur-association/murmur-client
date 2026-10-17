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
}
