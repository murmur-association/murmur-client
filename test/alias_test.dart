// Aliases, PROTOCOL.md Section 7.8: the message format and its checks, and
// resolving an address's alias without ever showing a replaced one.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/alias.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/aliases.dart';
import 'package:murmur_client/services/node_client.dart';

final _me = Uint8List(32)..fillRange(0, 32, 7);
var _serial = 0;

/// A mined Orphan of the alias length at `height` carrying `message`
/// (salted), or with no content at hand when `message` is null.
(TxView, Uint8List?) _candidate(int height, Uint8List? message) {
  final content = message == null ? Uint8List(aliasContentSize) : saltedContent(message);
  final tx = Transaction(
    kind: TxKind.orphan,
    from: _me,
    nonce: ++_serial,
    to: null,
    amount: 10,
    fee: 1,
    messageHash: sha256Bytes(content),
    contentSize: aliasContentSize,
    reference: null,
    timestamp: 1790208000,
    pubkey: Uint8List(32),
    signature: Uint8List(64)..buffer.asByteData().setUint32(0, _serial),
  );
  return (TxView(tx, height: height, blockTime: 1790208000 + height), message == null ? null : content);
}

/// Resolves candidates given latest first, with every block fetched unless
/// listed in `missing`.
String? _resolve(List<(TxView, Uint8List?)> candidates, {int tip = 100, Set<int> missing = const {}}) {
  final contents = {for (final (v, c) in candidates) v.tx.id: c};
  return resolveAlias([for (final (v, _) in candidates) v],
      tip: tip, unknown: missing.contains, contentOf: (v) => contents[v.tx.id]);
}

void main() {
  test('the example of Section 7.8: bob', () {
    final message = aliasMessage('bob');
    expect(message.length, 71);
    expect(toHex(message.sublist(0, 10)), '00616c6961733a626f62');
    expect(message.sublist(10).every((b) => b == 0), isTrue);
    expect(aliasOf(message), 'bob');
    expect(isNonText(message), isTrue);
    expect(saltLength + message.length, aliasContentSize);
  });

  test('names: 64 bytes at most, no control or invisible characters, no edge spaces', () {
    expect(aliasOf(aliasMessage('')), '', reason: 'empty clears');
    expect(aliasOf(aliasMessage('Ñandú 🐦 名前')), 'Ñandú 🐦 名前');
    expect(aliasProblem('a' * 64), isNull);
    expect(aliasProblem('a' * 65), AliasProblem.tooLong);
    expect(aliasProblem('é' * 33), AliasProblem.tooLong, reason: '66 bytes');
    for (final bad in ['a\tb', 'a\u0085b', 'soft\u00ADhyphen', 'zero\u200Bwidth', 'rtl\u202Eoverride', 'word\u2060joiner', '\uFEFFbom']) {
      expect(aliasProblem(bad), AliasProblem.forbiddenCharacter, reason: bad);
    }
    expect(aliasProblem(' bob'), AliasProblem.edgeSpace);
    expect(aliasProblem('bob '), AliasProblem.edgeSpace);
    expect(() => aliasMessage('bob '), throwsArgumentError);
  });

  test('what is not an alias', () {
    Uint8List raw(List<int> name, {int length = aliasMessageLength}) =>
        Uint8List(length)..setAll(0, [...aliasPrefix, ...name]);
    expect(aliasOf(raw(utf8.encode('bob'), length: 70)), isNull, reason: 'wrong length');
    expect(aliasOf(raw([...utf8.encode('bob'), 0, 0x41])), isNull, reason: 'bytes after the padding starts');
    expect(aliasOf(raw([0xC3, 0x28])), isNull, reason: 'invalid UTF-8');
    expect(aliasOf(raw([0xED, 0xA0, 0x80])), isNull, reason: 'an encoded surrogate is not UTF-8');
    expect(aliasOf(raw(utf8.encode(' bob'))), isNull);
    expect(aliasOf(Uint8List(71)..setAll(0, [0x00, ...utf8.encode('alias;bob')])), isNull, reason: 'other prefix');
    // Section 2.4: not text, alias or not.
    expect(isNonText(Uint8List.fromList([0, 1, 2])), isTrue);
    expect(isNonText(Uint8List.fromList(utf8.encode('hello'))), isFalse);
  });

  test('resolving: the latest alias wins, and an empty one clears it', () {
    expect(_resolve([_candidate(50, aliasMessage('new')), _candidate(20, aliasMessage('old'))]), 'new');
    expect(_resolve([_candidate(50, aliasMessage('')), _candidate(20, aliasMessage('old'))]), isNull);
    expect(_resolve(const []), isNull);
  });

  test('resolving: an ordinary 71-byte message is skipped', () {
    final text = Uint8List(aliasMessageLength)..fillRange(0, aliasMessageLength, 0x61);
    expect(_resolve([_candidate(50, text), _candidate(20, aliasMessage('old'))]), 'old');
  });

  test('resolving: content that is gone means no known alias, never the older one', () {
    expect(_resolve([_candidate(50, null), _candidate(20, aliasMessage('old'))]), isNull);
  });

  test('resolving: a block not fetched above the alias could hold a newer one', () {
    final c = [_candidate(20, aliasMessage('bob'))];
    expect(_resolve(c, missing: {60}), isNull);
    expect(_resolve(c, missing: {20}), isNull, reason: 'a later transaction in its own block');
    expect(_resolve(c, missing: {10}), 'bob', reason: 'older blocks don\'t matter');
  });

  test('resolving: within a block, the later position wins', () {
    expect(_resolve([_candidate(30, aliasMessage('later')), _candidate(30, aliasMessage('earlier'))]), 'later');
  });
}
