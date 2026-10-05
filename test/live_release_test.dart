// What a release waits on, against the live network (.gitlab-ci.yml,
// public-node-tests): the client about to be released connects to a public
// node, starts from the shipped checkpoint, and proves the supply, the burn
// pool and an account against the tip's state root, and reads the fees.
// Read-only, and bounded: a few requests, whatever the chain's length (the
// headers above the checkpoint are at most a week's), so it can't start
// failing releases as the chain grows. Skipped unless MURMUR_NODE is set:
//
//   MURMUR_NODE=testnet-seed.murmur.info:7878 flutter test test/live_release_test.dart
//
// The longer checks, by hand, are in live_node_test.dart.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/node_client.dart';

import 'support/client_checks.dart';

final _node = Platform.environment['MURMUR_NODE'];

void main() {
  test('a public node: the client syncs from the shipped checkpoint and proves the supply, an account and the fees',
      () async {
    final started = DateTime.now();
    final client = await publicNode(_node!)(MurmurClient());
    await checkProvenBasics(client);
    print('${client.network!.id} at ${client.height}: synced and proven in '
        '${DateTime.now().difference(started).inMilliseconds} ms');
  }, skip: _node == null ? 'set MURMUR_NODE=host:port to run' : false, timeout: const Timeout(Duration(minutes: 5)));
}
