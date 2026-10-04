// Transactions and blocks, mirroring murmur core's transaction.rs and
// consensus.rs (PROTOCOL.md Sections 2 and 3). Hashes must match the node
// byte for byte, so the preimages here follow the Rust field order and
// little-endian integer encoding.

import 'dart:math';
import 'dart:typed_data';

import 'bytes.dart';

/// Maximum message size, salt excluded (PROTOCOL.md Section 2.3).
const maxMessageSize = 1024;

/// Content is `salt ‖ message`, so a deleted message's hash can't be matched
/// against guesses of its text (PROTOCOL.md Section 2.4).
const saltLength = 16;

/// Maximum content size: salt plus the largest message.
const maxContentSize = saltLength + maxMessageSize;

final _secureRandom = Random.secure();

final BigInt _u128Max = (BigInt.one << 128) - BigInt.one;

/// Salts a message with 16 bytes from a cryptographically secure source,
/// giving the content a transaction commits to.
Uint8List saltedContent(List<int> message) {
  final content = Uint8List(saltLength + message.length);
  for (var i = 0; i < saltLength; i++) {
    content[i] = _secureRandom.nextInt(256);
  }
  content.setRange(saltLength, content.length, message);
  return content;
}

/// The message inside content: everything after the salt, which is never shown.
Uint8List messageOf(Uint8List content) =>
    content.length <= saltLength ? Uint8List(0) : Uint8List.sublistView(content, saltLength);

/// What every transaction weighs before its content: the fixed fields, with
/// optional ones counted at full width (PROTOCOL.md Section 2.3).
const txBaseBytes = 264;

/// An Orphan's `amount` must be exactly this times its fee, and is burned:
/// starting a thread costs 11 x the fee.
const orphanBurnMultiple = 10;

int orphanBurn(int fee) => fee * orphanBurnMultiple;

/// Weight of a transaction carrying `contentSize` bytes of content: what its
/// fee per byte is measured against.
int txWeight(int contentSize) => txBaseBytes + contentSize;

/// The index is the on-chain tag: Orphan = 0, Reply = 1, Raw = 2, Flag = 3.
enum TxKind { orphan, reply, raw, flag }

class Transaction {
  Transaction({
    required this.kind,
    required this.from,
    required this.nonce,
    required this.to,
    required this.amount,
    required this.fee,
    required this.messageHash,
    required this.contentSize,
    required this.reference,
    required this.timestamp,
    required this.pubkey,
    required this.signature,
  });

  final TxKind kind;
  final Uint8List from;

  /// The sender's transaction count before this one: valid only if it equals
  /// the sender's nonce in the state (PROTOCOL.md Sections 2.1 and 5).
  final int nonce;
  final Uint8List? to;
  final int amount;
  final int fee;

  /// H(content); the content itself travels separately.
  final Uint8List? messageHash;

  /// The content's length in bytes; 0 for Raw and Flag.
  final int contentSize;

  /// Another transaction's txid: a Reply's parent, or what a Flag reports.
  final Uint8List? reference;

  final int timestamp;
  final Uint8List pubkey;
  final Uint8List signature;

  /// Everything except the signature: what gets signed.
  static Uint8List signingBytesFor({
    required TxKind kind,
    required Uint8List from,
    required int nonce,
    required Uint8List? to,
    required int amount,
    required int fee,
    required Uint8List? messageHash,
    required int contentSize,
    required Uint8List? reference,
    required int timestamp,
    required Uint8List pubkey,
  }) {
    final w = ByteWriter()
      ..u8(kind.index)
      ..bytes(from)
      ..u64(nonce, Endian.little);
    _optional(w, to);
    w
      ..u64(amount, Endian.little)
      ..u64(fee, Endian.little);
    _optional(w, messageHash);
    w.u32(contentSize, Endian.little);
    _optional(w, reference);
    w
      ..u64(timestamp, Endian.little)
      ..bytes(pubkey);
    return w.take();
  }

  static void _optional(ByteWriter w, Uint8List? v) {
    if (v != null) {
      w
        ..u8(1)
        ..bytes(v);
    } else {
      w.u8(0);
    }
  }

