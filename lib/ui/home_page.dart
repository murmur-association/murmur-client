import 'dart:math';

import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/node_client.dart';
import '../services/storage.dart';
import '../services/transport.dart';
import 'brand.dart';
import 'chain_tab.dart';
import 'common.dart';
import 'compose_page.dart';
import 'messages_tab.dart';
import '../services/starred.dart';
import 'starred_tab.dart';
import 'threads_tab.dart';
import 'wallet_tab.dart';
import 'glyphs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  static const _threads = 0, _messages = 1, _starred = 2, _wallet = 3;

  int _tab = _threads;
  bool _started = false;

  /// Bumped each time the Threads tab comes into view, so it takes a fresh
  /// snapshot: switching to it, or coming back to it from another page (after
  /// publishing a thread, for example).
  int _threadsShown = 0;

  /// Bumped each time the Starred tab comes into view: it lists the stars
  /// as they are then.
  int _starredShown = 0;

  void _selectTab(int i) {
    setState(() {
      if (i == _threads && _tab != _threads) _threadsShown++;
      if (i == _starred && _tab != _starred) _starredShown++;
      _tab = i;
    });
  }

  @override
  void didPopNext() {
    if (_tab == _threads) setState(() => _threadsShown++);
    // Back from a page where a star may have been given or taken.
    if (_tab == _starred) setState(() => _starredShown++);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    scope.wallets.load();
    NodeSettings.load().then((s) => scope.client.connect(s.$1, s.$2));
  }

  void _compose(BuildContext context, WalletController wallets, TxKind kind) {
    if (wallets.wallet == null) {
      _selectTab(_wallet);
      showSnack(context, context.l10n.createWalletFirst);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComposePage(kind: kind)));
  }

  /// Replies to `me` newer than the newest one seen in the Messages tab (at
  /// most 99), and the time of the newest reply there is.
  static (int, int?) _newReplies(MurmurClient client, Preferences prefs, String me) {
    final seen = prefs.messagesSeen[me] ?? 0;
    var count = 0;
    int? newest;
    for (final v in client.activityOf(me)) {
      final t = activityTime(v);
      if (v.confirmed && t <= seen) break; // newest first: the rest were seen
      final tx = v.tx;
      // Replies in the wallet's threads (those credit it), and answers to
      // its replies in other people's, and threads and replies that mention it.
      if (tx.fromAddress == me) continue;
      final replied = tx.kind == TxKind.reply && (client.creditedBy(tx) == me || client.answersTo(tx, me));
      if (!replied && !client.mentions(tx, me)) continue;
      if (prefs.muted.contains(tx.fromAddress)) continue;
      newest = max(newest ?? 0, t);
      if (t > seen && ++count == 99) break;
    }
    return (count, newest);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final prefs = AppScope.of(context).prefs;
      final me = wallets.wallet?.addressHex;
      var newReplies = 0;
      if (me != null) {
        // The badge counts answers too, wherever the Messages tab is.
        client.watchAddress(me, mentions: true);
        final int? newest;
        (newReplies, newest) = _newReplies(client, prefs, me);
        // A wallet starts from now, not its whole history. On the Messages
        // tab, what's there is seen.
        final seen = prefs.messagesSeen[me];
        final until =
            seen == null ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : (_tab == _messages ? newest : null);
        if (until != null && until > (seen ?? 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => prefs.setMessagesSeen(me, until));
        }
        if (_tab == _messages) newReplies = 0;
      }
      // Starred threads and people: followed, and counted when they have
      // activity not seen yet. Seeing starts when the first star is given,
      // not with its whole history, and moves on while the tab is open.
      final activity = starredActivity(client,
          starred: prefs.starred, people: prefs.starredPeople, me: me, muted: prefs.muted);
      var starredNew = 0;
      if (prefs.starred.isNotEmpty || prefs.starredPeople.isNotEmpty) {
        final seen = prefs.starredSeen;
        final until =
            seen == null ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : (_tab == _starred ? activity.newest : null);
        if (until != null && until > (seen ?? -1)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => prefs.setStarredSeen(until));
        }
        if (seen != null && _tab != _starred) starredNew = min(activity.newSince(seen).length, 99);
      }
      Widget starredIcon(bool filled) => Badge(
            isLabelVisible: starredNew > 0,
            label: Text(starredNew >= 99 ? '99+' : formatCount(context, starredNew)),
            child: Semantics(
              label: starredNew > 0 ? l.starredNew(starredNew) : null,
              child: MurmurIcon(Glyph.star, filled: filled),
            ),
          );
      Widget messagesIcon(bool filled) => Badge(
            isLabelVisible: newReplies > 0,
            label: Text(newReplies >= 99 ? '99+' : formatCount(context, newReplies)),
            child: Semantics(
              label: newReplies > 0 ? l.newReplies(newReplies) : null,
              child: MurmurIcon(Glyph.outbox, filled: filled),
            ),
          );
      return Scaffold(
        appBar: AppBar(
          // On phones the logo alone leaves room for the actions.
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const MurmurLogo(size: 30),
            if (MediaQuery.sizeOf(context).width >= 520) ...[
              const SizedBox(width: 10),
              Text(l.appTitle),
            ],
          ]),
          actions: [
            ConnectionChip(client: client),
            const LanguageMenu(),
            const ThemeToggle(),
            IconButton(
              icon: const MurmurIcon(Glyph.refresh),
              tooltip: l.syncNow,
              onPressed: client.isOnline ? client.sync : null,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(children: [
          // Always there on a public test network, whatever else is shown.
          if (client.network?.isTestnet ?? false) const TestnetStrip(),
          if (AppScope.of(context).prefs.storageConsent == null)
            MaterialBanner(
              content: Text(l.storageBanner),
              leading: const MurmurIcon(Glyph.blocks),
              actions: [
                TextButton(
                  onPressed: () => setStorageConsent(context, StorageConsent.rejected),
                  child: Text(l.storageReject),
                ),
                FilledButton(
                  onPressed: () => setStorageConsent(context, StorageConsent.allowed),
                  child: Text(l.storageAllow),
                ),
              ],
            ),
          if (client.error != null)
            MaterialBanner(
              // With the countdown to the client's own next try, if any.
              content: Ticking(builder: (context) {
                final at = client.retryAt;
                final wait = at == null ? null : at.difference(DateTime.now()).inSeconds + 1;
                return Text([
                  linkErrorText(l, client.error!),
                  if (wait != null && wait > 0) l.reconnectingIn(wait),
                ].join(' '));
              }),
              leading: const MurmurIcon(Glyph.error),
              actions: [
                if (client.state == LinkState.disconnected)
                  TextButton(
                    onPressed: () => client.connect(
                        client.host ?? NodeSettings.defaultHost, client.port ?? NodeSettings.defaultPort),
                    child: Text(l.reconnect),
                  ),
                TextButton(onPressed: () => showConnectDialog(context), child: Text(l.changeNode)),
              ],
            ),
          // A tip far behind the clock: this node may be behind, or cut off.
          if (client.state == LinkState.live && client.tipLooksOld)
            MaterialBanner(
              content: Ticking(
                builder: (context) =>
                    Text(l.staleTip(formatElapsed(context, client.headerAt(client.height)!.timestamp))),
              ),
              leading: const MurmurIcon(Glyph.warning),
              actions: [TextButton(onPressed: () => showConnectDialog(context), child: Text(l.changeNode))],
            ),
          if (client.network != null && !client.network!.known)
            MaterialBanner(
              content: Text(l.unknownNetwork),
              leading: const MurmurIcon(Glyph.warning),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: IndexedStack(index: _tab, children: [
              ThreadsTab(refreshToken: _threadsShown),
              const MessagesTab(),
              StarredTab(refreshToken: _starredShown, activity: activity),
              const WalletTab(),
              const ChainTab(),
            ]),
          ),
        ]),
        // Each tab's own action: a thread from Threads, a transfer from the
        // wallet (once there is one to send from).
        floatingActionButton: switch (_tab) {
          _threads => FloatingActionButton.extended(
              onPressed: () => _compose(context, wallets, TxKind.orphan),
              icon: const MurmurIcon(Glyph.edit),
              label: Text(l.newThread),
            ),
          _wallet when wallets.wallet != null => FloatingActionButton.extended(
              onPressed: () => _compose(context, wallets, TxKind.raw),
              icon: const MurmurIcon(Glyph.transfer),
              label: Text(l.newTransaction),
            ),
          _ => null,
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          destinations: [
            // Selected tabs fill their nodes, like the logo's endpoints.
            NavigationDestination(
                icon: const MurmurIcon(Glyph.thread),
                selectedIcon: const MurmurIcon(Glyph.thread, filled: true),
                label: l.tabThreads),
            NavigationDestination(icon: messagesIcon(false), selectedIcon: messagesIcon(true), label: l.tabMessages),
            NavigationDestination(icon: starredIcon(false), selectedIcon: starredIcon(true), label: l.starredTitle),
            NavigationDestination(
                icon: const MurmurIcon(Glyph.wallet),
                selectedIcon: const MurmurIcon(Glyph.wallet, filled: true),
                label: l.tabWallet),
            NavigationDestination(
                icon: const MurmurIcon(Glyph.blocks),
                selectedIcon: const MurmurIcon(Glyph.blocks, filled: true),
                label: l.tabChain),
          ],
        ),
      );
    });
  }
}

