// The chain cache as files, for native builds, in the user's application
// data folder (murmur-client/chain):
// - genesis: the network's genesis hash (hex);
// - headers.bin: headers from height 1, each [headerBytes] long;
// - blocks.log: (length:u32 ‖ block) records, later ones replacing earlier;
// - contents.log: (hash:32 ‖ length:u32 ‖ content) records.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../protocol/bytes.dart';
import '../protocol/models.dart';
import '../protocol/wire.dart';
import 'chain_cache.dart';

Future<ChainCache> openChainCache() async {
  final env = Platform.environment;
  final base = env['APPDATA'] ??
      env['XDG_DATA_HOME'] ??
      (env['HOME'] == null ? null : '${env['HOME']}/.local/share') ??
      Directory.systemTemp.path;
  final dir = Directory('$base${Platform.pathSeparator}murmur-client${Platform.pathSeparator}chain');
  await dir.create(recursive: true);
  return FileChainCache(dir);
}

/// The cache in `dir` (public so tests can use a temporary folder).
class FileChainCache implements ChainCache {
  FileChainCache(Directory dir)
      : _genesisFile = File('${dir.path}/genesis'),
        _headersFile = File('${dir.path}/headers.bin'),
        _blocksFile = File('${dir.path}/blocks.log'),
        _contentsFile = File('${dir.path}/contents.log');

  final File _genesisFile, _headersFile, _blocksFile, _contentsFile;

  Future<String?> _genesis() async => await _genesisFile.exists() ? (await _genesisFile.readAsString()).trim() : null;

  @override
  Future<CachedChain?> load(String genesis) async {
    if (await _genesis() != genesis) return null;
    final headers = storedHeaders(await _headersFile.exists() ? await _headersFile.readAsBytes() : Uint8List(0));
    final blocks = <int, Block>{};
    if (await _blocksFile.exists()) {
      final r = ByteReader(await _blocksFile.readAsBytes());
      try {
        while (true) {
          final b = decodeBlock(r.vec());
          blocks[b.header.height] = b;
        }
      } on FormatException {
        // End of the log (or a record cut short by a crash).
      }
    }
    final contents = <String, Uint8List>{};
    if (await _contentsFile.exists()) {
      final r = ByteReader(await _contentsFile.readAsBytes());
      try {
        while (true) {
          final hash = toHex(r.hash32());
          contents[hash] = r.vec();
        }
      } on FormatException {
        // End of the log.
      }
    }
    return CachedChain(headers, blocks, contents);
  }

  @override
  Future<void> saveHeaders(String genesis, List<BlockHeader> headers, int changedFrom) async {
    if (await _genesis() != genesis) {
      await clear();
      await _genesisFile.writeAsString(genesis);
      changedFrom = 1;
    }
    // Keep the unchanged headers already on disk, rewrite from there.
    final onDisk = await _headersFile.exists() ? await _headersFile.length() ~/ headerBytes : 0;
    final keep = min(onDisk, changedFrom - 1);
    final file = await _headersFile.open(mode: FileMode.append);
    try {
      await file.truncate(keep * headerBytes);
      final w = BytesBuilder(copy: false);
      for (var i = keep; i < headers.length; i++) {
        w.add(encodeHeader(headers[i]));
      }
      await file.writeFrom(w.takeBytes());
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> saveBlocks(List<Block> blocks) async {
    if (blocks.isEmpty) return;
    final w = ByteWriter();
    for (final b in blocks) {
      w.vec(encodeBlock(b));
    }
    await _blocksFile.writeAsBytes(w.take(), mode: FileMode.append);
  }

  @override
  Future<void> saveContents(Map<String, Uint8List> contents) async {
    if (contents.isEmpty) return;
    final w = ByteWriter();
    contents.forEach((hash, content) => w
      ..bytes(fromHex(hash))
      ..vec(content));
    await _contentsFile.writeAsBytes(w.take(), mode: FileMode.append);
  }

  @override
  Future<void> removeContents(Set<String> hashes) async {
    if (hashes.isEmpty || !await _contentsFile.exists()) return;
    // The log is append-only: rewrite it without those records.
    final kept = ByteWriter();
    final r = ByteReader(await _contentsFile.readAsBytes());
    try {
      while (true) {
        final hash = r.hash32();
        final content = r.vec();
        if (!hashes.contains(toHex(hash))) {
          kept
            ..bytes(hash)
            ..vec(content);
        }
      }
    } on FormatException {
      // End of the log.
    }
    await _contentsFile.writeAsBytes(kept.take());
  }

  @override
  Future<void> dropBlocksAbove(int height) async {
    if (!await _blocksFile.exists()) return;
    final kept = ByteWriter();
    final r = ByteReader(await _blocksFile.readAsBytes());
    try {
      while (true) {
        final bytes = r.vec();
        if (decodeBlock(bytes).header.height <= height) kept.vec(bytes);
      }
    } on FormatException {
      // End of the log.
    }
    await _blocksFile.writeAsBytes(kept.take());
  }

  @override
  Future<void> clear() async {
    for (final f in [_genesisFile, _headersFile, _blocksFile, _contentsFile]) {
      if (await f.exists()) await f.delete();
    }
  }
}
