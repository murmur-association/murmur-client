// Aliases, PROTOCOL.md Section 7.8 (a client convention, not consensus): an
// address names itself with an Orphan whose message is exactly
// `0x00 ‖ "alias:" ‖ name ‖ 0x00 padding` (71 bytes). And Section 2.4: a
// message whose first byte is 0x00 isn't text.

import 'dart:convert';
import 'dart:typed_data';

import 'models.dart';

/// An alias message's fixed length.
const aliasMessageLength = 71;

/// Every alias transaction's `content_size`: the salt and the message.
const aliasContentSize = saltLength + aliasMessageLength;

/// `0x00 ‖ "alias:"`.
const aliasPrefix = [0x00, 0x61, 0x6c, 0x69, 0x61, 0x73, 0x3a];

/// The longest name, in UTF-8 bytes.
const maxAliasBytes = aliasMessageLength - 7;

/// Section 2.4: a message whose first byte is 0x00 is reserved for client
/// conventions. It isn't shown as a thread, nor replied to.
bool isNonText(Uint8List message) => message.isNotEmpty && message[0] == 0x00;

/// Why a name can't be an alias.
enum AliasProblem { tooLong, forbiddenCharacter, edgeSpace }

/// Code points no alias may hold: control characters, and invisible ones
/// and bidirectional overrides, which can make one name look like another.
bool _forbidden(int c) =>
    c <= 0x1F ||
    (c >= 0x7F && c <= 0x9F) ||
    c == 0xAD ||
    (c >= 0x200B && c <= 0x200F) ||
    (c >= 0x2028 && c <= 0x202E) ||
    (c >= 0x2060 && c <= 0x206F) ||
    c == 0xFEFF;

/// What's wrong with `name` as an alias, or null if nothing (an empty name
/// is fine: it clears the alias).
AliasProblem? aliasProblem(String name) {
  if (utf8.encode(name).length > maxAliasBytes) return AliasProblem.tooLong;
  if (name.runes.any(_forbidden)) return AliasProblem.forbiddenCharacter;
  if (name.startsWith(' ') || name.endsWith(' ')) return AliasProblem.edgeSpace;
  return null;
}

/// The 71-byte message setting `name` as the sender's alias (the client
/// salts it like any message). Throws [ArgumentError] for an invalid name.
Uint8List aliasMessage(String name) {
  final problem = aliasProblem(name);
  if (problem != null) throw ArgumentError.value(name, 'name', problem.name);
  return Uint8List(aliasMessageLength)
    ..setAll(0, aliasPrefix)
    ..setAll(aliasPrefix.length, utf8.encode(name));
}

/// The name an alias message sets ('' when it clears the alias), or null
/// if `message` isn't a valid alias. Byte and code-point checks only, so
/// every client reaches the same result.
String? aliasOf(Uint8List message) {
  if (message.length != aliasMessageLength) return null;
  for (var i = 0; i < aliasPrefix.length; i++) {
    if (message[i] != aliasPrefix[i]) return null;
  }
  var end = aliasPrefix.length;
  while (end < message.length && message[end] != 0) {
    end++;
  }
  // Only padding after the name.
  for (var i = end; i < message.length; i++) {
    if (message[i] != 0) return null;
  }
  final String name;
  try {
    name = utf8.decode(Uint8List.sublistView(message, aliasPrefix.length, end));
  } on FormatException {
    return null;
  }
  return aliasProblem(name) == null ? name : null;
}
