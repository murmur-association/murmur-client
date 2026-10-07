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
      target: (BigInt.one << 120) + BigInt.from(height),
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

  test('unknown slots, back-fill and rollback', () {
    final chain = HeaderChain()
      ..add(null)
      ..add(null)
      ..add(_header(3))
      ..add(_header(4));
    expect(chain[0], isNull);
    expect(chain.hashAt(1), isNull);
    expect(chain.timestampAt(0), isNull);
    expect(chain.isKnown(2), isTrue);
    expect(() => chain.snapshot()[0], throwsStateError);

    final backfill = HeaderChain()
      ..add(_header(1))
      ..add(_header(2));
    chain.copyStart(backfill, 2);
    expect(chain[0]!.id, _header(1).id);
    expect(chain[1]!.id, _header(2).id);

    chain[3] = _header(40);
    expect(chain[3]!.id, _header(40).id);

    chain.truncate(2);
    expect(chain.length, 2);
    expect(chain[2], isNull);
    chain.add(_header(30));
    expect(chain[2]!.id, _header(30).id);
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
