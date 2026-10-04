// The node's peer-to-peer messages (PROTOCOL.md Section 7, murmur
// node/src/wire.rs). A message's payload is `tag:u8 ‖ body`; framing and
// encryption are the transport's job (services/secure_channel.dart).
//
// The node penalizes malformed messages and invalid transactions with
// misbehavior points, so every encoder here must match the Rust side
// exactly.

import 'dart:convert';
import 'dart:typed_data';

import 'bytes.dart';
import 'commitments.dart';
import 'models.dart';

const protocolVersion = 10;

/// Payloads over this are a protocol violation.
const maxPayloadBytes = 16 * 1024 * 1024;
const maxHeaders = 2000;
const maxBatchBlocks = 128;
const maxLocator = 64;

/// Message hashes per GetContent (and so items per Content).
const maxContentRequest = 256;

/// Txids per GetTx, keys per GetState, heights per GetHeaderProof.
const maxTxRequest = 64;
const maxStateKeys = 64;
const maxHeaderProofs = 64;

/// Filters per GetFilters.
const maxFilters = 1000;

/// Transactions in a CompactBlock, GetBlockTxs or BlockTxs (Section 7.9).
const maxCompactTxs = 10000;

sealed class Message {
  const Message();
}

class Hello extends Message {
  const Hello({
    required this.version,
    required this.genesis,
    required this.nonce,
    required this.listenPort,
    required this.height,
    required this.work,
  });

  final int version;
  final Uint8List genesis;
  final int nonce;
  final int listenPort;
  final int height;
  final BigInt work;
}

class NewTx extends Message {
  const NewTx(this.tx, this.content);

  final Transaction tx;
  final Uint8List? content;
}

/// A block alone: its content travelled with its transactions (NewTx), and
/// what's missing is fetched with GetContent (PROTOCOL.md Section 7.3).
class NewBlock extends Message {
  const NewBlock(this.block, this.foundMs);

  final Block block;
  final int foundMs;
}

class GetHeaders extends Message {
  const GetHeaders(this.locator);

  final List<Uint8List> locator;
}

class Headers extends Message {
  const Headers(this.headers);

  final List<BlockHeader> headers;
}

class GetBlocks extends Message {
  const GetBlocks(this.hashes);

  final List<Uint8List> hashes;
}

class BlockRecord {
  BlockRecord(this.block, this.contents);

  final Block block;
  final List<MessageContent> contents;
}

class Blocks extends Message {
  const Blocks(this.blocks);

  final List<BlockRecord> blocks;
}

class GetAddr extends Message {
  const GetAddr();
}

class Addr extends Message {
  const Addr(this.addrs);

  /// Raw IP bytes (4 or 16) and port.
  final List<(Uint8List, int)> addrs;
}

class Ping extends Message {
  const Ping();
}

/// Ask for message content by message hash.
class GetContent extends Message {
  const GetContent(this.hashes);

  final List<Uint8List> hashes;
}

/// Whichever requested content the responder has and chooses to serve.
class Content extends Message {
  const Content(this.items);

  final List<MessageContent> items;
}

// ---- light-client messages (Section 7.6) --------------------------------------

class GetFees extends Message {
  const GetFees();
}

/// A fee-per-byte bar: the fee a pending transaction of `weight` bytes pays.
typedef FeeBar = ({int fee, int weight});

class Fees extends Message {
  const Fees({this.nextBlock, this.poolEntry, required this.pending, this.recentLowest, this.recentMedian});

  final FeeBar? nextBlock;
  final FeeBar? poolEntry;
  final int pending;
  final int? recentLowest;
  final int? recentMedian;
}

class GetTx extends Message {
  const GetTx(this.txids);

  final List<Uint8List> txids;
}

/// What a node knows of a txid.
sealed class TxLookup {
  const TxLookup();
}

class TxUnknown extends TxLookup {
  const TxUnknown();
}

class TxPendingEntry extends TxLookup {
  const TxPendingEntry(this.tx);
  final Transaction tx;
}

/// On the best chain: its block, position and merkle branch (Section 7.6).
class TxOnChain extends TxLookup {
  const TxOnChain(this.tx, this.blockHash, this.height, this.index, this.branch);
  final Transaction tx;
  final Uint8List blockHash;
  final int height;
  final int index;
  final List<Uint8List> branch;
}

class Tx extends Message {
  const Tx(this.entries);

  final List<(Uint8List, TxLookup)> entries;
}