/// A thin line under the top bar saying the network is a testnet.
class TestnetStrip extends StatelessWidget {
  const TestnetStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        color: scheme.tertiaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Text(
          context.l10n.testnetLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}

class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.client});

  final MurmurClient client;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = StatusColors.of(context);
    final (label, color) = switch (client.state) {
      LinkState.disconnected => (l.linkOffline, status.idle),
      LinkState.connecting => (l.linkConnecting, status.pending),
      LinkState.syncing => (l.linkSyncing(client.height, client.peerHeight), status.pending),
      LinkState.live => (l.linkLive(client.height), status.success),
    };
    return ActionChip(
      avatar: MurmurIcon(Glyph.node, size: 10, color: color),
      label: Text(label),
      tooltip: client.host == null ? l.connectToNode : l.nodeAt('${client.host}:${client.port}'),
      onPressed: () => showConnectDialog(context),
    );
  }
}

/// Picks the interface language; the first entry follows the system.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).prefs;
    final current = prefs.locale?.languageCode;
    return PopupMenuButton<String>(
      icon: const MurmurIcon(Glyph.language),
      tooltip: context.l10n.language,
      onSelected: (code) => prefs.setLocale(code.isEmpty ? null : Locale(code)),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(value: '', checked: current == null, child: Text(context.l10n.systemLanguage)),
        const PopupMenuDivider(),
        for (final MapEntry(key: code, value: name) in languageNames.entries)
          CheckedPopupMenuItem(value: code, checked: current == code, child: Text(name)),
      ],
    );
  }
}

