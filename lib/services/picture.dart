// Turning an image the user picked into a profile picture (PROTOCOL.md
// Section 7.8): its middle square, shrunk to 32 x 32, reduced to 16 colours.
// The engine decodes the user's own file here; what others publish is never
// decoded by it (protocol/profile.dart reads those).
//
// Nothing is drawn: the decoded pixels are read and averaged here. Drawing
// the image and reading it back failed on a machine with software graphics
// (Windows' CI runner: "operation failed"), and left the dialog waiting.

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../protocol/profile.dart';

/// The largest file taken, in bytes: past it, a photo isn't worth decoding
/// for 32 x 32 pixels.
const maxPictureFileBytes = 20 * 1000 * 1000;

/// The shorter side an image is decoded at, at most: four pixels each way
/// per picture pixel.
const _decoded = profileSide * 4;

/// The profile picture made from an image file's bytes (PNG, JPEG, GIF,
/// WebP, BMP: what the engine decodes), or null if they can't be made one.
/// Transparent parts come out white.
Future<ProfilePicture?> pictureFromImage(Uint8List bytes) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    // Decoded straight to about the size needed, not the photo's own.
    final codec = await ui.instantiateImageCodecWithSize(buffer, getTargetSize: (w, h) {
      final scale = _decoded / (w < h ? w : h);
      return scale >= 1
          ? ui.TargetImageSize(width: w, height: h)
          : ui.TargetImageSize(width: (w * scale).ceil(), height: (h * scale).ceil());
    });
    final image = (await codec.getNextFrame()).image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (pixels == null) return null;
    return pictureFromRgb(middleSquare(pixels.buffer.asUint8List(), image.width, image.height));
    // Whatever the engine throws (not only Exceptions): no picture, which
    // the dialog says, rather than a dialog left waiting.
  } catch (_) {
    return null;
  }
}

/// The middle square of `width` x `height` RGBA pixels (alpha not
/// premultiplied), at 32 x 32, as 0xRRGGBB values on white, rows from the
/// top: each picture pixel the average of the pixels it covers, or the
/// nearest one when the image is smaller.
List<int> middleSquare(Uint8List rgba, int width, int height) {
  final side = width < height ? width : height;
  final left = (width - side) ~/ 2, top = (height - side) ~/ 2;
  // Where picture pixel `i` starts in the square, along one side.
  int from(int i) => i * side ~/ profileSide;
  return [
    for (var y = 0; y < profileSide; y++)
      for (var x = 0; x < profileSide; x++)
        _average(rgba, width, left + from(x), top + from(y),
            (from(x + 1) - from(x)).clamp(1, side), (from(y + 1) - from(y)).clamp(1, side)),
  ];
}

/// The average of a `w` x `h` block from (`x0`, `y0`), on white.
int _average(Uint8List rgba, int width, int x0, int y0, int w, int h) {
  var r = 0.0, g = 0.0, b = 0.0;
  for (var y = y0; y < y0 + h; y++) {
    for (var x = x0; x < x0 + w; x++) {
      final i = (y * width + x) * 4;
      final a = rgba[i + 3] / 255;
      r += rgba[i] * a + 255 * (1 - a);
      g += rgba[i + 1] * a + 255 * (1 - a);
      b += rgba[i + 2] * a + 255 * (1 - a);
    }
  }
  final n = w * h;
  return (r / n).round() * 0x10000 + (g / n).round() * 0x100 + (b / n).round();
}

int _channel(int rgb, int ch) => (rgb >> (16 - 8 * ch)) & 0xff;

/// 32 x 32 colours (0xRRGGBB, rows from the top) reduced to 16 by median
/// cut: the box of colours with the widest channel is split at its median
/// until there are 16, each becomes its average, and each pixel takes the
/// nearest. No dithering: at 32 pixels it reads as noise.
ProfilePicture pictureFromRgb(List<int> colours) {
  var boxes = [List.of(colours)];
  int spread(List<int> box, int ch) {
    var lo = 255, hi = 0;
    for (final c in box) {
      final v = _channel(c, ch);
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return hi - lo;
  }

  while (boxes.length < profileColours) {
    var best = -1, bestCh = 0, bestSpread = 0;
    for (var b = 0; b < boxes.length; b++) {
      for (var ch = 0; ch < 3; ch++) {
        final s = spread(boxes[b], ch);
        if (boxes[b].length > 1 && s > bestSpread) (best, bestCh, bestSpread) = (b, ch, s);
      }
    }
    // Fewer than 16 colours: each has its box already.
    if (best < 0) break;
    final box = boxes.removeAt(best)..sort((a, b) => _channel(a, bestCh) - _channel(b, bestCh));
    boxes = [...boxes, box.sublist(0, box.length ~/ 2), box.sublist(box.length ~/ 2)];
  }
  final palette = [
    for (final box in boxes)
      [for (var ch = 0; ch < 3; ch++) (box.fold(0, (s, c) => s + _channel(c, ch)) / box.length).round()]
          .fold(0, (v, ch) => v * 256 + ch),
    for (var i = boxes.length; i < profileColours; i++) 0,
  ];
  int nearest(int c) {
    var best = 0, bestD = 1 << 30;
    for (var i = 0; i < boxes.length; i++) {
      var d = 0;
      for (var ch = 0; ch < 3; ch++) {
        final e = _channel(c, ch) - _channel(palette[i], ch);
        d += e * e;
      }
      if (d < bestD) (best, bestD) = (i, d);
    }
    return best;
  }

  return ProfilePicture(palette, Uint8List.fromList([for (final c in colours) nearest(c)]));
}
