// Serves the release web build (build/web) on localhost, for use with the
// WebSocket bridge (tool/ws_bridge.dart).
//
//   flutter build web --no-web-resources-cdn
//   dart run tool/fetch_fallback_fonts.dart
//   dart run tool/serve_web.dart [--port 8080]

// ignore_for_file: avoid_print

import 'dart:io';

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.frag': 'application/octet-stream',
  '.bin': 'application/octet-stream',
};

Future<void> main(List<String> args) async {
  final port = args.length == 2 && args[0] == '--port' ? int.parse(args[1]) : 8080;
  final root = Directory('build/web').absolute;
  if (!root.existsSync()) {
    stderr.writeln('build/web not found; run `flutter build web` first');
    exit(1);
  }
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('serving ${root.path} at http://localhost:$port');

  await for (final request in server) {
    final segments = request.uri.pathSegments.where((s) => s.isNotEmpty && s != '..').toList();
    var file = File([root.path, ...segments].join(Platform.pathSeparator));
    if (segments.isEmpty || !file.existsSync()) {
      file = File('${root.path}${Platform.pathSeparator}index.html');
    }
    final name = file.path.toLowerCase();
    final ext = name.contains('.') ? name.substring(name.lastIndexOf('.')) : '';
    request.response.headers
      ..set(HttpHeaders.contentTypeHeader, _types[ext] ?? 'application/octet-stream')
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}
