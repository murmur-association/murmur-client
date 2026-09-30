import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../protocol/alias.dart';
import '../protocol/models.dart';
import '../services/chain_cache.dart';
import '../services/local_node.dart';
import '../services/node_client.dart';
import '../services/storage.dart';
import 'address_page.dart';
import 'brand.dart';
import 'l10n.dart';
import 'thread_page.dart';
import 'tx_page.dart';
import 'glyphs.dart';
import 'people.dart';
import 'share.dart';

export 'l10n.dart';
export 'people.dart' show nameOf, publicNameOf, AddressAvatar, editAlias;
export 'share.dart' show ShareButton;

/// Makes the client, the wallet and the preferences available to every page.
class AppScope extends InheritedWidget {
  const AppScope(
      {super.key,
      required this.client,
      required this.wallets,
      required this.prefs,
      this.localNode,
      required super.child});

  final MurmurClient client;
  final WalletController wallets;
  final Preferences prefs;

  /// The app's own node (desktop builds with the node program next to
  /// them); null or unavailable elsewhere.
  final LocalNode? localNode;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      client != oldWidget.client || wallets != oldWidget.wallets || prefs != oldWidget.prefs;
}

/// Records the user's storage choice and applies it: keep the downloaded
/// chain on this device from now on, or stop and delete what's kept.
Future<void> setStorageConsent(BuildContext context, StorageConsent consent) async {
  final scope = AppScope.of(context);
  await scope.prefs.setStorageConsent(consent);
  final cache = await ChainCache.open();
  if (consent == StorageConsent.allowed) {
    scope.client.useCache(cache);
  } else {
    scope.client.useCache(null);
    await cache?.clear();
  }
}

/// The public web app: where links shared from a native build point.
const webAppUrl = 'https://app.murmur.info';

/// Where links point: this page's own site on the web, the public web app
/// from a native build. `main.dart` opens them.
String get appBaseUrl => kIsWeb ? Uri.base.origin : webAppUrl;

/// A link that opens thread `txid`.
String threadLink(String txid) => '$appBaseUrl/#/thread/$txid';

/// The thread a route name (a link's `#/thread/<txid>`) opens, if any.
String? threadInRoute(String? name) => RegExp(r'^/thread/([0-9a-f]{64})$').firstMatch(name ?? '')?.group(1);

/// The node's repository: its code, PROTOCOL.md and the whitepaper.
const nodeRepositoryUrl = 'https://gitlab.com/elc4no/murmur';
const whitepaperUrl = '$nodeRepositoryUrl/-/blob/main/murmur-whitepaper.md';

/// Opens `url` outside the app (a new browser tab on the web). Only ever
/// on the user's tap: the app itself requests nothing from other origins.
Future<void> openLink(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Tells pages when a page pushed over them closes (the home page refreshes
/// the Threads tab on returning to it).
final routeObserver = RouteObserver<ModalRoute<void>>();

/// Rebuilds whenever the chain view, the wallet or the preferences change.
class AppBuilder extends StatelessWidget {
  const AppBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, MurmurClient client, WalletController wallets)
      builder;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.client, scope.wallets, scope.prefs]),
      builder: (context, _) => builder(context, scope.client, scope.wallets),
    );
  }
}

// ---- formatting -------------------------------------------------------------

String shortHex(String hex, {int head = 8, int tail = 6}) =>
    hex.length <= head + tail + 1 ? hex : '${hex.substring(0, head)}…${hex.substring(hex.length - tail)}';

/// UI name for a transaction kind. Orphans are called threads in the
/// interface.
String kindLabel(BuildContext context, TxKind k) {
  final l = context.l10n;
  return switch (k) {
    TxKind.orphan => l.kindThread,
    TxKind.reply => l.kindReply,
    TxKind.raw => l.kindTransfer,
    TxKind.flag => l.kindFlag,
  };
}

Glyph kindIcon(TxKind k) => switch (k) {
      TxKind.orphan => Glyph.thread,
      TxKind.reply => Glyph.reply,
      TxKind.raw => Glyph.transfer,
      TxKind.flag => Glyph.flag,
    };

/// The message in a transaction's content as text (UTF-8, tolerating bad
/// bytes), without the salt. A message that isn't text (PROTOCOL.md Section
/// 2.4: first byte 0x00) is said for what it is: an alias it sets (Section
/// 7.8), or data for some other client convention.
String? messageText(BuildContext context, Uint8List? content) {
  if (content == null) return null;
  final message = messageOf(content);
  if (!isNonText(message)) return utf8.decode(message, allowMalformed: true);
  final alias = aliasOf(message);
  final l = context.l10n;
  return alias == null ? l.nonTextMessage : (alias.isEmpty ? l.aliasCleared : l.aliasSetTo(alias));
}

/// A message's text, read live from the client, or a note that it isn't at
/// hand: withdrawn by its author (their own flag, so its text was deleted
/// here), still loading, or not available because the node doesn't have it
/// (any node may delete content, PROTOCOL.md Section 7.3).
String messageOrUnavailable(BuildContext context, TxView view) {
  final client = AppScope.of(context).client;
  final l = context.l10n;
  if (client.contentWithdrawn(view.tx)) return l.contentWithdrawn;
  return messageText(context, client.liveContent(view)) ??
      (client.contentExpected(view.tx) ? l.contentLoading : l.contentUnavailable);
}

