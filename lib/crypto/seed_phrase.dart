// A wallet seed as words: the 24-word BIP39 encoding of its 32 bytes, for
// people who'd rather write down, read out or type words than 64 hex
// characters. The hex seed is what the node's key files hold; the phrase is
// the same 32 bytes, nothing more.
//
// The encoding is BIP39's own (the seed is the "entropy": its 256 bits and
// an 8-bit checksum, the first byte of its SHA-256, cut into 24 groups of
// 11 bits, each a word of the list), so other tools can turn a phrase back
// into the bytes. It stops there: BIP39's second step, stretching the
// phrase into a different key with PBKDF2, is not used. A phrase from
// another wallet app therefore doesn't open that app's accounts here; it
// gives a Murmur wallet of its own.
//
// English words only, as most BIP39 tools read.

import 'dart:typed_data';

import '../protocol/bytes.dart';
import 'seed_words.dart';

/// Why some text isn't a seed.
enum SeedProblem {
  /// Neither 64 hex characters nor 24 words.
  format,

  /// A word that isn't in the list: `word` says which.
  unknownWord,

  /// 24 known words whose checksum doesn't match: a wrong or misplaced word.
  checksum,
}

/// A seed read from text, or what's wrong with the text.
class SeedInput {
  const SeedInput.seed(Uint8List this.seed)
      : problem = null,
        word = null;
  const SeedInput.problem(SeedProblem this.problem, {this.word}) : seed = null;

  final Uint8List? seed;
  final SeedProblem? problem;

  /// The word not in the list, for [SeedProblem.unknownWord].
  final String? word;
}

final Map<String, int> _indexOf = {for (var i = 0; i < seedWords.length; i++) seedWords[i]: i};

/// The 24 words for a 32-byte seed, separated by spaces.
String seedPhrase(Uint8List seed) {
  if (seed.length != 32) throw ArgumentError('a seed is 32 bytes');
  final bytes = [...seed, sha256Bytes(seed)[0]]; // 264 bits
  final words = <String>[];
  for (var w = 0; w < 24; w++) {
    var index = 0;
    for (var bit = w * 11; bit < (w + 1) * 11; bit++) {
      index = index * 2 + ((bytes[bit ~/ 8] >> (7 - bit % 8)) & 1);
    }
    words.add(seedWords[index]);
  }
  return words.join(' ');
}

/// The seed in `text`: 64 hex characters, or its 24 words (in any case,
/// with any spacing).
SeedInput parseSeed(String text) {
  final trimmed = text.trim();
  final hex = tryParseHash32(trimmed.toLowerCase());
  if (hex != null) return SeedInput.seed(hex);
  final words = trimmed.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length != 24) return const SeedInput.problem(SeedProblem.format);
  final bytes = Uint8List(33);
  for (var w = 0; w < 24; w++) {
    final index = _indexOf[words[w]];
    if (index == null) return SeedInput.problem(SeedProblem.unknownWord, word: words[w]);
    for (var b = 0; b < 11; b++) {
      if ((index >> (10 - b)) & 1 == 1) {
        final bit = w * 11 + b;
        bytes[bit ~/ 8] |= 1 << (7 - bit % 8);
      }
    }
  }
  final seed = Uint8List.sublistView(bytes, 0, 32);
  if (sha256Bytes(seed)[0] != bytes[32]) return const SeedInput.problem(SeedProblem.checksum);
  return SeedInput.seed(Uint8List.fromList(seed));
}
