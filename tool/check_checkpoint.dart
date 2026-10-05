// Checks the shipped testnet checkpoint against the live network, before a
// release is built (.gitlab-ci.yml):
//
//   flutter test tool/check_checkpoint.dart
//
// The network is only a check here, never the source: the checkpoint is the
// one committed in lib/protocol/network.dart (written by
// refresh_checkpoint.dart, and reviewed). Each node behind the seed name
// must serve a chain that contains it and checks out back to genesis (see
// checkpoint/live.dart), and it must be recent, so a first session has few
// headers to check before it shows anything.

// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'checkpoint/live.dart';

/// How far behind the tip a release's checkpoint may be: a week of blocks.
final maxAge = 7 * 86400 ~/ network.targetBlockSecs;

void main() {
  test('the shipped ${network.id} checkpoint is on the live chain, and recent', () async {
    final shipped = network.checkpoint;
    if (shipped == null) fail('${network.id} ships no checkpoint');
    final chains = await checkedChains(print);
    addTearDown(() {
      for (final c in chains) {
        c.client.dispose();
      }
    });
    expect(agreedHashAt(chains, shipped.height), shipped.hash);
    final age = chains.map((c) => c.height).reduce(min) - shipped.height;
    print('checkpoint ${shipped.height}: on ${chains.length} nodes\' chains, $age blocks below the tip');
    expect(age, lessThanOrEqualTo(maxAge),
        reason: 'the checkpoint is over a week old: run `flutter test tool/refresh_checkpoint.dart` and commit it');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