  Uint8List signingBytes() => signingBytesFor(
        kind: kind,
        from: from,
        nonce: nonce,
        to: to,
        amount: amount,
        fee: fee,
        messageHash: messageHash,
        contentSize: contentSize,
        reference: reference,
        timestamp: timestamp,
        pubkey: pubkey,
      );

  /// The txid: SHA-256 of the signing bytes followed by the signature.
  late final Uint8List hash = sha256Bytes([...signingBytes(), ...signature]);
  late final String id = toHex(hash);
  late final String fromAddress = toHex(from);
  late final String? toAddress = to == null ? null : toHex(to!);
  late final String? referenceId = reference == null ? null : toHex(reference!);

  /// Toward the block cap and fee per byte.
  int get weight => txWeight(contentSize);

  /// Tokens this transaction destroys: an Orphan's amount (it has no
  /// recipient). Zero for every other kind.
  int get burned => kind == TxKind.orphan ? amount : 0;

  /// Whether `content` is this transaction's content: right hash and length.
  bool isContent(Uint8List content) =>
      messageHash != null && content.length == contentSize && bytesEqual(sha256Bytes(content), messageHash!);
}

class BlockHeader {
  BlockHeader({
    required this.height,
    required this.prevHash,
    required this.merkleRoot,
    required this.stateRoot,
    required this.filterHash,
    required this.historyRoot,
    required this.timestamp,
    required this.target,
    required this.nonce,
    required this.miner,
    Uint8List? hash,
  }) : _hash = hash;

  final int height;
  final Uint8List prevHash;
  final Uint8List merkleRoot;

  /// The state tree after this block (PROTOCOL.md Section 3.6).
  final Uint8List stateRoot;

  /// H(filter) of this block's filter.
  final Uint8List filterHash;

  /// The header history (MMR) of every block before this one.
  final Uint8List historyRoot;
  final int timestamp;
  final BigInt target;
  final int nonce;
  final Uint8List miner;

  Uint8List _preimage() {
    return (ByteWriter()
          ..u64(height, Endian.little)
          ..bytes(prevHash)
          ..bytes(merkleRoot)
          ..bytes(stateRoot)
          ..bytes(filterHash)
          ..bytes(historyRoot)
          ..u64(timestamp, Endian.little)
          ..u128(target, Endian.little)
          ..u64(nonce, Endian.little)
          ..bytes(miner))
        .take();
  }

  /// Double SHA-256 of the header preimage: computed once, or given by
  /// whoever already has it (a packed header chain keeps each header's hash
  /// beside it, so the headers it rebuilds don't hash themselves again).
  Uint8List get hash => _hash ??= sha256Bytes(sha256Bytes(_preimage()));
  Uint8List? _hash;
  late final String id = toHex(hash);

  /// The block's work, `floor((2^128 − 1) / target)` (PROTOCOL.md Section
  /// 3.2). Computed once: the retarget reads each header's about 90 times,
  /// and 128-bit division is slow on the web.
  late final BigInt work = target == BigInt.zero ? _u128Max : _u128Max ~/ target;

  /// The node compares the first 16 bytes of the hash, read big-endian,
  /// against the u128 target.
  bool get meetsTarget => bigIntFromBytes(hash.sublist(0, 16)) <= target;
}

class Block {
  Block(this.header, this.transactions);

  final BlockHeader header;
  final List<Transaction> transactions;

  int get totalFees => transactions.fold(0, (sum, t) => sum + t.fee);
}

/// A message body keyed by the message hash it must match.
class MessageContent {
  MessageContent(this.hash, this.content);

  final Uint8List hash;
  final Uint8List content;
}

/// Binary merkle root over tx hashes; odd levels duplicate the last hash.
Uint8List merkleRoot(List<Uint8List> txHashes) {
  if (txHashes.isEmpty) return Uint8List(32);
  var level = List<Uint8List>.of(txHashes);
  while (level.length > 1) {
    if (level.length.isOdd) level.add(level.last);
    final next = <Uint8List>[];
    for (var i = 0; i < level.length; i += 2) {
      next.add(sha256Bytes([...level[i], ...level[i + 1]]));
    }
    level = next;
  }
  return level.first;
}
