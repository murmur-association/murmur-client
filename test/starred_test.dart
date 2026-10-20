// What the user starred (lib/services/starred.dart, lib/ui/starred_tab.dart):
// threads, messages and people, listed in the Starred tab, with a mark on
// the tab and on the row when one has activity not seen yet.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/starred.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/address_page.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/home_page.dart';
import 'package:murmur_client/ui/starred_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/messages.dart';

final _dave = person(4);
final _eve = person(5);

/// The block time `txAt` gives height `h`.
int _time(int h) => 1790208000 + h * 2;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('activity', () {
    test('replies in a starred thread are its activity; own, muted, withdrawn and pending are not', () {
      final root = txAt(TxKind.orphan, 10, text: 'a thread');
      final first = replyTo(root, 20);
      final nested = replyTo(first, 30, from: carol);
      final mine = replyTo(root, 40, from: _dave);
      final muted = replyTo(root, 50, from: _eve);
      final withdrawn = replyTo(root, 60);
      final pending = replyTo(root, null, from: carol);
      final other = txAt(TxKind.orphan, 70, text: 'another thread, not starred');
      final chain = FakeChain([
        root, first, nested, mine, muted, withdrawn, //
        txAt(TxKind.flag, 61, from: bob, reference: withdrawn), other, replyTo(other, 80), pending,
      ]);
      final missing = 'ab' * 32;
      final activity = starredActivity(chain,
          starred: {root.tx.id, first.tx.id, missing}, people: const {}, me: toHex(_dave), muted: {toHex(_eve)});

      // A starred reply has no replies of its own: threads are flat.
      expect(activity.messages, {root.tx.id: _time(30)});
      expect(activity.people, isEmpty);
      // Followed: the thread's blocks are looked for, and what isn't known
      // is asked of the node.
      expect(chain.watchedThreads, {root.tx.id});
      expect(chain.requested, {missing});

      // Without a wallet or mutes, those two replies count like any other.
      final all = starredActivity(chain, starred: {root.tx.id}, people: const {});
      expect(all.messages, {root.tx.id: _time(50)});
    });

    test('a starred person\'s newest text message is their activity', () {
      final root = txAt(TxKind.orphan, 10, text: 'a thread');
      final chain = FakeChain([
        root,
        replyTo(root, 20), // bob
        txAt(TxKind.orphan, 30, text: 'bob\'s own thread', from: bob),
        txAt(TxKind.orphan, 40, text: '\u0000alias:bob', from: bob), // not text: a public name
        txAt(TxKind.raw, 50, from: bob, to: carol), // a transfer says nothing
        txAt(TxKind.orphan, 60, text: 'from the wallet here', from: _dave),
        txAt(TxKind.orphan, 70, text: 'from someone muted', from: _eve),
      ]);
      final people = {toHex(bob), toHex(carol), toHex(_dave), toHex(_eve)};
      final activity =
          starredActivity(chain, starred: const {}, people: people, me: toHex(_dave), muted: {toHex(_eve)});
      expect(activity.people, {toHex(bob): _time(30)});
      expect(chain.watchedAddresses, people, reason: 'each is followed, so their messages are found');
    });

    test('what is new is what came after what was seen', () {
      const activity = StarredActivity(messages: {'thread': 100, 'message': 300}, people: {'bob': 200});
      expect(activity.newest, 300);
      expect(activity.newSince(0), {'thread', 'message', 'bob'});
      expect(activity.newSince(200), {'message'});
      expect(activity.newSince(300), isEmpty);
      expect(const StarredActivity().newest, isNull);
    });

    test('starred people and what was seen are kept on the device', () async {
      final prefs = Preferences();
      await prefs.setStarredPerson('aa' * 32, true);
      await prefs.setStarredPerson('bb' * 32, true);
      await prefs.setStarredPerson('aa' * 32, false);
      await prefs.setStarredSeen(200);
      await prefs.setStarredSeen(100); // never back
      final again = Preferences();
      await again.load();
      expect(again.starredPeople, {'bb' * 32});
      expect(again.starredSeen, 200);
    });
  });

  group('the tab', () {
    Future<void> pumpHome(WidgetTester tester, FakeChain chain, Preferences prefs) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(AppScope(
        client: chain,
        wallets: WalletController(),
        prefs: prefs,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: lightTheme,
          navigatorObservers: [routeObserver],
          home: const HomePage(),
        ),
      ));
      await tester.pump();
    }

    /// The Starred tab's badge saying `n` starred things have news.
    Finder badge(AppLocalizations l, int n) =>
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l.starredNew(n));

    /// Whether each of the Starred tab's lists (threads, people) has its dot.
    List<bool> listDots(WidgetTester tester) => tester
        .widgetList<Badge>(find.descendant(of: find.byType(Tab), matching: find.byType(Badge)))
        .map((b) => b.isLabelVisible)
        .toList();

    /// The pages tick and spin, so nothing ever settles: a few frames do.
    Future<void> frames(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('new activity marks the tab until seen, and the rows until opened', (tester) async {
      final root = txAt(TxKind.orphan, 10, text: 'a starred thread');
      final chain = FakeChain([root, replyTo(root, 20)]);
      // Read up to then.
      final prefs = Preferences()..unreadFrom = _time(25);
      await prefs.setStarred(root.tx.id, true);
      await prefs.setStarredPerson(toHex(bob), true);
      await prefs.setStarredSeen(_time(25));
      await pumpHome(tester, chain, prefs);
      final l = tester.element(find.byType(HomePage)).l10n;
      // Nothing since it was last seen.
      expect(find.byType(Badge), findsWidgets);
      for (final n in [1, 2]) {
        expect(badge(l, n), findsNothing);
      }

      // A reply in the starred thread, then a thread by the starred person.
      chain.add([replyTo(root, 30, from: carol)]);
      await tester.pump();
      expect(badge(l, 1), findsWidgets);
      chain.add([txAt(TxKind.orphan, 40, text: 'bob writes again', from: bob)]);
      await tester.pump();
      expect(badge(l, 2), findsWidgets);
      expect(prefs.starredSeen, _time(25), reason: 'not seen while another tab is open');

      // Opening the tab: the threads' list, its row marked, and a dot on the
      // people's list; the tab's badge clears.
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);
      expect(find.text(l.starredPeople), findsOneWidget);
      expect(find.text(l.starredThreads), findsOneWidget);
      expect(find.text('a starred thread'), findsOneWidget);
      expect(find.textContaining('bob writes again'), findsNothing, reason: 'people have a list of their own');
      expect(find.byTooltip(l.newActivity), findsOneWidget);
      expect(listDots(tester), [true, true]);
      expect(badge(l, 2), findsNothing);
      expect(prefs.starredSeen, _time(40));

      // The people's list, its row marked too.
      await tester.tap(find.text(l.starredPeople));
      await frames(tester);
      expect(find.text('a starred thread'), findsNothing);
      expect(find.textContaining('bob writes again'), findsOneWidget);
      expect(find.byTooltip(l.newActivity), findsOneWidget);

      // Seen, not opened: still marked at the next visit, though the badge
      // stays clear.
      await tester.tap(find.text(l.tabThreads));
      await frames(tester);
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);
      expect(listDots(tester), [true, true]);
      expect(badge(l, 2), findsNothing);

      // Opened: the row is read, and its list's dot goes; the other stays.
      await tester.tap(find.text(l.starredThreads));
      await frames(tester);
      await tester.tap(find.text('a starred thread'));
      await frames(tester);
      expect(prefs.opened[root.tx.id], _time(30));
      await tester.pageBack();
      await frames(tester);
      expect(find.byTooltip(l.newActivity), findsNothing);
      expect(listDots(tester), [false, true]);

      // Something newer marks it again, and the tab.
      await tester.tap(find.text(l.tabThreads));
      await frames(tester);
      chain.add([replyTo(root, 50, from: carol)]);
      await tester.pump();
      expect(badge(l, 1), findsWidgets);
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);
      expect(find.byTooltip(l.newActivity), findsOneWidget);
      expect(listDots(tester), [true, true]);

      await tester.pumpWidget(const SizedBox()); // stops the pages' timers
    });

    testWidgets('an open tab sees only while the app is in front: away, its news is left to notifications',
        (tester) async {
      final root = txAt(TxKind.orphan, 10, text: 'a starred thread');
      final chain = FakeChain([root, replyTo(root, 20)]);
      final prefs = Preferences()..unreadFrom = _time(15);
      await prefs.setStarred(root.tx.id, true);
      await prefs.setStarredSeen(_time(20));
      await pumpHome(tester, chain, prefs);
      final l = tester.element(find.byType(HomePage)).l10n;
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);

      // Another window takes the focus; a reply comes.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      chain.add([replyTo(root, 30, from: carol)]);
      await frames(tester);
      expect(prefs.starredSeen, _time(20), reason: 'nobody was looking');

      // Back in front, the open tab shows it: seen.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester);
      expect(prefs.starredSeen, _time(30));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a first star starts from now: what is already there is not new', (tester) async {
      final root = txAt(TxKind.orphan, 10, text: 'a thread with history');
      final chain = FakeChain([root, replyTo(root, 20)]);
      final prefs = Preferences();
      await pumpHome(tester, chain, prefs);
      final l = tester.element(find.byType(HomePage)).l10n;
      expect(prefs.starredSeen, isNull, reason: 'nothing starred, nothing to see');

      await prefs.setStarred(root.tx.id, true);
      await frames(tester);
      expect(prefs.starredSeen, greaterThan(_time(20)));
      expect(badge(l, 1), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('lists people and threads, opens them, and a removed star keeps its row', (tester) async {
      final root = txAt(TxKind.orphan, 10, text: 'a starred thread');
      final chain = FakeChain([root]);
      final prefs = Preferences();
      await pumpHome(tester, chain, prefs);
      final l = tester.element(find.byType(HomePage)).l10n;
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);
      expect(find.text(l.noStarred), findsOneWidget);

      // Starred elsewhere; the list is taken when the tab comes into view.
      await prefs.setStarred(root.tx.id, true);
      await prefs.setStarred('ab' * 32, true); // something the node can't give (offline here)
      await prefs.setStarredPerson(toHex(carol), true);
      await tester.tap(find.text(l.tabThreads));
      await frames(tester);
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);
      expect(find.text('a starred thread'), findsOneWidget);
      expect(find.text(l.starredGone), findsOneWidget);
      expect(find.byTooltip(l.newActivity), findsNothing);
      expect(find.text(shortHex(toHex(carol))), findsNothing, reason: 'people have a list of their own');

      // Unstarring the person leaves the row, to star again.
      await tester.tap(find.text(l.starredPeople));
      await frames(tester);
      final person = find.ancestor(of: find.text(shortHex(toHex(carol))), matching: find.byType(ListTile));
      await tester.tap(find.descendant(of: person, matching: find.byTooltip(l.unstar)));
      await tester.pump();
      expect(prefs.starredPeople, isEmpty);
      expect(find.descendant(of: person, matching: find.byTooltip(l.star)), findsOneWidget);

      // The row opens the person's page, where the star is given back.
      await tester.tap(person);
      await frames(tester);
      final page = find.byType(AddressPage);
      expect(tester.widget<AddressPage>(page).address, toHex(carol));
      await tester.tap(find.descendant(of: page, matching: find.byTooltip(l.star)));
      await tester.pump();
      expect(prefs.starredPeople, {toHex(carol)});

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with only people starred, their list opens, and the other says how to star', (tester) async {
      final prefs = Preferences();
      await prefs.setStarredPerson(toHex(carol), true);
      await pumpHome(tester, FakeChain(), prefs);
      final l = tester.element(find.byType(HomePage)).l10n;
      await tester.tap(find.text(l.starredTitle));
      await frames(tester);
      expect(find.text(shortHex(toHex(carol))), findsOneWidget);

      await tester.tap(find.text(l.starredThreads));
      await frames(tester);
      expect(find.text(l.noStarredThreads), findsOneWidget);
      expect(find.text(shortHex(toHex(carol))), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('one\'s own address has no star', (tester) async {
      final prefs = Preferences();
      await tester.pumpWidget(AppScope(
        client: FakeChain(),
        wallets: WalletController()..wallet = WalletId(alice, Uint8List(32)),
        prefs: prefs,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddressPage(address: toHex(alice)),
        ),
      ));
      await tester.pump();
      expect(find.byType(StarButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the tab alone, with nothing starred, says how to star', (tester) async {
      await tester.pumpWidget(AppScope(
        client: FakeChain(),
        wallets: WalletController(),
        prefs: Preferences(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StarredTab()),
        ),
      ));
      final l = tester.element(find.byType(StarredTab)).l10n;
      expect(find.text(l.noStarred), findsOneWidget);
    });
  });
}