/// A message's text as the client holds it now, or null while it's missing.
String? liveMessageText(BuildContext context, TxView view) =>
    messageText(context, AppScope.of(context).client.liveContent(view));

/// Text whose `**key words**` show in bold copper: how explanations mark
/// what matters, so they read at a glance. The markers live in the ARB
/// strings, so each language chooses its own key words.
class Emphasized extends StatelessWidget {
  const Emphasized(this.text, {super.key, this.style, this.maxLines, this.weight = FontWeight.w700});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final FontWeight weight;

  /// `value` (a name, say) with its own `**` made harmless, to put between
  /// markers: a zero-width space splits them.
  static String safe(String value) => value.replaceAll('**', '*​*');

  /// `value` marked for emphasis.
  static String mark(String value) => '**${safe(value)}**';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strong = TextStyle(fontWeight: weight, color: theme.colorScheme.primary);
    final parts = text.split('**');
    return Text.rich(
      TextSpan(children: [
        // Odd pieces sit between markers.
        for (var i = 0; i < parts.length; i++)
          if (parts[i].isNotEmpty) TextSpan(text: parts[i], style: i.isOdd ? strong : null),
      ]),
      style: style ?? theme.textTheme.bodyMedium,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// A list row's subtitle style, for subtitles built as [Emphasized]: what
/// ListTile gives a plain Text subtitle.
TextStyle? _subtitleStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
}

/// A row's subtitle: the person first, in copper, then the rest. For thread
/// and message lists.
class PersonLine extends StatelessWidget {
  const PersonLine(this.name, this.rest, {super.key});

  final String name;
  final String rest;

  @override
  Widget build(BuildContext context) => Emphasized('${Emphasized.mark(name)} · ${Emphasized.safe(rest)}',
      style: _subtitleStyle(context), maxLines: 1, weight: FontWeight.w600);
}

/// One point of an explanation: an icon, and a short line with its key
/// words emphasized. Several stacked replace a paragraph.
class InfoPoint extends StatelessWidget {
  const InfoPoint(this.glyph, this.text, {super.key, this.color, this.style});

  final Glyph glyph;
  final String text;

  /// The icon's color; the muted text color unless given (a warning, say).
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: MurmurIcon(glyph, size: 18, color: color ?? theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(child: Emphasized(text, style: style ?? theme.textTheme.bodyMedium)),
      ]),
    );
  }
}

/// Stars or unstars a message, or a whole thread by its root: starred ones
/// are easy to find, and their content stays in the local copy however old.
class StarButton extends StatelessWidget {
  const StarButton(this.txid, {super.key});

  final String txid;

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).prefs;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final starred = prefs.starred.contains(txid);
        return IconButton(
          // Starred: a solid copper star, unmistakable next to an outline.
          icon: MurmurIcon(Glyph.star, filled: starred, color: starred ? Theme.of(context).colorScheme.primary : null),
          tooltip: starred ? context.l10n.unstar : context.l10n.star,
          onPressed: () => prefs.setStarred(txid, !starred),
        );
      },
    );
  }
}

/// Pending, or how long ago its block was mined.
String whenOf(BuildContext context, TxView v) =>
    v.blockTime != null ? formatAgo(context, v.blockTime!) : context.l10n.pending;

const mono = TextStyle(fontFamily: 'monospace', fontFamilyFallback: ['Courier New', 'Menlo']);

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

// ---- widgets ------------------------------------------------------------------

/// A hex value with a copy button; optionally tappable.
class HashText extends StatelessWidget {
  const HashText(this.hex, {super.key, this.shorten = false, this.onTap});

  final String hex;
  final bool shorten;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      shorten ? shortHex(hex) : hex,
      // Hex reads left to right in every language.
      textDirection: TextDirection.ltr,
      style: mono.copyWith(
        fontSize: 13,
        color: onTap != null ? Theme.of(context).colorScheme.primary : null,
        decoration: onTap != null ? TextDecoration.underline : null,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: onTap != null ? InkWell(onTap: onTap, child: text) : SelectionArea(child: text)),
        ShareButton(hex, size: 16),
      ],
    );
  }
}

/// A label/value row for detail pages; stacks on narrow screens.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 520) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, value]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 150, child: labelWidget),
          Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: value)),
        ]);
      }),
    );
  }
}

void openAddress(BuildContext context, String address) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddressPage(address: address)));

void openTx(BuildContext context, String txid) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TxPage(txid: txid)));

/// Opens the thread a message belongs to, or the transaction page for
/// transfers, flags and replies whose thread isn't known.
void openMessage(BuildContext context, TxView view) {
  final client = AppScope.of(context).client;
  // Not text (an alias, say): not a thread, so its own page (Section 2.4).
  final isMessage = (view.tx.kind == TxKind.orphan || view.tx.kind == TxKind.reply) && !client.isNonText(view);
  final root = isMessage ? client.threadRootOf(view) : null;
  if (root == null) {
    openTx(context, view.tx.id);
  } else {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ThreadPage(rootTxid: root.tx.id, focusTxid: view.tx.id),
    ));
  }
}

