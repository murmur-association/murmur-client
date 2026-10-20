// Invitation cards at rest (InviteStore): a card's code holds its key, so
// codes are stored sealed, and reading one asks every time. On platforms
// without a device key store, as in these tests, with a passphrase.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/invite.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/invitations.dart';
import 'package:murmur_client/services/key_vault.dart';
import 'package:murmur_client/protocol/wire.dart' show Fees;
import 'package:murmur_client/services/fees.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/unlock.dart';
import 'package:murmur_client/ui/invitations_page.dart';
import 'package:murmur_client/ui/qr.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/vault_prompts.dart';

const _stored = 'murmur_invitations';
final _network = Uint8List.fromList([1, 2, 3, 4]);

/// A card: its code, and the record a device keeps of it.
Future<(InviteRecord, String)> _card(int n) async {
  final invite = Invite(network: _network, seed: Uint8List.fromList(List.generate(32, (i) => i + n)));
  final address = (await cardWallet(invite)).addressHex;
  return (InviteRecord(address: address, amount: 56, serial: n, batch: 2, funder: 'ab' * 32), invite.code);
}

Future<String?> _raw() => const FlutterSecureStorage().read(key: _stored);

/// A client that is live on some network, and counts what it's asked to
/// send instead of sending it.
class _Client extends MurmurClient {
  _Client() {
    genesis = Uint8List(32);
  }

  int sent = 0;

  @override
  Future<Transaction> submit(
      {required MurmurWallet wallet,
      required TxKind kind,
      Uint8List? to,
      int amount = 0,
      required int fee,
      Uint8List? message,
      String? reference,
      List<String> mentions = const []}) {
    sent++;
    throw const TxProblem(TxProblemKind.notLive);
  }

  /// Every card holds what it was funded with (and so does the wallet,
  /// until a test says otherwise).
  int balance = 56;

  @override
  int? availableTo(String address) => balance;

