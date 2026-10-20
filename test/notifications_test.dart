// Notifications of news (lib/services/news.dart, lib/ui/notifications.dart):
// what counts as news, what's told and only once, and the settings that
// switch each topic on.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart' show WalletId;
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/news.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/messages.dart';
import 'support/notifier.dart';

/// The block time `txAt` gives height `h`.
int _time(int h) => 1790208000 + h * 2;

final _me = toHex(alice);

/// A chain that lists an address's history from what it was given: what
/// it sent, what credits it, and what mentions it.
class _History extends FakeChain {
  _History(super.oldestFirst) : _views = [...oldestFirst];

  final List<TxView> _views;

  @override
  void add(List<TxView> more) {
    _views.addAll(more);
    super.add(more);
  }

  @override
  Iterable<TxView> activityOf(String address) => _views.reversed.where((v) =>
      v.tx.fromAddress == address || creditedBy(v.tx) == address || mentions(v.tx, address));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  final l = lookupAppLocalizations(const Locale('en'));

  group('what is news', () {
    test('replies in the wallet\'s threads and mentions of it; not its own, muted, or seen', () {
      final thread = txAt(TxKind.orphan, 10, text: 'my thread');
      final seen = replyTo(thread, 20, text: 'seen already');
      final reply = replyTo(thread, 30, text: 'a reply');
      final own = replyTo(thread, 31, from: alice, text: 'my own');
      final muted = replyTo(thread, 32, from: carol, text: 'muted');
      final other = txAt(TxKind.orphan, 33, from: bob, text: 'bob\'s thread');
      final unrelated = replyTo(other, 34, from: carol, text: 'not for me');
      final mention = replyTo(other, 35, from: carol, text: 'hi @alice', mentions: [alice]);
      final chain = _History([thread, seen, reply, own, muted, other, unrelated, mention]);

      final news = newsSince(chain,
          topics: NotifyTopic.values.toSet(), me: _me, walletSince: _time(20), muted: {toHex(carol)});
      // Carol is muted: her mention is left out too.
      expect([for (final n in news) n.txid], [reply.tx.id]);
      expect(news.single.kind, NewsKind.reply);

      final all = newsSince(chain, topics: NotifyTopic.values.toSet(), me: _me, walletSince: _time(20));
      expect({for (final n in all) n.txid: n.kind}, {
        mention.tx.id: NewsKind.mention,
        muted.tx.id: NewsKind.reply,
        reply.tx.id: NewsKind.reply,
      });
      expect([for (final n in all) n.time], [_time(35), _time(32), _time(30)], reason: 'newest first');

      // Each topic alone.
      expect([for (final n in newsSince(chain, topics: {NotifyTopic.mentions}, me: _me, walletSince: _time(20))) n.txid],
          [mention.tx.id]);
      expect(newsSince(chain, topics: {NotifyTopic.starred}, me: _me, walletSince: _time(20)), isEmpty);
    });

    test('activity on what is starred, each message once', () {
      final mine = txAt(TxKind.orphan, 10, text: 'my thread');
      final theirs = txAt(TxKind.orphan, 11, from: carol, text: 'carol\'s thread');
      final inMine = replyTo(mine, 20, text: 'in my starred thread');
      final inTheirs = replyTo(theirs, 21, text: 'in carol\'s starred thread');
      final byBob = txAt(TxKind.orphan, 22, from: bob, text: 'bob writes');
      final chain = _History([mine, theirs, inMine, inTheirs, byBob]);

      final news = newsSince(chain,
          topics: NotifyTopic.values.toSet(),
          me: _me,
          starred: {mine.tx.id, theirs.tx.id},
          people: {toHex(bob)},
          walletSince: _time(15),
          starredSince: _time(15));
      // A reply in the wallet's own thread is the wallet's news, starred or not.
      expect({for (final n in news) n.txid: (n.kind, n.starred)}, {
        inMine.tx.id: (NewsKind.reply, null),
        inTheirs.tx.id: (NewsKind.starredThread, theirs.tx.id),
        byBob.tx.id: (NewsKind.starredPerson, toHex(bob)),
      });
      // Later on, only what's newer: Bob's thread, not the reply before it.
      final later = newsSince(chain,
          topics: {NotifyTopic.starred}, starred: {theirs.tx.id}, people: {toHex(bob)}, starredSince: _time(21));
      expect([for (final n in later) n.txid], [byBob.tx.id]);
    });
  });

