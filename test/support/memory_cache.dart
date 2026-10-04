import 'dart:typed_data';

import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/chain_cache.dart';

/// A local copy in memory: headers only, recording every header save the
/// client makes.
class MemoryCache implements ChainCache {
  MemoryCache([List<BlockHeader>? headers]) : headers = headers ?? [];

  List<BlockHeader> headers;

  /// Every header save: (changed from, length).
  final saves = <(int, int)>[];

  @override
  Future<CachedChain?> load(String genesis) async => headers.isEmpty ? null : CachedChain(List.of(headers), {}, {});

  @override
  Future<void> saveHeaders(String genesis, List<BlockHeader> headers, int changedFrom) async {
    saves.add((changedFrom, headers.length));
    this.headers = List.of(headers);
  }

  @override
  Future<void> saveBlocks(List<Block> blocks) async {}

  @override
  Future<void> saveContents(Map<String, Uint8List> contents) async {}

  @override
  Future<void> removeContents(Set<String> hashes) async {}

  @override
  Future<void> dropBlocksAbove(int height) async {}

  @override
  Future<void> clear() async => headers = [];
}
