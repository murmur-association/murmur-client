// Driving the whole app as a user does, for the acceptance tests: the same
// steps on every flavour (a browser, Android, Windows, Linux). What a test
// needs from outside comes in at build time (tool/acceptance_test.dart sets
// it): the node to use, and the seed of a wallet that node's chain pays.
//
// The app keeps its settings and secrets in memory here, never in the
// device's own storage: a run can't touch a wallet the user has, and starts
// from nothing wherever it runs. (Storing for real is
// wallet_storage_test.dart's subject.)

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/main.dart' as app;
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'passkey_io.dart' if (dart.library.js_interop) 'passkey_web.dart';

/// `host:port` of the demo node the app connects to.
const acceptanceNode = String.fromEnvironment('ACCEPTANCE_NODE');

/// The seed (64 hex characters) of the wallet that node's chain pays.
const acceptanceSeed = String.fromEnvironment('ACCEPTANCE_SEED');

/// Whether the app may run a node of its own in this run: on a desktop,
/// where the runner puts the node program and a data folder at hand.
const acceptanceOwnNode = bool.fromEnvironment('ACCEPTANCE_OWN_NODE');

/// Whether this run's browser has a passkey authenticator (a virtual one,
/// which test_driver/integration_test.dart puts in place): the vault then
/// uses a passkey, and never asks for a passphrase.
const acceptancePasskey = bool.fromEnvironment('ACCEPTANCE_PASSKEY');

/// Whether this machine can't show the system's notifications at all: a
/// CI runner's service session has no desktop, and the Windows plugin's
/// start-up ends the app there. The runner sets it from the environment's
/// ACCEPTANCE_NO_NOTIFICATIONS.
const acceptanceNoNotifications = bool.fromEnvironment('ACCEPTANCE_NO_NOTIFICATIONS');

/// Whether the device is much slower than a desktop: an emulator with no
/// KVM, which emulates every instruction (CI's Android runner). A
/// passphrase's 600,000 rounds of PBKDF2 then take minutes, so every wait
/// is six times as long. The runner sets it from the environment's
/// ACCEPTANCE_SLOW.
const acceptanceSlow = bool.fromEnvironment('ACCEPTANCE_SLOW');

Duration _scaled(Duration d) => acceptanceSlow ? d * 6 : d;

/// Whether the app's vault uses the device's key store here, and its
/// check passes by itself: an iPhone simulator, which has no passcode set,
/// so the key store asks nothing (services/key_vault_io.dart). The vault
/// then never asks for a passphrase either.
bool get acceptanceDeviceLock => defaultTargetPlatform == TargetPlatform.iOS;

/// The one passphrase of the app in these tests.
const passphrase = 'correct horse battery';

/// A fresh device: no wallet, no cards, the test's node as its node, and
/// the question about keeping a local copy answered (no).
void freshDevice() {
  final colon = acceptanceNode.lastIndexOf(':');
  if (colon < 0 || acceptanceSeed.length != 64) {
    fail('Run through `flutter test tool/acceptance_test.dart`, which starts the node and passes '
        'ACCEPTANCE_NODE and ACCEPTANCE_SEED.');
  }
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({
    'node_host': acceptanceNode.substring(0, colon),
    'node_port': int.parse(acceptanceNode.substring(colon + 1)),
    'storage_consent': StorageConsent.rejected.name,
  });
}

/// The app on screen, and what a user does with it.
class AppDriver {
  AppDriver(this.tester);

  final WidgetTester tester;