/// A transaction from its author's client, answered with one TxStatus.
class SubmitTx extends Message {
  const SubmitTx(this.tx, this.content);

  final Transaction tx;
  final Uint8List? content;
}

enum TxStatusCode {
  /// In the mempool and relayed.
  accepted,

  /// Already in the mempool or on the chain.
  known,

  /// Can never be valid.
  invalid,

  /// Valid, but not accepted now (balance, a full mempool...).
  refused,
}

class TxStatus extends Message {
  const TxStatus(this.txid, this.code, this.reason);

  final Uint8List txid;
  final TxStatusCode code;

  /// English, from the node, for display with codes 2 and 3.
  final String reason;
}

class GetState extends Message {
  const GetState(this.block, this.keys);

  final Uint8List block;
  final List<Uint8List> keys;
}

class State extends Message {
  const State(this.block, this.available, this.proofs);

  final Uint8List block;
  final bool available;
  final List<(Uint8List, StateProof)> proofs;
}

class GetFilters extends Message {
  const GetFilters(this.start, this.count);

  final int start;
  final int count;
}

class Filters extends Message {
  const Filters(this.start, this.filters);

  final int start;
  final List<Uint8List> filters;
}

class GetHeaderProof extends Message {
  const GetHeaderProof(this.at, this.heights);

  final Uint8List at;
  final List<int> heights;
}

class HeaderProof extends Message {
  const HeaderProof(this.at, this.available, this.peaks, this.entries);

  final Uint8List at;
  final bool available;

  /// The history peaks `at` commits to, as full nodes.
  final List<HistoryNode> peaks;

  /// Each requested header, with its sibling nodes inside its peak.
  final List<(BlockHeader, List<HistoryNode>)> entries;
}

// ---- compact block relay, between nodes (Section 7.9) ---------------------------
//
// Nodes announce new blocks to each other by short txids and rebuild them
// from their pools. A light client keeps no full pool, so it never asks for
// this (never sends SendCompact) and keeps receiving NewBlock. It still
// decodes all four, since decoding is strict and every node sends
// SendCompact right after its Hello.

/// "Announce new blocks to me as CompactBlock." Sent by nodes, ignored here.
class SendCompact extends Message {
  const SendCompact();
}

/// A new block by its transactions' short ids (the first 8 bytes of each
/// txid), in block order.
class CompactBlock extends Message {
  const CompactBlock(this.header, this.foundMs, this.shortIds);

  final BlockHeader header;
  final int foundMs;
  final List<Uint8List> shortIds;
}

/// Transactions of a CompactBlock's block, asked for by position.
class GetBlockTxs extends Message {
  const GetBlockTxs(this.block, this.indexes);

  final Uint8List block;
  final List<int> indexes;
}

/// The transactions asked for with GetBlockTxs, in that order.
class BlockTxs extends Message {
  const BlockTxs(this.block, this.txs);

  final Uint8List block;
  final List<Transaction> txs;
}

// ---- transactions and blocks ------------------------------------------------

void _optional(ByteWriter w, Uint8List? v) {
  if (v != null) {
    w
      ..u8(1)
      ..bytes(v);
  } else {
    w.u8(0);
  }
}

void _encodeTx(ByteWriter w, Transaction tx) {
  w
    ..u8(tx.kind.index)
    ..bytes(tx.from)
    ..u64(tx.nonce);
  _optional(w, tx.to);
  w
    ..u64(tx.amount)
    ..u64(tx.fee);
  _optional(w, tx.messageHash);
  w.u32(tx.contentSize);
  _optional(w, tx.reference);
  w
    ..u64(tx.timestamp)
    ..bytes(tx.pubkey)
    ..bytes(tx.signature);
}

Transaction _decodeTx(ByteReader r) {
  final tag = r.u8();
  if (tag > 3) throw FormatException('unknown tx kind tag $tag');
  final from = r.hash32();
  final nonce = r.u64();
  final to = r.boolean() ? r.hash32() : null;
  final amount = r.u64();
  final fee = r.u64();
  final messageHash = r.boolean() ? r.hash32() : null;
  final contentSize = r.u32();
  final reference = r.boolean() ? r.hash32() : null;
  return Transaction(
    kind: TxKind.values[tag],
    from: from,
    nonce: nonce,
    to: to,
    amount: amount,
    fee: fee,
    messageHash: messageHash,
    contentSize: contentSize,
    reference: reference,
    timestamp: r.u64(),
    pubkey: r.take(32),
    signature: r.take(64),
  );
}

