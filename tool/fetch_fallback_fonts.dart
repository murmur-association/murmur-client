// Copies the fonts the web engine falls back to (for glyphs Roboto lacks:
// Arabic, Chinese, Japanese, emoji, every other script a message may use)
// into build/web/fallback-fonts/, so the page never fetches them from
// fonts.gstatic.com (web/flutter_bootstrap.js points the engine there).
//
//   flutter build web --release --no-web-resources-cdn ...
//   dart run tool/fetch_fallback_fonts.dart [--web build/web] [--cache <dir>]
//
// The list comes from the engine itself: every font path it may request is
// in the compiled main.dart.js. About 20 MiB in all; a browser downloads
// only the slices the text on screen needs. With --cache, files already
// fetched once are copied from there instead (for CI).

// ignore_for_file: avoid_print

import 'dart:io';

const _source = 'https://fonts.gstatic.com/s/';
final _path = RegExp(r'"(noto[a-z0-9]+/v\d+/[A-Za-z0-9_\-]+(?:\.\d+)?\.(?:woff2|ttf))"');

Future<void> main(List<String> args) async {
  var web = 'build/web';
  String? cache;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--web':
        web = args[++i];
      case '--cache':
        cache = args[++i];
      default:
        stderr.writeln('usage: dart run tool/fetch_fallback_fonts.dart [--web build/web] [--cache <dir>]');
        exit(2);
    }
  }
  final js = File('$web/main.dart.js');
  if (!js.existsSync()) {
    stderr.writeln('$web/main.dart.js not found: run `flutter build web` first');
    exit(1);
  }
  final text = await js.readAsString();
  final paths = _path.allMatches(text).map((m) => m.group(1)!).toSet().toList();
  // If the engine changes how it lists fonts, fail rather than ship a page
  // whose fallback glyphs are missing.
  if (paths.length < 100 || !text.contains(_source)) {
    stderr.writeln('found ${paths.length} font paths in main.dart.js: the engine\'s font list changed; update this tool');
    exit(1);
  }

  final out = Directory('$web/fallback-fonts');
  final client = HttpClient();
  var fetched = 0, copied = 0, bytes = 0;
  final failures = <String>[];
  final queue = List.of(paths);
  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      final target = File('${out.path}/$path');
      final cached = cache == null ? null : File('$cache/$path');
      try {
        target.parent.createSync(recursive: true);
        if (cached != null && cached.existsSync()) {
          cached.copySync(target.path);
          copied++;
        } else {
          final response = await (await client.getUrl(Uri.parse('$_source$path'))).close();
          if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
          await response.pipe(target.openWrite());
          fetched++;
          if (cached != null) {
            cached.parent.createSync(recursive: true);
            target.copySync(cached.path);
          }
        }
        bytes += target.lengthSync();
      } catch (e) {
        failures.add('$path: $e');
      }
    }
  }

  await Future.wait(List.generate(16, (_) => worker()));
  client.close();
  File('tool/fallback_fonts_OFL.txt').copySync('${out.path}/OFL.txt');
  if (failures.isNotEmpty) {
    stderr.writeln(failures.join('\n'));
    exit(1);
  }
  print('${paths.length} fallback fonts in ${out.path} ($fetched fetched, $copied from cache, '
      '${(bytes / 1048576).toStringAsFixed(1)} MiB)');
}
