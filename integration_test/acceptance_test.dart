// What a user does with the app, start to finish, inside the built app and
// against a real node on a demo chain: the same test on every flavour (a
// browser, Android, Windows, Linux). Run it through its runner, which
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
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/invitations_page.dart';
import 'package:murmur_client/ui/thread_page.dart';
import 'package:murmur_client/ui/threads_tab.dart';

import 'support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Told apart from any other run's on the same chain.
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final threadText = 'Acceptance thread $stamp';
  final replyText = 'Acceptance reply $stamp';

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
    await app.tapText(l.newThread);
    await app.writeAndSend(threadText);
    await app.waitFor(find.byType(ThreadPage), what: "the new thread's page");
    expect(find.text(threadText), findsWidgets);

    // Once mined it can be replied to; the reply shows under it.
    await app.press<TextButton>(l.actionReply);
    await app.writeAndSend(replyText);
    await app.waitFor(find.text(replyText), what: 'the reply in its thread');
    expect(find.text(threadText), findsWidgets);

    // The Threads tab lists it, with its reply counted once that's mined.
    await app.backHome();
    await app.waitFor(find.byType(ThreadsTab), what: 'the home page again');
    await app.waitFor(find.descendant(of: find.byType(ThreadsTab), matching: find.text(threadText)),
        what: 'the thread in the list');
    await app.waitUntil(() => app.client.threads().any((t) => t.root.tx.fromAddress == me && t.replies == 1),
        what: 'the reply to be mined and counted');

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
    // passphrase, or the wallet's own passkey, not a second one.
    final wallet = (await WalletController.storedVault())!, cards = (await InviteStore.storedVault())!;
    expect(wallet['protection'], acceptancePasskey ? 'passkey' : 'passphrase');
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
