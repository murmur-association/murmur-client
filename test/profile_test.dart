// Profiles (protocol/profile.dart, proposed for PROTOCOL.md Section 7.8): the
// message format, its single form, and the vector given in the proposal.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/alias.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/profile.dart';

/// The proposal's example picture: colour `i` is (17i, 255 - 17i, 53i mod
/// 256), and pixel (x, y) takes colour (x + y) mod 16, a diagonal ramp.
ProfilePicture _example() => ProfilePicture(
      [for (var i = 0; i < 16; i++) (17 * i) * 0x10000 + (255 - 17 * i) * 0x100 + (53 * i) % 256],
      Uint8List.fromList([for (var y = 0; y < 32; y++) for (var x = 0; x < 32; x++) (x + y) % 16]),
    );

void main() {
  test("the proposal's example: bob and a diagonal ramp", () {
    final message = profileMessage('bob', _example());
    expect(message.length, 633);
    expect(toHex(message.sublist(0, 12)), '0070726f66696c653a626f62');
    expect(message.sublist(12, 73).every((b) => b == 0), isTrue, reason: 'the name padded to 64 bytes');
    expect(toHex(message.sublist(73, 79)), '00ff0011ee35', reason: 'the first two colours');
    expect(toHex(message.sublist(121, 125)), '01234567', reason: 'the first row, two pixels to a byte');
    expect(sha256.convert(message).toString(), '1c002e3d097a682918db61735a25cd16b80d6d1cb532f2e1f82bd5ac6952c710');
    expect(isNonText(message), isTrue);

    final profile = profileOf(message)!;
    expect(profile.name, 'bob');
    expect(profile.picture.pixels, _example().pixels);
    expect(profile.picture.palette, _example().palette);
    expect(profile.picture.rgbAt(1, 0), 0x11ee35);
  });

  test('a picture without a name', () {
    expect(profileOf(profileMessage('', _example()))!.name, '');
  });

  test('one form: any other length, prefix or padding is not a profile', () {
    final message = profileMessage('bob', _example());
    expect(profileOf(message.sublist(0, 632)), isNull);
    expect(profileOf(message.sublist(0, 73)), isNull, reason: 'a name alone is an alias');
    expect(profileOf(Uint8List.fromList([...message, 0])), isNull);
    expect(profileOf(Uint8List.fromList([...message]..[1] = 0x50)), isNull, reason: 'prefix');
    expect(profileOf(Uint8List.fromList([...message]..[40] = 0x41)), isNull, reason: 'a byte after the padding');
    final rtl = Uint8List.fromList([...message]..setAll(9, [0x61, 0xe2, 0x80, 0xae]));
    expect(profileOf(rtl), isNull, reason: 'the name follows the alias rules');
  });

  test('an alias is not a profile, nor a profile an alias', () {
    expect(profileOf(aliasMessage('bob')), isNull);
    expect(aliasOf(profileMessage('bob', _example())), isNull);
  });

  test('a picture is 32 x 32 indices of 16 colours', () {
    expect(() => ProfilePicture(List.filled(15, 0), Uint8List(1024)), throwsArgumentError);
    expect(() => ProfilePicture(List.filled(16, 0), Uint8List(1023)), throwsArgumentError);
    expect(() => ProfilePicture(List.filled(16, 0), Uint8List(1024)..[5] = 16), throwsArgumentError);
    expect(() => profileMessage('bob ', _example()), throwsArgumentError);
  });
}