  /// Starts the app as its `main` does, on what the device holds now, and
  /// waits until it follows the node's chain.
  Future<void> start() async {
    if (acceptancePasskey) {
      // The page loads before the driver has given the browser its
      // authenticator: nothing starts until it's there.
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (!await passkeyAuthenticatorThere()) {
        if (DateTime.now().isAfter(deadline)) fail('the browser has no passkey authenticator');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    // Typing goes to the test's text input, not the system's keyboard, which
    // integration tests otherwise keep: an iPhone's reports its own state
    // back, and moved the cursor away from what the test had just typed.
    if (!tester.testTextInput.isRegistered) {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
    }
    await app.main();
    await waitFor(find.byType(HomePage), what: 'the home page');
    await waitUntil(() => client.state == LinkState.live, what: 'the app to follow the chain');
  }

  // Still there, offstage, under a page pushed over it.
  BuildContext get _home => tester.element(find.byType(HomePage, skipOffstage: false));
  AppLocalizations get l => _home.l10n;
  MurmurClient get client => AppScope.of(_home).client;
  WalletController get wallets => AppScope.of(_home).wallets;
  Preferences get prefs => AppScope.of(_home).prefs;
  LocalNode get ownNode => AppScope.of(_home).localNode!;

  /// Lets the app run until `done`, for at most `timeout`: frames are drawn
  /// as time passes, without waiting for animations to end (a spinner never
  /// does).
  Future<void> waitUntil(bool Function() done,
      {required String what, Duration timeout = const Duration(seconds: 90)}) async {
    final deadline = DateTime.now().add(_scaled(timeout));
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for $what (link ${client.state.name} at ${client.height}, error ${client.error})\n'
            '${_onScreen()}');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
  }

  Future<void> waitFor(Finder finder, {required String what, Duration timeout = const Duration(seconds: 90)}) async {
    final deadline = DateTime.now().add(_scaled(timeout));
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('timed out waiting for $what\n${_onScreen()}');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
  }

  /// The texts on screen, for a failure's report: what the user would see.
  String _onScreen() {
    final texts = [
      for (final e in find.byType(Text).evaluate())
        if ((e.widget as Text).data case final String t when t.trim().isNotEmpty) t.replaceAll('\n', ' '),
    ];
    return 'on screen: ${texts.take(60).join(' | ')}';
  }

  Future<void> waitGone(Finder finder, {required String what}) =>
      waitUntil(() => finder.evaluate().isEmpty, what: what);

  /// Taps what `finder` finds (the last, which is the one on top), once
  /// it's there, scrolled into view.
  Future<void> tap(Finder finder, {String? what}) async {
    await waitFor(finder, what: what ?? '$finder');
    await tester.ensureVisible(finder.last);
    await tester.pump();
    // Not while its page still slides in: a tap would land beside it.
    for (var i = 0, at = tester.getRect(finder.last); i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isEmpty) break;
      final now = tester.getRect(finder.last);
      if (now == at) break;
      at = now;
    }
    await tester.tap(finder.last);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapText(String text) => tap(find.text(text), what: '"$text"');

  /// Scrolls the page down to what `finder` looks for, when it isn't built
  /// yet: a long page builds only what's near the screen.
  Future<void> _reveal(Finder finder) async {
    final page = find.byType(Scrollable);
    if (finder.evaluate().isNotEmpty || page.evaluate().isEmpty) return;
    try {
      await tester.scrollUntilVisible(finder, 250, scrollable: page.first, maxScrolls: 15);
    } on StateError {
      // Not on this page (yet): the caller waits for it.
    }
  }

  /// A button of type `T` labelled `label`, enabled. With `within`, the one
  /// inside what that finds (a message's card, say).
  Future<void> press<T extends ButtonStyleButton>(String label, {Finder? within}) async {
    final text = within == null ? find.text(label) : find.descendant(of: within, matching: find.text(label));
    await _reveal(text);
    // By what it is, not its exact type: a button with an icon is a subclass.
    final button = find.ancestor(of: text, matching: find.byWidgetPredicate((w) => w is T));
    await waitUntil(() => button.evaluate().isNotEmpty && tester.widget<T>(button.last).onPressed != null,
        what: 'the "$label" button to be there and enabled');
    await tap(button, what: 'the "$label" button');
  }

  /// Flips the switch titled `title`.
  Future<void> flip(String title) async {
    await _reveal(find.text(title));
    await tap(find.descendant(of: find.widgetWithText(SwitchListTile, title), matching: find.byType(Switch)),
        what: 'the "$title" switch');
  }

  /// Whether a point of an explanation (an icon and one line) says `text`.
  bool says(String text) => find.byWidgetPredicate((w) => w is Emphasized && w.text == text).evaluate().isNotEmpty;

  /// Types into the field labelled `label`.
  Future<void> type(String label, String text) async {
    final field = find.ancestor(of: find.text(label), matching: find.byType(TextField));
    await waitFor(field, what: 'the "$label" field');
    await tester.enterText(field.last, text);
    await tester.pump();
  }

  /// What the field labelled `label` holds.
  String fieldText(String label) {
    final field = find.ancestor(of: find.text(label), matching: find.byType(TextField));
    return tester.widget<TextField>(field.last).controller!.text;
  }

  /// Pulls the list in view down from its top, as a finger does, to have it
  /// taken again.
  Future<void> pullDown(Finder list) async {
    await waitFor(list, what: 'the list to pull');
    await tester.fling(list.first, const Offset(0, 500), 1500);
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// A tab of the home page.
  Future<void> openTab(String label) => tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
      what: 'the $label tab');

  /// Back, page by page, to the home page.
  Future<void> backHome() async {
    // Not while a page still slides in: the home page under it counts as
    // on screen until it has.
    await tester.pump(const Duration(milliseconds: 600));
    for (var pages = 0; find.byType(HomePage).evaluate().isEmpty; pages++) {
      if (pages == 10) fail('no way back to the home page\n${_onScreen()}');
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  // ---- the passphrase ----------------------------------------------------------

  bool get asksPassphrase => find.text(l.passphraseTitle).evaluate().isNotEmpty;

  /// Chooses the app's passphrase, when a wallet (or the first cards) set
  /// it up.
  Future<void> choosePassphrase() async {
    // A passkey is made instead, by the browser's own check; or the
    // device's key store keeps it.
    if (acceptancePasskey || acceptanceDeviceLock) return;
    await waitFor(find.text(l.passphraseNewTitle), what: 'the dialog that chooses a passphrase');
    await type(l.passphraseField, passphrase);
    await type(l.passphraseRepeat, passphrase);
    await press<FilledButton>(l.save);
    await waitGone(find.text(l.passphraseNewTitle), what: 'the passphrase to be taken');
  }

  /// Answers the one question an action asks, and checks it isn't asked a
  /// second time for the same action.
  Future<void> unlock() async {
    // The passkey's or the device's check passes by itself, with nothing
    // on screen.
    if (acceptancePasskey || acceptanceDeviceLock) return;
    await waitFor(find.text(l.passphraseTitle), what: 'the passphrase to be asked');
    await type(l.passphraseField, passphrase);
    await press<FilledButton>(l.unlock);
    await waitGone(find.text(l.passphraseTitle), what: 'the passphrase to be taken');
  }

  // ---- what a user does ----------------------------------------------------------

  /// Brings the test's wallet onto the device from its seed.
  Future<void> importWallet() async {
    await openTab(l.tabWallet);
    await press<OutlinedButton>(l.importSeed);
    await type(l.seedOrWords, acceptanceSeed);
    await press<FilledButton>(l.import);
    await choosePassphrase();
    await waitUntil(() => wallets.wallet != null, what: 'the wallet to be saved');
  }

  /// Switches on notifications of `topic` (its switch's title), from the
  /// bell in the Messages tab, and closes the settings.
  Future<void> switchOnNotifications(String topic) async {
    await openTab(l.tabMessages);
    await tap(find.byTooltip(l.notifications), what: 'the notifications bell');
    await flip(topic);
    await press<TextButton>(l.done);
    await waitGone(find.text(topic), what: 'the notification settings to close');
  }

  /// The app stops being in front, as when another window takes the focus;
  /// [comeBack] brings it back. (Not hidden: a hidden app draws no frames,
  /// and the test drives it by frames.)
  void goAway() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);

  void comeBack() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  /// Someone else, with a wallet of their own on another device, replies to
  /// the thread `root`: the test's wallet funds theirs, they send the reply,
  /// and both are mined. Returns their address and the reply.
  Future<(String, Transaction)> someoneReplies(String root, String text) async {
    final payer = await MurmurWallet.fromSeed(fromHex(acceptanceSeed));
    final someone = await MurmurWallet.generate();
    final colon = acceptanceNode.lastIndexOf(':');
    final other = MurmurClient();
    bool mined(Transaction tx) => other.lookupTx(tx.id)?.confirmed ?? false;
    try {
      unawaited(other.connect(acceptanceNode.substring(0, colon), int.parse(acceptanceNode.substring(colon + 1))));
      // Proven at the tip: a fresh client's first proof can be from a block
      // before the wallet's last transaction (sent from the app, which this
      // device doesn't know of), and its nonce would then be one too few.
      await waitUntil(
          () =>
              other.state == LinkState.live &&
              other.account(payer.addressHex)?.height == other.height &&
              (other.availableTo(payer.addressHex) ?? 0) > 0,
          what: "the other device to see the test's wallet, proven at the tip");
      final fund = await other.submit(
          wallet: payer, kind: TxKind.raw, to: someone.address, amount: 5 * unitsPerToken, fee: minFee);
      try {
        await waitUntil(() => mined(fund) && (other.availableTo(someone.addressHex) ?? 0) > 0,
            what: 'their wallet to be funded', timeout: const Duration(minutes: 3));
      } on TestFailure catch (e) {
        // What the other device knew, to tell a refused transaction from a
        // slow chain.
        fail('${e.message}\nthe funding ${fund.id}, nonce ${fund.nonce}: the node says ${other.statusOf(fund.id)}, '
            'mined ${mined(fund)}; the payer\'s proven nonce ${other.account(payer.addressHex)?.nonce}, '
            'their balance ${other.availableTo(someone.addressHex)}, the other device at ${other.height} '
            '(${other.state.name}, error ${other.error})');
      }
      // The thread itself, as a page opened on it has: a fresh client holds
      // only recent blocks, and on a slow device the thread can be older.
      other.requestTx(root);
      await waitUntil(() => other.lookupTx(root)?.confirmed ?? false, what: 'the thread on the other device');
      final reply = await other.submit(
          wallet: someone,
          kind: TxKind.reply,
          amount: minFee,
          fee: minFee,
          message: MurmurClient.encodeText(text),
          reference: root);
      await waitUntil(() => mined(reply), what: 'their reply to be mined', timeout: const Duration(minutes: 3));
      return (someone.addressHex, reply);
    } finally {
      other.dispose();
    }
  }

  /// Writes `text` on the compose page that's open, and signs and sends it:
  /// the form, the summary, then the passphrase.
  Future<void> writeAndSend(String text) async {
    await type(l.message, text);
    await press<FilledButton>(l.signAndSend);
    await waitFor(find.text(l.confirmSendTitle), what: 'the summary before signing');
    await press<FilledButton>(l.signAndSend);
    await unlock();
  }
}
