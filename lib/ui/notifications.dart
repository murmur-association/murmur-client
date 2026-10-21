// Notifications of news (services/news.dart): replies and answers to the
// wallet, mentions of it, and activity on what's starred, each topic
// switched on by the user. The app raises them itself, from what it fetched
// and proved from the node the user chose; no push service is involved
// (AGENTS.md rule 2).
//
// - While the app runs, `NewsWatcher` tells of news when the app isn't in
//   front (another window, a hidden tab, a phone's home screen), and records
//   as told what arrives while it is: the badges show that.
// - On Android, a background job checks about every 15 minutes while the
//   app is closed (notifications_background_io.dart).

import 'dart:async';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/news.dart';
import '../services/node_client.dart';
import '../services/notifier.dart';
import '../services/starred.dart';
import '../services/storage.dart';
import 'common.dart';
import 'glyphs.dart';
import 'notifications_background.dart';
import 'people.dart';
import 'thread_page.dart';

/// What a background check for news writes to the log as it starts: the
/// acceptance tests look for it after asking Android to run the job.
const backgroundCheckLog = 'murmur: background news check';

/// The app's navigator, so a tapped notification can open its thread.
final appNavigator = GlobalKey<NavigatorState>();

/// The app's strings in the language chosen here, else the system's (else
/// English): for text raised away from the widgets.
AppLocalizations localizationsFor(Locale? chosen) {
  final want = chosen ?? PlatformDispatcher.instance.locale;
  final match = AppLocalizations.supportedLocales.where((s) => s.languageCode == want.languageCode).firstOrNull;
  return lookupAppLocalizations(match ?? const Locale('en'));
}

/// What a notification opens: a message in its thread.
String notificationPayload(String root, String txid) => '/thread/$root/$txid';

/// The thread and message a payload names, or null.
({String root, String txid})? payloadTarget(String payload) {
  final m = RegExp(r'^/thread/([0-9a-f]{64})/([0-9a-f]{64})$').firstMatch(payload);
  return m == null ? null : (root: m.group(1)!, txid: m.group(2)!);
}

/// Opens what a tapped notification tells of.
void openNotification(String payload) {
  final target = payloadTarget(payload);
  final navigator = appNavigator.currentState;
  if (target == null || navigator == null) return;
  navigator.push(MaterialPageRoute(
    builder: (_) =>
        ThreadPage(rootTxid: target.root, focusTxid: target.txid == target.root ? null : target.txid),
  ));
}

/// A notification's id: the same for the same message, so a message told
/// twice (by the app and by a background check) shows once.
int notificationId(String txid) => int.parse(txid.substring(0, 7), radix: 16) | 1;

/// Finds news not told yet, and tells of it.
class NewsNotifications {
  NewsNotifications({required this.client, required this.prefs, required this.notifier, required this.me});

  final MurmurClient client;
  final Preferences prefs;
  final Notifier notifier;

  /// The wallet's address, if there's a wallet.
  final String? Function() me;

  /// How far before [Preferences.notifiedUntil] messages are still looked
  /// at: a block's time may be earlier than the block's before it.
  static const slack = 2 * 60 * 60;

  /// At most this many notifications at once; one more says how many others.
  static const maxShown = 5;

  /// The id of the notification that counts the others.
  static const moreId = 0;

  /// Asks the client to follow what news comes from: the wallet's lists
  /// (what it's sent, and the answers and mentions others sent it), and
  /// what's starred.
  void follow() {
    final topics = prefs.notifyTopics;
    final address = me();
    if (address != null && (topics.contains(NotifyTopic.replies) || topics.contains(NotifyTopic.mentions))) {
      client.watchAddress(address, mentions: true);
    }
    if (topics.contains(NotifyTopic.starred)) {
      for (final _ in starredMessages(client,
          starred: prefs.starred, people: prefs.starredPeople, me: address, muted: prefs.muted)) {}
    }
  }

