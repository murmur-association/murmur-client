// What a test asks of the page it runs in, in a browser.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The bytes of `path` beside the page, from its own origin (which the
/// page's policy allows), or null if it isn't served.
Future<Uint8List?> pageFile(String path) async {
  final response = await web.window.fetch(path.toJS).toDart;
  if (!response.ok) return null;
  return (await response.arrayBuffer().toDart).toDart.asUint8List();
}

/// Whether the browser gives a canvas's pixels back: a red square drawn on
/// a 2D canvas, then read. Safari, driven by safaridriver on GitHub's Mac,
/// refused every image's pixels to the engine (InvalidStateError,
/// 2026-11-07); this tells a browser that refuses all reading back from
/// one that refuses the engine's.
String canvasReadBack() {
  try {
    final canvas = (web.document.createElement('canvas') as web.HTMLCanvasElement)
      ..width = 4
      ..height = 4;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D
      ..fillStyle = 'rgb(255, 0, 0)'.toJS
      ..fillRect(0, 0, 4, 4);
    final pixel = context.getImageData(1, 1, 1, 1).data.toDart;
    return 'a 2D canvas reads back ${pixel.join(',')} (drawn 255,0,0,255)';
  } catch (e) {
    return 'a 2D canvas does not read back: $e';
  }
}
