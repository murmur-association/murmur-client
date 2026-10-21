// An address's public name and picture, PROTOCOL.md Section 7.8. The chain
// records which message is an address's name (the state's Name entry: the
// hash of its latest Name transaction's content); what the message says is
// content, in a format that is a convention between clients: an alias (a
// name alone) or a profile (a name and a picture). The client proves the
// entry, fetches the content by that hash and checks it; this reads it.

import 'dart:typed_data';

import '../protocol/alias.dart';
import '../protocol/models.dart';
import '../protocol/profile.dart';

/// Whether `content` has the length of a Name's content: an alias's or a
/// profile's. Anything else is no name, and isn't worth keeping.
bool isNameContentSize(int length) => length == aliasContentSize || length == profileContentSize;

/// The name `content` (a Name's content, already checked against the hash
/// the state holds) gives its address, or null for none: an empty name
/// clears the one before, and anything that isn't a valid alias or profile
/// is no name. There is never an older one to fall back on.
String? nameIn(Uint8List content) {
  final name = switch (content.length) {
    aliasContentSize => aliasOf(messageOf(content)),
    profileContentSize => profileOf(messageOf(content))?.name,
    _ => null,
  };
  return name == null || name.isEmpty ? null : name;
}

/// The picture `content` gives its address, or null for none: only a
/// profile has one.
ProfilePicture? pictureIn(Uint8List content) =>
    content.length == profileContentSize ? profileOf(messageOf(content))?.picture : null;
