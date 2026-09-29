// The native chain cache (files): content can be removed one message at a
// time, as a withdrawn message's must be, and the rest survives.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/chain_cache_io.dart';

void main() {
  test('removed content is gone after a reload, and the rest is kept', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-cache-test');
    addTearDown(() => dir.delete(recursive: true));
    final cache = FileChainCache(dir);
    final genesis = 'ab' * 32;
    await cache.saveHeaders(genesis, const [], 1);

    final a = 'aa' * 32, b = 'bb' * 32, c = 'cc' * 32;
    await cache.saveContents({a: Uint8List.fromList([1, 2]), b: Uint8List.fromList([3])});
    await cache.saveContents({c: Uint8List.fromList([4, 5, 6])});
    await cache.removeContents({a, c});

    final loaded = (await cache.load(genesis))!;
    expect(loaded.contents.keys, [b]);
    expect(loaded.contents[b], [3]);

    // Removing what isn't there, or nothing, changes nothing.
    await cache.removeContents({a});
    await cache.removeContents({});
    expect((await cache.load(genesis))!.contents.keys, [b]);
  });
}
