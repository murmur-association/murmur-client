import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'glyphs.dart';
import 'thread_page.dart';

/// Everything the user starred, newest star first: whole threads (starred by
/// their root) and single messages. A tap opens it in its thread.
///
/// The list is the one at the time the page opened, so unstarring a row
/// leaves it in place with an empty star, ready to be starred again.
class StarredPage extends StatefulWidget {
  const StarredPage({super.key});

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  List<String>? _txids;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stars are kept in the order they were given: newest last.
    _txids ??= AppScope.of(context).prefs.starred.toList().reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final txids = _txids!;
    return Scaffold(
      appBar: AppBar(title: Text(l.starredTitle)),
      body: txids.isEmpty
          ? EmptyState(icon: Glyph.star, text: l.noStarred)
          : AppBuilder(
              builder: (context, client, _) => ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: txids.length,
                separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) => _StarredTile(txid: txids[i], client: client),
              ),
            ),
    );
  }
}

class _StarredTile extends StatelessWidget {
  const _StarredTile({required this.txid, required this.client});

  final String txid;
  final MurmurClient client;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final view = client.lookupTx(txid);
    if (view == null) {
      // Not loaded yet: asked of the node by id, with a merkle branch to
      // its block.
      client.requestTx(txid);
      final gone = client.isUnknownTx(txid) || !client.isOnline;
      return ListTile(
        leading: const SizedBox.square(dimension: 40, child: Center(child: MurmurIcon(Glyph.star))),
        title: Text(gone ? l.starredGone : l.contentLoading,
            style: TextStyle(color: theme.colorScheme.outline)),
        subtitle: Text(shortHex(txid), style: mono),
        trailing: StarButton(txid),
      );
    }
    final tx = view.tx;
    final text = messageOrUnavailable(context, view).replaceAll('\n', ' ');
    final kind = tx.kind == TxKind.orphan ? l.kindThread : l.kindReply;
    final isRoot = tx.kind == TxKind.orphan;
    return ListTile(
      leading: Opacity(opacity: view.confirmed ? 1 : 0.5, child: AddressAvatar(tx.fromAddress)),
      title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: PersonLine(nameOf(context, tx.fromAddress), '$kind · ${whenOf(context, view)}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isRoot) CountBadges(replies: client.replyCountOf(view), flags: client.flagCountOf(view)),
        StarButton(txid),
      ]),
      // A thread opens at its top; a message in its thread, highlighted.
      onTap: () => isRoot
          ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => ThreadPage(rootTxid: txid)))
          : openMessage(context, view),
    );
  }
}
