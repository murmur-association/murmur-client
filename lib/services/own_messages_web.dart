// The user's own messages in the browser's IndexedDB: database
// murmur-own, store messages, txid (hex) -> record. Apart from the chain
// cache's database, which may be cleared at any time.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'own_messages.dart';

const _dbName = 'murmur-own';
const _store = 'messages';

Future<OwnMessageStore> openOwnMessages() async {
  final request = web.window.indexedDB.open(_dbName, 1);
  request.onupgradeneeded = ((web.Event _) {
    (request.result as web.IDBDatabase).createObjectStore(_store);
  }).toJS;
  return _WebOwnMessages(await _result(request) as web.IDBDatabase);
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

class _WebOwnMessages implements OwnMessageStore {
  _WebOwnMessages(this._db);

  final web.IDBDatabase _db;

  web.IDBObjectStore _open(String mode, void Function(web.IDBTransaction) onTransaction) {
    final t = _db.transaction(_store.toJS, mode);
    onTransaction(t);
    return t.objectStore(_store);
  }

  @override
  Future<List<OwnMessage>> load() async {
    final done = Completer<List<OwnMessage>>();
    final out = <OwnMessage>[];
    final r = _open('readonly', (_) {}).openCursor();
    r.onsuccess = ((web.Event _) {
      final result = r.result;
      if (result == null) {
        // Stored by txid; given back in the order they were kept.
        done.complete(out..sort((a, b) => a.keptAt.compareTo(b.keptAt)));
        return;
      }
      final cursor = result as web.IDBCursorWithValue;
      final m = OwnMessage.decode((cursor.value as JSUint8Array).toDart);
      if (m != null) out.add(m);
      cursor.continue_();
    }).toJS;
    r.onerror = ((web.Event _) => done.completeError(StateError('IndexedDB: ${r.error?.message}'))).toJS;
    return done.future;
  }

  @override
  Future<void> add(List<OwnMessage> messages) async {
    if (messages.isEmpty) return;
    late web.IDBTransaction t;
    final store = _open('readwrite', (x) => t = x);
    for (final m in messages) {
      store.put(m.encode().toJS, m.txid.toJS);
    }
    await _finished(t);
  }

  @override
  Future<void> remove(Set<String> txids) async {
    if (txids.isEmpty) return;
    late web.IDBTransaction t;
    final store = _open('readwrite', (x) => t = x);
    for (final txid in txids) {
      store.delete(txid.toJS);
    }
    await _finished(t);
  }
}
