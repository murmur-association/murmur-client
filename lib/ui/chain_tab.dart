import 'package:flutter/material.dart';

import '../protocol/bytes.dart';
import '../services/local_node.dart';
import '../services/node_client.dart';
import '../services/storage.dart';
import 'block_page.dart';
import 'brand.dart';
import 'common.dart';
import 'paged_list.dart';
import 'glyphs.dart';

/// The chain itself: network status, search, and every block, newest first.
class ChainTab extends StatefulWidget {
  const ChainTab({super.key});

  @override
  State<ChainTab> createState() => _ChainTabState();
}

class _ChainTabState extends State<ChainTab> {
  final _search = TextEditingController();

  /// Accepts a block height, a txid, a block hash or an address.
  void _runSearch(MurmurClient client) {
    final l = context.l10n;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return;
    final asHeight = int.tryParse(q.replaceAll(RegExp(r'[\s,.]'), ''));
    if (asHeight != null && q.length < 20) {
      if (client.headerAt(asHeight) != null) {
        openBlock(context, asHeight);
      } else {
        showSnack(context, l.noBlockAt(asHeight, client.height));
      }
      return;
    }
    if (tryParseHash32(q) == null) {
      showSnack(context, l.searchInvalid);
      return;
    }
    if (client.lookupTx(q) != null) return openTx(context, q);
    final h = client.heightOfBlock(q);
    if (h != null) return openBlock(context, h);
    openAddress(context, q);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, _) {
      final tip = client.height;
      return PagedList<int>(
        resetKey: client.network?.id,
        // Newest first, down to the first block not fetched yet.
        fetch: (n) => [for (var h = tip; h >= 1 && h > tip - n && client.blockAt(h) != null; h--) h],
        itemBuilder: (context, height) => _BlockTile(client: client, height: height),
        dividerIndent: null,
        empty: EmptyState(icon: Glyph.blocks, text: l.noBlocks),
        loadingMore: client.canLoadOlder,
        onNeedMore: client.requestOlder,
        header: [
          SliverToBoxAdapter(child: _ChainSummary(client: client)),
          if (AppScope.of(context).localNode?.available ?? false)
            SliverToBoxAdapter(child: _LocalNodeCard(node: AppScope.of(context).localNode!)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Padding(padding: EdgeInsets.all(12), child: MurmurIcon(Glyph.search, size: 20)),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                      icon: const MurmurIcon(Glyph.arrowForward), onPressed: () => _runSearch(client)),
                ),
                onSubmitted: (_) => _runSearch(client),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.client, required this.height});

  final MurmurClient client;
  final int height;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = client.blockAt(height);
    if (b == null) return const SizedBox.shrink(); // rolled back since the list was built
    return ListTile(
      leading: CircleAvatar(child: Text('${height % 1000}', style: const TextStyle(fontSize: 12))),
      title: Text(l.blockTitle(height)),
      // The miner's name in copper.
      subtitle: Emphasized(
        '${formatAgo(context, b.header.timestamp)} · ${l.txShortCount(b.transactions.length)} · '
        '${l.minerIs(Emphasized.link(nameOf(context, toHex(b.header.miner)), 0))}',
        links: [toHex(b.header.miner)],
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        maxLines: 1,
        weight: FontWeight.w600,
      ),
      trailing: Text(shortHex(b.header.id, head: 6, tail: 4),
          style: mono.copyWith(fontSize: 12), textDirection: TextDirection.ltr),
      onTap: () => openBlock(context, height),
    );
  }
}

class _ChainSummary extends StatelessWidget {
  const _ChainSummary({required this.client});

