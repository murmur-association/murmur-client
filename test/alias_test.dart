// Aliases, PROTOCOL.md Section 7.8: the message format and its checks, and
// resolving an address's alias without ever showing a replaced one.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/alias.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/profile.dart';
import 'package:murmur_client/services/aliases.dart';

/// A Name's content carrying `message`, salted.
Uint8List _content(Uint8List message) => saltedContent(message);

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

  test('the name in a Name\'s content: valid, cleared, or none', () {
    expect(nameIn(_content(aliasMessage('bob'))), 'bob');
    expect(nameIn(_content(aliasMessage(''))), isNull, reason: 'an empty name clears the one before');
    // An ordinary 71-byte message, and content of another length: no name.
    expect(nameIn(_content(Uint8List(aliasMessageLength)..fillRange(0, aliasMessageLength, 0x61))), isNull);
    expect(nameIn(_content(Uint8List.fromList(utf8.encode('bob')))), isNull);
    expect(nameIn(Uint8List(aliasContentSize)), isNull);
  });

  test("a profile's name and picture; an alias has no picture", () {
    final picture = ProfilePicture(
        [for (var i = 0; i < 16; i++) i * 0x111111], Uint8List.fromList([for (var i = 0; i < 1024; i++) i % 16]));
    final content = _content(profileMessage('bob', picture));
    expect(content.length, profileContentSize);
    expect(nameIn(content), 'bob');
    expect(pictureIn(content)!.pixels, picture.pixels);
    // A picture without a name: no name, but the picture.
    final pictureOnly = _content(profileMessage('', picture));
    expect(nameIn(pictureOnly), isNull);
    expect(pictureIn(pictureOnly), isNotNull);
    expect(pictureIn(_content(aliasMessage('bob'))), isNull);
    expect(pictureIn(Uint8List(profileContentSize)), isNull, reason: 'the length alone is not a profile');
    expect(isNameContentSize(aliasContentSize) && isNameContentSize(profileContentSize), isTrue);
    expect(isNameContentSize(profileContentSize - 1), isFalse);
  });
}
