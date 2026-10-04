// The client against a public node, read-only: the same checks node_test.dart
// runs against a node it starts, here on the real network's chain. Skipped
// unless MURMUR_NODE is set, e.g.:
//
//   MURMUR_NODE=testnet-seed.murmur.info:7878 flutter test test/live_node_test.dart
//
// It sends nothing. Sending, invitations, checkpoints and reorganizations
// are tested in node_test.dart, on generated chains.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/node_client.dart';

import 'support/client_checks.dart';
import 'support/test_node.dart';

final _node = Platform.environment['MURMUR_NODE'];

Future<MurmurClient> _connected(MurmurClient client) async {
  addTearDown(client.dispose);
  final parts = _node!.split(':');
  await client.connect(parts[0], int.parse(parts[1]));
  await until(client, () => client.state == LinkState.live && client.height > 0, timeout: const Duration(minutes: 3));
  return client;
}

void main() {
  group('a public node', () {
    test('proves state, finds an address through filters, without the chain', () => checkProvenState(_connected),
        timeout: const Timeout(Duration(minutes: 3)));

    test('with a local copy, counts the chain and agrees with the state root; a second session starts from it',
        () => checkLocalCopy(_connected),
        timeout: const Timeout(Duration(minutes: 5)));
  }, skip: _node == null ? 'set MURMUR_NODE=host:port to run' : false);
}
