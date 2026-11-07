// A file the page serves, from its own origin (which the page's policy
// allows).

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The bytes of `path` beside the page, or null if it isn't served.
Future<Uint8List?> pageFile(String path) async {
  final response = await web.window.fetch(path.toJS).toDart;
  if (!response.ok) return null;
  return (await response.arrayBuffer().toDart).toDart.asUint8List();
}
