// The store of the user's own messages (services/own_messages.dart): kept
// in order, found again, and withdrawn ones removed.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/own_messages.dart';
import 'package:murmur_client/services/own_messages_io.dart';

OwnMessage _message(int i) => OwnMessage(
      txid: toHex(Uint8List(32)..fillRange(0, 32, i)),
      author: 'ab' * 32,
      content: Uint8List.fromList([...List.filled(16, i), 104, 105]),
      keptAt: 1000 + i,
    );

void main() {
  test('a record reads back as it was written, and a damaged one is refused', () {
    final m = _message(3);
    final back = OwnMessage.decode(m.encode())!;
    expect((back.txid, back.author, back.keptAt), (m.txid, m.author, m.keptAt));
    expect(back.content, m.content);
    expect(back.hash, toHex(sha256Bytes(m.content)), reason: 'what a node asks for it by');
    expect(OwnMessage.decode(Uint8List(10)), isNull);
  });

  test('the file keeps them in order, across sessions, and forgets the withdrawn', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-own');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/messages.log');
    final store = FileOwnMessages(file);
    expect(await store.load(), isEmpty);
    await store.add([_message(1), _message(2)]);
    await store.add([_message(3)]);
    // Another session finds them, in the order they were kept.
    expect((await FileOwnMessages(file).load()).map((m) => m.keptAt), [1001, 1002, 1003]);
    await store.remove({_message(2).txid});
    expect((await store.load()).map((m) => m.keptAt), [1001, 1003]);
    // A record cut short at the end (a crash while writing) loses only itself.
    await file.writeAsBytes([0, 0, 0, 99, 1, 2], mode: FileMode.append);
    expect((await store.load()).map((m) => m.keptAt), [1001, 1003]);
  });
}