  /// Tells of the news not told yet. With `show` off, only records it as
  /// told: the user is looking at the app, whose badges show it. Returns how
  /// many notifications were shown.
  Future<int> check(AppLocalizations l, {bool show = true}) async {
    final topics = prefs.notifyTopics;
    if (topics.isEmpty) return 0;
    final address = me();
    final from = (prefs.notifiedUntil ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) - slack;
    final told = prefs.notifiedIds.toSet();
    final news = newsSince(
      client,
      topics: topics,
      me: address,
      walletSince: max(from, address == null ? 0 : prefs.messagesSeen[address] ?? 0),
      starredSince: max(from, prefs.starredSeen ?? 0),
      starred: prefs.starred,
      people: prefs.starredPeople,
      muted: prefs.muted,
    ).where((n) => !told.contains(n.txid) && !client.selfFlagged(n.view) && !client.isNonText(n.view)).toList();
    // Once everything asked for is read, what's older than the tip is
    // considered, news or not.
    final tip = client.settled ? client.headerAt(client.height)?.timestamp : null;
    final until = max(news.isEmpty ? 0 : news.first.time, tip ?? 0);
    if (news.isEmpty) {
      if (until > (prefs.notifiedUntil ?? 0)) await prefs.setNotified(const [], until);
      return 0;
    }
    var shown = 0;
    if (show) {
      for (final n in news.take(maxShown)) {
        if (await _tried(() => _show(l, n))) shown++;
      }
      if (news.length > maxShown) {
        await _tried(() => notifier.show(
              id: moreId,
              title: l.appTitle,
              body: l.notifyMore(news.length - maxShown),
              payload: '',
              channel: l.notifyChannel,
            ));
      }
    }
    // Told, shown or not: a system that refused once isn't asked again for
    // the same news at every check.
    await prefs.setNotified([for (final n in news) n.txid], until);
    return shown;
  }

  /// Whether the system took the notification `show` gives it. A system
  /// may refuse (notifications switched off for the app, no desktop to show
  /// them on): the app goes on all the same.
  static Future<bool> _tried(Future<void> Function() show) async {
    try {
      await show();
      return true;
    } catch (e) {
      debugPrint('the system refused a notification: $e');
      return false;
    }
  }

  Future<void> _show(AppLocalizations l, News n) {
    final name = nameFor(prefs, client, n.from);
    final title = switch (n.kind) {
      NewsKind.reply => l.notifyReply(name),
      NewsKind.answer => l.notifyAnswer(name),
      NewsKind.mention => l.notifyMention(name),
      NewsKind.starredThread => l.notifyStarredReply(name),
      NewsKind.starredPerson => l.notifyStarredPerson(name),
    };
    final text = messageTextIn(l, client.liveContent(n.view), reply: n.view.tx.kind == TxKind.reply);
    final root = client.threadRootOf(n.view)?.tx.id ?? n.txid;
    return notifier.show(
      id: notificationId(n.txid),
      title: title,
      body: text == null ? '' : firstLine(text),
      payload: notificationPayload(root, n.txid),
      channel: l.notifyChannel,
      when: n.view.blockTime,
    );
  }
}

/// Tells of news while the app runs: when it isn't in front, through the
/// system; when it is, it only records what came as told.
class NewsWatcher with WidgetsBindingObserver {
  NewsWatcher(this.news);

  final NewsNotifications news;
  Timer? _soon;
  bool _running = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    news.client.addListener(_changed);
    news.prefs.addListener(_changed);
    _changed();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    news.client.removeListener(_changed);
    news.prefs.removeListener(_changed);
    _soon?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _changed();

  /// The client changes many times a second while it syncs: one check for
  /// a couple of seconds of them.
  void _changed() {
    if (news.prefs.notifyTopics.isEmpty) return;
    _soon ??= Timer(const Duration(seconds: 2), _check);
  }

  Future<void> _check() async {
    _soon = null;
    if (_running) return _changed();
    _running = true;
    try {
      news.follow();
      final away = WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
      await news.check(localizationsFor(news.prefs.locale), show: away);
    } finally {
      _running = false;
    }
  }
}

/// What [startNotifications] started, stopped if it starts again (the app's
/// `main` runs once per acceptance test, in one process).
void Function()? _stopNotifications;

