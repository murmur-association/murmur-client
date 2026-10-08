import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/header_chain.dart';
import 'package:murmur_client/protocol/models.dart';

Uint8List _filled(int seed) => Uint8List.fromList(List.generate(32, (i) => (seed * 31 + i) & 0xff));

/// A header whose every field differs from its neighbours', with a
/// timestamp and target past 32 bits (rule 7).
BlockHeader _header(int height) => BlockHeader(
      height: height,
      prevHash: _filled(height),
      merkleRoot: _filled(height + 1000),
      stateRoot: _filled(height + 2000),
      filterHash: _filled(height + 3000),
      historyRoot: _filled(height + 4000),
      timestamp: 0x100000000 + height * 30,
      target: u256Bytes((BigInt.one << 250) + BigInt.from(height)),
      nonce: u64Bytes(0x200000000 + height),
      miner: _filled(height % 3),
    );

void main() {
  test('headers come back field for field, hash included', () {
    final chain = HeaderChain();
    final originals = [for (var h = 1; h <= 3000; h++) _header(h)];
    chain.addAll(originals);
    expect(chain.length, 3000);
    // Past the recent cache, so these are rebuilt from the bytes.
    for (final i in [0, 1, 1500, 2999]) {
      final want = originals[i];
      final got = chain[i]!;
      expect(got.height, want.height);
      expect(got.prevHash, want.prevHash);
      expect(got.merkleRoot, want.merkleRoot);
      expect(got.stateRoot, want.stateRoot);
      expect(got.filterHash, want.filterHash);
      expect(got.historyRoot, want.historyRoot);
      expect(got.timestamp, want.timestamp);
      expect(got.target, want.target);
      expect(got.nonce, want.nonce);
      expect(got.miner, want.miner);
      expect(got.id, want.id);
      expect(chain.hashAt(i), want.hash);
      expect(chain.prevHashAt(i), want.prevHash);
      expect(chain.stateRootAt(i), want.stateRoot);
      expect(chain.filterHashAt(i), want.filterHash);
      expect(chain.minerAt(i), want.miner);
      expect(chain.timestampAt(i), want.timestamp);
      expect(chain.hashIs(i, want.hash), isTrue);
      expect(chain.minedBy(i, want.miner), isTrue);
      expect(chain.minedBy(i, _filled(99)), isFalse);
    }
    // A rebuilt header hashes to the same as the original (the injected
    // hash isn't the only thing right).
    final rebuilt = chain.snapshot()[10];
    expect(toHex(rebuilt.hash), originals[10].id);
  });

  test('unknown slots, an old header put below, and rollback', () {
    final chain = HeaderChain()
      ..add(null)
      ..add(null)
      ..add(_header(3))
      ..add(_header(4));
    expect(chain[0], isNull);
    expect(chain.hashAt(1), isNull);
    expect(chain.timestampAt(0), isNull);
    expect(chain.isKnown(2), isTrue);
    // What is packed starts at the first header.
    expect(chain.packedFrom, 2);
    expect(chain.snapshot().map((h) => h.id), [_header(3).id, _header(4).id]);

    // An old header, fetched on its own.
    chain[1] = _header(2);
    expect(chain.isKnown(1), isTrue);
    expect(chain.isKnown(0), isFalse);
    expect(chain[1]!.id, _header(2).id);
    expect(chain.hashAt(1), _header(2).hash);
    expect(chain.prevHashAt(1), _header(2).prevHash);
    expect(chain.timestampAt(1), _header(2).timestamp);
    expect(chain.hashIs(1, _header(2).hash), isTrue);
    expect(chain.minedBy(1, _header(2).miner), isTrue);
    expect(chain.packedFrom, 2, reason: 'kept apart');

    chain[3] = _header(40);
    expect(chain[3]!.id, _header(40).id);

    chain.truncate(2);
    expect(chain.length, 2);
    expect(chain[2], isNull);
    chain.add(_header(30));
    expect(chain[2]!.id, _header(30).id);
  });

  test('a chain that starts at a checkpoint holds nothing for the heights below it', () {
    const below = 10000000; // ten years of blocks
    final chain = HeaderChain();
    for (var i = 0; i < below; i++) {
      chain.add(null);
    }
    chain.addAll([for (var h = 1; h <= 20; h++) _header(h)]);
    expect(chain.length, below + 20);
    expect(chain.packedFrom, below);
    expect(chain.bytesHeld, lessThan(1024 * 300), reason: 'room for the headers it has, not for the chain');
    expect(chain[below + 19]!.id, _header(20).id);
    expect(chain[below - 1], isNull);
    expect(chain.snapshot().length, 20);

    final other = HeaderChain()..startAt(below);
    other.add(_header(1));
    expect(other.length, below + 1);
    expect(other[below]!.id, _header(1).id);
    expect(() => other.startAt(5), throwsStateError);
  });

  test('headers checked and let go: what is dropped is unknown, the rest stays where it was', () {
    final chain = HeaderChain()..addAll([for (var h = 1; h <= 3000; h++) _header(h)]);
    final before = chain.bytesHeld;
    chain.dropBelow(2990);
    expect(chain.length, 3000);
    expect(chain.packedFrom, 2990);
    expect(chain[2989], isNull);
    expect(chain.isKnown(100), isFalse);
    expect(chain[2990]!.id, _header(2991).id);
    expect(chain.hashAt(2999), _header(3000).hash);
    expect(chain.bytesHeld, lessThan(before ~/ 2));
    chain.add(_header(3001));
    expect(chain[3000]!.id, _header(3001).id);
    expect(chain[2995]!.id, _header(2996).id);
    // Nothing to do below what is already gone.
    chain.dropBelow(10);
    expect(chain.packedFrom, 2990);
    // A rollback below what is held leaves an empty stretch to grow from.
    chain.truncate(2000);
    expect(chain.length, 2000);
    chain.add(_header(7));
    expect(chain[2000]!.id, _header(7).id);
    expect(chain[1999], isNull);
  });

  test('a snapshot keeps its length and bytes while the chain moves on', () {
    final chain = HeaderChain()..addAll([for (var h = 1; h <= 10; h++) _header(h)]);
    final snapshot = chain.snapshot();
    chain.addAll([for (var h = 11; h <= 5000; h++) _header(h)]); // grows: new buffer
    expect(snapshot.length, 10);
    expect(snapshot[9].id, _header(10).id);
    chain.clear();
    expect(chain.isEmpty, isTrue);
    expect(snapshot[0].id, _header(1).id);
  });

  test('a chain loaded apart is adopted whole, and the other left empty', () {
    final loaded = HeaderChain()..addAll([for (var h = 1; h <= 2000; h++) _header(h)]);
    final chain = HeaderChain()..add(_header(77));
    chain.takeFrom(loaded);
    expect(chain.length, 2000);
    expect(chain[0]!.id, _header(1).id);
    expect(chain[1999]!.id, _header(2000).id);
    expect(loaded.isEmpty, isTrue);
    // Each grows on its own from here.
    loaded.add(_header(5));
    chain.add(_header(2001));
    expect(chain[0]!.id, _header(1).id);
    expect(chain.length, 2001);
  });
}
