// Quotes (protocol/quote.dart): how a reply says which reply it answers,
// now that the chain only knows its thread, and how a thread shows it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/quote.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/thread_page.dart';

import 'support/messages.dart';

void main() {
  final id = '3fa9c21e${'00' * 28}';
  // A text's quotes and what it says itself, as lists compare.
  (String, String) cut(String text) => (quotesIn(text).quotes.join(' '), quotesIn(text).body);

  test('a quote is a line of its own before the text: ">" and eight hex characters of the txid', () {
    expect(quoteLine(id), '>3fa9c21e\n');
    expect(cut('>3fa9c21e\nthe answer'), ('3fa9c21e', 'the answer'));
    expect(cut('>3fa9c21e\n>00ff00ff\nto both\nof you'), ('3fa9c21e 00ff00ff', 'to both\nof you'));
    // Nothing but the quote.
    expect(cut('>3fa9c21e'), ('3fa9c21e', ''));
    expect(cut('>3fa9c21e\n'), ('3fa9c21e', ''));
  });

  test('anything else reads as written', () {
    for (final text in [
      'plain',
      '',
      '> 3fa9c21e\nspaced',
      '>3fa9c21\nseven',
      '>3fa9c21e0\nnine',
      '>3FA9C21E\nupper case',
      '>3fa9c21e and more\non the line',
      ' >3fa9c21e\nindented',
      'first\n>3fa9c21e\nnot at the start',
      '>3fa9c21e\r\nanother line end',
    ]) {
      expect(cut(text), ('', text), reason: text);
    }
    // After a quote, the same.
    expect(cut('>3fa9c21e\n\n>00ff00ff\nx'), ('3fa9c21e', '\n>00ff00ff\nx'));
  });

  test('a quote means the oldest earlier reply that starts so', () {
    final a = 'aaaaaaaa${'11' * 28}', twin = 'aaaaaaaa${'22' * 28}', b = 'bbbbbbbb${'33' * 28}';
    expect(quotedReply([a, b], 'bbbbbbbb'), b);
    expect(quotedReply([a, b], 'cccccccc'), isNull);
    // One made later to share the characters doesn't take the quote over.
    expect(quotedReply([a, b, twin], 'aaaaaaaa'), a);
    expect(quotedReply(<String>[], 'aaaaaaaa'), isNull);
  });

  // A page going to a card: scrolled there, and its highlight not faded yet.
  Future<void> goneTo(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a thread shows the reply an answer quotes, and a tap goes to that reply', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread');
    final first = replyTo(thread, 2, text: 'The first reply\nwith a second line');
    final answer = replyTo(thread, 3, from: carol, text: '${quoteLine(first.tx.id)}An answer to it');
    // Names a reply that comes after it: not a quote of anything.
    final early = replyTo(thread, 3, from: carol, text: '${quoteLine('ff' * 32)}To nobody');
    final chain = FakeChain([thread, first, answer, early]);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    await tester.pumpAndSettle();
    // What each says itself, without its quote line.
    expect(find.text('An answer to it'), findsOneWidget);
    expect(find.text('To nobody'), findsOneWidget);
    expect(find.textContaining('>'), findsNothing);
    // The quoted reply, in one line above the answer; its own card below.
    expect(find.text('The first reply with a second line'), findsOneWidget);
    // Its card is marked once the quote is tapped, and nothing opens over
    // the thread.
    Color? cardOf(String text) =>
        tester.widget<Card>(find.ancestor(of: find.text(text), matching: find.byType(Card)).first).color;
    expect(cardOf('The first reply\nwith a second line'), isNull);
    await tester.tap(find.text('The first reply with a second line'));
    await goneTo(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(cardOf('The first reply\nwith a second line'), isNotNull);
    expect(cardOf('An answer to it'), isNull);
    // For a moment: the mark fades.
    await tester.pumpAndSettle();
    expect(cardOf('The first reply\nwith a second line'), isNull);
  });

  testWidgets("a quote's author, picture or name, opens their page", (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread');
    final first = replyTo(thread, 2, from: bob, text: 'The first reply');
    final answer = replyTo(thread, 3, from: carol, text: '${quoteLine(first.tx.id)}An answer to it');
    await tester.pumpWidget(AppScope(
      client: FakeChain([thread, first, answer]),
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    await tester.pumpAndSettle();
    // The quote's own picture is the small one; its name sits beside it.
    final picture = find.byWidgetPredicate((w) => w is AddressAvatar && w.size == 16);
    final name = find.descendant(
        of: find.ancestor(of: picture, matching: find.byType(Row)).first, matching: find.byType(Text));
    for (final target in [picture, name]) {
      await tester.tap(target);
      await tester.pumpAndSettle();
      final page = tester.widget<AddressPage>(find.byType(AddressPage));
      expect(page.address, first.tx.fromAddress);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    // The rest of the quote still goes to the reply, opening nothing.
    await tester.tap(find.text('The first reply').last);
    await tester.pumpAndSettle();
    expect(find.byType(AddressPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('replies run from the oldest down, under the first message', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread');
    final chain = FakeChain([
      thread,
      for (var i = 1; i <= 3; i++) replyTo(thread, 1 + i, text: 'Reply $i'),
    ]);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    await tester.pumpAndSettle();
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('A thread'), lessThan(top('Reply 1')));
    expect(top('Reply 1'), lessThan(top('Reply 2')));
    expect(top('Reply 2'), lessThan(top('Reply 3')));
    expect(find.text('Earlier replies'), findsNothing, reason: 'the thread is all here');
  });

  testWidgets('a page opened for a reply far down goes to it', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread');
    final replies = [for (var i = 1; i <= 40; i++) replyTo(thread, 1 + i, text: 'Reply $i')];
    await tester.pumpWidget(AppScope(
      client: FakeChain([thread, ...replies]),
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id, focusTxid: replies.last.tx.id),
      ),
    ));
    await goneTo(tester);
    expect(find.text('Reply 40'), findsOneWidget);
    expect(find.text('A thread'), findsNothing, reason: 'scrolled away from the top');
    final card = tester.widget<Card>(find.ancestor(of: find.text('Reply 40'), matching: find.byType(Card)).first);
    expect(card.color, isNotNull, reason: 'marked');
  });

  testWidgets('a long thread: earlier replies come when asked for, and so does a quoted one', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread');
    final old = replyTo(thread, 2, text: 'An old reply');
    final answer = replyTo(thread, 9, from: carol, text: '${quoteLine(old.tx.id)}An answer to it');
    // Only the newest reply is loaded so far.
    final chain = FakeChain([thread, answer])..partly.add(thread.tx.id);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    await tester.pumpAndSettle();
    double top(Finder f) => tester.getTopLeft(f).dy;
    expect(top(find.text('A thread')), lessThan(top(find.text('Earlier replies'))));
    expect(top(find.text('Earlier replies')), lessThan(top(find.text('An answer to it'))),
        reason: 'the earlier replies go above the ones loaded');
    expect(find.textContaining('1 reply'), findsNothing, reason: 'not counted while there are more');
    await tester.tap(find.text('Earlier replies'));
    expect(chain.earlierAsked, 1);

    // The quote stands for a reply not loaded yet: a tap loads back to it.
    await tester.tap(find.text('An earlier reply (tap to load it)'));
    await tester.pump();
    expect(chain.earlierAsked, greaterThan(1));
    chain
      ..partly.clear()
      ..add([old]);
    await goneTo(tester);
    expect(find.text('An earlier reply (tap to load it)'), findsNothing);
    expect(find.text('An old reply'), findsNWidgets(2), reason: 'quoted, and its own card above');
    expect(top(find.text('An old reply').first), lessThan(top(find.text('An answer to it'))));
    final card = tester.widget<Card>(find.ancestor(of: find.text('An old reply').first, matching: find.byType(Card)).first);
    expect(card.color, isNotNull, reason: 'gone to, and marked');
  });

  testWidgets('a muted author is not shown quoted either', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread');
    final first = replyTo(thread, 2, text: 'Muted words');
    final answer = replyTo(thread, 3, from: carol, text: '${quoteLine(first.tx.id)}An answer to it');
    final prefs = Preferences();
    prefs.muted = {first.tx.fromAddress};
    await tester.pumpWidget(AppScope(
      client: FakeChain([thread, first, answer]),
      wallets: WalletController(),
      prefs: prefs,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThreadPage(rootTxid: thread.tx.id),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('An answer to it'), findsOneWidget);
    expect(find.textContaining('Muted words'), findsNothing);
  });
}
