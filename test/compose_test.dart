// The compose page's fee: the suggestion follows the chain without
// overwriting what the fee field says, a change is pointed out, a reply's
// reward is the suggested fee, and the summary remarks on a fee that isn't
// the suggestion.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart' show WalletId;
import 'package:murmur_client/protocol/alias.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/profile.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/fees.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/compose_page.dart';

import 'support/messages.dart';

/// A chain whose fee figures and tip the test sets, ready to send from.
class _FeeChain extends FakeChain {
  _FeeChain(super.oldestFirst) {
    state = LinkState.live;
  }

  FeeInfo fees = feeInfoFromNode(const Fees(pending: 0));
  int tip = 10;

  /// Moves the tip on with new figures, as a new block does.
  void newBlock(FeeInfo now) {
    fees = now;
    tip++;
    notifyListeners();
  }

  @override
  int get height => tip;

  @override
  Future<FeeInfo> feeInfo() async => fees;

  @override
  int? availableTo(String address) => 100 * unitsPerToken;

  /// The message the page last checked before its summary.
  Uint8List? checked;

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
    checked = message;
    return null;
  }
}

void main() {
  testWidgets('the suggested fee follows the chain, flashes when it moves, and is taken only with "Use"',
      (tester) async {
    final thread = txAt(TxKind.orphan, 1, text: 'A thread', from: bob);
    final chain = _FeeChain([thread]);
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: chain,
      wallets: WalletController()..wallet = WalletId(alice, Uint8List(32)),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ComposePage(replyTo: thread),
      ),
    ));
    await tester.pump();
    await tester.pump();
    final l = tester.element(find.byType(ComposePage)).l10n;
    String field(String label) => tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;
    Iterable<FadingHighlight> flashing() =>
        tester.widgetList<FadingHighlight>(find.byType(FadingHighlight)).where((h) => h.since != null);

    // The fee is the suggestion, and so is the reward to the thread's
    // author: nothing more by default.
    expect(field(l.feeToMiner), '0.5');
    expect(field(l.payToAuthor), '0.5');

    // A phone's keyboard capitalizes the message's sentences.
    final message = tester.widget<TextField>(find.widgetWithText(TextField, l.message));
    expect(message.textCapitalization, TextCapitalization.sentences);
    await tester.enterText(find.widgetWithText(TextField, l.message), 'Hello there');
    await tester.pump();

    // Blocks fill up: the suggestion moves. The fee stays as it was; "Use"
    // and the fee field flash.
    chain.newBlock(feeInfoFromNode(const Fees(nextBlock: (fee: 2 * unitsPerToken, weight: 200), pending: 900)));
    await tester.pump();
    await tester.pump();
    expect(field(l.feeToMiner), '0.5');
    expect(flashing().length, 2);
    await tester.pumpAndSettle();

    // The summary says, lightly, that it's below the suggestion.
    await tester.tap(find.widgetWithText(FilledButton, l.signAndSend));
    await tester.pumpAndSettle();
    expect(find.textContaining('Below the suggested fee'), findsOneWidget);
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();

    // "Use" takes it: the fee, and the untouched reward with it.
    await tester.tap(find.text(l.use));
    await tester.pumpAndSettle();
    final fee = field(l.feeToMiner);
    expect(fee, isNot('0.5'));
    expect(field(l.payToAuthor), fee);
    expect(flashing(), isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, l.signAndSend));
    await tester.pumpAndSettle();
    expect(find.textContaining('suggested fee'), findsNothing, reason: 'the suggestion itself');
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();

    // A reward set by hand stays; a fee set above the suggestion is said too.
    await tester.enterText(find.widgetWithText(TextField, l.payToAuthor), '7');
    await tester.enterText(find.widgetWithText(TextField, l.feeToMiner), '5');
    await tester.pump();
    expect(field(l.payToAuthor), '7');
    await tester.tap(find.widgetWithText(FilledButton, l.signAndSend));
    await tester.pumpAndSettle();
    expect(find.textContaining('Above the suggested fee'), findsOneWidget);
    await tester.tap(find.text(l.cancel));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a public name with a picture is sent as a profile, and without one as an alias', (tester) async {
    final picture = ProfilePicture([for (var i = 0; i < 16; i++) i * 0x111111],
        Uint8List.fromList([for (var i = 0; i < 1024; i++) i % 16]));
    for (final withPicture in [true, false]) {
      final chain = _FeeChain(const []);
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(AppScope(
        client: chain,
        wallets: WalletController()..wallet = WalletId(alice, Uint8List(32)),
        prefs: Preferences(),
        child: MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ComposePage(alias: 'bob', picture: withPicture ? picture : null),
        ),
      ));
      await tester.pump();
      await tester.pump();
      final l = tester.element(find.byType(ComposePage)).l10n;
      expect(find.text(withPicture ? l.profileSetTo('bob') : l.aliasSetTo('bob')), findsOneWidget);
      // The page shows the picture being published, not the one published now.
      expect(tester.widget<PicturePreview>(find.byType(PicturePreview)).picture, withPicture ? picture : isNull);
      await tester.tap(find.widgetWithText(FilledButton, l.signAndSend));
      await tester.pumpAndSettle();
      expect(chain.checked, withPicture ? profileMessage('bob', picture) : aliasMessage('bob'));
      await tester.tap(find.text(l.cancel));
      await tester.pumpWidget(const SizedBox());
    }
  });
}
