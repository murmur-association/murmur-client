// The response headers app.murmur.info is served with (web/_headers): what
// the page needs of its Content-Security-Policy, and that nothing from
// another origin gets in (rule 2). The acceptance tests run the page under
// the same headers (tool/acceptance_test.dart); this checks them on every
// push, where those tests may not run.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The policy's directives: name to sources.
Map<String, List<String>> _policy() {
  final line = File('web/_headers')
      .readAsLinesSync()
      .firstWhere((l) => l.trimLeft().startsWith('Content-Security-Policy:'));
  return {
    for (final directive in line.split(':').skip(1).join(':').split(';'))
      if (directive.trim().split(RegExp(r'\s+')) case [final name, ...final sources]) name: sources,
  };
}

void main() {
  test('the page may read a picked picture, and reach the node the user chose', () {
    final connect = _policy()['connect-src']!;
    expect(connect, contains('blob:'), reason: 'a picked file is read from its blob: URL (v0.9.2 did nothing without it)');
    expect(connect, contains('wss:'), reason: 'any node the user picks, over a secure WebSocket');
  });

  test('nothing from another origin', () {
    final policy = _policy();
    expect(policy['default-src'], ["'none'"]);
    for (final MapEntry(key: name, value: sources) in policy.entries) {
      for (final source in sources) {
        expect(source, isNot(matches(RegExp(r'^https?:|\.'))), reason: '$name allows $source');
      }
    }
    expect(policy['script-src'], ["'self'", "'wasm-unsafe-eval'"]);
  });
}
