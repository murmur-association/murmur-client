// Times the client's header checks, and measures what holding the headers
// costs in memory, on a long valid testnet chain (see header_bench/bench.dart).
//
//   dart run tool/header_bench.dart generate 20000 build/headers.bin   # once; slow
//   dart run tool/header_bench.dart check build/headers.bin            # as objects
//   dart run tool/header_bench.dart packed build/headers.bin           # packed, as the client keeps them
//
// Each mode runs in its own process, so the memory figures don't mix.
// For the browser, compile header_bench_web.dart (see that file).

import 'dart:io';

import 'header_bench/bench.dart';

void main(List<String> args) {
  if (args.length == 3 && args[0] == 'generate') {
    final count = int.parse(args[1]);
    final watch = Stopwatch()..start();
    final chain = generateChain(count, progress: (done) => stdout.write('\rmined $done of $count'));
    File(args[2])
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeChain(chain));
    stdout.writeln('\n$count headers in ${watch.elapsed.inSeconds} s -> ${args[2]}');
  } else if (args.length == 2 && args[0] == 'check') {
    final data = File(args[1]).readAsBytesSync();
    final before = ProcessInfo.currentRss;
    final chain = decodeChain(data);
    final held = ProcessInfo.currentRss - before;
    final took = checkChain(chain);
    final perHeader = took.inMicroseconds / chain.length;
    stdout.writeln('${chain.length} headers checked in ${took.inMilliseconds} ms: '
        '${perHeader.toStringAsFixed(1)} µs each, ${(1e6 / perHeader).round()} a second');
    stdout.writeln('memory for the decoded headers: about ${(held / chain.length).round()} bytes each '
        '(${(held / 1048576).toStringAsFixed(1)} MiB, process RSS)');
  } else if (args.length == 2 && args[0] == 'packed') {
    final data = File(args[1]).readAsBytesSync();
    final (took, chain) = checkPacked(data);
    final perHeader = took.inMicroseconds / chain.length;
    stdout.writeln('${chain.length} headers decoded, checked and packed in ${took.inMilliseconds} ms: '
        '${perHeader.toStringAsFixed(1)} µs each, ${(1e6 / perHeader).round()} a second');
    stdout.writeln('packed: ${(chain.bytesHeld / chain.length).round()} bytes each '
        '(${(chain.bytesHeld / 1048576).toStringAsFixed(1)} MiB with spare capacity), '
        'plus up to 1024 recent headers as objects');
  } else {
    stderr.writeln('usage: dart run tool/header_bench.dart (generate <count> <file> | check <file> | packed <file>)');
    exitCode = 64;
  }
}