void _encodeHeader(ByteWriter w, BlockHeader h) {
  w
    ..u64(h.height)
    ..bytes(h.prevHash)
    ..bytes(h.merkleRoot)
    ..bytes(h.stateRoot)
    ..bytes(h.filterHash)
    ..bytes(h.historyRoot)
    ..u64(h.timestamp)
    ..u128(h.target)
    ..u64(h.nonce)
    ..bytes(h.miner);
}

BlockHeader _decodeHeader(ByteReader r) => BlockHeader(
      height: r.u64(),
      prevHash: r.hash32(),
      merkleRoot: r.hash32(),
      stateRoot: r.hash32(),
      filterHash: r.hash32(),
      historyRoot: r.hash32(),
      timestamp: r.u64(),
      target: r.u128(),
      nonce: r.u64(),
      miner: r.hash32(),
    );

void _encodeBlock(ByteWriter w, Block b) {
  _encodeHeader(w, b.header);
  w.u32(b.transactions.length);
  for (final tx in b.transactions) {
    _encodeTx(w, tx);
  }
}

Block _decodeBlock(ByteReader r) {
  final header = _decodeHeader(r);
  final n = r.u32();
  final txs = <Transaction>[];
  for (var i = 0; i < n; i++) {
    txs.add(_decodeTx(r));
  }
  return Block(header, txs);
}

/// A header's wire size: height, prev hash, merkle root, state root, filter
/// hash, history root, timestamp, target, nonce, miner.
const headerBytes = 8 + 32 * 5 + 8 + 16 + 8 + 32;

/// Headers and blocks in their wire encoding, for storage.
Uint8List encodeHeader(BlockHeader h) {
  final w = ByteWriter();
  _encodeHeader(w, h);
  return w.take();
}

BlockHeader decodeHeader(Uint8List bytes) {
  final r = ByteReader(bytes);
  final h = _decodeHeader(r);
  r.finish();
  return h;
}

Uint8List encodeBlock(Block b) {
  final w = ByteWriter();
  _encodeBlock(w, b);
  return w.take();
}

Block decodeBlock(Uint8List bytes) {
  final r = ByteReader(bytes);
  final b = _decodeBlock(r);
  r.finish();
  return b;
}

void _encodeContents(ByteWriter w, List<MessageContent> contents) {
  w.u32(contents.length);
  for (final c in contents) {
    w
      ..bytes(c.hash)
      ..vec(c.content);
  }
}

List<MessageContent> _decodeContents(ByteReader r) {
  final n = r.u32();
  final out = <MessageContent>[];
  for (var i = 0; i < n; i++) {
    out.add(MessageContent(r.hash32(), r.vec()));
  }
  return out;
}

void _encodeHashes(ByteWriter w, List<Uint8List> hashes) {
  w.u32(hashes.length);
  for (final h in hashes) {
    w.bytes(h);
  }
}

List<Uint8List> _decodeHashes(ByteReader r, [int? limit]) {
  final n = r.u32();
  if (limit != null && n > limit) throw FormatException('$n hashes exceeds limit $limit');
  return [for (var i = 0; i < n; i++) r.hash32()];
}

(Uint8List, int) _decodeSocketAddr(ByteReader r) {
  final family = r.u8();
  final ip = switch (family) {
    4 => r.take(4),
    6 => r.take(16),
    _ => throw FormatException('unknown address family $family'),
  };
  return (ip, r.u16());
}

FeeBar? _decodeBar(ByteReader r) => r.boolean() ? (fee: r.u64(), weight: r.u32()) : null;

void _encodeBar(ByteWriter w, FeeBar? bar) {
  if (bar == null) {
    w.u8(0);
  } else {
    w
      ..u8(1)
      ..u64(bar.fee)
      ..u32(bar.weight);
  }
}

int? _decodeOptU64(ByteReader r) => r.boolean() ? r.u64() : null;

void _encodeOptU64(ByteWriter w, int? v) {
  if (v == null) {
    w.u8(0);
  } else {
    w
      ..u8(1)
      ..u64(v);
  }
}

TxLookup _decodeLookup(ByteReader r) {
  final tag = r.u8();
  return switch (tag) {
    0 => const TxUnknown(),
    1 => TxPendingEntry(_decodeTx(r)),
    2 => TxOnChain(_decodeTx(r), r.hash32(), r.u64(), r.u32(), _decodeHashes(r, 32)),
    _ => throw FormatException('unknown tx lookup tag $tag'),
  };
}

