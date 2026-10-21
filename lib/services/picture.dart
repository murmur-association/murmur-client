// Turning an image the user picked into a profile picture (PROTOCOL.md
// Section 7.8): its middle square, shrunk to 32 x 32, reduced to 16 colours.
// The engine decodes the user's own file here; what others publish is never
// decoded by it (protocol/profile.dart reads those).

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../protocol/profile.dart';

/// The largest file taken, in bytes: past it, a photo isn't worth decoding
/// for 32 x 32 pixels.
const maxPictureFileBytes = 20 * 1000 * 1000;

/// The side the image is drawn at before averaging down to 32: four source
/// pixels each way per picture pixel.
const _drawn = profileSide * 4;

/// The profile picture made from an image file's bytes (PNG, JPEG, GIF,
/// WebP, BMP: what the engine decodes), or null if they aren't an image.
/// Transparent parts come out white.
Future<ProfilePicture?> pictureFromImage(Uint8List bytes) async {
  final ui.Image image;
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    // Decoded straight to about the size needed, not the photo's own.
    final codec = await ui.instantiateImageCodecWithSize(buffer, getTargetSize: (w, h) {
      final scale = _drawn / (w < h ? w : h);
      return scale >= 1 ? ui.TargetImageSize(width: w, height: h)
          : ui.TargetImageSize(width: (w * scale).ceil(), height: (h * scale).ceil());
    });
    image = (await codec.getNextFrame()).image;
  } on Exception {
    return null;
  }
  final side = image.width < image.height ? image.width : image.height;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(const ui.Rect.fromLTWH(0, 0, _drawn * 1.0, _drawn * 1.0), ui.Paint()..color = const ui.Color(0xFFFFFFFF))
    ..drawImageRect(
      image,
      ui.Rect.fromLTWH((image.width - side) / 2, (image.height - side) / 2, side * 1.0, side * 1.0),
      const ui.Rect.fromLTWH(0, 0, _drawn * 1.0, _drawn * 1.0),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
  final drawn = await recorder.endRecording().toImage(_drawn, _drawn);
  final rgba = (await drawn.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  return pictureFromRgb(_shrunk(rgba));
}

/// [_drawn]-pixel RGBA shrunk to 32 x 32 by averaging, as 0xRRGGBB values.
List<int> _shrunk(Uint8List rgba) {
  const k = _drawn ~/ profileSide;
  return [
    for (var y = 0; y < profileSide; y++)
      for (var x = 0; x < profileSide; x++) _average(rgba, x * k, y * k, k),
  ];
}

int _average(Uint8List rgba, int x0, int y0, int k) {
  var r = 0, g = 0, b = 0;
  for (var y = y0; y < y0 + k; y++) {
    for (var x = x0; x < x0 + k; x++) {
      final i = (y * _drawn + x) * 4;
      r += rgba[i];
      g += rgba[i + 1];
      b += rgba[i + 2];
    }
  }
  final n = k * k;
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
