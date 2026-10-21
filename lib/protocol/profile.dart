// Profiles, PROTOCOL.md Section 7.8: a name and a small picture in one Name
// transaction. Like an alias it is a convention between clients: the chain
// records only which message is an address's latest Name, and a picture has
// to share that one slot with the name, or setting either would clear the
// other.
//
// message = 0x00 ‖ "profile:" ‖ name:64 ‖ palette:48 ‖ pixels:512   (633 bytes)
//
// - name: as an alias's (Section 7.8): UTF-8, then 0x00 padding to 64 bytes.
// - palette: 16 colours, each red, green, blue.
// - pixels: 32 x 32, rows from the top, each from the left, two to a byte,
//   the left one in the high four bits, each the index of its colour.
//
// A name without a picture stays an alias, which every client reads: a
// profile is sent only with a picture, and removing the picture sends an
// alias again.
//
// The picture is in a format of its own rather than PNG or WebP so that the
// app decodes what strangers publish with a few lines of Dart, not with an
// image codec, and so that a profile has a fixed length: any other is not a
// profile. (The same image under a reordered palette encodes differently.)

import 'dart:typed_data';

import 'alias.dart';
import 'models.dart';

/// `0x00 ‖ "profile:"`.
const profilePrefix = [0x00, 0x70, 0x72, 0x6f, 0x66, 0x69, 0x6c, 0x65, 0x3a];

/// A picture's side, in pixels.
const profileSide = 32;

/// The colours a picture holds.
const profileColours = 16;

/// Where the picture starts: after the prefix and the padded name.
const _pictureStart = 9 + maxAliasBytes;

/// A profile message's length.
const profileMessageLength = _pictureStart + profileColours * 3 + profileSide * profileSide ~/ 2;

/// Every profile transaction's `content_size`: the salt and the message.
const profileContentSize = saltLength + profileMessageLength;

/// A 32 x 32 picture of 16 colours.
class ProfilePicture {
  ProfilePicture(this.palette, this.pixels) {
    if (palette.length != profileColours) throw ArgumentError.value(palette.length, 'palette');
    if (pixels.length != profileSide * profileSide || pixels.any((p) => p >= profileColours)) {
      throw ArgumentError('32 x 32 indices below 16', 'pixels');
    }
  }

  /// The colours, as 0xRRGGBB.
  final List<int> palette;

  /// Each pixel's colour index, rows from the top.
  final Uint8List pixels;

  /// The pixel at (`x`, `y`), as 0xRRGGBB.
  int rgbAt(int x, int y) => palette[pixels[y * profileSide + x]];
}

/// What a profile message sets.
class Profile {
  const Profile(this.name, this.picture);

  /// The name ('' for none).
  final String name;

  final ProfilePicture picture;
}

/// The message setting `name` and `picture` as the sender's profile (salted
/// like any message). Throws [ArgumentError] for an invalid name.
Uint8List profileMessage(String name, ProfilePicture picture) {
  final out = Uint8List(profileMessageLength)
    ..setAll(0, profilePrefix)
    ..setAll(profilePrefix.length, aliasMessage(name).sublist(aliasPrefix.length));
  var o = _pictureStart;
  for (final rgb in picture.palette) {
    out[o++] = (rgb ~/ 0x10000) % 0x100;
    out[o++] = (rgb ~/ 0x100) % 0x100;
    out[o++] = rgb % 0x100;
  }
  for (var i = 0; i < picture.pixels.length; i += 2) {
    out[o++] = picture.pixels[i] * 16 + picture.pixels[i + 1];
  }
  return out;
}

/// The profile `message` sets, or null if it isn't one.
Profile? profileOf(Uint8List message) {
  if (message.length != profileMessageLength) return null;
  for (var i = 0; i < profilePrefix.length; i++) {
    if (message[i] != profilePrefix[i]) return null;
  }
  final name = paddedName(Uint8List.sublistView(message, profilePrefix.length, _pictureStart));
  if (name == null) return null;
  var o = _pictureStart;
  final palette = [
    for (var c = 0; c < profileColours; c++, o += 3) message[o] * 0x10000 + message[o + 1] * 0x100 + message[o + 2],
  ];
  final pixels = Uint8List(profileSide * profileSide);
  for (var i = 0; i < pixels.length; i += 2, o++) {
    pixels[i] = message[o] ~/ 16;
    pixels[i + 1] = message[o] % 16;
  }
  return Profile(name, ProfilePicture(palette, pixels));
}
