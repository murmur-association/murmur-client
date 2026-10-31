// The user's own messages as a file, for native builds:
// murmur-client/own/messages.log, (length:u32 ‖ record) one after another.
// On a desktop it sits beside the chain cache, in the user's application
// data folder; on a phone in the app's support folder, not its cache folder:
// the system may clear a cache, and this is kept for good.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../protocol/bytes.dart';
import 'chain_cache_io.dart' show chainCacheBase;
import 'own_messages.dart';

Future<OwnMessageStore> openOwnMessages() async {
  final phone = Platform.isAndroid || Platform.isIOS;
  final sep = Platform.pathSeparator;
  final base = chainCacheBase(
    phone: phone,
    env: Platform.environment,
    temp: Directory.systemTemp.path,
    appCache: phone ? (await getApplicationSupportDirectory()).path : null,
  );
  final dir = Directory('$base${sep}murmur-client${sep}own');
  await dir.create(recursive: true);
  return FileOwnMessages(File('${dir.path}${sep}messages.log'));
}

/// The store in `file` (public so tests can use a temporary one).
class FileOwnMessages implements OwnMessageStore {
  FileOwnMessages(this._file);

  final File _file;

  @override
  Future<List<OwnMessage>> load() async {
    if (!await _file.exists()) return [];
    final r = ByteReader(await _file.readAsBytes());
    final out = <OwnMessage>[];
    try {
      while (true) {
        final m = OwnMessage.decode(r.vec());
        if (m != null) out.add(m);
      }
    } on FormatException {
      // The end, or a record cut short: what came before is kept.
    }
    return out;
  }

  Uint8List _records(Iterable<OwnMessage> messages) {
    final w = ByteWriter();
    for (final m in messages) {
      w.vec(m.encode());
    }
    return w.take();
  }

  @override
  Future<void> add(List<OwnMessage> messages) async {
    if (messages.isEmpty) return;
    await _file.writeAsBytes(_records(messages), mode: FileMode.append, flush: true);
  }

  @override
  Future<void> remove(Set<String> txids) async {
    if (txids.isEmpty) return;
    final kept = (await load()).where((m) => !txids.contains(m.txid));
    await _file.writeAsBytes(_records(kept), flush: true);
  }
}
