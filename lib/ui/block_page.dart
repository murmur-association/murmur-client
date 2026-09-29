import 'package:flutter/material.dart';

import '../protocol/bytes.dart';
import 'common.dart';
import 'glyphs.dart';

class BlockPage extends StatelessWidget {
  const BlockPage({super.key, required this.height});

  final int height;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, _) {
      final block = client.blockAt(height);
      // A block on the chain that isn't fetched yet is fetched now.
      final onChain = client.headerAt(height) != null;
      if (block == null && onChain) client.requestBlock(height);
      final payout = client.payoutAt(height);
      String n(int v) => formatAmount(context, v);
      void go(int h) => Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => BlockPage(height: h)));
      return Scaffold(
        appBar: AppBar(
          title: Text(l.blockTitle(height)),
          actions: [
            IconButton(
              icon: const MurmurIcon(Glyph.chevronLeft),
              tooltip: l.previousBlock,
              onPressed: height > 1 ? () => go(height - 1) : null,
            ),
            IconButton(
              icon: const MurmurIcon(Glyph.chevronRight),
              tooltip: l.nextBlock,
              onPressed: height < client.height ? () => go(height + 1) : null,
            ),
          ],
        ),
        body: block == null
            ? (onChain
                ? EmptyState(icon: Glyph.blocks, text: l.blockLoading)
                : EmptyState(icon: Glyph.unknown, text: l.blockGone))
            : ListView(padding: const EdgeInsets.all(16), children: [
                InfoRow(l.hash, HashText(block.header.id)),
                InfoRow(
                  l.previous,
                  HashText(toHex(block.header.prevHash), onTap: height > 1 ? () => go(height - 1) : null),
                ),
                InfoRow(l.time, Text(formatTime(context, block.header.timestamp))),
                InfoRow(l.confirmations, Text(n(client.height - height + 1))),
                InfoRow(l.miner, HashText(toHex(block.header.miner),
                    onTap: () => openAddress(context, toHex(block.header.miner)))),
                // The burn-pool payout is known once the chain below is counted.
                InfoRow(
                    l.reward,
                    Text(payout == null
                        ? '…'
                        : l.rewardBreakdown(client.network!.subsidyAt(height), payout, block.totalFees))),
                InfoRow(l.merkleRoot, HashText(toHex(block.header.merkleRoot))),
                InfoRow(l.target,
                    SelectableText(block.header.target.toRadixString(16).padLeft(32, '0'), style: mono)),
                InfoRow(l.nonce, Text('${block.header.nonce}')),
                const Divider(height: 32),
                Text(l.txCount(block.transactions.length), style: Theme.of(context).textTheme.titleMedium),
                for (final tx in block.transactions) TxTile(client.lookupTx(tx.id)!),
              ]),
      );
    });
  }
}
