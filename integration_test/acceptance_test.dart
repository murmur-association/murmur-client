// What a user does with the app, start to finish, inside the built app and
// against a real node on a demo chain: the same test on every flavour (a
// browser, Android, iOS, Windows, Linux). Run it through its runner, which
// builds the chain, starts the node and picks the device:
//
//   flutter test tool/acceptance_test.dart              # this desktop
//   ACCEPTANCE_DEVICE=chrome flutter test tool/acceptance_test.dart
//
// The steps are in support/app_driver.dart, one per thing a user does.
// Rules of the code (which reply answers what, the order of threads, the
// vault) are unit-tested in test/; here it's the app as a whole.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/news.dart' show NotifyTopic;
import 'package:murmur_client/services/notifier.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/common.dart' show AvatarLink, shortHex;
import 'package:murmur_client/ui/invitations_page.dart';
import 'package:murmur_client/ui/notifications.dart' show openNotification, payloadTarget;
import 'package:murmur_client/ui/thread_page.dart';
import 'package:murmur_client/ui/threads_tab.dart';

import 'support/app_driver.dart';
import 'support/header_nonce_checks.dart';
import 'support/system_notifications.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // What numbers do differs between a browser and the rest: the header
  // vectors that each once got wrong, on the flavour at hand.
  group('header nonces', headerNonceTests);

  // Told apart from any other run's on the same chain.
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final threadText = 'Acceptance thread $stamp';
  final replyText = 'Acceptance reply $stamp';
  final answerText = 'Acceptance answer $stamp';

  testWidgets('a wallet from its seed, a thread, a reply to it, and an invitation card', (tester) async {
    freshDevice();
    final app = AppDriver(tester);
    await app.start();
    final l = app.l;

    // The wallet: imported, under the passphrase chosen now, and paid.
    await app.importWallet();
    final me = app.wallets.wallet!.addressHex;
    await app.waitFor(find.text(me), what: "the wallet's address on its tab");
    await app.waitUntil(() => (app.client.availableTo(me) ?? 0) > 0, what: "the wallet's proven balance");
    expect(find.text(l.checkingBalance), findsNothing);

    // A thread: written, summarized, signed with the passphrase, and shown
    // in its own page at once.
    await app.openTab(l.tabThreads);
    // It mentions a friend the device knows by name: "@" suggests them.
    final friend = 'f1' * 32;
    await app.prefs.setAlias(friend, 'Friend');
    await app.tapText(l.newThread);
    // On a line of its own: the thread's first line is its title in lists.
    await app.type(l.message, '$threadText\n@Fri');
    await app.tap(find.widgetWithText(ActionChip, '@Friend'), what: 'the suggested friend');
    expect(app.fieldText(l.message), '$threadText\n@Friend ');
    await app.press<FilledButton>(l.signAndSend);
    await app.waitFor(find.text(l.confirmSendTitle), what: 'the summary before signing');
    expect(find.text(l.mentionsLabel), findsWidgets, reason: 'the summary says whom it mentions');
    await app.press<FilledButton>(l.signAndSend);
    await app.unlock();
    await app.waitFor(find.byType(ThreadPage), what: "the new thread's page");
    expect(find.textContaining(threadText), findsWidgets);
    final sent = app.client.messagesBy(me).firstWhere((v) => v.tx.kind == TxKind.orphan).tx;
    expect([for (final m in sent.mentions) toHex(m)], [friend.substring(0, 16)]);
    await app.waitFor(find.text('@Friend'), what: 'whom the thread mentions, under it');

    // Once mined it can be replied to; the reply shows under it. What it
    // pays the thread's author is the suggested fee, nothing more, and the
    // suggestion follows the chain by itself.
    await app.press<TextButton>(l.actionReply);
    await app.waitUntil(() => app.fieldText(l.payToAuthor).isNotEmpty, what: 'the suggested fee');
    expect(app.fieldText(l.payToAuthor), app.fieldText(l.feeToMiner));
    expect(find.byTooltip('Check again'), findsNothing);
    await app.writeAndSend(replyText);
    await app.waitFor(find.text(replyText), what: 'the reply in its thread');
    expect(find.textContaining(threadText), findsWidgets);

    // An answer to the reply (its own Reply button, once the reply is
    // mined): in the same thread, with the reply quoted above it.
    await app.press<TextButton>(l.actionReply,
        within: find.ancestor(of: find.text(replyText), matching: find.byType(Card)));
    await app.writeAndSend(answerText);
    await app.waitFor(find.byType(ThreadPage), what: 'the thread again');
    await app.waitFor(find.text(answerText), what: 'the answer in the thread');
    await app.waitUntil(() => find.text(replyText).evaluate().length == 2,
        what: 'the reply, and the same quoted above its answer');

    // The Threads tab lists it, with its replies counted once they're mined.
    await app.backHome();
    await app.waitFor(find.byType(ThreadsTab), what: 'the home page again');
    await app.waitFor(find.descendant(of: find.byType(ThreadsTab), matching: find.text(threadText)),
        what: 'the thread in the list');
    await app.waitUntil(() => app.client.threads().any((t) => t.root.tx.fromAddress == me && t.replies == 2),
        what: 'the replies to be mined and counted');
    final root = app.client.threads().firstWhere((t) => t.root.tx.fromAddress == me).root.tx.id;

    // Pulled down, the list is taken again at the tip: no button for it.
    // "As of block n (": the block the list is as of.
    bool asOf(int height) => find.textContaining('${l.threadsAsOf(height, '', '').split(' (').first} (').evaluate().isNotEmpty;
    await app.waitUntil(() => !asOf(app.client.height), what: 'a block since the list was taken');
    final tip = app.client.height;
    await app.pullDown(find.descendant(of: find.byType(ThreadsTab), matching: find.byType(Scrollable)));
    expect([for (var h = tip; h <= app.client.height; h++) h].any(asOf), isTrue, reason: 'taken again at the tip');

    // The thread remembers how far it was read, and opens there again.
    final left = app.prefs.threadsRead[root];
    expect(left, isNotNull, reason: 'where the reader left off');
    await app.tap(find.descendant(of: find.byType(ThreadsTab), matching: find.text(threadText)), what: 'the thread');
    await app.waitFor(find.byType(ThreadPage), what: "the thread's page");
    await app.waitFor(find.text(answerText), what: 'where it was left');
    await app.backHome();

    // Messages: each row leads with its author's picture.
    await app.openTab(l.tabMessages);
    await app.waitFor(find.descendant(of: find.byType(ListTile), matching: find.text(answerText)),
        what: 'the answer among the messages');
    final row = find.ancestor(of: find.text(answerText), matching: find.byType(ListTile));
    expect(app.tester.widget<AvatarLink>(find.descendant(of: row, matching: find.byType(AvatarLink))).address, me);
    expect(app.tester.widget<ListTile>(row).tileColor, isNull, reason: "one's own messages are never unread");

    // One invitation card: funding it asks the passphrase once, for the
    // signature and for the cards' codes together.
    await app.openTab(l.tabWallet);
    await app.press<OutlinedButton>(l.invitations);
    await app.tapText(l.createInvitations);
    await app.waitFor(find.byType(CreateInvitationsDialog), what: 'the dialog that makes cards');
    for (var i = 0; i < 4; i++) {
      await app.tapText('−');
    }
    await app.press<FilledButton>(l.inviteFund);
    await app.unlock();
    await app.waitGone(find.byType(CreateInvitationsDialog), what: 'the card to be made');
    expect(app.asksPassphrase, isFalse, reason: 'one question for the whole action');
    expect(inviteStore.invites, hasLength(1));
    await app.waitFor(find.text(l.inviteWaitingState), what: 'the card, waiting to be claimed');

    // One protection for the app: the cards' key is under the wallet's
    // passphrase, or the wallet's own passkey, not a second one (on an
    // iPhone, each is under the device's lock).
    final wallet = (await WalletController.storedVault())!, cards = (await InviteStore.storedVault())!;
    expect(wallet['protection'], acceptancePasskey ? 'passkey' : (acceptanceDeviceLock ? 'device' : 'passphrase'));
    expect(cards['protection'], wallet['protection']);
    if (acceptancePasskey) {
      expect(cards['credential'], wallet['credential'], reason: 'the same passkey');
      expect(cards['salt'], isNot(wallet['salt']), reason: 'a key of its own from it');
    }
    expect(app.asksPassphrase, isFalse);
  });

  testWidgets('after a restart: the wallet, the thread with its reply, and the card are all there',
      (tester) async {
    // What the device held when the first test ended, and nothing more.
    final app = AppDriver(tester);
    await app.start();
    final l = app.l;

    await app.waitFor(find.descendant(of: find.byType(ThreadsTab), matching: find.text(threadText)),
        what: 'the thread, fetched again from the node');

    await app.openTab(l.tabWallet);
    await app.waitUntil(() => app.wallets.wallet != null, what: 'the wallet to be found');
    await app.waitFor(find.text(app.wallets.wallet!.addressHex), what: "the wallet's address");
    expect(find.text(l.importSeed), findsNothing);

    await app.press<OutlinedButton>(l.invitations);
    await app.waitFor(find.byType(InvitationsPage), what: 'the invitations');
    await app.waitUntil(() => inviteStore.invites.length == 1, what: 'the card kept on the device');
    // Listing asks nothing; its code is still locked.
    expect(app.asksPassphrase, isFalse);
  });

  testWidgets('notifications: a reply from someone else is told while the app is away, once, and opens its thread',
      (tester) async {
    final app = AppDriver(tester);
    await app.start();
    final l = app.l;
    await app.waitUntil(() => app.wallets.wallet != null, what: 'the wallet to be found');
    final me = app.wallets.wallet!.addressHex;
    // What the app hands the system, on every flavour.
    final told = <({int id, String title, String body, String payload})>[];
    SystemNotifier.onShown = told.add;
    addTearDown(() => SystemNotifier.onShown = null);

    // Switched on: the system is asked (a desktop asks nothing; the test's
    // browser has granted it, test_driver/integration_test.dart).
    await app.switchOnNotifications(l.notifyReplies);
    expect(app.prefs.notifyTopics, {NotifyTopic.replies});
    await app.waitUntil(() => app.client.threads().any((t) => t.root.tx.fromAddress == me),
        what: "the wallet's thread");
    final root = app.client.threads().firstWhere((t) => t.root.tx.fromAddress == me).root.tx.id;

    // Away from the app, someone else replies to the wallet's thread.
    app.goAway();
    final text = 'Notified reply $stamp';
    final (someone, reply) = await app.someoneReplies(root, text);
    await app.waitUntil(() => told.any((n) => n.body == text),
        what: 'the notification of their reply', timeout: const Duration(minutes: 2));
    final shown = told.singleWhere((n) => n.body == text);
    expect(shown.title, l.notifyReply(shortHex(someone)));
    expect(payloadTarget(shown.payload), (root: root, txid: reply.id));

    // The system has it, where the test can read the system.
    final system = await systemNotifications();
    debugPrint(system == null ? "the system's notifications: not readable here" : 'the system shows: $system');
    final there = system?.where((n) => n.title == shown.title && n.body == text).toList();
    if (there != null) expect(there, hasLength(1));

    // Back in the app, a click on it opens the reply in its thread: from the
    // system where a test can click there, else as the app takes a click.
    app.comeBack();
    if (there == null || !await clickSystemNotification(there.single)) openNotification(shown.payload);
    await app.waitFor(find.byType(ThreadPage), what: 'the thread the notification opens');
    await app.waitFor(find.text(text), what: 'their reply in it');
    await app.backHome();

    // Told once, however many checks come after.
    final tip = app.client.height;
    await app.waitUntil(() => app.client.height > tip, what: 'a block since', timeout: const Duration(minutes: 2));
    expect(told.where((n) => n.body == text), hasLength(1));

    // And off again.
    await app.switchOnNotifications(l.notifyReplies);
    expect(app.prefs.notifyTopics, isEmpty);
    // Not where the app offers none (iOS, for now).
  }, skip: !notificationsSupported);

  testWidgets("a desktop's own node: it runs beside the app, and mines on the graphics card or says why not",
      (tester) async {
    // With the wallet the tests above left: mining pays it.
    final app = AppDriver(tester);
    await app.start();
    final l = app.l;
    final node = app.ownNode;
    final (host, port) = (app.client.host, app.client.port);

    await app.openTab(l.tabChain);
    await app.flip(l.localNodeRun);
    await app.waitUntil(() => node.state == LocalNodeState.running, what: "the app's own node to run");
    await app.waitFor(find.textContaining('127.0.0.1:${node.port}'), what: 'where the node listens');
    // The app goes on reading from the node it was given.
    expect((app.client.host, app.client.port), (host, port));

    // Mining pays the wallet here, shown in full.
    await app.flip(l.localNodeMine);
    await app.waitFor(find.text(app.wallets.wallet!.addressHex), what: 'the address mining pays');

    // The graphics card: whatever this machine has, the node says which it
    // is, and the app shows it.
    await app.flip(l.localNodeGpu);
    await app.waitUntil(() => node.gpu != null && node.gpu!.state != GpuMiningState.starting,
        what: 'the node to say whether the graphics card mines', timeout: const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 300));
    final gpu = node.gpu!;
    debugPrint('the graphics card here: $gpu');
    switch (gpu.state) {
      case GpuMiningState.mining:
        expect(app.says(gpu.device == null ? l.localNodeGpuMiningAny : l.localNodeGpuMining(gpu.device!)), isTrue);
      case GpuMiningState.unavailable:
        expect(app.says(l.localNodeGpuUnavailable), isTrue);
        expect(find.text(l.localNodeGpuDetail(gpu.reason!)), findsOneWidget);
      case GpuMiningState.starting:
        fail('still starting');
    }
    expect(node.state, LocalNodeState.running, reason: 'the node runs either way');
    expect((app.client.host, app.client.port), (host, port));

    // Switched off: the node stops, and its miner with it.
    await app.flip(l.localNodeRun);
    await app.waitUntil(() => node.state == LocalNodeState.stopped, what: "the app's own node to stop");
    expect(find.text(l.localNodeGpu), findsNothing);
  }, skip: !acceptanceOwnNode);
}
