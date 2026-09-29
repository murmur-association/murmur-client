// A local copy of the chain the client has downloaded: headers, blocks and
// message content, so a later session starts from it and asks the node only
// for what's new. In the browser it's IndexedDB; natively, files in the
// user's application data folder. It's used only with the user's consent
// (Preferences.storageConsent) and never leaves the device.
//
// What's stored was verified when it was downloaded; it's checked again
// (linkage, proof of work, merkle roots, content hashes) when loaded, so a
// damaged or edited store is ignored rather than trusted.

import 'dart:typed_data';

import '../protocol/models.dart';
import 'chain_cache_io.dart' if (dart.library.js_interop) 'chain_cache_web.dart' as impl;

class CachedChain {
  CachedChain(this.headers, this.blocks, this.contents);

  /// Headers from height 1 up.
  final List<BlockHeader> headers;

  /// Downloaded blocks by height (not necessarily all of them).
  final Map<int, Block> blocks;

  /// Message content by message hash (hex).
  final Map<String, Uint8List> contents;
}

abstract class ChainCache {
  /// The store for this platform, or null when there's none (for example a
  /// private browser window without IndexedDB).
  static Future<ChainCache?> open() async {
    try {
      return await impl.openChainCache();
    } catch (_) {
      return null;
    }
  }

  /// What's stored for the network with this genesis hash; null if nothing
  /// is, or the store holds another network.
  Future<CachedChain?> load(String genesis);

  /// Stores the header chain, which changed from height `changedFrom` on.
  /// Headers above the list's end, and a different network's data, are
  /// dropped.
  Future<void> saveHeaders(String genesis, List<BlockHeader> headers, int changedFrom);

  Future<void> saveBlocks(List<Block> blocks);

  Future<void> saveContents(Map<String, Uint8List> contents);

  /// Deletes the content of these message hashes (hex), if stored.
  Future<void> removeContents(Set<String> hashes);

  /// Drops blocks above `height` (after a reorganization).
  Future<void> dropBlocksAbove(int height);

  /// Deletes everything.
  Future<void> clear();
}
