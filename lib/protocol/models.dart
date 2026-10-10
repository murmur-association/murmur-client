// Transactions and blocks, mirroring murmur core's transaction.rs and
// consensus.rs (PROTOCOL.md Sections 2 and 3). Hashes must match the node
// byte for byte: a transaction has one encoding, signed, hashed and sent,
// and the header preimage follows the Rust field order with little-endian
// integers.

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

/// Every amount on the chain is a whole number of units; people read and
/// write tokens, with up to six decimals.
const unitsPerToken = 1000000;

final _secureRandom = Random.secure();

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

/// The most a transaction's own bytes can be (PROTOCOL.md Section 2.3): what
/// a fee is worked out against before the transaction exists.
const txMaxOwnBytes = 200;

/// An Orphan's or a Name's amount is exactly this times its fee, and is
/// burned: starting a thread costs 11 x the fee.
const orphanBurnMultiple = 10;

int orphanBurn(int fee) => fee * orphanBurnMultiple;

/// The most a transaction carrying `contentSize` bytes of content can weigh:
/// what its fee per byte is measured against before it is signed. A signed
/// transaction knows its own [Transaction.weight], a little less.
int txWeight(int contentSize) => txMaxOwnBytes + contentSize;

/// The index is the on-chain tag: Orphan = 0, Reply = 1, Raw = 2, Flag = 3,
/// Name = 4.
///
/// The chain has a sixth, Answer (5): a Reply that also carries the first 4
/// bytes of the txid of the reply it answers, and is a Reply in every other
/// respect (PROTOCOL.md Section 2.1). Here it is a [reply] whose
/// [Transaction.answers] is set, so that nothing that handles replies has
/// to know of two kinds; only the encoding tells them apart.
enum TxKind {
  orphan,
  reply,
  raw,
  flag,
  name;

  /// Carries a message: a hash and a size of content.
  bool get hasMessage => this == orphan || this == reply || this == name;

  /// The first message of a thread, which burns ten times its fee. A Name is
  /// one so that it can be flagged; it's never shown as a thread.
  bool get startsThread => this == orphan || this == name;
}

class Transaction {
  /// `amount` is what a Reply pays its thread's author or a Raw its
  /// recipient. An Orphan's and a Name's is their burn and a Flag's is 0,
  /// whatever is given: none of them writes one.
  Transaction({
    required this.kind,
    required this.pubkey,
    required this.nonce,
    required this.fee,
    int amount = 0,
    this.to,
    this.messageHash,
    this.contentSize = 0,
    this.reference,
    this.thread,
    this.answers,
    required this.signature,
  }) : amount = kind.startsThread ? orphanBurn(fee) : (kind == TxKind.flag ? 0 : amount);

  /// The tag of an Answer on the chain: a Reply with [answers].
  static const answerTag = 5;

  final TxKind kind;

  /// The sender's public key. The sender is its address, [from].
  final Uint8List pubkey;

  /// The sender's transaction count before this one: valid only if it equals
  /// the sender's nonce in the state (PROTOCOL.md Sections 2.1 and 5).
  final int nonce;
  final int fee;
  final int amount;

  /// A Raw's recipient. A Reply has none: the chain pays its thread's author.
  final Uint8List? to;

  /// H(content); the content itself travels separately.
  final Uint8List? messageHash;

  /// The content's length in bytes; 0 for Raw and Flag.
  final int contentSize;

  /// A Reply's thread (the txid of its first message), or the message a Flag
  /// reports.
  final Uint8List? reference;

  /// A Flag's thread, when its target isn't the thread's first message.
  final Uint8List? thread;

  /// Of a Reply that answers another reply (an Answer on the chain): the
  /// first 4 bytes of that reply's txid. The chain carries them and never
  /// reads them; which reply they mean is Section 2.4's rule (the oldest
  /// earlier reply of the thread that starts so; `quotedReply`).
  final Uint8List? answers;

  final Uint8List signature;

  /// Everything but the signature (PROTOCOL.md Section 2.2): what is signed,
  /// after the network's tag.
  static Uint8List bodyFor({
    required TxKind kind,
    required Uint8List pubkey,
    required int nonce,
    required int fee,
    int amount = 0,
    Uint8List? to,
    Uint8List? messageHash,
    int contentSize = 0,
    Uint8List? reference,
    Uint8List? thread,
    Uint8List? answers,
  }) {
    if (answers != null && (kind != TxKind.reply || answers.length != 4)) {
      throw ArgumentError('only a reply answers, with 4 bytes');
    }
    final w = ByteWriter()
      ..u8(answers == null ? kind.index : answerTag)
      ..bytes(pubkey)
      ..varint(nonce)
      ..varint(fee);
    switch (kind) {
      case TxKind.orphan || TxKind.name:
        w
          ..bytes(messageHash!)
          ..varint(contentSize);
      case TxKind.reply:
        w
          ..varint(amount)
          ..bytes(messageHash!)
          ..varint(contentSize)
          ..bytes(reference!);
        if (answers != null) w.bytes(answers);
      case TxKind.raw:
        w
          ..bytes(to!)
          ..varint(amount);
      case TxKind.flag:
        w.bytes(reference!);
        if (thread == null) {
          w.u8(0);
        } else {
          w
            ..u8(1)
            ..bytes(thread);
        }
    }
    return w.take();
  }

