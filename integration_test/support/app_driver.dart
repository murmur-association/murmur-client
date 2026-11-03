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
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/main.dart' as app;
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/key_vault.dart' show deviceKeyStoreAllowed;
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/notifier.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/home_page.dart';
import 'package:murmur_client/protocol/profile.dart';
import 'package:murmur_client/ui/people.dart' show ProfilePicturePainter;
import 'package:murmur_client/ui/picture_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'acceptance_protocol.dart';
import 'passkey_io.dart' if (dart.library.js_interop) 'passkey_web.dart';
import 'runner_signal_io.dart' if (dart.library.js_interop) 'runner_signal_web.dart';

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

/// Who works the system's picture chooser in this run, as the runner says:
/// `host`, the runner itself, at the app's requests (Android, Linux, and
/// Windows with a desktop: tool/system_chooser.dart); `browser`, the
/// browser's driver, by itself; empty where nothing outside the app can
/// (macOS, iOS, Windows without a desktop), and the test then hands over a
/// file in the chooser's place.
const acceptanceSystemChooser = String.fromEnvironment('ACCEPTANCE_SYSTEM_CHOOSER');

Duration _scaled(Duration d) => acceptanceSlow ? d * 6 : d;

/// Whether the app's vault uses the device's key store here, and its
/// check passes by itself: an iPhone simulator, which has no passcode set,
/// so the key store asks nothing (services/key_vault_io.dart). The vault
/// then never asks for a passphrase either.
/// On Android, the runner enrolls a fingerprint in the emulator and touches
/// it for each prompt (tool/android_system.dart), and says so with
/// ACCEPTANCE_DEVICE_LOCK.
bool get acceptanceDeviceLock =>
    defaultTargetPlatform == TargetPlatform.iOS || const bool.fromEnvironment('ACCEPTANCE_DEVICE_LOCK');

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
    // A Mac's key store asks for the login password in a dialog the test
    // can't answer: a passphrase instead, as on Windows and Linux.
    if (defaultTargetPlatform == TargetPlatform.macOS) deviceKeyStoreAllowed = false;
    // A window the system never showed has no size (a Mac runner with no
    // one at its screen: "Failed to foreground app"), and every tap then
    // lands outside it. The app is laid out at a laptop's size instead; so
    // too a Mac window of the template's 800 × 600, which GitHub's runner
    // shows: a thread page gone to a new reply had its first message off
    // the screen, unbuilt (2026-11-03).
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    debugPrint('the window: ${tester.view.physicalSize} at ${tester.view.devicePixelRatio}');
    if (tester.view.physicalSize.isEmpty ||
        (defaultTargetPlatform == TargetPlatform.macOS && (size.width < 1280 || size.height < 800))) {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    // Android's accessibility switches the app's semantics on whenever the
    // runner reads a screen of the system's (uiautomator, every 2 s), and
    // the test then fails at its end: "A SemanticsHandle was active". The
    // runner never reads the app's own screen, so they stay off.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      tester.binding.platformDispatcher.semanticsEnabledTestValue = false;
      addTearDown(tester.binding.platformDispatcher.clearSemanticsEnabledTestValue);
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
  /// does). A `done` that throws (it reads a field of a page not built yet,
  /// as on a slow device) counts as not yet.
  Future<void> waitUntil(bool Function() done,
      {required String what, Duration timeout = const Duration(seconds: 90)}) async {
    final deadline = DateTime.now().add(_scaled(timeout));
    Object? lastError;
    bool doneYet() {
      try {
        return done();
      } on StateError catch (e) {
        lastError = e;
        return false;
      }
    }

    while (!doneYet()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for $what (link ${client.state.name} at ${client.height}, error ${client.error})\n'
            '${lastError == null ? '' : 'last: $lastError\n'}${_onScreen()}');
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
    // Apple's notification centre asks the user, in a dialog of the system's
    // that the test can't answer: quiet permission needs no answer.
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      SystemNotifier.quietPermission = true;
    }
    await openTab(l.tabMessages);
    await tap(find.byTooltip(l.notifications), what: 'the notifications bell');
    final wasOn = prefs.notifyTopics.isNotEmpty;
    // Switching off cancels Android's background check: first the runner
    // runs it, as asked when it was switched on, and says so.
    if (wasOn && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final deadline = DateTime.now().add(_scaled(const Duration(minutes: 5)));
      while (!await runnerSaid(androidBackgroundJobDone)) {
        if (DateTime.now().isAfter(deadline)) fail('timed out waiting for the runner to run the background check');
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    await flip(topic);
    // Switched on, it's on only once the system has answered: Android's
    // permission prompt stays up until the runner taps "Allow", and closing
    // the sheet before then left the topic off. (Flipped again, it goes
    // off, which asks nothing.)
    await waitUntil(() => prefs.notifyTopics.isNotEmpty != wasOn,
        what: wasOn ? 'the topic to go off' : 'the system to allow notifications');
    // Android's background check, scheduled now: the runner runs it as
    // Android would, and checks its Dart side ran.
    if (defaultTargetPlatform == TargetPlatform.android && prefs.notifyTopics.isNotEmpty) {
      debugPrint(androidBackgroundJobRequest);
    }
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
      // Paid again if another of the wallet's transactions takes the
      // funding's nonce: one no device here knows of can still be waiting to
      // be mined (the card funded before the app restarted), and the proven
      // nonce counts only what is mined.
      for (var attempt = 1;; attempt++) {
        // Proven at the tip: a fresh client's first proof can be from a
        // block before the wallet's last transaction (sent from the app,
        // which this device doesn't know of), and its nonce would then be one
        // too few.
        await waitUntil(
            () =>
                other.state == LinkState.live &&
                other.account(payer.addressHex)?.height == other.height &&
                (other.availableTo(payer.addressHex) ?? 0) > 0,
            what: "the other device to see the test's wallet, proven at the tip");
        final fund = await other.submit(
            wallet: payer, kind: TxKind.raw, to: someone.address, amount: 5 * unitsPerToken, fee: minFee);
        bool passed() => (other.account(payer.addressHex)?.nonce ?? 0) > fund.nonce;
        try {
          await waitUntil(() => mined(fund) || passed(), what: 'their funding to be mined', timeout: const Duration(minutes: 3));
          // Mined, though perhaps not looked up yet; or another took its nonce.
          await waitUntil(() => mined(fund), what: 'their funding to be mined', timeout: const Duration(seconds: 30));
          break;
        } on TestFailure catch (e) {
          if (passed() && attempt < 3) {
            debugPrint('the funding (nonce ${fund.nonce}) was replaced by another of the wallet\'s transactions: paid again');
            continue;
          }
          // What the other device knew, to tell a refused transaction from a
          // slow chain.
          fail('${e.message}\nthe funding ${fund.id}, nonce ${fund.nonce}, attempt $attempt: '
              'the node says ${other.statusOf(fund.id)?.code.name}, mined ${mined(fund)}; '
              'the payer\'s proven nonce ${other.account(payer.addressHex)?.nonce}, '
              'the other device at ${other.height} (${other.state.name}, error ${other.error})');
        }
      }
      await waitUntil(() => (other.availableTo(someone.addressHex) ?? 0) > 0,
          what: 'their wallet to be funded', timeout: const Duration(minutes: 3));
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

  /// Whether every picture of `address` on screen is its published one,
  /// with no mark beside it, and there is one.
  bool showsPicture(String address) {
    final avatars = find.byWidgetPredicate((w) => w is AddressAvatar && w.address == address);
    final painters = [
      for (final e in find.descendant(of: avatars, matching: find.byType(CustomPaint)).evaluate())
        (e.widget as CustomPaint).painter,
    ];
    return painters.isNotEmpty && painters.every((p) => p is ProfilePicturePainter);
  }

  /// Sets the wallet's public name with a picture (a profile, PROTOCOL.md
  /// Section 7.8), from the Wallet tab: the name typed, a picture chosen
  /// from every source the device offers, then the summary and the
  /// passphrase. The chooser is the system's own wherever something outside
  /// the app can work it ([acceptanceSystemChooser]), which first cancels it
  /// once from each source where it can; elsewhere [samplePictureFile] is
  /// handed over in its place. Gives the picture the dialog showed, which is
  /// what's sent.
  Future<ProfilePicture> setPublicName(String name) async {
    await backHome();
    await openTab(l.tabWallet);
    await press<FilledButton>(l.publicNameAndPictureSet);
    await waitFor(find.text(l.publicNameField), what: 'the public name dialog');
    await type(l.publicNameField, name);
    // What each chooser gave back, in turn.
    final returned = <PickedPicture?>[];
    final file = acceptanceSystemChooser.isEmpty ? await samplePictureFile() : null;
    pickPictureOverride = (source) async {
      final picked = file != null ? (bytes: file, problem: null) : await pickPictureFromSystem(source);
      returned.add(picked);
      return picked;
    };
    // A phone offers its photos and its files; elsewhere, one button for a file.
    final sources = hasPhotoLibrary ? [PictureSource.photos, PictureSource.files] : [PictureSource.files];
    String label(PictureSource source) => !hasPhotoLibrary
        ? l.pictureChoose
        : (source == PictureSource.photos ? l.pictureFromPhotos : l.pictureFromFiles);
    Future<PickedPicture?> choose(PictureSource source, {bool cancel = false}) async {
      final before = returned.length;
      if (acceptanceSystemChooser == 'host') {
        debugPrint('${cancel ? chooserCancelRequest : chooserPickRequest}${source.name}');
      }
      await press<OutlinedButton>(label(source));
      await waitUntil(() => returned.length > before,
          what: cancel ? "the system's chooser to be cancelled" : "a file from the system's chooser",
          timeout: const Duration(minutes: 3));
      // Its buttons come back once the file is read.
      await waitFor(find.text(label(source)), what: 'the picked file to be read');
      return returned.last;
    }

    try {
      // Cancelled, the chooser leaves the dialog as it was.
      if (acceptanceSystemChooser == 'host') {
        for (final source in sources) {
          expect(await choose(source, cancel: true), isNull, reason: 'cancelled from ${source.name}');
          expect(find.text(l.pictureRemove), findsNothing, reason: 'no picture after a cancel');
          expect(find.text(l.pictureUnreadable), findsNothing, reason: 'and nothing wrong');
        }
      }
      // Picked from each source; the last is what's sent.
      for (final source in sources) {
        final picked = await choose(source);
        expect(picked?.bytes, isNotNull, reason: 'a file from ${source.name}');
        expect(picked!.bytes, isNotEmpty);
        expect(find.text(l.pictureUnreadable), findsNothing, reason: 'the file from ${source.name} is a picture');
        expect(find.text(l.pictureRemove), findsOneWidget, reason: 'a picture to send, from ${source.name}');
      }
    } finally {
      pickPictureOverride = null;
    }
    final shown = tester.widget<PicturePreview>(find.byWidgetPredicate((w) => w is PicturePreview && w.size == 72));
    expect(find.byWidgetPredicate((w) => w is InfoPoint && w.text == l.pictureCost), findsOneWidget,
        reason: 'what a picture costs, said before sending');
    await press<FilledButton>(l.publicNameSet);
    await waitFor(find.text(l.profileSetTo(name)), what: 'the profile on the compose page');
    await press<FilledButton>(l.signAndSend);
    await waitFor(find.text(l.confirmSendTitle), what: 'the summary before signing');
    await press<FilledButton>(l.signAndSend);
    await unlock();
    return shown.picture!;
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

/// An image file a user might pick for their picture: a wide PNG (a sky, a
/// sun, a hill), of which the picture takes the middle. Made in plain Dart,
/// with nothing drawn: drawing and reading back failed on a machine with
/// software graphics (Windows' CI runner).
Future<Uint8List> samplePictureFile() async {
  const width = 240, height = 160;
  int mix(int a, int b, double t) => (a + (b - a) * t).round();
  final rows = BytesBuilder();
  for (var y = 0; y < height; y++) {
    rows.addByte(0); // Each row unfiltered.
    for (var x = 0; x < width; x++) {
      final t = y / (height - 1);
      var rgb = [mix(0x2B, 0xF2, t), mix(0x2D, 0xB3, t), mix(0x6E, 0x5E, t)];
      if ((x - 130) * (x - 130) + (y - 70) * (y - 70) <= 26 * 26) rgb = [0xFF, 0xE3, 0xA3];
      final hx = (x - 120) / 160, hy = (y - 170) / 60;
      if (hx * hx + hy * hy <= 1) rgb = [0x3A, 0x2E, 0x3F];
      rows.add(rgb);
    }
  }
  return _png(width, height, rows.takeBytes());
}

/// A PNG of `width` x `height` RGB pixels, `raw` its filtered rows, stored
/// uncompressed (zlib's stored blocks), so no compressor is needed.
Uint8List _png(int width, int height, Uint8List raw) {
  final png = BytesBuilder()..add(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  List<int> u32(int v) => [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];
  void chunk(String type, List<int> data) {
    final typed = [...type.codeUnits, ...data];
    png
      ..add(u32(data.length))
      ..add(typed)
      ..add(u32(_crc32(typed)));
  }

  final zlib = BytesBuilder()..add(const [0x78, 0x01]);
  for (var at = 0; at < raw.length; at += 65535) {
    final n = raw.length - at < 65535 ? raw.length - at : 65535;
    zlib
      ..addByte(at + n == raw.length ? 1 : 0)
      ..add([n & 0xff, n >> 8, ~n & 0xff, (~n >> 8) & 0xff])
      ..add(Uint8List.sublistView(raw, at, at + n));
  }
  var a = 1, b = 0;
  for (final byte in raw) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  zlib.add(u32(b * 65536 + a));
  chunk('IHDR', [...u32(width), ...u32(height), 8, 2, 0, 0, 0]);
  chunk('IDAT', zlib.takeBytes());
  chunk('IEND', const []);
  return png.takeBytes();
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var k = 0; k < 8; k++) {
      crc = crc & 1 != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
