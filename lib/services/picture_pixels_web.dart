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
/// can't decode): from `createImageBitmap` and, failing that, from an
/// image element, which the page's policy lets read a `blob:` URL.
Future<(Uint8List?, int, int)> decodePixels(Uint8List bytes, int shorter) async {
  // Typed, since a browser may not guess a blob's type itself.
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: _typeOf(bytes)));
  try {
    final bitmap = await web.window.createImageBitmap(blob).toDart;
    try {
      return _draw(bitmap, bitmap.width, bitmap.height, shorter);
    } finally {
      bitmap.close();
    }
  } catch (bitmapFailed) {
    final url = web.URL.createObjectURL(blob);
    try {
      final image = web.HTMLImageElement()..src = url;
      await image.decode().toDart;
      return _draw(image, image.naturalWidth, image.naturalHeight, shorter);
    } catch (imageFailed) {
      throw StateError('createImageBitmap: $bitmapFailed; an image element: $imageFailed');
    } finally {
      web.URL.revokeObjectURL(url);
    }
  }
}

/// `source`'s pixels, drawn on a canvas scaled to a shorter side of
/// `shorter` at most.
(Uint8List, int, int) _draw(web.CanvasImageSource source, int width, int height, int shorter) {
  final scale = shorter / (width < height ? width : height);
  if (scale < 1) (width, height) = ((width * scale).ceil(), (height * scale).ceil());
  final canvas = (web.document.createElement('canvas') as web.HTMLCanvasElement)
    ..width = width
    ..height = height;
  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D..imageSmoothingQuality = 'high';
  context.drawImage(source, 0, 0, width, height);
  return (context.getImageData(0, 0, width, height).data.toDart.buffer.asUint8List(), width, height);
}

/// The image type a file's first bytes say, or '' for one not known here.
String _typeOf(Uint8List bytes) {
  bool startsWith(List<int> magic, [int at = 0]) =>
      bytes.length >= at + magic.length &&
      [for (var i = 0; i < magic.length; i++) bytes[at + i]].join(',') == magic.join(',');
  if (startsWith(const [0x89, 0x50, 0x4e, 0x47])) return 'image/png';
  if (startsWith(const [0xff, 0xd8, 0xff])) return 'image/jpeg';
  if (startsWith('GIF8'.codeUnits)) return 'image/gif';
  if (startsWith('RIFF'.codeUnits) && startsWith('WEBP'.codeUnits, 8)) return 'image/webp';
  if (startsWith('BM'.codeUnits)) return 'image/bmp';
  return '';
}
