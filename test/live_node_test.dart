// The client against a public node, read-only, by hand: the same checks
// node_test.dart runs against a node it starts, here on the real network's
// chain. Skipped unless MURMUR_NODE is set, e.g.:
//
//   MURMUR_NODE=testnet-seed.murmur.info:7878 flutter test test/live_node_test.dart
//
// It sends nothing. Both tests do work that grows with the chain (a filter
// scan of all of it, and every block downloaded and counted), so they take
// longer every day and aren't part of any pipeline: a release waits on
// live_release_test.dart, which is bounded. Sending, invitations,
// checkpoints and reorganizations are tested in node_test.dart, on chains
// the node builds.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/client_checks.dart';

final _node = Platform.environment['MURMUR_NODE'];

void main() {
  group('a public node', () {
    test('proves state, finds an address through filters, without the chain',
        () => checkProvenState(publicNode(_node!)),
        timeout: const Timeout(Duration(minutes: 15)));

    test('with a local copy, counts the chain and agrees with the state root; a second session starts from it',
        () => checkLocalCopy(publicNode(_node!)),
        timeout: const Timeout(Duration(minutes: 45)));
  }, skip: _node == null ? 'set MURMUR_NODE=host:port to run' : false);
}
