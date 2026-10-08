// Refreshes the testnet checkpoint in lib/protocol/network.dart from the
// live network, as a step of making a release (AGENTS.md, Recipes):
//
//   flutter test tool/refresh_checkpoint.dart
//
// It takes no node's word (see checkpoint/live.dart): every node behind the
// seed name is asked separately by a client that starts from the checkpoint
// shipped now and checks every header back to genesis, and they must agree.
// The new checkpoint is a day below the lowest tip, out of any
// reorganization's reach. Review and commit the one-line change it makes.
//
// A network under a day old gets none: the source says "checkpoint: none
// yet" and sessions start from genesis. The first is written here like any
// other, by clients that checked every header from genesis.

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'checkpoint/live.dart';

/// How far below the lowest tip the checkpoint goes: a day of blocks.
final depth = 86400 ~/ network.targetBlockSecs;

void main() {
  test('refresh the ${network.id} checkpoint from the live network', () async {
    final chains = await checkedChains(print);
    addTearDown(() {
      for (final c in chains) {
        c.client.dispose();
      }
    });
    // A round height, for a line that's easy to read and compare.
    final height = (chains.map((c) => c.height).reduce(min) - depth) ~/ 100 * 100;
    final current = network.checkpoint;
    if (current != null && height <= current.height) {
      print('the checkpoint at ${current.height} is less than a day old: nothing to do');
      return;
    }
    // A checkpoint needs the 11 headers before it.
    if (height <= 11) {
      if (current != null) fail('the chain is too short for a checkpoint ($height)');
      print('${network.id} is under a day old: no checkpoint yet, sessions start from genesis');
      return;
    }
    final hash = agreedHashAt(chains, height);

    final file = File('lib/protocol/network.dart');
    final source = file.readAsStringSync();
    // The shipped line, or the comment that stands for it before the first.
    final line = RegExp(r"checkpoint: Checkpoint\(\d+, '[0-9a-f]{64}'\),");
    final none = RegExp(r'(?:[ \t]*//[^\n]*\n)*[ \t]*// checkpoint: none yet');
    final place = current == null ? none : line;
    if (place.allMatches(source).length != 1) {
      fail('expected one shipped checkpoint line, or "// checkpoint: none yet", in ${file.path}');
    }
    file.writeAsStringSync(
        source.replaceFirst(place, "${current == null ? '    ' : ''}checkpoint: Checkpoint($height, '$hash'),"));
    print('${chains.length} nodes agree: ${network.id} $height $hash');
    print('written to ${file.path} (was ${current?.height}): review and commit it');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
