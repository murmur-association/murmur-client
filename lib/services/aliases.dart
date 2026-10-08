// An address's public name, PROTOCOL.md Section 7.8. The chain records
// which message is an address's name (the state's Name entry: the hash of
// its latest Name transaction's content); what the message says is content,
// in a format that is a convention between clients. The client proves the
// entry, fetches the content by that hash and checks it; this reads it.

import 'dart:typed_data';

import '../protocol/alias.dart';
import '../protocol/models.dart';

/// The name `content` (a Name's content, already checked against the hash
/// the state holds) gives its address, or null for none: an empty name
/// clears the one before, and anything that isn't a valid name message is
/// no name. There is never an older one to fall back on.
String? nameIn(Uint8List content) {
  if (content.length != aliasContentSize) return null;
  final name = aliasOf(messageOf(content));
  return name == null || name.isEmpty ? null : name;
}
