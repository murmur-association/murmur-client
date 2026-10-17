// A thread's page as its reader comes back to it: it opens where they left
// off, others' replies newer than that are highlighted for a moment as they
// come into view, and the replies after the ones at hand are read as the
// reader reaches them.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart' show WalletId;
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/thread_page.dart';

import 'support/messages.dart';

void main() {
  late TxView thread;
  late List<TxView> replies;
  late FakeChain chain;

  setUp(() {
    thread = txAt(TxKind.orphan, 1, text: 'A thread');
    replies = [for (var i = 1; i <= 40; i++) replyTo(thread, 1 + i, text: 'Reply $i')];
    chain = FakeChain([thread, ...replies]);
    // As the node's index numbers them.
    for (var i = 0; i < replies.length; i++) {
      chain.places[replies[i].tx.id] = i + 1;
    }
  });

  Future<void> open(WidgetTester tester, Preferences prefs, {MurmurClient? client}) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: client ?? chain,
      wallets: WalletController(),
      prefs: prefs,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    // Long enough to scroll to a card, not for a highlight to fade.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Color? cardOf(WidgetTester tester, String text) =>
      tester.widget<Card>(find.ancestor(of: find.text(text), matching: find.byType(Card)).first).color;

  testWidgets('a first visit opens at the top, marks nothing, and remembers how far it got', (tester) async {
    final prefs = Preferences()..unreadFrom = 0;
    await open(tester, prefs);
    expect(find.text('A thread'), findsOneWidget);
    expect(find.text('Reply 1'), findsOneWidget);
    expect(chain.watchedFrom[thread.tx.id], isNull, reason: 'read from its first reply');
    expect(cardOf(tester, 'Reply 1'), isNull);
    // The last reply on screen is where the reader left off.
    final left = prefs.threadsRead[thread.tx.id]!;
    expect(left.place, greaterThan(1));
    expect(left.txid, replies[left.place! - 1].tx.id);
    expect(find.text('Reply ${left.place}'), findsOneWidget);
    expect(find.text('Reply ${left.place! + 1}').hitTestable(), findsNothing, reason: 'not on screen yet');
    await tester.pumpAndSettle();
  });

  testWidgets('a later visit opens where the reader left off, and newer replies flash as they come into view',
      (tester) async {
    final prefs = Preferences()..threadsRead = {thread.tx.id: (txid: replies[19].tx.id, place: 20)};
    await open(tester, prefs);
    expect(chain.watchedFrom[thread.tx.id], 20, reason: 'read from where the reader left off');
    expect(find.text('A thread'), findsNothing, reason: 'scrolled down to it');
    expect(find.text('Reply 20'), findsOneWidget);
    // Read before: as it was. Newer, and on screen: highlighted.
    expect(cardOf(tester, 'Reply 20'), isNull);
    expect(cardOf(tester, 'Reply 21'), isNotNull);
    expect(find.text('Reply 40'), findsNothing);
    // The highlight fades.
    await tester.pumpAndSettle();
    expect(cardOf(tester, 'Reply 21'), isNull);

    // Further down, the newest come into view, and flash in their turn.
    await tester.scrollUntilVisible(find.text('Reply 40'), 400, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(cardOf(tester, 'Reply 40'), isNotNull);
    await tester.pumpAndSettle();
    expect(prefs.threadsRead[thread.tx.id], (txid: replies.last.tx.id, place: 40));
  });

  testWidgets('one\'s own replies are not news', (tester) async {
    final mine = replyTo(thread, 50, from: alice, text: 'My own');
    chain.add([mine]);
    chain.places[mine.tx.id] = 41;
    final wallets = WalletController()..wallet = WalletId(alice, Uint8List(32));
    final prefs = Preferences()..threadsRead = {thread.tx.id: (txid: replies.last.tx.id, place: 40)};
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: wallets,
      prefs: prefs,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('My own'), findsOneWidget);
    expect(cardOf(tester, 'My own'), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('the replies after the ones at hand are read as the reader reaches them', (tester) async {
    final short = FakeChain([thread, ...replies.take(3)])..early.add(thread.tx.id);
    await open(tester, Preferences(), client: short);
    expect(find.text('Reply 3'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'more below');
    expect(short.laterAsked, greaterThan(0));
    expect(find.textContaining('3 replies'), findsNothing, reason: 'not counted while there are more');
    await tester.pumpWidget(const SizedBox());
  });
}
