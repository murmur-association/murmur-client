// What checking a header chain costs the client: a long, fully valid
// testnet header chain (proof of work, retargets, history roots), checked
// with the client's own rules (checkHeaderRules in lib/protocol/consensus.dart).
// No I/O here, so the same code runs in the Dart VM (header_bench.dart) and,
// compiled to JavaScript, in a browser (header_bench_web.dart).

import 'dart:typed_data';

import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/consensus.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';

/// The network the bench chain is on: the public testnet's parameters
/// (a 90-block retarget window, 30-second blocks).
const benchNetwork = NetworkInfo.whitepaper;

/// `count` valid headers after genesis, one every target interval, each
/// mined to its retarget target. Slow: about 256 hashes per header.
List<BlockHeader> generateChain(int count, {void Function(int done)? progress}) {
  const net = benchNetwork;
  final genesis = net.genesisHeader();
  final chain = <BlockHeader>[genesis];
  final history = HistoryPeaks()..pushHeader(genesis);
  for (var height = 1; height <= count; height++) {
    final from = height - 1 - net.lwmaWindow < 0 ? 0 : height - 1 - net.lwmaWindow;
    final target = nextTarget(chain.sublist(from, height), net);
    final root = history.root;
    BlockHeader header;
    for (var nonce = 0;; nonce++) {
      header = BlockHeader(
        height: height,
        prevHash: chain.last.hash,
        merkleRoot: Uint8List(32),
        stateRoot: Uint8List(32),
        filterHash: Uint8List(32),
        historyRoot: root,
        timestamp: net.genesisTimestamp + height * net.targetBlockSecs,
        target: target,
        nonce: nonce,
        miner: Uint8List(32),
      );
      if (header.meetsTarget) break;
    }
    chain.add(header);
    history.pushHeader(header);
    if (progress != null && height % 1000 == 0) progress(height);
  }
  return chain.sublist(1);
}

/// The chain as consecutive Headers messages (each u32 length, then the
/// payload), at most [maxHeaders] per message, as a node sends them.
Uint8List encodeChain(List<BlockHeader> chain) {
  final w = ByteWriter();
  for (var i = 0; i < chain.length; i += maxHeaders) {
    final payload = encodePayload(Headers(chain.sublist(i, i + maxHeaders > chain.length ? chain.length : i + maxHeaders)));
    w
      ..u32(payload.length)
      ..bytes(payload);
  }
  return w.take();
}

/// Inverse of [encodeChain].
List<BlockHeader> decodeChain(Uint8List data) {
  final view = ByteData.sublistView(data);
  final chain = <BlockHeader>[];
  var at = 0;
  while (at < data.length) {
    final length = view.getUint32(at);
    at += 4;
    chain.addAll((decodeMessage(Uint8List.sublistView(data, at, at + length)) as Headers).headers);
    at += length;
  }
  return chain;
}

/// Checks `chain` (heights 1 up) after genesis as the client does, and
/// returns how long it took. Throws if any header breaks a rule.
Duration checkChain(List<BlockHeader> chain) {
  const net = benchNetwork;
  final genesis = net.genesisHeader();
  final all = <BlockHeader>[genesis];
  final history = HistoryPeaks()..pushHeader(genesis);
  final watch = Stopwatch()..start();
  for (final h in chain) {
    checkHeaderRules(h, (height) => height < all.length ? all[height] : null, history, net);
    all.add(h);
    history.pushHeader(h);
  }
  return watch.elapsed;
}