void _encodeLookup(ByteWriter w, TxLookup lookup) {
  switch (lookup) {
    case TxUnknown():
      w.u8(0);
    case TxPendingEntry(:final tx):
      w.u8(1);
      _encodeTx(w, tx);
    case TxOnChain(:final tx, :final blockHash, :final height, :final index, :final branch):
      w.u8(2);
      _encodeTx(w, tx);
      w
        ..bytes(blockHash)
        ..u64(height)
        ..u32(index);
      _encodeHashes(w, branch);
  }
}

StateProof _decodeStateProof(ByteReader r) {
  final siblings = _decodeHashes(r, 256);
  final tag = r.u8();
  final StateTerminal terminal = switch (tag) {
    0 => const EmptyTerminal(),
    1 => ValueTerminal(r.vec()),
    2 => OtherTerminal(r.hash32(), r.hash32()),
    _ => throw FormatException('unknown state proof terminal $tag'),
  };
  if (terminal is ValueTerminal && terminal.value.length > 64) {
    throw const FormatException('state value over 64 bytes');
  }
  return StateProof(siblings, terminal);
}

void _encodeStateProof(ByteWriter w, StateProof p) {
  _encodeHashes(w, p.siblings);
  switch (p.terminal) {
    case EmptyTerminal():
      w.u8(0);
    case ValueTerminal(:final value):
      w
        ..u8(1)
        ..vec(value);
    case OtherTerminal(:final key, :final valueHash):
      w
        ..u8(2)
        ..bytes(key)
        ..bytes(valueHash);
  }
}

List<HistoryNode> _decodeHistoryNodes(ByteReader r) {
  final n = r.u32();
  if (n > 64) throw FormatException('$n history nodes exceeds limit');
  return [
    for (var i = 0; i < n; i++)
      HistoryNode(
        hash: r.hash32(),
        work: r.u128(),
        firstTime: r.u64(),
        lastTime: r.u64(),
        firstTarget: r.u128(),
        lastTarget: r.u128(),
      ),
  ];
}

void _encodeHistoryNodes(ByteWriter w, List<HistoryNode> nodes) {
  w.u32(nodes.length);
  for (final n in nodes) {
    w
      ..bytes(n.hash)
      ..u128(n.work)
      ..u64(n.firstTime)
      ..u64(n.lastTime)
      ..u128(n.firstTarget)
      ..u128(n.lastTarget);
  }
}

// ---- messages -----------------------------------------------------------------