  /// Reads one transaction: its kind and fields say where it ends. Anything
  /// that isn't the one encoding of a transaction is refused.
  static Transaction read(ByteReader r) {
    final tag = r.u8();
    if (tag > answerTag) throw FormatException('unknown tx kind tag $tag');
    final kind = tag == answerTag ? TxKind.reply : TxKind.values[tag];
    final pubkey = r.take(32);
    final nonce = r.varint();
    final fee = r.varint();
    var amount = 0, contentSize = 0;
    Uint8List? to, messageHash, reference, thread, answers;
    switch (kind) {
      case TxKind.orphan || TxKind.name:
        messageHash = r.hash32();
        contentSize = r.varint();
      case TxKind.reply:
        amount = r.varint();
        messageHash = r.hash32();
        contentSize = r.varint();
        reference = r.hash32();
        if (tag == answerTag) answers = r.take(4);
      case TxKind.raw:
        to = r.hash32();
        amount = r.varint();
      case TxKind.flag:
        reference = r.hash32();
        final marker = r.u8();
        if (marker > 1) throw FormatException('invalid flag thread marker $marker');
        if (marker == 1) thread = r.hash32();
    }
    if (contentSize > 0xffffffff) throw const FormatException('a content size over 32 bits');
    return Transaction(
      kind: kind,
      pubkey: pubkey,
      nonce: nonce,
      fee: fee,
      amount: amount,
      to: to,
      messageHash: messageHash,
      contentSize: contentSize,
      reference: reference,
      thread: thread,
      answers: answers,
      signature: r.take(64),
    );
  }

  late final Uint8List body = bodyFor(
    kind: kind,
    pubkey: pubkey,
    nonce: nonce,
    fee: fee,
    amount: amount,
    to: to,
    messageHash: messageHash,
    contentSize: contentSize,
    reference: reference,
    thread: thread,
    answers: answers,
  );

  /// The transaction as it is sent, and as its id hashes it.
  late final Uint8List bytes = Uint8List.fromList([...body, ...signature]);

  /// The txid: SHA-256 of the transaction's bytes.
  late final Uint8List hash = sha256Bytes(bytes);
  late final String id = toHex(hash);

  /// The sender: the address of [pubkey], which a transaction doesn't write.
  late final Uint8List from = sha256Bytes(pubkey);
  late final String fromAddress = toHex(from);
  late final String? toAddress = to == null ? null : toHex(to!);
  late final String? referenceId = reference == null ? null : toHex(reference!);

  /// [answers] as the start of a txid in hex (8 characters), or null.
  late final String? answersHex = answers == null ? null : toHex(answers!);

  /// The thread this transaction is in, as the txid of its first message: a
  /// Reply's reference, a Flag's thread (its target when it names none), an
  /// Orphan's or a Name's own id. None for a Raw.
  late final String? threadId = switch (kind) {
    TxKind.orphan || TxKind.name => id,
    TxKind.reply => referenceId,
    TxKind.flag => thread == null ? referenceId : toHex(thread!),
    TxKind.raw => null,
  };

  /// Toward the block cap and fee per byte: its bytes plus its content's.
  int get weight => bytes.length + contentSize;

  /// Tokens this transaction destroys: an Orphan's or a Name's amount (they
  /// have no recipient). Zero for every other kind.
  int get burned => kind.startsThread ? amount : 0;

  /// Whether `content` is this transaction's content: right hash and length.
  bool isContent(Uint8List content) =>
      messageHash != null && content.length == contentSize && bytesEqual(sha256Bytes(content), messageHash!);
}

/// A block's work, `floor(2^256 / (target + 1))`: the expected number of
/// hashes to find it (PROTOCOL.md Section 3.2). A target of 0 would give
/// 2^256, one past what 256 bits hold: it gives 2^256 − 1.
BigInt blockWork(Uint8List target) {
  final t = bigIntFromBytes(target);
  if (t == BigInt.zero) return u256Max;
  return (u256Max - t) ~/ (t + BigInt.one) + BigInt.one;
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

  /// The 32 bytes of the target, most significant first, as everywhere it
  /// is written. All 256 bits count.
  final Uint8List target;

  /// The 8 bytes of the nonce, as on the wire (big-endian). Any 64-bit
  /// value: a miner may start anywhere (murmur-miner picks at random), so
  /// it's never held as an `int`, which rounds from 2^53 on the web and
  /// wraps from 2^63 elsewhere. A header read that way hashed to something
  /// else, and a valid block was refused.
  final Uint8List nonce;
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
          ..bytes(target)
          // Little-endian in the preimage (PROTOCOL.md Section 3.1).
          ..bytes(nonce.reversed.toList())
          ..bytes(miner))
        .take();
  }

  /// Double SHA-256 of the header preimage: computed once, or given by
  /// whoever already has it (a packed header chain keeps each header's hash
  /// beside it, so the headers it rebuilds don't hash themselves again).
  Uint8List get hash => _hash ??= sha256Bytes(sha256Bytes(_preimage()));
  Uint8List? _hash;
  late final String id = toHex(hash);

  /// The target as a number, for the difficulty rule.
  late final BigInt targetValue = bigIntFromBytes(target);

  /// The block's work. Computed once: 256-bit division is slow on the web.
  late final BigInt work = blockWork(target);

  /// The hash, read as a number with its first byte the most significant,
  /// must be at most the target: a comparison byte by byte.
  bool get meetsTarget {
    final h = hash;
    for (var i = 0; i < 32; i++) {
      if (h[i] != target[i]) return h[i] < target[i];
    }
    return true;
  }
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
