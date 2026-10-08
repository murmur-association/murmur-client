// A header's nonce is any 64-bit value (PROTOCOL.md Section 3.1): a miner
// may start anywhere, and murmur-miner starts at random. It's carried as its
// 8 bytes from the wire to the hash, never as an `int`, which rounds from
// 2^53 in a browser and wraps from 2^63 elsewhere: read that way, a valid
// block hashed to something else and was refused.
//
// Both platforms failed, at different values, so these checks run on both:
// on the Dart VM with the unit tests (test/header_nonce_test.dart), and in
// a browser with the acceptance tests, inside the app on every flavour
// (acceptance_test.dart). They live here because a browser build can only
// import from beside the test it compiles.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/wire.dart';

/// The header of PROTOCOL.md Section 3.1 as sent on the wire: testnet-9's
/// block 27802, the first a browser refused, in the 248-byte layout. Its
/// nonce (bytes 208 to 215, 55e96d778ea4c761) is above 2^53. It tests the
/// hash alone: it doesn't meet its target.
const _block27802 = '0000000000006c9a0000003fbddd247dcc70a4a380e4d961de600da963d41c611400d4720bb0f10b'
    '0000000000000000000000000000000000000000000000000000000000000000'
    'f34c0e6bf382756779500d39a00a7821af4cc162825b1de8b3de4a3b1e69ea98'
    'df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b81119'
    '04717153a74686397cb63948d8a5f406af099169adaee20b435347433f4fead3'
    '000000006ac64dd6000001c0c0490469817b48c4f6d1a867ffffffffffffffff'
    'ffffffffffffffff55e96d778ea4c7617c2d9aee91b740ba61aa4ef61e0f853f'
    '67c3a292b065f1b3b77b6068066fee28';

/// That header with another nonce (8 bytes, hex, big-endian as on the wire).
Uint8List _withNonce(String nonce) => fromHex(_block27802.replaceRange(416, 432, nonce));

void headerNonceTests() {
  test('a header with a nonce above 2^53 keeps its hash', () {
    final bytes = fromHex(_block27802);
    expect(bytes.length, headerBytes);
    final header = decodeHeader(bytes);
    expect(header.height, 27802);
    expect(toHex(header.nonce), '55e96d778ea4c761');
    expect(toHex(header.target), '000001c0c0490469817b48c4f6d1a867ffffffffffffffffffffffffffffffff',
        reason: 'all 32 bytes of the target');
    expect(header.id, 'c4281183b93686debedc6f05c86c7c609707fd43cf1ec1d27d62f08602e79116');
    expect(encodeHeader(header), bytes, reason: 'and goes back on the wire as it came');
  });

  test('nonces with the top bit set, and the largest, hash as the node hashes them', () {
    for (final (nonce, hash) in [
      // 2^63 + 12345: the Dart VM read it as 8000000100003039.
      ('8000000000003039', 'b7b4c3b69bc837a374d7a1c8ab6685b7b2e8f751b718286328c42e90dad06881'),
      // 2^64 - 1: the Dart VM read it as 00000000ffffffff.
      ('ffffffffffffffff', '6745c5eed4a53f7df3a51644e83ad33151de91539a0a6f1b60f068d2e894aad7'),
    ]) {
      final bytes = _withNonce(nonce);
      final header = decodeHeader(bytes);
      expect(toHex(header.nonce), nonce);
      expect(header.id, hash, reason: 'nonce $nonce');
      expect(encodeHeader(header), bytes);
    }
  });

  test('a small nonce is the same header as before', () {
    expect(u64Bytes(0), Uint8List(8));
    expect(toHex(u64Bytes(42)), '000000000000002a');
    expect(toHex(u64Bytes(0x200000001)), '0000000200000001');
  });

  test('a number of 2^53 or more is refused where a number is read, not rounded', () {
    int read(String hex) => ByteReader(fromHex(hex)).u64();
    expect(read('001fffffffffffff'), 9007199254740991, reason: '2^53 - 1, the largest exact everywhere');
    for (final tooLarge in ['0020000000000000', '55e96d778ea4c761', '8000000000003039', 'ffffffffffffffff']) {
      expect(() => read(tooLarge), throwsFormatException, reason: tooLarge);
    }
    // So a header claiming such a height or time is bad data, not a number
    // that quietly became another.
    expect(() => decodeHeader(fromHex(_block27802.replaceRange(0, 16, 'ffffffffffffffff'))), throwsFormatException);
  });

  test("a peer's Hello carries any 64-bit nonce", () {
    for (final nonce in ['ffffffffffffffff', '8000000000003039', '0000000000000001']) {
      final hello = Hello(
          version: 11, genesis: Uint8List(32), nonce: fromHex(nonce), listenPort: 7878, height: 5, work: BigInt.two);
      final back = decodeMessage(encodePayload(hello)) as Hello;
      expect(toHex(back.nonce), nonce);
      expect((back.version, back.listenPort, back.height, back.work), (11, 7878, 5, BigInt.two));
    }
  });
}