  group('telling', () {
    late TxView thread;
    late _History chain;
    late Preferences prefs;
    late RecordingNotifier notifier;
    late NewsNotifications news;

    setUp(() async {
      thread = txAt(TxKind.orphan, 10, text: 'my thread');
      chain = _History([thread]);
      prefs = Preferences();
      await prefs.setNotifyTopics(NotifyTopic.values.toSet());
      // Switched on long before these blocks' times.
      prefs.notifiedUntil = _time(1) - NewsNotifications.slack;
      notifier = RecordingNotifier();
      news = NewsNotifications(client: chain, prefs: prefs, notifier: notifier, me: () => _me);
    });

    test('tells of each message once, with who, what and where', () async {
      final reply = replyTo(thread, 20, text: 'Hello there\nsecond line');
      chain.add([reply]);
      expect(await news.check(l), 1);
      final shown = notifier.shown.single;
      expect(shown.title, l.notifyReply(shortHex(toHex(bob))));
      expect(shown.body, 'Hello there');
      expect(shown.id, notificationId(reply.tx.id));
      expect(payloadTarget(shown.payload), (root: thread.tx.id, txid: reply.tx.id));
      expect(prefs.notifiedIds, [reply.tx.id]);
      expect(prefs.notifiedUntil, _time(20));

      // Told already.
      expect(await news.check(l), 0);
      expect(notifier.shown, hasLength(1));

      // A name given here is used.
      await prefs.setAlias(toHex(bob), 'Bob');
      chain.add([replyTo(thread, 21)]);
      await news.check(l);
      expect(notifier.shown.last.title, l.notifyReply('Bob'));
    });

    test('while the user looks at the app, news is only recorded', () async {
      final reply = replyTo(thread, 20);
      chain.add([reply]);
      expect(await news.check(l, show: false), 0);
      expect(notifier.shown, isEmpty);
      expect(prefs.notifiedIds, [reply.tx.id]);
      expect(await news.check(l), 0, reason: 'not told later either');
    });

    test('at most a few at once, then how many more', () async {
      chain.add([for (var h = 20; h < 28; h++) replyTo(thread, h, text: 'reply $h')]);
      expect(await news.check(l), NewsNotifications.maxShown);
      expect(notifier.shown, hasLength(NewsNotifications.maxShown + 1));
      expect(notifier.shown.first.body, 'reply 27', reason: 'newest first');
      expect(notifier.shown.last.id, NewsNotifications.moreId);
      expect(notifier.shown.last.body, l.notifyMore(3));
      expect(prefs.notifiedIds, hasLength(8), reason: 'the others are counted as told');
    });

    test('nothing that was withdrawn, seen in the app, or with every topic off', () async {
      final withdrawn = replyTo(thread, 20);
      chain.add([withdrawn, txAt(TxKind.flag, 21, from: bob, reference: withdrawn)]);
      expect(await news.check(l), 0);

      await prefs.setMessagesSeen(_me, _time(30));
      chain.add([replyTo(thread, 30)]);
      expect(await news.check(l), 0, reason: 'seen in the Messages tab');

      await prefs.setNotifyTopics({});
      chain.add([replyTo(thread, 40)]);
      expect(await news.check(l), 0);
      expect(notifier.shown, isEmpty);
    });

    testWidgets('the app tells only while it is not in front', (tester) async {
      final watcher = NewsWatcher(news)..start();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      // In front: recorded, not told.
      final first = replyTo(thread, 20, text: 'while looking');
      chain.add([first]);
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(notifier.shown, isEmpty);
      await tester.pump(const Duration(seconds: 3));
      expect(prefs.notifiedIds, contains(first.tx.id));

      // Away: told.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      chain.add([replyTo(thread, 21, text: 'while away')]);
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(seconds: 3));
      expect([for (final s in notifier.shown) s.body], ['while away']);
      watcher.stop();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    test('a system that refuses shows nothing, and the app goes on', () async {
      notifier.refuse = true;
      final reply = replyTo(thread, 20);
      chain.add([reply]);
      expect(await news.check(l), 0);
      expect(notifier.shown, isEmpty);
      expect(prefs.notifiedIds, [reply.tx.id], reason: 'not asked again at every check');
    });

    test('a block older than the last one told is still looked at', () async {
      chain.add([replyTo(thread, 40)]);
      await news.check(l);
      // Its time is before the last told, within the slack.
      chain.add([replyTo(thread, 39, text: 'late')]);
      expect(await news.check(l), 1);
      expect(notifier.shown.last.body, 'late');
    });
  });

  group('settings', () {
    test('switching notifications on starts from now, and what was told is kept', () async {
      final prefs = Preferences();
      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setNotifyTopics({NotifyTopic.replies});
      expect(prefs.notifiedUntil, greaterThanOrEqualTo(before));
      final from = prefs.notifiedUntil!;
      await prefs.setNotifyTopics({NotifyTopic.replies, NotifyTopic.starred});
      expect(prefs.notifiedUntil, from, reason: 'only the first topic sets it');

      await prefs.setNotified(['aa' * 32, 'bb' * 32], from + 10);
      await prefs.setNotified(['aa' * 32], from + 5); // never back
      final again = Preferences();
      await again.load();
      expect(again.notifyTopics, {NotifyTopic.replies, NotifyTopic.starred});
      expect(again.notifiedUntil, from + 10);
      expect(again.notifiedIds, ['bb' * 32, 'aa' * 32]);
    });

    test('only the latest told are kept', () async {
      final prefs = Preferences();
      await prefs.setNotified([for (var i = 0; i < Preferences.maxNotifiedIds + 10; i++) '$i'], 1);
      expect(prefs.notifiedIds, hasLength(Preferences.maxNotifiedIds));
      expect(prefs.notifiedIds.first, '10');
    });

    test('payloads name a thread and a message', () {
      final root = 'ab' * 32, txid = 'cd' * 32;
      expect(payloadTarget(notificationPayload(root, txid)), (root: root, txid: txid));
      expect(payloadTarget(''), isNull);
      expect(payloadTarget('/thread/$root'), isNull);
      expect(notificationId(txid), notificationId(txid));
      expect(notificationId(txid), isNot(NewsNotifications.moreId));
    });

    Future<void> pumpSettings(WidgetTester tester, Preferences prefs, RecordingNotifier notifier, {bool wallet = true}) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(AppScope(
        client: FakeChain(),
        wallets: WalletController()..wallet = wallet ? WalletId(alice, Uint8List(32)) : null,
        prefs: prefs,
        notifier: notifier,
        child: MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: NotificationsButton())),
        ),
      ));
      await tester.tap(find.byTooltip(l.notifications));
      await tester.pumpAndSettle();
    }

    testWidgets('the first topic asks the system; a refusal leaves it off and says so', (tester) async {
      final prefs = Preferences();
      final notifier = RecordingNotifier(grant: false);
      await pumpSettings(tester, prefs, notifier);
      expect(find.text(l.notifyPointLocal.replaceAll('**', '')), findsOneWidget);

      await tester.tap(find.text(l.notifyReplies));
      await tester.pumpAndSettle();
      expect(notifier.asked, 1);
      expect(prefs.notifyTopics, isEmpty);
      expect(find.text(l.notifyDenied), findsOneWidget);

      notifier.grant = true;
      await tester.tap(find.text(l.notifyReplies));
      await tester.pumpAndSettle();
      expect(prefs.notifyTopics, {NotifyTopic.replies});
      expect(find.text(l.notifyDenied), findsNothing);

      // Asked once: the next topics are switched on and off freely.
      await tester.tap(find.text(l.notifyStarred));
      await tester.tap(find.text(l.notifyReplies));
      await tester.pumpAndSettle();
      expect(notifier.asked, 2);
      expect(prefs.notifyTopics, {NotifyTopic.starred});
    });

    testWidgets('without a wallet, only what is starred can be switched on', (tester) async {
      final prefs = Preferences();
      await pumpSettings(tester, prefs, RecordingNotifier(), wallet: false);
      expect(find.text(l.notifyNeedsWallet), findsNWidgets(2));
      await tester.tap(find.text(l.notifyReplies));
      await tester.tap(find.text(l.notifyStarred));
      await tester.pumpAndSettle();
      expect(prefs.notifyTopics, {NotifyTopic.starred});
    });

    testWidgets('no button where the platform has no notifications', (tester) async {
      await tester.pumpWidget(AppScope(
        client: FakeChain(),
        wallets: WalletController(),
        prefs: Preferences(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NotificationsButton()),
        ),
      ));
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
