// Quotes (protocol/quote.dart): how a reply says which reply it answers,
// now that the chain only knows its thread, and how a thread shows it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/quote.dart';
import 'package:murmur_client/services/storage.dart';
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

  testWidgets('a thread shows the reply an answer quotes, and all of it on a tap', (tester) async {
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
    await tester.tap(find.text('The first reply with a second line'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('The first reply\nwith a second line'), findsNWidgets(2));
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
