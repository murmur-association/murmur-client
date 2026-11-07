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

  test('the back-fill mark is kept beside the headers, replaced by the next, and cleared with the rest', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-cache-test');
    addTearDown(() => dir.delete(recursive: true));
    final cache = FileChainCache(dir);
    final genesis = 'ab' * 32;
    await cache.saveHeaders(genesis, const [], 1);
    expect((await cache.load(genesis))!.mark, isNull);
    await cache.saveMark(Uint8List.fromList([1, 2, 3]));
    await cache.saveMark(Uint8List.fromList([4, 5]));
    expect((await cache.load(genesis))!.mark, [4, 5]);
    await cache.clear();
    expect(await cache.load(genesis), isNull);
    await cache.saveHeaders(genesis, const [], 1);
    expect((await cache.load(genesis))!.mark, isNull);
  });

  test('the local copy goes to the application data folder, or on a phone the app cache folder', () {
    String base(Map<String, String> env, {bool phone = false, String? appCache}) =>
        chainCacheBase(phone: phone, env: env, temp: '/tmp', appCache: appCache);
    expect(base({'APPDATA': r'C:\Users\a\AppData\Roaming', 'HOME': '/h'}), r'C:\Users\a\AppData\Roaming');
    expect(base({'XDG_DATA_HOME': '/x', 'HOME': '/h'}), '/x');
    expect(base({'HOME': '/h'}), '/h/.local/share');
    expect(base({}), '/tmp');
    // A folder given for the run (the acceptance tests) wins on a desktop.
    expect(base({'MURMUR_DATA_HOME': '/run', 'APPDATA': r'C:\a', 'HOME': '/h'}), '/run');
    // Phones: never the environment (Android sets HOME to "/"), and never
    // the temp folder when the app's cache folder is known.
    expect(base({'HOME': '/'}, phone: true, appCache: '/data/user/0/app/cache'), '/data/user/0/app/cache');
    expect(base({}, phone: true), '/tmp');
  });
}