  @override
  Future<FeeInfo> feeInfo() async => feeInfoFromNode(const Fees(pending: 0));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('codes are stored sealed; making cards asks once, and reading a code asks every time', () async {
    final (first, firstCode) = await _card(1);
    final (second, secondCode) = await _card(2);
    final store = InviteStore();
    await store.load();
    final setup = TestPrompts('correct horse', null);
    await store.add([first], [firstCode], setup, reason: 'test');
    await store.add([second], [secondCode], setup, reason: 'test');
    expect((setup.setupAsked, setup.asked), (1, 0), reason: 'only the first cards set the protection up');

    // What's on the device: the cards' addresses, never a code or a key.
    final raw = (await _raw())!;
    expect(raw, contains(first.address));
    for (final code in [firstCode, secondCode]) {
      expect(raw, isNot(contains(code)));
      expect(raw.toLowerCase(), isNot(contains(toHex(Invite.parse(code)!.seed))));
    }

    // Another session: the list needs nothing, a code needs the passphrase.
    final later = InviteStore();
    await later.load();
    expect([for (final r in later.invites) r.address], [first.address, second.address]);
    expect(later.invites.every((r) => r.plainCode == null), isTrue);
    final prompts = TestPrompts(null, 'correct horse');
    expect(await later.unlock(later.invites, prompts, reason: 'test'), [firstCode, secondCode]);
    expect(await later.unlock([later.invites.last], prompts, reason: 'test'), [secondCode]);
    expect((prompts.asked, prompts.setupAsked), (2, 0));

    await expectLater(later.unlock(later.invites, TestPrompts(null, 'wrong horse'), reason: 'test'),
        throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrongPassphrase', isTrue)));
    await expectLater(later.unlock(later.invites, TestPrompts(null, null), reason: 'test'),
        throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrongPassphrase', isFalse)));

    // Cancelling one is remembered without unlocking anything.
    await later.markTookBack(later.invites.first);
    final again = InviteStore();
    await again.load();
    expect([for (final r in again.invites) r.tookBack], [true, false]);
  });

  test('without the protection set up, no card is kept and none is funded', () async {
    final store = InviteStore();
    await store.load();
    final client = _Client();
    final wallet = await MurmurWallet.generate();
    final cancelled = TestPrompts(null, null);
    await expectLater(
        createInvitations(
          client: client,
          wallet: wallet,
          keep: (records, codes) => store.add(records, codes, cancelled, reason: 'test'),
          count: 2,
          perCard: 56,
          fundingFee: 1,
        ),
        throwsA(isA<VaultLocked>()));
    expect(client.sent, 0);
    expect(store.invites, isEmpty);
    expect(await _raw(), isNull);

    // Set up: the cards are kept, sealed, before the first is paid for.
    final kept = <String>[];
    await expectLater(
        createInvitations(
          client: client,
          wallet: wallet,
          keep: (records, codes) async {
            await store.add(records, codes, TestPrompts('correct horse', null), reason: 'test');
            kept.addAll(codes);
          },
          count: 2,
          perCard: 56,
          fundingFee: 1,
        ),
        throwsA(isA<TxProblem>()));
    expect((client.sent, store.invites.length), (1, 2));
    expect(await store.unlock(store.invites, TestPrompts(null, 'correct horse'), reason: 'test'), kept);
    expect([for (final c in kept) (await cardWallet(Invite.parse(c)!)).addressHex],
        [for (final r in store.invites) r.address]);
  });

  test('cards an earlier version stored in the clear are listed as before, and sealed at the next unlock', () async {
    final (first, firstCode) = await _card(1);
    final (second, secondCode) = await _card(2);
    FlutterSecureStorage.setMockInitialValues({
      _stored: jsonEncode([
        {'code': firstCode, 'amount': 56, 'serial': 1, 'batch': 2, 'funder': 'ab' * 32, 'tookBack': false},
        {'code': secondCode, 'amount': 56, 'serial': 2, 'batch': 2, 'tookBack': true},
        {'code': 'not a card', 'amount': 56, 'serial': 3, 'batch': 3},
      ]),
    });
    final store = InviteStore();
    await store.load();
    expect([for (final r in store.invites) (r.address, r.funder, r.tookBack)],
        [(first.address, 'ab' * 32, false), (second.address, null, true)]);

    // The first unlock sets the protection up, and that's the one prompt.
    final prompts = TestPrompts('correct horse', null);
    expect(await store.unlock(store.invites, prompts, reason: 'test'), [firstCode, secondCode]);
    expect((prompts.setupAsked, prompts.asked), (1, 0));
    final raw = (await _raw())!;
    expect(raw, isNot(contains(firstCode)));
    expect(raw, isNot(contains(secondCode)));

    final later = InviteStore();
    await later.load();
    expect(await later.unlock(later.invites, TestPrompts(null, 'correct horse'), reason: 'test'),
        [firstCode, secondCode]);
  });

  testWidgets('a card\'s QR code is shown only after unlocking', (tester) async {
    final card = await tester.runAsync(() async {
      final (record, code) = await _card(1);
      await inviteStore.load();
      await inviteStore.add([record], [code], TestPrompts('correct horse', null), reason: 'test');
      return (record, code);
    });
    final code = card!.$2;
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      client: _Client(),
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InvitationsPage(),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    final l = tester.element(find.byType(InvitationsPage)).l10n;
    // The list says the codes are locked, and shows none.
    expect(find.byWidgetPredicate((w) => w is Emphasized && w.text == l.inviteLockedPoint), findsOneWidget);
    expect(find.textContaining(code), findsNothing);

    Future<void> ask(String passphrase) async {
      await tester.tap(find.byTooltip(l.inviteCardHow));
      await tester.pumpAndSettle();
      expect(find.text(l.authReasonCards), findsOneWidget);
      expect(find.byType(QrView), findsNothing);
      await tester.enterText(find.byType(TextField), passphrase);
      // The passphrase is stretched for real, outside the test's fake
      // clock: until the answer shows, whichever it is.
      await tester.tap(find.text(l.unlock));
      await tester.pumpAndSettle(); // the passphrase dialog closes
      // The passphrase is stretched for real, in steps the test's clock
      // drives: until the answer shows, whichever it is.
      bool answered() =>
          find.byType(QrView).evaluate().isNotEmpty || find.text(l.wrongPassphrase).evaluate().isNotEmpty;
      for (var i = 0; i < 100000 && !answered(); i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      await tester.pumpAndSettle();
    }

    await ask('wrong horse');
    expect(find.byType(QrView), findsNothing);
    expect(find.text(l.wrongPassphrase), findsOneWidget);

    await ask('correct horse');
    expect(tester.widget<QrView>(find.byType(QrView)).text, inviteLink(appBaseUrl, code));
    expect(find.text(code), findsOneWidget);
    // From there the link can be passed on.
    expect(find.descendant(of: find.byType(Dialog), matching: find.byType(ShareButton)), findsOneWidget);
  });
  group('one passphrase for the app', () {
    final wrong = throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrongPassphrase', isTrue));

    test('the first cards take the wallet\'s passphrase: none is chosen, and a wrong one keeps nothing', () async {
      final wallets = WalletController();
      await wallets.create(TestPrompts('correct horse', null), reason: 'test');
      final (card, code) = await _card(1);
      final store = InviteStore();
      await store.load();

      await expectLater(store.add([card], [code], TestPrompts('another one', 'wrong horse'), reason: 'test'), wrong);
      expect(store.invites, isEmpty);
      expect(await InviteStore.storedVault(), isNull);

      final setup = TestPrompts('another one', 'correct horse');
      await store.add([card], [code], setup, reason: 'test');
      expect((setup.setupAsked, setup.asked), (0, 1), reason: 'the passphrase there is, not a new one');

      // Both open with it, each asking; the one offered as new opens neither.
      final later = InviteStore();
      await later.load();
      expect(await later.unlock(later.invites, TestPrompts(null, 'correct horse'), reason: 'test'), [code]);
      await expectLater(later.unlock(later.invites, TestPrompts(null, 'another one'), reason: 'test'), wrong);
      expect((await wallets.unlock(TestPrompts(null, 'correct horse'), reason: 'test')).addressHex,
          wallets.wallet!.addressHex);
      // Two records, each with its own ciphertext: the cards' key isn't the seed.
      expect((await InviteStore.storedVault())!['box'], isNot((await WalletController.storedVault())!['box']));
    });

    test('a wallet made after the cards takes theirs, and so does the one that replaces it', () async {
      final (card, code) = await _card(1);
      final store = InviteStore();
      await store.load();
      await store.add([card], [code], TestPrompts('correct horse', null), reason: 'test');

      final wallets = WalletController();
      await expectLater(wallets.create(TestPrompts('another one', 'wrong horse'), reason: 'test'), wrong);
      expect(wallets.wallet, isNull);
      final setup = TestPrompts('another one', 'correct horse');
      await wallets.create(setup, reason: 'test');
      expect((setup.setupAsked, setup.asked), (0, 1));
      await wallets.unlock(TestPrompts(null, 'correct horse'), reason: 'test');

      // Removed and replaced: the cards are still there, and still readable.
      await wallets.forget();
      final again = TestPrompts('another one', 'correct horse');
      await wallets.create(again, reason: 'test');
      expect((again.setupAsked, again.asked), (0, 1));
      expect(await store.unlock(store.invites, TestPrompts(null, 'correct horse'), reason: 'test'), [code]);
    });

    test('funding the first cards asks once: the answer signs and sets the cards up', () async {
      final wallets = WalletController();
      await wallets.create(TestPrompts('correct horse', null), reason: 'test');
      final (card, code) = await _card(1);
      final store = InviteStore();
      await store.load();
      // As the dialog does: one set of prompts for the whole action.
      final asked = TestPrompts(null, 'correct horse');
      final once = OneAnswer(asked);
      await wallets.unlock(once, reason: 'fund');
      await store.add([card], [code], once, reason: 'cards');
      expect((asked.asked, asked.setupAsked), (1, 0));
      // The next action asks again: nothing stayed unlocked.
      final next = TestPrompts(null, 'correct horse');
      expect(await store.unlock(store.invites, next, reason: 'test'), [code]);
      expect(next.asked, 1);

      // A wrong answer fails at the wallet, before any card is kept.
      final wrongOnce = OneAnswer(TestPrompts(null, 'wrong horse'));
      await expectLater(wallets.unlock(wrongOnce, reason: 'fund'), wrong);
    });

    test('with neither there, the first one chooses it', () async {
      final wallets = WalletController();
      final setup = TestPrompts('correct horse', null);
      await wallets.create(setup, reason: 'test');
      expect((setup.setupAsked, setup.asked), (1, 0));
    });
  });

  testWidgets('making cards: "not enough" and the button follow the balance as it changes', (tester) async {
    final client = _Client()..balance = 0;
    final wallets = WalletController()..wallet = WalletId(Uint8List(32), Uint8List(32));
    await tester.pumpWidget(AppScope(
      client: client,
      wallets: wallets,
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreateInvitationsDialog(),
      ),
    ));
    await tester.pumpAndSettle(); // the fees arrive
    final l = tester.element(find.byType(CreateInvitationsDialog)).l10n;
    bool canFund() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, l.inviteFund)).onPressed != null;
    final short = find.byWidgetPredicate(
        (w) => w is Text && w.style?.color == lightTheme.colorScheme.error && (w.data ?? '').isNotEmpty);
    expect(short, findsOneWidget);
    expect(canFund(), isFalse);

    // A block pays the wallet while the dialog is open.
    client.balance = 1 << 30;
    client.notifyListeners();
    await tester.pump();
    expect(short, findsNothing);
    expect(canFund(), isTrue);

    // And it's spent again elsewhere.
    client.balance = 1;
    client.notifyListeners();
    await tester.pump();
    expect(short, findsOneWidget);
    expect(canFund(), isFalse);
  });
}
