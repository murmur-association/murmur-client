// The node list (NodeSettings): the nodes the client uses, in order. Up to
// three are connected at once, from the top (MurmurClient.connectTo); the
// user adds, removes and moves entries, or puts the defaults back.

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../services/node_client.dart';
import '../services/storage.dart';
import '../services/transport.dart' show viaBridge;
import 'common.dart';
import 'glyphs.dart';

/// Opens the node list; Connect saves it and connects to it.
Future<void> showConnectDialog(BuildContext context) async {
  final list = await NodeSettings.loadList();
  if (!context.mounted) return;
  await showAppDialog<void>(context: context, builder: (context) => NodesDialog(initial: list));
}

class NodesDialog extends StatefulWidget {
  const NodesDialog({super.key, required this.initial});

  final List<NodeAddress> initial;

  @override
  State<NodesDialog> createState() => _NodesDialogState();
}

class _NodesDialogState extends State<NodesDialog> {
  late List<NodeAddress> _nodes = [...widget.initial];
  final _entry = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _add() {
    final l = context.l10n;
    final node = NodeAddress.parse(_entry.text);
    setState(() {
      if (node == null) {
        _problem = l.nodeEntryInvalid;
      } else if (_nodes.contains(node)) {
        _problem = l.nodeEntryKnown;
      } else {
        _nodes = [..._nodes, node];
        _problem = null;
        _entry.clear();
      }
    });
  }

  void _moveUp(int i) => setState(() => _nodes = [..._nodes]..insert(i - 1, _nodes[i])..removeAt(i + 1));

  void _remove(int i) => setState(() => _nodes = [..._nodes]..removeAt(i));

  Future<void> _connect() async {
    // What's typed and not added yet counts, if it's an entry.
    if (_entry.text.trim().isNotEmpty) {
      _add();
      if (_problem != null) return;
    }
    final client = AppScope.of(context).client;
    final navigator = Navigator.of(context);
    await NodeSettings.save(_nodes);
    unawaited(client.connectTo(await NodeSettings.load()));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final client = AppScope.of(context).client;
    return AnimatedBuilder(
      animation: client,
      builder: (context, _) {
        final connected = client.connectedByEntry;
        return AlertDialog(
          scrollable: true,
          title: Text(l.nodes),
          content: SizedBox(
            width: 440,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              InfoPoint(Glyph.node, l.nodesPointPool),
              InfoPoint(Glyph.refresh, l.nodesPointNext),
              InfoPoint(Glyph.edit, viaBridge ? l.nodesPointEntryBridge : l.nodesPointEntryNative),
              const SizedBox(height: 8),
              for (var i = 0; i < _nodes.length; i++)
                ListTile(
                  key: ValueKey('node-${_nodes[i]}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('${_nodes[i]}', style: const TextStyle(fontFamily: 'monospace')),
                  subtitle: (connected[_nodes[i]] ?? 0) > 0 ? Text(l.connectedNodes(connected[_nodes[i]]!)) : null,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (i > 0)
                      IconButton(
                        tooltip: l.moveNodeUp,
                        icon: const MurmurIcon(Glyph.moveUp),
                        onPressed: () => _moveUp(i),
                      ),
                    // The list never goes empty: there'd be nothing to connect to.
                    if (_nodes.length > 1)
                      IconButton(
                        tooltip: l.removeNode,
                        icon: const MurmurIcon(Glyph.remove),
                        onPressed: () => _remove(i),
                      ),
                  ]),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _entry,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l.addNode,
                  hintText: l.nodeEntryHint,
                  errorText: _problem,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(tooltip: l.addNode, icon: const MurmurIcon(Glyph.add), onPressed: _add),
                ),
                onSubmitted: (_) => _add(),
              ),
              if (!listEquals(_nodes, NodeSettings.defaults))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => setState(() {
                      _nodes = [...NodeSettings.defaults];
                      _problem = null;
                    }),
                    child: Text(l.defaultNodes),
                  ),
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
            FilledButton(onPressed: _connect, child: Text(l.connect)),
          ],
        );
      },
    );
  }
}
