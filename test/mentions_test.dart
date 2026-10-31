// Mentions in the app: written with "@" in Compose (only people the app
// knows, at most four, each costing 8 bytes of weight), said in the summary
// with what it makes public, shown under a message, and found in Messages.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart' show WalletId;
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/activity.dart';
import 'package:murmur_client/services/fees.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/compose_page.dart';
import 'package:murmur_client/ui/mentions.dart';
import 'package:murmur_client/ui/thread_page.dart';

import 'support/messages.dart';

/// A chain ready to send from, whose fee per byte is plain to see, that
/// records what it was asked to send.
class _Sending extends FakeChain {
  _Sending(super.oldestFirst) {
    state = LinkState.live;
  }

  List<String>? checkedMentions;

  @override
  Future<FeeInfo> feeInfo() async =>
      feeInfoFromNode(const Fees(nextBlock: (fee: 1000000, weight: 100), pending: 10));

  @override
  int? availableTo(String address) => 100 * unitsPerToken;

  @override
  TxProblem? checkTransaction({
    required String fromAddress,
    required TxKind kind,
    Uint8List? to,
    int amount = 0,
    required int fee,
    Uint8List? message,
    String? reference,
    List<String> mentions = const [],
  }) {
    checkedMentions = mentions;
    return null;
  }
}

void main() {
  Future<void> pump(WidgetTester tester, MurmurClient client, Widget home, {Preferences? prefs}) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: client,
      wallets: WalletController()..wallet = WalletId(alice, Uint8List(32)),
      prefs: prefs ?? (Preferences()..aliases = {toHex(bob): 'Bobby', toHex(carol): 'Carol'}),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('"@" in a reply suggests the thread\'s people; a pick writes the name and costs 8 bytes', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread', from: carol);
    final reply = replyTo(thread, 2, text: 'From bob');
    final chain = _Sending([thread, reply]);
    await pump(tester, chain, ComposePage(replyTo: reply));
    final l = tester.element(find.byType(ComposePage)).l10n;
    final field = find.widgetWithText(TextField, l.message);
    String fee() => tester.widget<TextField>(find.widgetWithText(TextField, l.feeToMiner)).controller!.text;
    // Nothing suggested until "@" is typed; then those the app knows.
    await tester.enterText(field, 'Hello ');
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing);
    await tester.enterText(field, 'Hello @bo');
    await tester.pump();
    expect(find.widgetWithText(ActionChip, '@Bobby'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '@Carol'), findsNothing, reason: 'not what was typed');
    final before = fee();
    await tester.tap(find.widgetWithText(ActionChip, '@Bobby'));
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'Hello @Bobby ');
    expect(find.widgetWithText(InputChip, 'Bobby'), findsOneWidget);
    expect(find.text(l.mentionPublicPoint), findsNothing, reason: 'an emphasized point, not plain text');
    // Its 8 bytes are paid for, with the 4 more of text.
    expect(parseAmountForTest(fee()), parseAmountForTest(before) + (8 + 4) * 10000);

    // The summary says whom, and that it is public; what is sent names them.
    await tester.tap(find.widgetWithText(FilledButton, l.signAndSend));
    await tester.pumpAndSettle();
    expect(find.text(l.mentionsLabel), findsWidgets);
    expect(find.byWidgetPredicate((w) => w is Emphasized && w.text == l.mentionPublicPoint), findsWidgets);
    expect(chain.checkedMentions, [toHex(bob)]);
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();

    // Taken away again.
    tester.widget<InputChip>(find.byType(InputChip)).onDeleted!();
    await tester.pump();
    expect(find.byType(InputChip), findsNothing);
    expect(parseAmountForTest(fee()), parseAmountForTest(before) + 4 * 10000);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('at most four', (tester) async {
    final people = [for (var i = 10; i < 15; i++) person(i)];
    final prefs = Preferences()..aliases = {for (var i = 0; i < 5; i++) toHex(people[i]): 'p$i'};
    await pump(tester, _Sending([]), const ComposePage(), prefs: prefs);
    final l = tester.element(find.byType(ComposePage)).l10n;
    final field = find.widgetWithText(TextField, l.message);
    var text = '';
    for (var i = 0; i < 4; i++) {
      await tester.enterText(field, '$text@p$i');
      await tester.pump();
      await tester.tap(find.widgetWithText(ActionChip, '@p$i'));
      await tester.pump();
      text = tester.widget<TextField>(field).controller!.text;
    }
    expect(find.byType(InputChip), findsNWidgets(4));
    await tester.enterText(field, '$text@p4');
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text(l.mentionsMax(maxMentions)), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a message shows whom it mentions, the picture and the name opening their page', (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'Look', from: bob, mentions: [alice, carol, person(40)]);
    final chain = FakeChain([thread, txAt(TxKind.orphan, 2, text: 'Carol was here', from: carol)]);
    await pump(tester, chain, ThreadPage(rootTxid: thread.tx.id), prefs: Preferences());
    final line = find.byType(MentionsLine);
    expect(line, findsOneWidget);
    // Alice is this wallet, carol wrote here: both known. The third only
    // by the 8 bytes the chain holds.
    expect(find.descendant(of: line, matching: find.byType(AddressAvatar)), findsNWidgets(2));
    expect(find.descendant(of: line, matching: find.text('@${toHex(mentionOf(person(40)))}')), findsOneWidget);
    // The name opens the page, not only the picture.
    await tester.tap(find.descendant(of: line, matching: find.text('@${shortHex(toHex(carol))}')));
    await tester.pumpAndSettle();
    expect(tester.widget<AddressPage>(find.byType(AddressPage)).address, toHex(carol));
    await tester.pumpWidget(const SizedBox());
  });

  test('Messages lists what others mention the wallet in, unless withdrawn', () {
    final me = toHex(alice);
    final thread = txAt(TxKind.orphan, 1, text: 'Hi', from: bob, mentions: [alice]);
    final reply = replyTo(thread, 2, from: carol, mentions: [alice, bob]);
    final mine = txAt(TxKind.orphan, 3, text: 'Me', mentions: [alice]);
    final other = txAt(TxKind.orphan, 4, text: 'Not you', from: bob, mentions: [carol]);
    final chain = FakeChain([thread, reply, mine, other]);
    expect(messageFiltersOf(thread, me, chain), {MessageFilter.mentioned});
    expect(messageFiltersOf(reply, me, chain), contains(MessageFilter.mentioned));
    expect(messageFiltersOf(mine, me, chain), {MessageFilter.threads}, reason: 'one\'s own isn\'t news');
    expect(messageFiltersOf(other, me, chain), isEmpty);
    expect(MessageFilter.defaults, contains(MessageFilter.mentioned));
    // Withdrawn by its author: withdrawn as a mention too.
    final withdrawn = txAt(TxKind.flag, 5, from: bob, reference: thread);
    expect(FakeChain([thread, withdrawn]).mentions(thread.tx, me), isFalse);
  });
}

/// Units in a field's text, for comparing fees.
int parseAmountForTest(String text) {
  final parts = text.split('.');
  final fraction = parts.length > 1 ? parts[1].padRight(6, '0') : '0';
  return int.parse(parts[0]) * unitsPerToken + int.parse(fraction);
}
