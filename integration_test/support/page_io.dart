// What a test asks of the page it runs in: nothing outside a browser.

import 'dart:typed_data';

/// A file the page serves; none outside a browser.
Future<Uint8List?> pageFile(String path) async => null;

/// Whether the browser gives a canvas's pixels back; null outside one.
String? canvasReadBack() => null;
