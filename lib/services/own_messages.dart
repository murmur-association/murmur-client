// The content of the user's own messages, salt included, kept for good:
// whatever nodes delete, the author can give it back (Restore) and answer
// readers through a node (Serving; PROTOCOL.md Section 7.3, rules 6 and 7).
// Nobody else can: without the salt the content can't be made again from
// its hash, by anyone, the author included.
//
// Kept apart from the chain cache (chain_cache.dart), which is only used
// with consent, may be dropped and rebuilt at any time, and on phones lives
// in a folder the system clears when storage runs short. This store holds
// only what the user wrote, and never leaves the device except to the node
// the user chose, as Restore and Serving.

import 'dart:typed_data';

import '../protocol/bytes.dart';
import 'own_messages_io.dart' if (dart.library.js_interop) 'own_messages_web.dart' as impl;

/// One of the user's messages: its transaction, who sent it, and the
/// salted content the transaction's message hash is of.
class OwnMessage {
  OwnMessage({required this.txid, required this.author, required this.content, required this.keptAt});

  /// The transaction, and its sender, in hex.
  final String txid;
  final String author;
  final Uint8List content;

  /// When it was kept (Unix milliseconds): the newest are given back first.
  final int keptAt;

  /// The message hash (hex): what a node asks for it by.
  late final String hash = toHex(sha256Bytes(content));

  /// `kept_at:u64 ‖ txid:32 ‖ author:32 ‖ content`, as stored.
  Uint8List encode() {
    final w = ByteWriter()
      ..u64(keptAt)
      ..bytes(fromHex(txid))
      ..bytes(fromHex(author))
      ..bytes(content);
    return w.take();
  }

  /// What [encode] wrote, or null if `record` is damaged.
  static OwnMessage? decode(Uint8List record) {
    if (record.length < 8 + 64) return null;
    try {
      final r = ByteReader(record);
      final keptAt = r.u64();
      return OwnMessage(
        keptAt: keptAt,
        txid: toHex(r.take(32)),
        author: toHex(r.take(32)),
        content: Uint8List.fromList(record.sublist(8 + 64)),
      );
    } on FormatException {
      return null;
    }
  }
}

abstract class OwnMessageStore {
  /// The store for this platform, or null when there's none (a private
  /// browser window without IndexedDB, say).
  static Future<OwnMessageStore?> open() async {
    try {
      return await impl.openOwnMessages();
    } catch (_) {
      return null;
    }
  }

  /// Everything kept, in the order it was kept.
  Future<List<OwnMessage>> load();

  Future<void> add(List<OwnMessage> messages);

  /// Deletes these transactions' content (the author withdrew them).
  Future<void> remove(Set<String> txids);
}

/// A store in memory: for tests, and where there's no other.
class MemoryOwnMessages implements OwnMessageStore {
  final List<OwnMessage> kept = [];

  @override
  Future<List<OwnMessage>> load() async => List.of(kept);

  @override
  Future<void> add(List<OwnMessage> messages) async => kept.addAll(messages);

  @override
  Future<void> remove(Set<String> txids) async => kept.removeWhere((m) => txids.contains(m.txid));
}