/// Encodes a message's payload: `tag:u8 ‖ body`.
Uint8List encodePayload(Message message) {
  final w = ByteWriter();
  switch (message) {
    case final Hello msg:
      w
        ..u8(0)
        ..u32(msg.version)
        ..bytes(msg.genesis)
        ..u64(msg.nonce)
        ..u16(msg.listenPort)
        ..u64(msg.height)
        ..u128(msg.work);
    case final NewTx msg:
      w.u8(1);
      _encodeTx(w, msg.tx);
      _optionalVec(w, msg.content);
    case final NewBlock msg:
      w.u8(2);
      _encodeBlock(w, msg.block);
      w.u64(msg.foundMs);
    case final GetHeaders msg:
      w.u8(3);
      _encodeHashes(w, msg.locator);
    case final Headers msg:
      w
        ..u8(4)
        ..u32(msg.headers.length);
      for (final h in msg.headers) {
        _encodeHeader(w, h);
      }
    case GetAddr():
      w.u8(5);
    case Addr():
      throw UnsupportedError('the client never sends Addr');
    case Ping():
      w.u8(7);
    case final GetBlocks msg:
      w.u8(8);
      _encodeHashes(w, msg.hashes);
    case final Blocks msg:
      w
        ..u8(9)
        ..u32(msg.blocks.length);
      for (final b in msg.blocks) {
        _encodeBlock(w, b.block);
        _encodeContents(w, b.contents);
      }
    case final GetContent msg:
      w.u8(10);
      _encodeHashes(w, msg.hashes);
    case final Content msg:
      w.u8(11);
      _encodeContents(w, msg.items);
    case GetFees():
      w.u8(12);
    case final Fees msg:
      w.u8(13);
      _encodeBar(w, msg.nextBlock);
      _encodeBar(w, msg.poolEntry);
      w.u32(msg.pending);
      _encodeOptU64(w, msg.recentLowest);
      _encodeOptU64(w, msg.recentMedian);
    case final GetTx msg:
      w.u8(14);
      _encodeHashes(w, msg.txids);
    case final Tx msg:
      w
        ..u8(15)
        ..u32(msg.entries.length);
      for (final (txid, lookup) in msg.entries) {
        w.bytes(txid);
        _encodeLookup(w, lookup);
      }
    case final SubmitTx msg:
      w.u8(16);
      _encodeTx(w, msg.tx);
      _optionalVec(w, msg.content);
    case final TxStatus msg:
      w
        ..u8(17)
        ..bytes(msg.txid)
        ..u8(msg.code.index)
        ..vec(utf8.encode(msg.reason));
    case final GetState msg:
      w
        ..u8(18)
        ..bytes(msg.block);
      _encodeHashes(w, msg.keys);
    case final State msg:
      w
        ..u8(19)
        ..bytes(msg.block)
        ..u8(msg.available ? 1 : 0)
        ..u32(msg.proofs.length);
      for (final (key, proof) in msg.proofs) {
        w.bytes(key);
        _encodeStateProof(w, proof);
      }
    case final GetFilters msg:
      w
        ..u8(20)
        ..u64(msg.start)
        ..u32(msg.count);
    case final Filters msg:
      w
        ..u8(21)
        ..u64(msg.start)
        ..u32(msg.filters.length);
      for (final f in msg.filters) {
        w.vec(f);
      }
    case final GetHeaderProof msg:
      w
        ..u8(22)
        ..bytes(msg.at)
        ..u32(msg.heights.length);
      for (final h in msg.heights) {
        w.u64(h);
      }
    case final HeaderProof msg:
      w
        ..u8(23)
        ..bytes(msg.at)
        ..u8(msg.available ? 1 : 0);
      _encodeHistoryNodes(w, msg.peaks);
      w.u32(msg.entries.length);
      for (final (header, siblings) in msg.entries) {
        _encodeHeader(w, header);
        _encodeHistoryNodes(w, siblings);
      }
    case SendCompact():
      w.u8(24);
    case final CompactBlock msg:
      w.u8(25);
      _encodeHeader(w, msg.header);
      w
        ..u64(msg.foundMs)
        ..u32(msg.shortIds.length);
      for (final id in msg.shortIds) {
        w.bytes(id);
      }
    case final GetBlockTxs msg:
      w
        ..u8(26)
        ..bytes(msg.block)
        ..u32(msg.indexes.length);
      for (final i in msg.indexes) {
        w.u32(i);
      }
    case final BlockTxs msg:
      w
        ..u8(27)
        ..bytes(msg.block)
        ..u32(msg.txs.length);
      for (final tx in msg.txs) {
        _encodeTx(w, tx);
      }
  }
  return w.take();
}

void _optionalVec(ByteWriter w, Uint8List? v) {
  if (v != null) {
    w
      ..u8(1)
      ..vec(v);
  } else {
    w.u8(0);
  }
}