/// Switches between light and dark mode. Shows the mode it switches to.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).prefs;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: MurmurIcon(dark ? Glyph.sun : Glyph.moon),
      tooltip: dark ? context.l10n.lightMode : context.l10n.darkMode,
      onPressed: () => prefs.setBrightness(dark ? Brightness.light : Brightness.dark),
    );
  }
}

Future<void> showConnectDialog(BuildContext context) async {
  final l = context.l10n;
  final client = AppScope.of(context).client;
  final host = TextEditingController(text: client.host ?? NodeSettings.defaultHost);
  final port = TextEditingController(text: '${client.port ?? NodeSettings.defaultPort}');
  final formKey = GlobalKey<FormState>();
  await showAppDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(l.node),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(viaBridge ? l.connectHelpBridge : l.connectHelpNative),
          const SizedBox(height: 16),
          TextFormField(
            controller: host,
            decoration: InputDecoration(labelText: l.host, border: const OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: port,
            decoration: InputDecoration(labelText: l.port, border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) {
              final p = int.tryParse(v ?? '');
              return (p == null || p < 1 || p > 65535) ? l.enterPort : null;
            },
          ),
        ]),
      ),
      actions: [
        if (client.state != LinkState.disconnected)
          TextButton(
            onPressed: () {
              client.disconnect();
              Navigator.pop(context);
            },
            child: Text(l.disconnect),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final h = host.text.trim();
            final p = int.parse(port.text);
            NodeSettings.save(h, p);
            client.connect(h, p);
            Navigator.pop(context);
          },
          child: Text(l.connect),
        ),
      ],
    ),
  );
}
