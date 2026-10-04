// Demo chains for tests, made with the client's own protocol code (no rule
// is restated here) and judged by the real node: `writeBlockLog` stores them
// in the node's block log, which `murmur-node` replays through full
// validation at startup (PROTOCOL.md Section 9). A chain the node doesn't
// accept in full fails the test that serves it (see test_node.dart).

import 'dart:io';
import 'dart:typed_data';

import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/consensus.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';

/// Empty demo blocks after genesis up to height `count`, mined to `miner`
/// (an address), one every target interval and the last one now, as on a
/// live chain. (A tip far in the past would make a node that mines on it
/// retarget to near nothing, race ahead and stall at the future-timestamp
/// limit, Section 8.2.) With `after`, a fork: its blocks up to `forkAt`,
/// then new ones on the same clock (another `miner` makes them differ).
/// Fast: the demo target needs about 16 hashes a header.
List<Block> demoChain(int count, {required Uint8List miner, List<Block> after = const [], int forkAt = 0}) {
  const net = NetworkInfo.demo;
  // Block `h` is at `base + h · interval`.
  final base = after.isEmpty
      ? DateTime.now().millisecondsSinceEpoch ~/ 1000 - count * net.targetBlockSecs
      : after.first.header.timestamp - net.targetBlockSecs;
  final headers = <BlockHeader>[net.genesisHeader(), for (final b in after.take(forkAt)) b.header];
  final history = HistoryPeaks();
  headers.forEach(history.pushHeader);
  // The state after each block, counted as Section 5 says: no transactions,
  // so only subsidies (no burn pool, no fees).
  final balances = <String, int>{};
  var issued = 0;
  void reward(BlockHeader h) {
    final subsidy = net.subsidyAt(h.height);
    balances.update(toHex(h.miner), (b) => b + subsidy, ifAbsent: () => subsidy);
    issued += subsidy;
  }

  headers.skip(1).forEach(reward);
  final blocks = [...after.take(forkAt)];
  for (var height = headers.length; height <= count; height++) {
    final from = height - 1 - net.lwmaWindow < 0 ? 0 : height - 1 - net.lwmaWindow;
    final target = nextTarget(headers.sublist(from, height), net);
    final prev = headers.last.hash;
    final root = history.root;
    final filterHash = sha256Bytes(blockFilter(Block(_draft(height, prev), const [])));
    final balance = (balances[toHex(miner)] ?? 0) + net.subsidyAt(height);
    final state = stateRootOf({
      for (final MapEntry(:key, :value) in {...balances, toHex(miner): balance}.entries)
        toHex(accountKey(fromHex(key))): Uint8List.fromList([...u64le(value), ...u64le(0)]),
      toHex(issuedKey): u64le(issued + net.subsidyAt(height)),
    });
    BlockHeader header;
    for (var nonce = 0;; nonce++) {
      header = BlockHeader(
        height: height,
        prevHash: prev,
        merkleRoot: merkleRoot(const []),
        stateRoot: state,
        filterHash: filterHash,
        historyRoot: root,
        timestamp: base + height * net.targetBlockSecs,
        target: target,
        nonce: nonce,
        miner: miner,
      );
      if (header.meetsTarget) break;
    }
    headers.add(header);
    history.pushHeader(header);
    reward(header);
    blocks.add(Block(header, const []));
  }
  return blocks;
}

/// A header with only what an empty block's filter depends on.
BlockHeader _draft(int height, Uint8List prev) => BlockHeader(
      height: height,
      prevHash: prev,
      merkleRoot: Uint8List(32),
      stateRoot: Uint8List(32),
      filterHash: Uint8List(32),
      historyRoot: Uint8List(32),
      timestamp: 0,
      target: BigInt.zero,
      nonce: 0,
      miner: Uint8List(32),
    );

/// Appends `blocks` to the node's block log in `dataDir` (PROTOCOL.md
/// Section 9): each record is `len:u32be ‖ payload ‖ H(payload)[0..4]`,
/// the payload a block record in wire encoding with no contents.
void writeBlockLog(String dataDir, List<Block> blocks) {
  final w = ByteWriter();
  for (final b in blocks) {
    // A Blocks message is `tag:u8 ‖ count:u32 ‖ records`: one record, minus
    // those five bytes, is the payload.
    final payload = Uint8List.sublistView(encodePayload(Blocks([BlockRecord(b, const [])])), 5);
    w
      ..u32(payload.length)
      ..bytes(payload)
      ..bytes(sha256Bytes(payload).sublist(0, 4));
  }
  File('$dataDir${Platform.pathSeparator}blocks.dat')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(w.take(), mode: FileMode.append);
}