/// Starts notifications in the app: the watcher, Android's background
/// checks, and the thread a tapped notification opens. The system's side
/// is set up only once the user has switched a topic on.
Future<void> startNotifications({
  required MurmurClient client,
  required Preferences prefs,
  required WalletController wallets,
  required Notifier notifier,
}) async {
  _stopNotifications?.call();
  registerAppPort();
  final news = NewsNotifications(
      client: client, prefs: prefs, notifier: notifier, me: () => wallets.wallet?.addressHex);
  final watcher = NewsWatcher(news);
  var on = false;
  Future<void> topicsChanged() async {
    final now = prefs.notifyTopics.isNotEmpty;
    if (now == on) return;
    on = now;
    // The system's side may fail to start (a session with no desktop):
    // the app goes on without it.
    try {
      if (now) await notifier.init(openLabel: localizationsFor(prefs.locale).notifyOpen, open: openNotification);
      await scheduleBackgroundChecks(now);
    } catch (e) {
      debugPrint('notifications could not start: $e');
    }
  }

  prefs.addListener(topicsChanged);
  _stopNotifications = () {
    prefs.removeListener(topicsChanged);
    watcher.stop();
  };
  await topicsChanged();
  watcher.start();
  if (on) {
    final payload = await notifier.launchPayload();
    if (payload != null) WidgetsBinding.instance.addPostFrameCallback((_) => openNotification(payload));
  }
}

/// The notification settings: a topic at a time, and what to expect.
Future<void> showNotificationSettings(BuildContext context, Notifier notifier) {
  return showAppDialog<void>(context: context, builder: (context) => _NotificationSettings(notifier: notifier));
}

class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings({required this.notifier});

  final Notifier notifier;

  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  /// The system said no: notifications are off for the app there.
  bool _denied = false;

  Future<void> _set(NotifyTopic topic, bool on) async {
    final prefs = AppScope.of(context).prefs;
    final topics = {...prefs.notifyTopics};
    // The system is asked when the first topic is switched on, within the
    // tap (browsers allow it only then).
    if (on && topics.isEmpty) {
      final granted = await widget.notifier.requestPermission();
      if (!mounted) return;
      setState(() => _denied = !granted);
      if (!granted) return;
    }
    on ? topics.add(topic) : topics.remove(topic);
    await prefs.setNotifyTopics(topics);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scope = AppScope.of(context);
    final prefs = scope.prefs;
    final hasWallet = scope.wallets.wallet != null;
    final small = Theme.of(context).textTheme.bodySmall;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final topics = prefs.notifyTopics;
        Widget topic(NotifyTopic t, String label, {bool needsWallet = false}) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              subtitle: needsWallet && !hasWallet ? Text(l.notifyNeedsWallet, style: small) : null,
              value: topics.contains(t),
              onChanged: needsWallet && !hasWallet && !topics.contains(t) ? null : (on) => _set(t, on),
            );
        return AlertDialog(
          scrollable: true,
          title: Text(l.notifications),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            topic(NotifyTopic.replies, l.notifyReplies, needsWallet: true),
            topic(NotifyTopic.mentions, l.notifyMentions, needsWallet: true),
            topic(NotifyTopic.starred, l.notifyStarred),
            if (_denied) InfoPoint(Glyph.warning, l.notifyDenied, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            InfoPoint(Glyph.node, l.notifyPointLocal, style: small),
            InfoPoint(Glyph.pending, backgroundChecks ? l.notifyPointBackground : l.notifyPointOpen, style: small),
            if (backgroundChecks) InfoPoint(Glyph.hide, l.notifyPointLockScreen, style: small),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.done))],
        );
      },
    );
  }
}

/// The button that opens the notification settings, where the platform
/// has notifications; filled while any topic is on.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final notifier = scope.notifier;
    if (notifier == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: scope.prefs,
      builder: (context, _) => IconButton(
        icon: MurmurIcon(Glyph.bell, filled: scope.prefs.notifyTopics.isNotEmpty),
        tooltip: context.l10n.notifications,
        onPressed: () => showNotificationSettings(context, notifier),
      ),
    );
  }
}