/// Reply and flag counts, shown at the end of message rows.
class CountBadges extends StatelessWidget {
  const CountBadges({super.key, required this.replies, required this.flags});

  final int replies;
  final int flags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    Widget badge(Glyph icon, int n, String tooltip, Color active) {
      final color = n > 0 ? active : scheme.outline;
      return Tooltip(
        message: tooltip,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          MurmurIcon(icon, size: 16, color: color),
          const SizedBox(width: 3),
          Text(formatAmount(context, n), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      badge(Glyph.reply, replies, l.replyCount(replies), scheme.primary),
      const SizedBox(width: 12),
      badge(Glyph.flag, flags, l.flagCount(flags), StatusColors.of(context).danger),
    ]);
  }
}

/// One transaction in a list.
class TxTile extends StatelessWidget {
  const TxTile(this.view, {super.key, this.perspective, this.showCounts = false});

  final TxView view;

  /// If set, amounts are shown as incoming/outgoing for this address.
  final String? perspective;

  /// Show reply/flag counts at the end instead of the amount, and open the
  /// message's thread on tap.
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tx = view.tx;
    final status = StatusColors.of(context);
    final client = AppScope.of(context).client;
    final String title;
    if (tx.kind == TxKind.raw) {
      title = l.transferOf(tx.amount);
    } else if (tx.kind == TxKind.flag) {
      final target = client.referenced(view);
      final targetText = target == null ? null : liveMessageText(context, target)?.replaceAll('\n', ' ');
      title = targetText == null ? l.flagOnTx(shortHex(tx.referenceId ?? '')) : l.flagOn(targetText);
    } else {
      title = messageOrUnavailable(context, view).replaceAll('\n', ' ');
    }
    // A reply that fails the Section 2.4 check is only a payment.
    final label = tx.kind == TxKind.reply && view.confirmed && !client.isThreadedReply(view)
        ? l.replyNotThreaded
        : kindLabel(context, tx.kind);
    // Who: the names in copper.
    final route = tx.toAddress == null
        ? l.routeFrom(Emphasized.mark(nameOf(context, tx.fromAddress)))
        : l.routeFromTo(
            Emphasized.mark(nameOf(context, tx.fromAddress)), Emphasized.mark(nameOf(context, tx.toAddress!)));

    Widget? trailing;
    if (showCounts) {
      if (tx.kind == TxKind.orphan || tx.kind == TxKind.reply) {
        trailing = CountBadges(replies: client.replyCountOf(view), flags: client.flagCountOf(view));
      }
    } else if (perspective != null) {
      final delta = MurmurClient.balanceChange(tx, perspective!);
      final after = view.balanceAfter;
      final change = Text(
        formatSigned(context, delta),
        style: TextStyle(color: delta >= 0 ? status.success : status.danger, fontWeight: FontWeight.w600),
      );
      trailing = after == null
          ? change
          : Tooltip(
              message: l.balanceBeforeAfterTooltip(after - delta, after),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  change,
                  Text(
                    l.balanceBeforeAfter(after - delta, after),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
    } else if (tx.amount > 0) {
      trailing = Text(formatAmount(context, tx.amount), style: const TextStyle(fontWeight: FontWeight.w600));
    }

    return ListTile(
      leading: GlyphAvatar(kindIcon(tx.kind), active: view.confirmed),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Emphasized('${Emphasized.safe(label)} · $route · ${whenOf(context, view)}',
          style: _subtitleStyle(context), maxLines: 1, weight: FontWeight.w600),
      trailing: trailing,
      onTap: () => showCounts ? openMessage(context, view) : openTx(context, tx.id),
    );
  }
}

/// An address's balance, proven against the tip's state root; "checking…"
/// until the node's proof arrives.
class BalanceText extends StatelessWidget {
  const BalanceText({super.key, required this.client, required this.address, this.style});

  final MurmurClient client;
  final String address;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final balance = client.knownBalance(address);
    if (balance != null) return Text(formatAmount(context, balance), style: style);
    return Text(context.l10n.checkingBalance,
        style: style?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
  }
}

/// A label, with a bar and "x of y blocks counted" beneath it, while the
/// chain is still being fetched and counted.
class ChainProgress extends StatelessWidget {
  const ChainProgress({super.key, required this.client, required this.label, this.style});

  final MurmurClient client;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = client.height;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      SizedBox(
        width: 240,
        child: LinearProgressIndicator(value: total == 0 ? null : client.countedHeight / total),
      ),
      const SizedBox(height: 4),
      Text(context.l10n.chainCounted(client.countedHeight, total), style: theme.textTheme.bodySmall),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final Glyph icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          MurmurIcon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

/// Rebuilds its child every second (for the elapsed time), without
/// rebuilding the list around it.
class Ticking extends StatefulWidget {
  const Ticking({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<Ticking> createState() => _TickingState();
}

class _TickingState extends State<Ticking> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
