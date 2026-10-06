// A seed as 24 words (lib/crypto/seed_phrase.dart): the BIP39 encoding,
// checked against the standard's own test vectors.

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/seed_phrase.dart';
import 'package:murmur_client/crypto/seed_words.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';

void main() {
  test('the word list is the standard one, unchanged', () {
    expect(seedWords, hasLength(2048));
    // As published: one word a line.
    final published = seedWords.map((w) => '$w\n').join();
    expect(sha256.convert(published.codeUnits).toString(),
        '2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda');
    // Never sorted or edited, and no file of it left behind.
    expect(seedWords.first, 'abandon');
    expect(seedWords.last, 'zoo');
    expect(File('lib/crypto/seed_words.dart').existsSync(), isTrue);
  });

  // BIP39's test vectors for 256 bits (github.com/trezor/python-mnemonic,
  // vectors.json): entropy and its words.
  const vectors = {
    '0000000000000000000000000000000000000000000000000000000000000000':
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art',
    '7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f':
        'legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful '
            'legal winner thank year wave sausage worth title',
    '8080808080808080808080808080808080808080808080808080808080808080':
        'letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor '
            'acoustic avoid letter advice cage absurd amount doctor acoustic bless',
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff':
        'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote',
    '68a79eaca2324873eacc50cb9c6eca8cc68ea5d936f98787c60c7ebc74e6ce7c':
        'hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel '
            'tennis maple dilemma loan word shrug inflict delay length',
    'f585c11aec520db57dd353c69554b21a89b20fb0650966fa0a9d6f74fd989d8f':
        'void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen '
            'patrol group space point ten exist slush involve unfold',
  };

  test('a seed and its words: the standard vectors, both ways', () {
    vectors.forEach((hex, words) {
      expect(seedPhrase(fromHex(hex)), words);
      expect(toHex(parseSeed(words).seed!), hex);
    });
  });

  test('every seed comes back from its words', () {
    for (var i = 0; i < 200; i++) {
      final seed = Uint8List.fromList(List.generate(32, (b) => (i * 37 + b * 101 + i * b) & 0xff));
      final words = seedPhrase(seed);
      expect(words.split(' '), hasLength(24));
      expect(parseSeed(words).seed, seed);
    }
  });

  test('either form is read: hex, or words in any case and spacing', () {
    const hex = '7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f';
    final words = vectors[hex]!;
    expect(toHex(parseSeed('  $hex\n').seed!), hex);
    expect(toHex(parseSeed(hex.toUpperCase()).seed!), hex);
    expect(toHex(parseSeed('  ${words.toUpperCase().replaceAll(' ', '\n  ')}  ').seed!), hex);
  });

  test('what is wrong with a text is said', () {
    final words = vectors.values.first.split(' ');
    expect(parseSeed('').problem, SeedProblem.format);
    expect(parseSeed('abc123').problem, SeedProblem.format);
    expect(parseSeed(words.take(23).join(' ')).problem, SeedProblem.format, reason: 'a word short');
    final typo = parseSeed([...words.take(5), 'abandonn', ...words.skip(6)].join(' '));
    expect((typo.problem, typo.word), (SeedProblem.unknownWord, 'abandonn'));
    // A right word in the wrong place: the checksum catches it.
    expect(parseSeed([...words.take(23), 'zoo'].join(' ')).problem, SeedProblem.checksum);
    expect(parseSeed([words.last, ...words.take(23)].join(' ')).problem, SeedProblem.checksum);
  });

  test('the words open the same wallet as the hex seed', () async {
    final seed = fromHex(vectors.keys.elementAt(4));
    final fromHexSeed = await MurmurWallet.fromSeed(seed);
    final fromWords = await MurmurWallet.fromSeed(parseSeed(seedPhrase(seed)).seed!);
    expect(fromWords.addressHex, fromHexSeed.addressHex);
  });
}
