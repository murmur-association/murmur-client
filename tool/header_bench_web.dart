// The header bench (header_bench/bench.dart) in a browser, where the client
// mostly runs. Compile it next to a generated chain and open the page:
//
//   dart run tool/header_bench.dart generate 100000 build/web/bench/headers.bin
//   dart compile js -O2 tool/header_bench_web.dart -o build/web/bench/bench.js
//   (an index.html in build/web/bench loading bench.js, with <pre id="out">)
//
// Open it as is to measure headers kept as objects, or with `?packed` to
// measure them packed, as the client keeps them. Each line also goes to the
// console. Heap figures are steadiest with the browser started with
// --js-flags=--expose-gc, so the page can collect before each reading.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'header_bench/bench.dart';

/// Collects garbage, where the browser allows it.
void _collect() {
  final gc = web.window.getProperty<JSFunction?>('gc'.toJS);
  gc?.callAsFunction();
}

/// The JavaScript heap in use, in bytes (Chromium browsers only).
int? _heap() {
  final memory = web.window.performance.getProperty<JSObject?>('memory'.toJS);
  return memory?.getProperty<JSNumber?>('usedJSHeapSize'.toJS)?.toDartInt;
}

Future<void> main() async {
  final out = web.document.getElementById('out')!;
  void say(String line) {
    out.textContent = '${out.textContent ?? ''}$line\n';
    web.console.log(line.toJS);
  }

  final response = await web.window.fetch('headers.bin'.toJS).toDart;
  final data = (await response.arrayBuffer().toDart).toDart.asUint8List();
  _collect();
  final before = _heap();
  if (web.window.location.search.contains('packed')) {
    final (took, chain) = checkPacked(data);
    _collect();
    final after = _heap();
    final perHeader = took.inMicroseconds / chain.length;
    say('${chain.length} headers decoded, checked and packed in ${took.inMilliseconds} ms: '
        '${perHeader.toStringAsFixed(1)} µs each, ${(1e6 / perHeader).round()} a second');
    if (before != null && after != null) {
      say('heap after checking, packed (with history): ${((after - before) / chain.length).round()} bytes each');
    }
  } else {
    final chain = decodeChain(data);
    _collect();
    final held = _heap();
    final took = checkChain(chain);
    _collect();
    final after = _heap();
    final perHeader = took.inMicroseconds / chain.length;
    say('${chain.length} headers checked in ${took.inMilliseconds} ms: '
        '${perHeader.toStringAsFixed(1)} µs each, ${(1e6 / perHeader).round()} a second');
    if (before != null && held != null && after != null) {
      say('heap for the decoded headers: ${((held - before) / chain.length).round()} bytes each');
      say('heap after checking (with history, cached hashes): ${((after - before) / chain.length).round()} bytes each');
    }
  }
  say('done');
}
