import 'package:flutter/material.dart';

import '../services/language.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'paged_list.dart';
import 'thread_page.dart';
import 'glyphs.dart';

/// Every thread, most recently active first (a new reply anywhere in a
/// thread moves it to the top), as of one block. The order stays put while
/// new blocks arrive, so the list can be read. A new snapshot is taken at the
/// tip with Refresh, and whenever the tab comes into view (`refreshToken`
/// changes). What this device sent shows at once, pending or not.
class ThreadsTab extends StatefulWidget {
  const ThreadsTab({super.key, this.refreshToken = 0});

  /// Changed by the home page each time the tab comes into view.
  final int refreshToken;

  @override
  State<ThreadsTab> createState() => _ThreadsTabState();
}

class _ThreadsTabState extends State<ThreadsTab> {
  /// The snapshot's height; null until the first one is taken.
  int? _height;

  /// When the snapshot's block was mined (Unix seconds).
  int _time = 0;
  String? _network;

  /// Bumped by every snapshot, so the list starts over from the top.
  int _generation = 0;

  void _snapshot(MurmurClient client) {
    _height = client.height;
    _time = client.headerAt(client.height)?.timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _network = client.network?.id;
    _generation++;
  }

  @override
  void didUpdateWidget(ThreadsTab old) {
    super.didUpdateWidget(old);
    // Back in view: start from the tip again (once there is a chain).
    if (old.refreshToken != widget.refreshToken && _height != null) {
      _snapshot(AppScope.of(context).client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, _) {
      // The first snapshot waits for the headers; a node on another network
      // starts over.
      final ready = client.state == LinkState.live || (client.state == LinkState.disconnected && client.height > 0);
      if (ready && (_height == null || _network != client.network?.id)) _snapshot(client);
      final height = _height;
      if (height == null) return _HeaderProgress(client: client);
      // Blocks up to the snapshot only: new ones don't reorder the list, and
      // older ones, still arriving, only add to it.
      final all = client.threads(upTo: height);
      final prefs = AppScope.of(context).prefs;
      final me = AppScope.of(context).wallets.wallet?.addressHex;
      final languages = prefs.threadLanguages ?? defaultThreadLanguages(context);
      final query = _query.trim().toLowerCase();
      // Left out by the user's own choices (counted, so nothing disappears
      // silently), then narrowed by the search (not counted).
      var hidden = 0;
      final shown = <ThreadSummary>[];
      for (final t in all) {
        // Withdrawn by its author: not anyone else's to see, and not counted
        // as hidden, since hiding it wasn't the user's choice.
        if (t.root.tx.fromAddress != me && client.selfFlagged(t.root)) continue;
        // Not text (Section 2.4), such as an alias: never a thread. Known only
        // once its content arrives, so checked live.
        if (client.isNonText(t.root)) continue;
        if (prefs.starredOnly && !prefs.starred.contains(t.root.tx.id)) {
          hidden++;
        } else if (!_wanted(t, client, prefs.muted, prefs.hideFlagged, languages, me, _threadLanguage(context, t))) {
          hidden++;
        } else if (query.isEmpty || _matches(context, client, t, query)) {
          shown.add(t);
        }
      }
      final newBlocks = (client.height - height).clamp(0, 1 << 30); // negative after a reorg
      final theme = Theme.of(context);
      final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
      return PagedList<ThreadSummary>(
        resetKey: (
          _generation,
          query,
          Object.hashAll(languages),
          prefs.hideFlagged,
          prefs.muted.length,
          prefs.starredOnly,
          prefs.starred.length,
        ),
        fetch: (n) => shown.length > n ? shown.sublist(0, n) : shown,
        itemBuilder: (context, t) => _ThreadTile(t),
        empty: EmptyState(icon: Glyph.thread, text: query.isEmpty ? l.noThreads : l.noMatches),
        loadingMore: client.canLoadOlder,
        onNeedMore: client.requestOlder,
        header: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 0),
              child: Row(children: [
                Expanded(
                  child: Ticking(
                    builder: (context) => Text(
                      '${l.threadsAsOf(height, formatClock(context, _time), formatElapsed(context, _time))} · '
                      '${l.newBlocksSince(newBlocks)}',
                      style: small,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const MurmurIcon(Glyph.refresh, size: 18),
                  label: Text(l.refresh),
                  onPressed: () => setState(() => _snapshot(client)),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l.searchThreads,
                      prefixIcon: const Padding(padding: EdgeInsets.all(12), child: MurmurIcon(Glyph.search, size: 18)),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _ThreadFilterMenu(languages: languages),
              ]),
            ),
          ),
          if (hidden > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
                child: Text(l.threadsHidden(hidden), style: small),
              ),
            ),
        ],
      );
    });
  }

  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}

/// Languages detected so far, by root txid: the text never changes, so each
/// is read once.
final _languageOf = <String, String>{};

/// A thread's language (a code, or [undetectedLanguage]); null while its
/// text hasn't arrived, so it's shown until it can be told.
String? _threadLanguage(BuildContext context, ThreadSummary t) {
  final id = t.root.tx.id;
  final known = _languageOf[id];
  if (known != null) return known;
  final text = liveMessageText(context, t.root);
  if (text == null) return null;
  return _languageOf[id] = detectLanguage(text) ?? undetectedLanguage;
}