  final MurmurClient client;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final net = client.network;
    final theme = Theme.of(context);
    // Proven against the tip's state root, so shown as soon as the proof arrives.
    String n(int? v) => v == null ? '…' : formatAmount(context, v);
    String count(int v) => formatCount(context, v);
    final reward = client.nextBlockReward;
    final prefs = AppScope.of(context).prefs;
    final storing = prefs.storageConsent == StorageConsent.allowed;
    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 24, bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.titleMedium),
          ]),
        );
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(children: [
            stat(l.statNetwork, net?.id ?? '—'),
            stat(l.statHeight, count(client.height)),
            stat(l.statNodeHeight, count(client.peerHeight)),
            if (net != null) stat(l.statNextReward, reward == null ? '…' : l.rewardPlusFees(formatAmount(context, reward))),
            stat(l.statBurnPool, n(client.provenPool)),
            stat(l.statCirculating, n(client.circulating)),
            stat(l.node, client.host == null ? '—' : '${client.host}:${client.port}'),
          ]),
          if (client.state == LinkState.syncing && client.peerHeight > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(value: (client.height / client.peerHeight).clamp(0, 1)),
            ),
          if (client.checkingFromCheckpoint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l.checkingToGenesis(client.checkingFromCheckpoint!, client.checkedTowardGenesis),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          Row(children: [
            Expanded(
              child: Text(
                storing ? l.storageOn : l.storageOff,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () =>
                  setStorageConsent(context, storing ? StorageConsent.rejected : StorageConsent.allowed),
              child: Text(storing ? l.storageTurnOff : l.storageTurnOn),
            ),
          ]),
          if (client.genesis != null) ...[
            Text(l.tip, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            HashText(toHex(client.hashAt(client.height)), shorten: true),
          ],
          // Where the node, the protocol and the whitepaper live; then the
          // client's own license and every bundled package's notice
          // (Flutter collects them), as their licenses require.
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(alignment: WrapAlignment.end, children: [
              TextButton(onPressed: () => openLink(nodeRepositoryUrl), child: Text(l.linkNodeRepo)),
              TextButton(onPressed: () => openLink(whitepaperUrl), child: Text(l.linkWhitepaper)),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l.appTitle,
                  applicationLegalese: l.appLicense,
                ),
                child: Text(l.licenses),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

void openBlock(BuildContext context, int height) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlockPage(height: height)));

/// Desktop builds with the node program beside them: run a Murmur node on
/// this computer, which the app then uses, and optionally mine with it. The
/// node keeps the user's own messages and nobody else's content past the
/// one-hour check (services/local_node.dart).
class _LocalNodeCard extends StatefulWidget {
  const _LocalNodeCard({required this.node});

  final LocalNode node;

  @override
  State<_LocalNodeCard> createState() => _LocalNodeCardState();
}

class _LocalNodeCardState extends State<_LocalNodeCard> {
  /// The slider's value while dragged; saved (restarting the node) on release.
  double? _cpu;

  /// How far the node has come with the chain: on a long chain, its first
  /// start takes a while, and the user should see it moving.
  List<Widget> _progress(BuildContext context, NodeSync sync, TextStyle? style) {
    final l = context.l10n;
    Widget bar((int, int) at) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: LinearProgressIndicator(value: at.$2 > 0 ? (at.$1 / at.$2).clamp(0.0, 1.0) : null),
        );
    String n(int v) => formatCount(context, v);
    return [
      if (sync.fromCheckpoint) ...[
        const SizedBox(height: 8),
        InfoPoint(Glyph.pending, l.localNodeFromCheckpoint, style: style),
      ],
      if (sync.catchingUp case final at?) ...[
        const SizedBox(height: 8),
        Text(l.localNodeCatchingUp(n(at.$1), n(at.$2)), style: style),
        bar(at),
      ],
      if (sync.history case final at?) ...[
        const SizedBox(height: 8),
        Text(l.localNodeCheckingHistory(n(at.$1), n(at.$2)), style: style),
        bar(at),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scope = AppScope.of(context);
    final prefs = scope.prefs;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.node, prefs, scope.wallets]),
      builder: (context, _) {
        final node = widget.node;
        final hasWallet = scope.wallets.wallet != null;
        final status = switch (node.state) {
          LocalNodeState.starting => l.localNodeStarting,
          LocalNodeState.running => l.localNodeRunning('127.0.0.1:${node.port}'),
          LocalNodeState.failed => node.problem == null ? l.localNodeFailedUnknown : l.localNodeFailed(node.problem!),
          LocalNodeState.stopped || LocalNodeState.unavailable => null,
        };
        final cpu = _cpu ?? prefs.localNodeCpu.toDouble();
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const MurmurIcon(Glyph.node),
                title: Text(l.localNodeRun),
                subtitle: Text(l.localNodeExplain),
                value: prefs.runLocalNode,
                onChanged: prefs.setRunLocalNode,
              ),
              if (prefs.runLocalNode && status != null) Text(status, style: small),
              if (prefs.runLocalNode && node.state == LocalNodeState.running) ..._progress(context, node.sync, small),
              if (prefs.runLocalNode) ...[
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.localNodeMine),
                  subtitle: Text(hasWallet ? l.localNodeMineNote : l.localNodeMineNeedsWallet),
                  value: hasWallet && prefs.localNodeMining,
                  onChanged: hasWallet ? prefs.setLocalNodeMining : null,
                ),
                if (hasWallet && prefs.localNodeMining) ...[
                  // Where the rewards go, in full: the node is started with
                  // this address (`--mine-to`), and holds no key.
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AddressAvatar(scope.wallets.wallet!.addressHex),
                    title: Emphasized(
                        l.localNodeMinesTo(Emphasized.safe(nameOf(context, scope.wallets.wallet!.addressHex)))),
                    subtitle: HashText(scope.wallets.wallet!.addressHex),
                  ),
                  // The graphics card, where the node has its miner.
                  if (node.canMineOnGpu) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.localNodeGpu),
                      subtitle: Text(l.localNodeGpuNote),
                      value: prefs.localNodeGpu,
                      onChanged: prefs.setLocalNodeGpu,
                    ),
                    if (prefs.localNodeGpu)
                      ...switch (node.gpu) {
                        null => const <Widget>[],
                        GpuMining(state: GpuMiningState.mining, :final device) => [
                            InfoPoint(Glyph.fee,
                                device == null ? l.localNodeGpuMiningAny : l.localNodeGpuMining(Emphasized.safe(device)),
                                style: small),
                          ],
                        // Starting again after the miner stopped says why.
                        GpuMining(state: GpuMiningState.starting, :final reason) => [
                            InfoPoint(Glyph.pending, l.localNodeGpuStarting, style: small),
                            if (reason != null) Text(l.localNodeGpuDetail(reason), style: small),
                          ],
                        // Still on: the node tries the card again by itself.
                        GpuMining(state: GpuMiningState.unavailable, :final reason) => [
                            InfoPoint(Glyph.warning, l.localNodeGpuUnavailable,
                                color: StatusColors.of(context).pending, style: small),
                            if (reason != null) Text(l.localNodeGpuDetail(reason), style: small),
                          ],
                      },
                    const SizedBox(height: 8),
                  ],
                  Text(l.localNodeCpu(cpu.round()), style: small),
                  Slider(
                    value: cpu,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: (v) => setState(() => _cpu = v),
                    onChangeEnd: (v) {
                      setState(() => _cpu = null);
                      prefs.setLocalNodeCpu(v.round());
                    },
                  ),
                ],
              ],
            ]),
          ),
        );
      },
    );
  }
}
