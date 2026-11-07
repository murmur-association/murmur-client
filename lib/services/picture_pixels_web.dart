// A picture file's pixels, decoded by the browser (services/picture.dart).
// Not by the engine: Safari refuses to give the engine's decoded image's
// pixels back (InvalidStateError, on any PNG, 2026-11-07), and choosing a
// picture there said the file couldn't be read. The browser decodes the
// user's own file and draws it on a canvas of its own, whose pixels any
// browser gives back.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The file's pixels (RGBA, alpha not premultiplied), scaled to a shorter
/// side of `shorter` at most. Throws what the browser throws (a file it
/// can't decode).
Future<(Uint8List?, int, int)> decodePixels(Uint8List bytes, int shorter) async {
  final bitmap = await web.window.createImageBitmap(web.Blob(<JSAny>[bytes.toJS].toJS)).toDart;
  try {
    final scale = shorter / (bitmap.width < bitmap.height ? bitmap.width : bitmap.height);
    final width = scale >= 1 ? bitmap.width : (bitmap.width * scale).ceil();
    final height = scale >= 1 ? bitmap.height : (bitmap.height * scale).ceil();
    final canvas = (web.document.createElement('canvas') as web.HTMLCanvasElement)
      ..width = width
      ..height = height;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D
      ..imageSmoothingQuality = 'high';
    context.drawImage(bitmap, 0, 0, width, height);
    return (context.getImageData(0, 0, width, height).data.toDart.buffer.asUint8List(), width, height);
  } finally {
    bitmap.close();
  }
}
