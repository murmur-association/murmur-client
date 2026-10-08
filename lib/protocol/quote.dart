// Quotes: a client convention, like aliases (PROTOCOL.md Section 7.8), with
// nothing of it in the protocol. Threads are flat: a Reply names its thread,
// not the message it answers. A reply that answers another reply says which
// in its text, with a line of its own before anything else:
//
//     >3fa9c21e
//     the answer
//
// `>` and the first eight hex characters of the answered reply's txid. The
// answered text is never copied: this client shows it from the thread. Any
// other client shows the line as written, which still reads as a quote.
// Several such lines, one after the other, answer several replies.

/// How many hex characters of a txid a quote holds.
const quoteIdLength = 8;

final _line = RegExp('^>([0-9a-f]{$quoteIdLength})\$');

/// The line that quotes the message `txid` (hex), with its line end.
String quoteLine(String txid) => '>${txid.substring(0, quoteIdLength)}\n';

/// A reply's text taken apart: the replies it quotes, each by the start of
/// its txid and in the order written, and what it says itself. Only whole
/// lines at the very start are quotes; the same anywhere else is text.
({List<String> quotes, String body}) quotesIn(String text) {
  final quotes = <String>[];
  var from = 0;
  while (true) {
    final end = text.indexOf('\n', from);
    final match = _line.firstMatch(end < 0 ? text.substring(from) : text.substring(from, end));
    if (match == null) break;
    quotes.add(match.group(1)!);
    from = end < 0 ? text.length : end + 1;
    if (end < 0) break;
  }
  return (quotes: quotes, body: text.substring(from));
}

/// Which reply a quote means: the oldest reply of the thread whose txid
/// starts with `quote`, among those before the quoting one. `earlier` are
/// the txids (hex) of the thread's replies before it, oldest first.
///
/// The oldest, so that a reply made later to share those characters can't
/// take a quote over; and never a later one, which the writer can't have
/// read.
String? quotedReply(Iterable<String> earlier, String quote) {
  for (final id in earlier) {
    if (id.startsWith(quote)) return id;
  }
  return null;
}
