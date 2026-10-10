// The client against the real node: the pinned murmur-node release
// (tool/node_release.dart, fetched with `dart run tool/bundle_node.dart
// --for-tests`), on demo chains the node builds itself (`murmur-node
// demo-chain`, through support/test_node.dart). Nothing to set up and
// nothing to wait for: no running node, no mining before the tests.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/alias.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/activity.dart';
import 'package:murmur_client/protocol/invite.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/invitations.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/starred.dart';
import 'package:murmur_client/services/storage.dart' show InviteRecord;

import 'support/client_checks.dart';
import 'support/memory_cache.dart';
import 'support/test_node.dart';

void main() {
  // The wallet every built block pays, so it has tokens to send.
  late final MurmurWallet miner;
  setUpAll(() async => miner = await MurmurWallet.generate());

  Future<Uint8List> someoneElse() async => (await MurmurWallet.generate()).address;

  // Long enough for two back-fill batches (2,000 headers each) below the
  // checkpoint at 2,570.
  Future<TestNode> long() async {
    final node = await TestNode.build(2600, mineTo: miner.address);
    await node.start();
    return node;
  }

  Checkpoint checkpointOf(TestNode node) => Checkpoint(2570, node.hashAt(2570));

  /// The headers a client stores from `node` (from genesis, no checkpoint).
  Future<List<BlockHeader>> headersOf(TestNode node) async {
    final cache = MemoryCache();
    final c = await node.connect(MurmurClient()..useCache(cache));
    await until(c, () => cache.headers.length == node.height);
    return cache.headers;
  }

  group('sync', () {
    test('starts from a checkpoint and checks back to genesis, keeping none of the headers below it', () async {
      final node = await long();
      final cp = checkpointOf(node);
      final cache = MemoryCache();
      final c = MurmurClient(checkpoint: cp)..useCache(cache);
      var fromCheckpoint = false;
      c.addListener(() => fromCheckpoint |= c.checkingFromCheckpoint != null);
      await node.connect(c);
      expect(c.headerAt(cp.height)!.id, cp.hash);
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(fromCheckpoint, isTrue);
      expect(c.headersFromNode, greaterThan(cp.height - 12), reason: 'every header from genesis was checked');
      // Checked, and let go: the chain is held from the checkpoint's context.
      expect(c.headerAt(1), isNull);
      expect(c.headerAt(cp.height - 12), isNull);
      expect(c.headerAt(cp.height - 11)!.id, node.hashAt(cp.height - 11));
      // The local copy holds the same, and how far the check got, batch by
      // batch, in place of the headers checked.
      await until(c, () => cache.headers.length == node.height - (cp.height - 12));
      expect(cache.headers.first.height, cp.height - 11);
      expect(cache.headers.last.id, node.hashAt(node.height));
      await until(c, () => cache.marks.length >= 2);
      expect(cache.marks.first.length, lessThan(8000), reason: 'a mark, not the headers');
      c
        ..useCache(null)
        ..disconnect();

      // The next session takes both up: nothing below the checkpoint is
      // fetched again, and the headers above it come from the copy.
      final again = await node.connect(MurmurClient(checkpoint: cp)..useCache(cache));
      await until(again, () => again.checkingFromCheckpoint == null && again.height == node.height);
      expect(again.headersFromNode, lessThan(100), reason: 'only the stored headers above the checkpoint, checked again');
      expect(again.headerAt(1), isNull);
    });

    test('older blocks than the checkpoint: their headers come by proof, a batch at a time', () async {
      final node = await long();
      final cp = checkpointOf(node);
      final c = await node.connect(MurmurClient(checkpoint: cp));
      await until(c, () => c.checkingFromCheckpoint == null);
      final wanted = cp.height - 300;
      expect(c.headerAt(wanted), isNull);
      await until(c, what: 'blocks below the checkpoint', () {
        c.requestOlder();
        return c.blockAt(wanted) != null;
      });
      expect(c.headerAt(wanted)!.id, node.hashAt(wanted));
      expect(c.oldHeadersProven, greaterThan(250));
      expect(c.headerAt(1), isNull, reason: 'only as far as was asked for');
    });

    test('a checkpoint that is not on the chain stops the client', () async {
      final node = await long();
      final c = MurmurClient(checkpoint: Checkpoint(2570, '00' * 32));
      addTearDown(c.dispose);
      await c.connect('127.0.0.1', node.port);
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (c.error == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final kind = c.error?.kind == LinkErrorKind.syncFailed ? c.error?.cause?.kind : c.error?.kind;
      expect(kind, LinkErrorKind.checkpointMismatch);
    });

    test('an interrupted back-fill resumes from the mark in the local copy', () async {
      final node = await long();
      final cp = checkpointOf(node);
      // What an interrupted back-fill leaves: the mark after its first
      // batch of 2,000 headers.
      final first = MemoryCache();
      final one = await node.connect(MurmurClient(checkpoint: cp)..useCache(first));
      await until(one, () => first.marks.isNotEmpty);
      one
        ..useCache(null)
        ..disconnect();
      final cache = MemoryCache(null, first.marks.first);
      final c = await node.connect(MurmurClient(checkpoint: cp)..useCache(cache));
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(c.headersFromNode, lessThanOrEqualTo(node.height - 2000),
          reason: 'headers 1 to 2,000 were not fetched again');
      expect(c.headerAt(cp.height)!.id, cp.hash);
    });

    test('a mark of another chain is dropped, and the back-fill starts over from genesis', () async {
      final other = await TestNode.build(500, mineTo: await someoneElse());
      await other.start();
      final theirs = MemoryCache();
      final onOther = await other.connect(MurmurClient(checkpoint: Checkpoint(400, other.hashAt(400)))..useCache(theirs));
      await until(onOther, () => theirs.marks.isNotEmpty);
      onOther
        ..useCache(null)
        ..disconnect();
      await other.stop();
      final node = await long();
      final cp = checkpointOf(node);
      final c = await node.connect(MurmurClient(checkpoint: cp)..useCache(MemoryCache(null, theirs.marks.last)));
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(c.headersFromNode, greaterThan(cp.height - 12), reason: 'checked from genesis');
      expect(c.headerAt(cp.height)!.id, cp.hash);
    });

    test('a copy kept from genesis, before a checkpoint shipped: its headers above the checkpoint are taken in', () async {
      final node = await long();
      final cp = checkpointOf(node);
      final cache = MemoryCache(await headersOf(node));
      final c = MurmurClient(checkpoint: cp)..useCache(cache);
      await node.connect(c);
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(c.height, node.height);
      expect(c.headerAt(1), isNull, reason: 'held from the checkpoint, whatever the copy holds');
      // And the copy is rewritten to hold the same.
      await until(c, () => cache.headers.first.height == cp.height - 11);
      expect(cache.headers.length, node.height - (cp.height - 12));
    });

    test('a damaged mark is no mark: the back-fill starts from genesis', () async {
      final node = await long();
      final cp = checkpointOf(node);
      final c = await node.connect(
          MurmurClient(checkpoint: cp)..useCache(MemoryCache(null, Uint8List.fromList(List.filled(300, 7)))));
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(c.headersFromNode, greaterThan(cp.height - 12));
    });

    test('a reorganization rebuilds the header history from the nearest mark', () async {
      // From genesis (the demo network has no checkpoint), past the marks
      // at 1,024 and 2,048. Ending ten minutes ago leaves the branches
      // room: demo-chain refuses a branch of n blocks without n × 2 s after
      // its fork point (120 blocks: four minutes).
      final node = await TestNode.build(2100,
          mineTo: miner.address, endTime: DateTime.now().subtract(const Duration(minutes: 10)));
      await node.start();
      final c = await node.connect(MurmurClient());
      final before = List.of(node.hashes);
      bool following(TestNode n) => c.height == n.height && toHex(c.hashAt(n.height)) == n.hashAt(n.height);
      // A heavier branch from block 2,060: the client rolls back to it,
      // rebuilds the history from the mark at 2,048, and checks every new
      // header's history root against it.
      await node.stop();
      await node.grow(2130, mineTo: await someoneElse(), forkAt: 2060);
      await node.start();
      await until(c, () => following(node), reconnecting: true);
      expect(c.headerAt(2060)!.id, before[2059]);
      expect(c.headerAt(2061)!.id, isNot(before[2060]));
      // A second one, below the newest mark: from the one before.
      await node.stop();
      await node.grow(2160, mineTo: miner.address, forkAt: 2040);
      await node.start();
      await until(c, () => following(node), reconnecting: true);
      expect(c.headerAt(2041)!.id, node.hashAt(2041));
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: nodeSkip);

  // A short chain ending now, for what doesn't need many blocks; the node
  // mines on top to the same wallet when transactions must be mined.
  Future<TestNode> short({bool mining = false, List<String> extra = const []}) async {
    final node = await TestNode.build(300, mineTo: miner.address);
    await node.start(mineTo: mining ? miner.address : null, extra: extra);
    return node;
  }

  group('state and sending', () {
    test('proves state, finds an address through filters, without the chain', () async {
      await checkProvenState((c) async => (await short()).connect(c));
    });

    test('with a local copy, a second session starts from what the first fetched and checked', () async {
      final node = await short();
      await checkLocalCopy(node.connect);
    });

    test('sends with proven nonces and gets transactions mined', () async {
      final node = await short(mining: true);
      final client = await node.connect(MurmurClient());
      final wallet = miner;
      final me = wallet.addressHex;
      await until(client, () => client.availableTo(me) != null);
      final start = client.account(me)!;
      print('wallet ${me.substring(0, 12)}… balance ${start.balance}, nonce ${start.nonce}');
      expect(start.balance, greaterThan(100 * unitsPerToken), reason: 'the built chain pays this wallet');
  
      final text = 'hello from the flutter client ${DateTime.now().toIso8601String()}';
      final orphan = await client.submit(
          wallet: wallet, kind: TxKind.orphan, fee: 2 * minFee, message: MurmurClient.encodeText(text));
      final recipient = await MurmurWallet.generate();
      final raw = await client.submit(
          wallet: wallet, kind: TxKind.raw, to: recipient.address, amount: 5 * unitsPerToken, fee: minFee);
      expect((orphan.nonce, raw.nonce), (start.nonce, start.nonce + 1), reason: 'the second follows the pending first');
      // The Threads tab's fixed view shows your own new thread at once, and
      // keeps it once mined above the snapshot.
      final snapshot = client.height;
      expect(client.threads(upTo: snapshot).first.root.tx.id, orphan.id);
      await until(client, what: 'status', () => client.statusOf(raw.id) != null);
      expect(client.statusOf(raw.id)!.code, TxStatusCode.accepted, reason: client.statusOf(raw.id)!.reason);
  
      await until(client, what: 'orphan and raw mined', () =>
          (client.lookupTx(orphan.id)?.confirmed ?? false) && (client.lookupTx(raw.id)?.confirmed ?? false));
      final mined = client.lookupTx(orphan.id)!;
      expect(String.fromCharCodes(messageOf(mined.content!)), text);
      expect(mined.height, greaterThan(snapshot));
      expect(client.threads(upTo: snapshot).any((t) => t.root.tx.id == orphan.id), isTrue);
      await until(client, what: 'recipient balance', () => (client.account(recipient.addressHex)?.balance ?? 0) == 5 * unitsPerToken);
      await until(client, what: 'nonce +2', () => (client.account(me)?.nonce ?? 0) == start.nonce + 2);
      print('orphan mined in block ${mined.height}, transfer in block ${client.lookupTx(raw.id)!.height}');
  
      // Threads: a reply chain and a flag, proven not flagged before.
      Uint8List utf(String s) => MurmurClient.encodeText(s);
      final older = await client.submit(
          wallet: wallet, kind: TxKind.orphan, fee: minFee, message: utf('older thread $text'));
      await until(client, what: 'older mined', () => client.lookupTx(older.id)?.confirmed ?? false);
      // Mined a moment ago, likely above the block the nonce proof is from:
      // the next nonce is past it all the same.
      expect(client.nextNonce(me), older.nonce + 1);
      // A reply names no recipient: the chain pays the thread's author.
      final reply = await client.submit(
          wallet: wallet, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('a reply'), reference: older.id);
      expect((reply.to, reply.referenceId), (null, older.id));
      await until(client, what: 'flag proof', () => client.provenFlagged(me, older.id) != null);
      final flag = await client.submit(wallet: wallet, kind: TxKind.flag, fee: minFee, reference: older.id);
      expect(flag.thread, isNull, reason: 'its target is the thread\'s first message');
      expect(
          () => client.submit(wallet: wallet, kind: TxKind.flag, fee: minFee, reference: older.id),
          throwsA(isA<TxProblem>().having((p) => p.kind, 'kind', TxProblemKind.alreadyFlagged)),
          reason: 'one flag per address per message');
      String txState(Transaction t) {
        final view = client.lookupTx(t.id);
        final status = client.statusOf(t.id);
        final where = view == null ? 'unknown' : (view.confirmed ? 'mined at ${view.height}' : 'pending');
        return '${t.kind.name} nonce ${t.nonce}: $where, node said ${status?.code.name} ${status?.reason ?? ''}';
      }

      await until(client, what: 'reply and flag mined', () =>
          (client.lookupTx(reply.id)?.confirmed ?? false) && (client.lookupTx(flag.id)?.confirmed ?? false),
          state: () => '${txState(reply)}; ${txState(flag)}; proven nonce ${client.account(me)?.nonce}');
      await until(client, what: 'flagged proven', () => client.provenFlagged(me, older.id) == true);
      final thread = client.threads().firstWhere((t) => t.root.tx.id == older.id);
      expect((thread.replies, thread.flags), (1, 1));
      // That flag was the author's own: a retraction. Its text is deleted here
      // and never fetched again; the reply keeps its own.
      final withdrawn = client.lookupTx(older.id)!;
      expect(client.contentWithdrawn(withdrawn.tx), isTrue);
      expect(client.liveContent(withdrawn), isNull);
      expect(client.contentExpected(withdrawn.tx), isFalse);
      expect(client.liveContent(client.lookupTx(reply.id)!), isNotNull);

      // Another device opens its Threads tab on this chain: while its blocks
      // arrive, newest first, no thread it has listed is ever moved. New
      // ones only join at the end.
      final reader = await node.connect(MurmurClient());
      final upTo = reader.height;
      var listed = <String>[];
      void check() {
        final now = [for (final t in reader.threads(upTo: upTo)) t.root.tx.id];
        expect(now.take(listed.length), listed, reason: 'a listed thread moved');
        listed = now;
        reader.requestOlder(); // as the list does while it has room
      }

      reader.addListener(check);
      check();
      await until(reader, what: 'every thread listed', () => !reader.canLoadOlder && !reader.threadsHeldBack);
      reader.removeListener(check);
      check();
      expect(listed, containsAll([orphan.id, older.id]));
      // And it ends as the list of the device that saw them being sent,
      // which got them in another order.
      expect(listed, [for (final t in client.threads(upTo: upTo)) t.root.tx.id]);

      // What that device stars is followed: the reply under the starred
      // thread, and the newest message of the starred person.
      final replied = reader.lookupTx(reply.id)!.blockTime;
      final activity = starredActivity(reader, starred: {older.id}, people: {me});
      expect(activity.messages, {older.id: replied});
      expect(activity.people, {me: replied});
    }, timeout: const Timeout(Duration(minutes: 3)));
  
    test('invitations: funded cards are claimed by a new wallet, or taken back', () async {
      final client = await (await short(mining: true)).connect(MurmurClient());
      final inviter = miner;
      await until(client, () => client.availableTo(inviter.addressHex) != null);
      final costs = invitationCosts(await client.feeInfo());
      final kept = <InviteRecord>[], codes = <String>[];
      final cards = await createInvitations(
        client: client,
        wallet: inviter,
        keep: (r, c) async {
          kept.addAll(r);
          codes.addAll(c);
        },
        count: 2,
        perCard: costs.perCard,
        fundingFee: costs.fundingFee,
      );
      expect(kept, hasLength(2), reason: 'the keys are kept before the cards are funded');
      final invites = [for (final c in codes) Invite.parse(c)!];
      final addresses = [for (final i in invites) (await cardWallet(i)).addressHex];
      expect([for (final c in cards) c.address], addresses, reason: 'each record names its card');
      await until(client, () => addresses.every((a) => (client.account(a)?.balance ?? 0) == costs.perCard));
      print('2 cards funded with ${costs.perCard} each');
  
      // A newcomer claims the first into a brand-new wallet.
      final newcomer = await MurmurWallet.generate();
      await sweepInvitation(client: client, invite: invites[0], to: newcomer.address);
      // The inviter takes back the second.
      await sweepInvitation(client: client, invite: invites[1], to: inviter.address);
      await until(client, () => (client.account(newcomer.addressHex)?.balance ?? 0) > 0);
      await until(client, () => addresses.every((a) => client.account(a)?.balance == 0));
      expect(client.account(newcomer.addressHex)!.balance, costs.perCard - costs.claimFee);
      expect(inviteState(client, cards[0]), InviteState.claimed);
      expect(inviterOf(client, addresses[0]), inviter.addressHex);
      print('claimed ${client.account(newcomer.addressHex)!.balance} into a new wallet: '
          '${costs.perCard - costs.claimFee} = five threads');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }, skip: nodeSkip);

  group('the node\'s index', () {
    Uint8List utf(String s) => MurmurClient.encodeText(s);
    bool mined(MurmurClient c, Transaction tx) => c.lookupTx(tx.id)?.confirmed ?? false;

    /// A thread by the miner's wallet with a reply and a flag by `other`
    /// (funded for it), all mined: (thread, reply, flag).
    Future<(Transaction, Transaction, Transaction)> conversation(MurmurClient c, MurmurWallet other) async {
      final me = miner.addressHex;
      await until(c, () => c.availableTo(me) != null);
      final thread = await c.submit(wallet: miner, kind: TxKind.orphan, fee: minFee, message: utf('a thread to find'));
      final fund = await c.submit(
          wallet: miner, kind: TxKind.raw, to: other.address, amount: 10 * unitsPerToken, fee: minFee);
      await until(c, what: 'thread and funding mined', () => mined(c, thread) && mined(c, fund));
      await until(c, what: 'the other wallet proven', () => (c.availableTo(other.addressHex) ?? 0) > 0);
      final reply = await c.submit(
          wallet: other, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('an answer'), reference: thread.id);
      await until(c, what: 'reply mined', () => mined(c, reply));
      await until(c, what: 'flag proof', () => c.provenFlagged(other.addressHex, thread.id) != null);
      final flag = await c.submit(wallet: other, kind: TxKind.flag, fee: minFee, reference: thread.id);
      await until(c, what: 'flag mined', () => mined(c, flag));
      return (thread, reply, flag);
    }

    test('a thread and a history older than the checkpoint are read from the index, each page proven', () async {
      final node = await short(mining: true);
      final writer = await node.connect(MurmurClient());
      final other = await MurmurWallet.generate();
      final (thread, reply, flag) = await conversation(writer, other);
      final last = writer.lookupTx(flag.id)!.height!;
      // A checkpoint well above it all: a later session starts there, with
      // no header below the eleven before it.
      await until(writer, what: 'blocks above the conversation', () => writer.height >= last + 15,
          timeout: const Duration(minutes: 2));
      final cp = Checkpoint(writer.height, toHex(writer.hashAt(writer.height)));

      final reader = MurmurClient(checkpoint: cp);
      // Asked for before connecting, so they come before the headers back
      // to genesis are checked: each needs a header below the checkpoint.
      reader.requestTx(thread.id);
      reader.watchAddress(miner.addressHex, mentions: true);
      addTearDown(reader.dispose);
      await reader.connect('127.0.0.1', node.port);
      await until(reader, what: 'the thread by id', () => mined(reader, thread));
      expect(reader.oldHeadersProven, greaterThan(0), reason: 'its header came by proof against the tip');
      final root = reader.lookupTx(thread.id)!;
      expect(root.height, lessThan(cp.height - 11));

      reader.watchThread(root, const []);
      await until(reader, what: 'the thread read whole', () => reader.threadComplete(thread.id));
      expect([for (final r in reader.repliesOf(root)) r.tx.id], [reply.id]);
      expect(reader.flagCountOf(root), 1);
      expect(reader.lookupTx(flag.id)!.height, last);

      await until(reader, what: 'the history read whole', () => !reader.historyPending(miner.addressHex));
      final history = [for (final v in reader.activityOf(miner.addressHex)) v.tx.id];
      // What the wallet sent, and the reply that credited it.
      expect(history, containsAll([thread.id, reply.id]));
      expect(history.indexOf(reply.id), lessThan(history.indexOf(thread.id)), reason: 'newest first');
      // The flag against its thread is in neither proven list: the node
      // lists it apart, and it is proven to be on the chain.
      await until(reader, what: 'the flag against its thread',
          () => reader.activityOf(miner.addressHex).any((v) => v.tx.id == flag.id));

      // A reply mined later reaches the thread without being asked for.
      final more = await writer.submit(
          wallet: other, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('one more'), reference: reply.id);
      expect(more.referenceId, thread.id, reason: 'answering a reply is answering in its thread');
      await until(reader, what: 'the new reply', () => reader.repliesOf(root).length == 2);
      await until(reader, what: 'the thread whole again', () => reader.threadComplete(thread.id));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('an answer to a reply in someone else\'s thread reaches the answered address, from the node\'s list', () async {
      final node = await short(mining: true);
      final writer = await node.connect(MurmurClient());
      final other = await MurmurWallet.generate();
      // The miner's thread, with a reply by the other wallet.
      final (thread, reply, _) = await conversation(writer, other);
      // A third wallet answers that reply: it credits the thread's author,
      // and is in no list of the answered wallet's.
      final third = await MurmurWallet.generate();
      final fund = await writer.submit(
          wallet: miner, kind: TxKind.raw, to: third.address, amount: 10 * unitsPerToken, fee: minFee);
      await until(writer, what: 'the third wallet funded',
          () => mined(writer, fund) && (writer.availableTo(third.addressHex) ?? 0) > 0);
      final answer = await writer.submit(
          wallet: third, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('to you'), reference: reply.id);
      expect(answer.bytes.first, Transaction.answerTag, reason: 'a reply to a reply is an Answer');
      expect(answer.answersHex, reply.id.substring(0, 8));
      expect(answer.referenceId, thread.id);
      // A reply to the thread's first message is a plain Reply.
      expect(reply.answers, isNull);
      await until(writer, what: 'the answer mined', () => mined(writer, answer));
      expect(writer.creditedBy(answer), miner.addressHex);
      final last = writer.lookupTx(answer.id)!.height!;
      await until(writer, what: 'blocks above the answer', () => writer.height >= last + 15,
          timeout: const Duration(minutes: 2));

      // The answered wallet, on another device, started above it all.
      final me = other.addressHex;
      final reader = MurmurClient(checkpoint: Checkpoint(writer.height, toHex(writer.hashAt(writer.height))));
      reader.watchAddress(me, mentions: true);
      await node.connect(reader);
      await until(reader, what: 'the answer, in the answered wallet\'s history',
          () => reader.activityOf(me).any((v) => v.tx.id == answer.id));
      expect(reader.blockAt(last), isNull, reason: 'from the node\'s list, not from its block');
      final view = reader.activityOf(me).firstWhere((v) => v.tx.id == answer.id);
      expect(reader.answersTo(view.tx, me), isTrue);
      expect(messageFiltersOf(view, me, reader), {MessageFilter.received});
      expect(walletFiltersOf(view, me, reader), isEmpty, reason: 'no tokens moved for the answered wallet');
      expect(reader.balanceChange(view.tx, me), 0);
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('a long thread opens with its newest replies, and reads earlier ones a page at a time', () async {
      final node = await short(mining: true);
      final writer = await node.connect(MurmurClient());
      final me = miner.addressHex;
      await until(writer, () => writer.availableTo(me) != null);
      final thread = await writer.submit(wallet: miner, kind: TxKind.orphan, fee: minFee, message: utf('a long thread'));
      await until(writer, what: 'the thread mined', () => mined(writer, thread));
      final replies = <Transaction>[];
      for (var i = 1; i <= 5; i++) {
        replies.add(await writer.submit(
            wallet: miner, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('reply $i'), reference: thread.id));
        // One block each, so their order is the chain's.
        await until(writer, what: 'reply $i mined', () => mined(writer, replies.last));
      }

      // A session that starts above them all: it knows the thread only from
      // the node's index, not from blocks it fetched.
      final last = writer.lookupTx(replies.last.id)!.height!;
      await until(writer, what: 'blocks above the replies', () => writer.height >= last + 15,
          timeout: const Duration(minutes: 2));
      final cp = Checkpoint(writer.height, toHex(writer.hashAt(writer.height)));
      final reader = MurmurClient(checkpoint: cp)..threadPage = 2;
      reader.requestTx(thread.id);
      await node.connect(reader);
      await until(reader, what: 'the thread by id', () => mined(reader, thread));
      final root = reader.lookupTx(thread.id)!;
      List<String> read() => [for (final r in reader.repliesOf(root)) r.tx.id];
      reader.watchThread(root, const []);
      await until(reader, what: 'the newest page', () => read().length == 2 && !reader.threadReading(thread.id));
      expect(read(), [replies[3].id, replies[4].id]);
      expect(reader.threadHasEarlier(thread.id), isTrue);
      expect(reader.threadComplete(thread.id), isFalse);

      // A reply mined meanwhile joins the ones at hand; nothing earlier is read for it.
      final late = await writer.submit(
          wallet: miner, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('a late one'), reference: thread.id);
      await until(reader, what: 'the new reply', () => read().contains(late.id));
      expect(read(), [replies[3].id, replies[4].id, late.id]);

      reader.readEarlier(thread.id);
      await until(reader, what: 'the page before', () => read().length == 5 && !reader.threadReading(thread.id));
      expect(read(), [for (final r in replies.skip(1)) r.id] + [late.id]);
      expect(reader.threadHasEarlier(thread.id), isTrue);
      reader.readEarlier(thread.id);
      await until(reader, what: 'the whole thread', () => reader.threadComplete(thread.id));
      expect(read(), [for (final r in replies) r.id] + [late.id]);
      expect(reader.threadHasEarlier(thread.id), isFalse);

      // The same for an address's history: its two lists are read from
      // their newest ends, and it shows as far down as both reach.
      await until(writer, what: 'the last reply mined', () => mined(writer, late));
      writer.watchAddress(me);
      await until(writer, what: 'the whole history, read at once',
          () => !writer.historyPending(me) && !writer.historyHasEarlier(me) && writer.activityOf(me).length >= 7);
      final whole = [for (final v in writer.activityOf(me)) v.tx.id];
      final paged = MurmurClient(checkpoint: cp)..historyPage = 2;
      paged.watchAddress(me);
      await node.connect(paged);
      List<String> rows() => [for (final v in paged.activityOf(me)) v.tx.id];
      await until(paged, what: 'the newest of the history', () => paged.historyHasEarlier(me) && !paged.historyPending(me));
      var steps = 0;
      while (paged.historyHasEarlier(me)) {
        // What shows is the history's newest part, in order, never a row
        // that an unread page could come before.
        final shown = rows();
        expect(shown.length, lessThan(whole.length));
        expect(shown, whole.take(shown.length).toList(), reason: 'after $steps more pages');
        paged.readEarlierHistory(me);
        await until(paged, what: 'an earlier page', () => !paged.historyPending(me));
        expect(++steps, lessThan(40));
      }
      expect(rows(), whole);
      expect(steps, greaterThan(2));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('a node without the index: the same thread and history, through filters', () async {
      final node = await short(mining: true, extra: ['--no-index']);
      final writer = await node.connect(MurmurClient());
      final other = await MurmurWallet.generate();
      final (thread, reply, _) = await conversation(writer, other);

      final reader = await node.connect(MurmurClient());
      reader.watchAddress(miner.addressHex);
      await until(reader, what: 'the history through filters', () => !reader.historyPending(miner.addressHex));
      final history = [for (final v in reader.activityOf(miner.addressHex)) v.tx.id];
      expect(history, containsAll([thread.id, reply.id]));
      final root = reader.lookupTx(thread.id)!;
      reader.watchThread(root, const []);
      await until(reader, what: 'the reply through filters', () => reader.repliesOf(root).length == 1);
      expect(reader.threadComplete(thread.id), isFalse, reason: 'nothing here says the list is whole but the scan');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('a public name is proven from the state, and a new one replaces it', () async {
      final node = await short(mining: true);
      final c = await node.connect(MurmurClient());
      final me = miner.addressHex;
      await until(c, () => c.availableTo(me) != null);
      expect(c.publishedAlias(me), isNull);
      final first = await c.submit(wallet: miner, kind: TxKind.name, fee: minFee, message: aliasMessage('bob'));
      expect(first.amount, orphanBurn(minFee), reason: 'a name costs what a thread costs');
      await until(c, what: 'the name', () => c.publishedAlias(me) == 'bob');
      // Another device learns it without any of the wallet's history.
      final reader = await node.connect(MurmurClient());
      await until(reader, what: 'the name elsewhere', () => reader.publishedAlias(me) == 'bob');
      // Never a thread, though the chain keeps it as one so it can be flagged.
      expect(c.threads().any((t) => t.root.tx.id == first.id), isFalse);

      await c.submit(wallet: miner, kind: TxKind.name, fee: minFee, message: aliasMessage('robert'));
      await until(c, what: 'the new name', () => c.publishedAlias(me) == 'robert');
      await c.submit(wallet: miner, kind: TxKind.name, fee: minFee, message: aliasMessage(''));
      await until(c, what: 'the name cleared', () => c.publishedAlias(me) == null && c.pendingDebitOf(me) == 0,
          timeout: const Duration(minutes: 2));
    }, timeout: const Timeout(Duration(minutes: 4)));
  }, skip: nodeSkip);
}
