// What checking a header chain costs the client: a long, fully valid
// testnet header chain (proof of work, retargets, history roots), checked
// with the client's own rules (checkHeaderRules in lib/protocol/consensus.dart).
// No I/O here, so the same code runs in the Dart VM (header_bench.dart) and,
// compiled to JavaScript, in a browser (header_bench_web.dart).

import 'dart:typed_data';

import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/consensus.dart';
import 'package:murmur_client/protocol/header_chain.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';

/// The network the bench chain is on: the public testnet's parameters
/// (30-second blocks, and the difficulty rule that goes with them).
const benchNetwork = NetworkInfo.whitepaper;

/// `count` valid headers after genesis, one every target interval, each
/// mined to the target the difficulty rule gives it. Slow: about 256 hashes per header.
List<BlockHeader> generateChain(int count, {void Function(int done)? progress}) {
  const net = benchNetwork;
  final genesis = net.genesisHeader();
  final chain = <BlockHeader>[genesis];
  final history = HistoryPeaks()..pushHeader(genesis);
  for (var height = 1; height <= count; height++) {
    final time = net.genesisTimestamp + height * net.targetBlockSecs;
    final target = nextTarget(
        parent: chain[height - 1], grandparent: height >= 2 ? chain[height - 2] : null, timestamp: time, net: net);
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
        timestamp: time,
        target: target,
        nonce: u64Bytes(nonce),
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

/// Decodes `data` (as [encodeChain] writes it) one Headers message at a
/// time, checks each header and packs it, as the client keeps them
/// (HeaderChain). Returns how long that took, decoding included, and the
/// packed chain: what stays in memory.
(Duration, HeaderChain) checkPacked(Uint8List data) {
  const net = benchNetwork;
  final genesis = net.genesisHeader();
  final chain = HeaderChain();
  final history = HistoryPeaks()..pushHeader(genesis);
  BlockHeader? at(int height) => height == 0 ? genesis : chain[height - 1];
  final view = ByteData.sublistView(data);
  final watch = Stopwatch()..start();
  var offset = 0;
  while (offset < data.length) {
    final length = view.getUint32(offset);
    offset += 4;
    final headers = (decodeMessage(Uint8List.sublistView(data, offset, offset + length)) as Headers).headers;
    offset += length;
    for (final h in headers) {
      checkHeaderRules(h, at, history, net);
      chain.add(h);
      history.pushHeader(h);
    }
  }
  return (watch.elapsed, chain);
}
