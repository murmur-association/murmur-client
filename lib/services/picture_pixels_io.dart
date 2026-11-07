// A picture file's pixels, decoded by the engine (services/picture.dart).

import 'dart:typed_data';
import 'dart:ui' as ui;

/// The file's pixels (RGBA, alpha not premultiplied), decoded straight to
/// a shorter side of `shorter` at most, not the photo's own; null pixels if
/// the engine gives none. Throws what the engine throws.
Future<(Uint8List?, int, int)> decodePixels(Uint8List bytes, int shorter) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final codec = await ui.instantiateImageCodecWithSize(buffer, getTargetSize: (w, h) {
    final scale = shorter / (w < h ? w : h);
    return scale >= 1
        ? ui.TargetImageSize(width: w, height: h)
        : ui.TargetImageSize(width: (w * scale).ceil(), height: (h * scale).ceil());
  });
  try {
    final image = (await codec.getNextFrame()).image;
    try {
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      return (pixels?.buffer.asUint8List(), image.width, image.height);
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
