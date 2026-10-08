// Murmur emoji: a client convention, like aliases (PROTOCOL.md Section 7.8),
// with nothing of it in the protocol. A message stays ordinary text; a name
// between colons, such as ":name:", is drawn by this client as one of its own
// glyphs once the client has one by that name (ui/emoji.dart). Any other
// client shows the name, which still reads.

final _code = RegExp(':([a-z]+):');

/// `text` cut into pieces in order: plain text (`emoji` null), and emoji
/// (`emoji` is the name) with the code they were written as. Joined, the
/// pieces' texts give `text` back. Only a name in `names` is an emoji:
/// anything else between colons stays text.
List<({String text, String? emoji})> emojiPieces(String text, Set<String> names) {
  if (names.isEmpty) return [if (text.isNotEmpty) (text: text, emoji: null)];
  final pieces = <({String text, String? emoji})>[];
  var plainFrom = 0, searchFrom = 0;
  while (true) {
    final match = _code.allMatches(text, searchFrom).firstOrNull;
    if (match == null) break;
    final name = match.group(1)!;
    if (!names.contains(name)) {
      // Its closing colon may open the next one (":a:name:").
      searchFrom = match.end - 1;
      continue;
    }
    if (match.start > plainFrom) pieces.add((text: text.substring(plainFrom, match.start), emoji: null));
    pieces.add((text: match.group(0)!, emoji: name));
    plainFrom = searchFrom = match.end;
  }
  if (plainFrom < text.length) pieces.add((text: text.substring(plainFrom), emoji: null));
  return pieces;
}

/// An emoji as written in a message: its name between colons.
String emojiCode(String name) => ':$name:';