/// Decodes one payload.
Message decodeMessage(Uint8List payload) {
  final r = ByteReader(payload);
  final tag = r.u8();
  final Message msg;
  switch (tag) {
    case 0:
      msg = Hello(
        version: r.u32(),
        genesis: r.hash32(),
        nonce: r.u64(),
        listenPort: r.u16(),
        height: r.u64(),
        work: r.u128(),
      );
    case 1:
      final tx = _decodeTx(r);
      msg = NewTx(tx, r.boolean() ? r.vec() : null);
    case 2:
      final block = _decodeBlock(r);
      msg = NewBlock(block, r.u64());
    case 3:
      msg = GetHeaders(_decodeHashes(r, maxLocator));
    case 4:
      final n = r.u32();
      if (n > maxHeaders) throw FormatException('$n headers exceeds limit');
      msg = Headers([for (var i = 0; i < n; i++) _decodeHeader(r)]);
    case 5:
      msg = const GetAddr();
    case 6:
      final n = r.u32();
      if (n > 100) throw FormatException('$n addresses exceeds limit');
      msg = Addr([for (var i = 0; i < n; i++) _decodeSocketAddr(r)]);
    case 7:
      msg = const Ping();
    case 8:
      msg = GetBlocks(_decodeHashes(r, maxBatchBlocks));
    case 9:
      final n = r.u32();
      if (n > maxBatchBlocks) throw FormatException('$n blocks exceeds limit');
      final blocks = <BlockRecord>[];
      for (var i = 0; i < n; i++) {
        final block = _decodeBlock(r);
        blocks.add(BlockRecord(block, _decodeContents(r)));
      }
      msg = Blocks(blocks);
    case 10:
      msg = GetContent(_decodeHashes(r, maxContentRequest));
    case 11:
      final items = _decodeContents(r);
      if (items.length > maxContentRequest) throw FormatException('${items.length} content items exceeds limit');
      msg = Content(items);
    case 12:
      msg = const GetFees();
    case 13:
      msg = Fees(
        nextBlock: _decodeBar(r),
        poolEntry: _decodeBar(r),
        pending: r.u32(),
        recentLowest: _decodeOptU64(r),
        recentMedian: _decodeOptU64(r),
      );
    case 14:
      msg = GetTx(_decodeHashes(r, maxTxRequest));
    case 15:
      final n = r.u32();
      if (n > maxTxRequest) throw FormatException('$n tx entries exceeds limit');
      msg = Tx([for (var i = 0; i < n; i++) (r.hash32(), _decodeLookup(r))]);
    case 16:
      final tx = _decodeTx(r);
      msg = SubmitTx(tx, r.boolean() ? r.vec() : null);
    case 17:
      final txid = r.hash32();
      final code = r.u8();
      if (code > 3) throw FormatException('unknown status $code');
      final reason = r.vec();
      if (reason.length > 256) throw const FormatException('status reason over 256 bytes');
      msg = TxStatus(txid, TxStatusCode.values[code], utf8.decode(reason, allowMalformed: true));
    case 18:
      msg = GetState(r.hash32(), _decodeHashes(r, maxStateKeys));
    case 19:
      final block = r.hash32();
      final available = r.boolean();
      final n = r.u32();
      if (n > maxStateKeys) throw FormatException('$n state proofs exceeds limit');
      msg = State(block, available, [for (var i = 0; i < n; i++) (r.hash32(), _decodeStateProof(r))]);
    case 20:
      msg = GetFilters(r.u64(), r.u32());
    case 21:
      final start = r.u64();
      final n = r.u32();
      if (n > maxFilters) throw FormatException('$n filters exceeds limit');
      msg = Filters(start, [for (var i = 0; i < n; i++) r.vec()]);
    case 22:
      final at = r.hash32();
      final n = r.u32();
      if (n > maxHeaderProofs) throw FormatException('$n heights exceeds limit');
      msg = GetHeaderProof(at, [for (var i = 0; i < n; i++) r.u64()]);
    case 23:
      final at = r.hash32();
      final available = r.boolean();
      final peaks = _decodeHistoryNodes(r);
      final n = r.u32();
      if (n > maxHeaderProofs) throw FormatException('$n header proofs exceeds limit');
      msg = HeaderProof(at, available, peaks, [for (var i = 0; i < n; i++) (_decodeHeader(r), _decodeHistoryNodes(r))]);
    case 24:
      msg = const SendCompact();
    case 25:
      final header = _decodeHeader(r);
      final foundMs = r.u64();
      final n = r.u32();
      if (n > maxCompactTxs) throw FormatException('$n short ids exceeds limit');
      msg = CompactBlock(header, foundMs, [for (var i = 0; i < n; i++) r.take(8)]);
    case 26:
      final block = r.hash32();
      final n = r.u32();
      if (n > maxCompactTxs) throw FormatException('$n indexes exceeds limit');
      msg = GetBlockTxs(block, [for (var i = 0; i < n; i++) r.u32()]);
    case 27:
      final block = r.hash32();
      final n = r.u32();
      if (n > maxCompactTxs) throw FormatException('$n transactions exceeds limit');
      msg = BlockTxs(block, [for (var i = 0; i < n; i++) _decodeTx(r)]);
    default:
      throw FormatException('unknown message tag $tag');
  }
  r.finish();
  return msg;
}

/// The merkle root a transaction's branch leads to (PROTOCOL.md Sections 3.3
/// and 7.6): its hash, combined with each sibling from the leaf up, on the
/// side its position at that level says.
Uint8List merkleRootFromBranch(Uint8List txid, int index, List<Uint8List> branch) {
  var hash = txid;
  var position = index;
  for (final sibling in branch) {
    hash = position % 2 == 0 ? sha256Bytes([...hash, ...sibling]) : sha256Bytes([...sibling, ...hash]);
    position ~/= 2;
  }
  return hash;
}
