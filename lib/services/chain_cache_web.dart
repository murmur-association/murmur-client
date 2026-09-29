// The chain cache in the browser's IndexedDB. Stores:
// - meta: 'genesis' -> the network's genesis hash (hex);
// - headers: chunk index -> up to [_chunk] headers, concatenated;
// - blocks: height -> block;
// - contents: message hash (hex) -> content.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../protocol/models.dart';
import '../protocol/wire.dart';
import 'chain_cache.dart';

const _dbName = 'murmur-chain';
const _chunk = 1000;
const _stores = ['meta', 'headers', 'blocks', 'contents'];

Future<ChainCache> openChainCache() async {
  final request = web.window.indexedDB.open(_dbName, 1);
  request.onupgradeneeded = ((web.Event _) {
    final db = request.result as web.IDBDatabase;
    for (final s in _stores) {
      db.createObjectStore(s);
    }
  }).toJS;
  final db = await _result(request) as web.IDBDatabase;
  return _WebChainCache(db);
}

Future<JSAny?> _result(web.IDBRequest r) {
  final done = Completer<JSAny?>();
  r.onsuccess = ((web.Event _) => done.complete(r.result)).toJS;
  r.onerror = ((web.Event _) => done.completeError(StateError('IndexedDB: ${r.error?.message}'))).toJS;
  return done.future;
}

Future<void> _finished(web.IDBTransaction t) {
  final done = Completer<void>();
  t.oncomplete = ((web.Event _) => done.complete()).toJS;
  t.onerror = ((web.Event _) => done.completeError(StateError('IndexedDB: ${t.error?.message}'))).toJS;
  return done.future;
}

/// Calls `f` with each key and value of `store`, in key order.
Future<void> _each(web.IDBObjectStore store, void Function(JSAny? key, JSAny? value) f) {
  final done = Completer<void>();
  final r = store.openCursor();
  r.onsuccess = ((web.Event _) {
    final result = r.result;
    if (result == null) {
      done.complete();
      return;
    }
    final cursor = result as web.IDBCursorWithValue;
    try {
      f(cursor.key, cursor.value);
    } catch (e) {
      // Thrown here, inside an event handler, it would never reach the
      // caller, which would wait forever.
      if (!done.isCompleted) done.completeError(e);
      return;
    }
    cursor.continue_();
  }).toJS;
  r.onerror = ((web.Event _) => done.completeError(StateError('IndexedDB: ${r.error?.message}'))).toJS;
  return done.future;
}

Uint8List _bytes(JSAny? v) => (v as JSUint8Array).toDart;

class _WebChainCache implements ChainCache {
  _WebChainCache(this._db);

  final web.IDBDatabase _db;

  web.IDBTransaction _tx(List<String> stores, [String mode = 'readonly']) =>
      _db.transaction([for (final s in stores) s.toJS].toJS, mode);

  Future<String?> _genesis() async {
    final stored = await _result(_tx(['meta']).objectStore('meta').get('genesis'.toJS));
    return stored == null ? null : (stored as JSString).toDart;
  }

  // Each transaction issues all its requests before anything is awaited:
  // IndexedDB commits a transaction once it has no requests left, and some
  // browsers do so between awaits.

  @override
  Future<CachedChain?> load(String genesis) async {
    if (await _genesis() != genesis) return null;
    final t = _tx(['headers', 'blocks', 'contents']);
    final headerChunks = BytesBuilder(copy: false);
    final blocks = <int, Block>{};
    final contents = <String, Uint8List>{};
    await Future.wait([
      _each(t.objectStore('headers'), (_, v) => headerChunks.add(_bytes(v))),
      _each(t.objectStore('blocks'), (k, v) {
        try {
          blocks[(k as JSNumber).toDartInt] = decodeBlock(_bytes(v));
        } on FormatException {
          // A damaged record: that block is fetched again when needed.
        }
      }),
      _each(t.objectStore('contents'), (k, v) => contents[(k as JSString).toDart] = _bytes(v)),
    ]);
    final all = headerChunks.takeBytes();
    final headers = [
      for (var i = 0; i + headerBytes <= all.length; i += headerBytes)
        decodeHeader(Uint8List.sublistView(all, i, i + headerBytes)),
    ];
    return CachedChain(headers, blocks, contents);
  }

  @override
  Future<void> saveHeaders(String genesis, List<BlockHeader> headers, int changedFrom) async {
    final sameNetwork = await _genesis() == genesis;
    final t = _tx(_stores, 'readwrite');
    if (!sameNetwork) {
      for (final s in _stores) {
        t.objectStore(s).clear();
      }
      t.objectStore('meta').put(genesis.toJS, 'genesis'.toJS);
      changedFrom = 1;
    }
    final store = t.objectStore('headers');
    final first = (changedFrom - 1) ~/ _chunk;
    final chunks = (headers.length + _chunk - 1) ~/ _chunk;
    for (var c = first; c < chunks; c++) {
      final w = BytesBuilder(copy: false);
      for (var i = c * _chunk; i < headers.length && i < (c + 1) * _chunk; i++) {
        w.add(encodeHeader(headers[i]));
      }
      store.put(w.takeBytes().toJS, c.toJS);
    }
    store.delete(web.IDBKeyRange.lowerBound(chunks.toJS));
    await _finished(t);
  }

  @override
  Future<void> saveBlocks(List<Block> blocks) async {
    if (blocks.isEmpty) return;
    final t = _tx(['blocks'], 'readwrite');
    final store = t.objectStore('blocks');
    for (final b in blocks) {
      store.put(encodeBlock(b).toJS, b.header.height.toJS);
    }
    await _finished(t);
  }

  @override
  Future<void> saveContents(Map<String, Uint8List> contents) async {
    if (contents.isEmpty) return;
    final t = _tx(['contents'], 'readwrite');
    final store = t.objectStore('contents');
    contents.forEach((hash, content) => store.put(content.toJS, hash.toJS));
    await _finished(t);
  }

  @override
  Future<void> removeContents(Set<String> hashes) async {
    if (hashes.isEmpty) return;
    final t = _tx(['contents'], 'readwrite');
    final store = t.objectStore('contents');
    for (final hash in hashes) {
      store.delete(hash.toJS);
    }
    await _finished(t);
  }

  @override
  Future<void> dropBlocksAbove(int height) async {
    final t = _tx(['blocks'], 'readwrite');
    t.objectStore('blocks').delete(web.IDBKeyRange.lowerBound(height.toJS, true));
    await _finished(t);
  }

  @override
  Future<void> clear() async {
    final t = _tx(_stores, 'readwrite');
    for (final s in _stores) {
      t.objectStore(s).clear();
    }
    await _finished(t);
  }
}
