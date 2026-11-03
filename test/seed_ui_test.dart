// The seed on screen (lib/ui/seed.dart): shown to every new wallet with a
// clear warning, in words and in characters, and read back in either form.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/seed_phrase.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/key_vault.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/seed.dart';
import 'package:murmur_client/ui/wallet_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/vault_prompts.dart';

final _seed = Uint8List.fromList(List.generate(32, (i) => 200 - i));

/// Wallets whose "create" makes a known wallet at once, without the vault's
/// passphrase dialogs (those have their own tests).
class _Wallets extends WalletController {
  _Wallets(this.made) {
    loaded = true;
  }

  final MurmurWallet made;

  @override
  Future<MurmurWallet> create(VaultPrompts prompts, {required String reason}) async {
    wallet = made.id;
    notifyListeners();
    return made;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late BuildContext app;
  Future<void> pumpApp(WidgetTester tester, {WalletController? wallets, Widget? home}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(AppScope(
      client: MurmurClient(),
      wallets: wallets ?? WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (c) {
            app = c;
            return home ?? const SizedBox();
          }),
        ),
      ),
    ));
    await tester.pump();
  }

  test('creating a wallet hands back the wallet it stored, to show its seed once', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final wallets = WalletController();
    final created = await wallets.create(TestPrompts('correct horse', null), reason: 'test');
    expect(created.addressHex, wallets.wallet!.addressHex);
    expect(created.seed, hasLength(32));
    // The stored record still says nothing of the seed.
    final stored = await const FlutterSecureStorage().readAll();
    expect(stored.values.single, isNot(contains(created.seedHex)));
  });

  testWidgets('creating a wallet shows its seed, with the warning, until the user says it is saved', (tester) async {
    final made = await tester.runAsync(() => MurmurWallet.fromSeed(_seed));
    await pumpApp(tester, wallets: _Wallets(made!)..wallet = null, home: const WalletTab());
    final l = app.l10n;
    await tester.tap(find.text(l.createWallet));
    await tester.pumpAndSettle();

    expect(find.text(l.seedNewTitle), findsOneWidget);
    // Why it matters, said three ways.
    for (final point in [l.seedNewKeep, l.seedNewOnlyWay, l.seedNewSecret]) {
      expect(find.byWidgetPredicate((w) => w is Emphasized && w.text == point), findsOneWidget);
    }
    // The new wallet's own seed, in both forms.
    final words = seedPhrase(_seed).split(' ');
    expect(find.text(toHex(_seed)), findsOneWidget);
    for (final (i, word) in words.indexed) {
      expect(find.textContaining('${i + 1} $word', findRichText: true), findsWidgets);
    }

    // It can't be closed before the box is ticked: not by its button, not
    // by Enter, not by tapping outside, not by going back.
    final done = find.widgetWithText(FilledButton, l.done);
    expect(tester.widget<FilledButton>(done).onPressed, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text(l.seedNewTitle), findsOneWidget);

    await tester.ensureVisible(find.text(l.seedNewSaved));
    await tester.tap(find.text(l.seedNewSaved));
    await tester.pump();
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.text(l.seedNewTitle), findsNothing);
  });

  testWidgets('the seed is copied, never shared: each form has its own copy button', (tester) async {
    final wallet = await tester.runAsync(() => MurmurWallet.fromSeed(_seed));
    await pumpApp(tester);
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    showSeed(app, wallet!);
    await tester.pumpAndSettle();
    final l = app.l10n;
    expect(find.text(l.seedWarning), findsOneWidget);
    await tester.tap(find.text(l.copyWords));
    await tester.tap(find.text(l.copyCharacters));
    await tester.pump();
    expect(copied, [seedPhrase(_seed), toHex(_seed)]);
    // "Copied" shows above the dialog, not as a snack bar on the page's
    // scaffold behind its barrier, and goes by itself.
    expect(find.text(l.copied), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.descendant(of: find.byType(Scaffold), matching: find.text(l.copied)), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(l.copied), findsNothing);
    expect(find.byType(ShareButton), findsNothing, reason: 'the seed is never offered to other apps');
    // Enter closes it: its button is the copper one.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(l.seedTitle), findsNothing);
  });

  testWidgets('a seed is taken as words or as characters, and what is wrong with it is said', (tester) async {
    await pumpApp(tester);
    final l = app.l10n;
    Future<Uint8List?>? result;
    Future<void> open() async {
      result = askSeed(app);
      await tester.pumpAndSettle();
    }

    Future<void> type(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter); // one entry: Enter confirms
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.text(l.seedOrWords), findsOneWidget);
    final words = seedPhrase(_seed).split(' ');

    await type('not a seed');
    expect(find.text(l.seedInvalid), findsOneWidget);
    await type([...words.take(3), 'murmurr', ...words.skip(4)].join(' '));
    expect(find.text(l.seedUnknownWord('murmurr')), findsOneWidget);
    await type([...words.skip(1), words.first].join(' '));
    expect(find.text(l.seedBadChecksum), findsOneWidget);
    // Typing again clears the complaint.
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    expect(find.text(l.seedBadChecksum), findsNothing);

    await type('  ${words.join('  ').toUpperCase()} ');
    expect(await result, _seed);

    await open();
    await type(toHex(_seed));
    expect(await result, _seed);

    await open();
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