/// The device's own languages that the detector knows, and undetected:
/// what the Threads tab shows until the user picks.
Set<String> defaultThreadLanguages(BuildContext context) => {
      context.l10n.localeName.split('_').first,
      for (final locale in WidgetsBinding.instance.platformDispatcher.locales)
        if (detectableLanguages.contains(locale.languageCode)) locale.languageCode,
      undetectedLanguage,
    };

/// Whether the user's filters keep `t`: not by a muted address, not flagged
/// by this wallet (if those are hidden), and in a chosen language (`lang`:
/// null while its text is still coming). The user's own threads show
/// whatever their language, unless the user flagged (withdrew) them and
/// flagged threads are hidden.
bool _wanted(ThreadSummary t, MurmurClient client, Set<String> muted, bool hideFlagged, Set<String> languages,
    String? me, String? lang) {
  final author = t.root.tx.fromAddress;
  final flagged = hideFlagged && me != null && client.flaggedKnown(me, t.root.tx.id);
  if (author == me) return !flagged;
  if (muted.contains(author) || flagged) return false;
  return lang == null || languages.contains(lang);
}

/// Whether the search matches the thread: its text, any loaded reply's, or
/// its author's name.
bool _matches(BuildContext context, MurmurClient client, ThreadSummary t, String query) {
  bool has(TxView v) =>
      (liveMessageText(context, v)?.toLowerCase().contains(query) ?? false) ||
      nameOf(context, v.tx.fromAddress).toLowerCase().contains(query);
  final stack = [t.root];
  final seen = <String>{};
  while (stack.isNotEmpty) {
    final v = stack.removeLast();
    if (!seen.add(v.tx.id)) continue;
    if (has(v)) return true;
    stack.addAll(client.repliesOf(v));
  }
  return false;
}

/// Languages (as checkboxes) and whether to hide threads this wallet
/// flagged.
class _ThreadFilterMenu extends StatelessWidget {
  const _ThreadFilterMenu({required this.languages});

  final Set<String> languages;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = AppScope.of(context).prefs;
    return MenuAnchor(
      menuChildren: [
        CheckboxMenuButton(
          value: prefs.starredOnly,
          closeOnActivate: false,
          onChanged: (on) => prefs.setStarredOnly(on ?? false),
          child: Text(l.starredOnly),
        ),
        CheckboxMenuButton(
          value: prefs.hideFlagged,
          closeOnActivate: false,
          onChanged: (on) => prefs.setHideFlagged(on ?? true),
          child: Text(l.hideFlaggedThreads),
        ),
        const Divider(height: 1),
        for (final code in [...detectableLanguages, undetectedLanguage])
          CheckboxMenuButton(
            value: languages.contains(code),
            closeOnActivate: false,
            onChanged: (on) => prefs.setThreadLanguages(on == true ? {...languages, code} : languages.difference({code})),
            child: Text(code == undetectedLanguage ? l.languageUndetected : languageNames[code]!),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const MurmurIcon(Glyph.filter),
        tooltip: l.filters,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}


/// Before the first list: the header chain being checked, with a bar, so
/// the wait reads as work. Nothing can be shown before the tip's header is
/// checked (PROTOCOL.md Section 7.2).
class _HeaderProgress extends StatelessWidget {
  const _HeaderProgress({required this.client});

  final MurmurClient client;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = client.peerHeight;
    if (client.state != LinkState.syncing || total == 0) {
      return EmptyState(icon: Glyph.thread, text: l.syncingChain);
    }
    final done = client.height.clamp(0, total);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          MurmurIcon(Glyph.blocks, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(l.checkingHeaders(done, total), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SizedBox(width: 240, child: LinearProgressIndicator(value: done / total)),
        ]),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile(this.thread);

  final ThreadSummary thread;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final root = thread.root;
    // The snapshot fixes the order and counts; the text is read live, since
    // content arrives after the chain is synced.
    final text = messageOrUnavailable(context, root).replaceAll('\n', ' ');
    final activity = thread.replies == 0
        ? l.threadStarted(whenOf(context, root))
        : l.threadLastReply(formatAgo(context, thread.lastActivity));
    // Only its author gets here with a withdrawn thread: faded, since others
    // no longer see it and its text may soon be kept only on this device.
    final withdrawn = AppScope.of(context).client.selfFlagged(root);
    final tile = ListTile(
      // The author's picture: threads read as people talking.
      leading: Opacity(opacity: root.confirmed ? 1 : 0.5, child: AddressAvatar(root.tx.fromAddress)),
      title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
          withdrawn ? l.threadWithdrawnMine : '${nameOf(context, root.tx.fromAddress)} · $activity',
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: CountBadges(replies: thread.replies, flags: thread.flags),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ThreadPage(rootTxid: root.tx.id),
      )),
    );
    return withdrawn ? Opacity(opacity: 0.45, child: tile) : tile;
  }
}
