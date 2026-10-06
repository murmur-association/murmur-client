// The wallet seed at rest: encrypted, opened only with the passphrase (on
// platforms without a device key store, as in these tests), and moved there
// from the plaintext storage of earlier versions.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/key_vault.dart';
import 'package:murmur_client/services/storage.dart';

import 'support/vault_prompts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));

  group('a passkey manager that can\'t encrypt', () {
    // The first passkey's manager lacks PRF; a second try uses one that has it.
    Future<Map<String, String>?> Function(Uint8List, String) tries() {
      var n = 0;
      return (seed, reason) async {
        if (n++ == 0) throw const PasskeyUnsupported();
        return {'protection': 'passkey', 'try': '$n'};
      };
    }

    test('lets the user try another manager', () async {
      final prompts = TestPrompts(null, null, onPasskeyUnsupported: [true]);
      final stored = await sealSeed(seed, prompts, reason: 'test', device: tries());
      expect(stored, {'protection': 'passkey', 'try': '2'});
      expect(prompts.passkeyAsked, 1);
    });

    test('or use a passphrase instead', () async {
      final prompts = TestPrompts('correct horse', null, onPasskeyUnsupported: [false]);
      final stored = await sealSeed(seed, prompts, reason: 'test', device: tries());
      expect(stored['protection'], 'passphrase');
    });

    test('or cancel, saving nothing', () async {
      final prompts = TestPrompts(null, null, onPasskeyUnsupported: [null]);
      await expectLater(sealSeed(seed, prompts, reason: 'test', device: tries()), throwsA(isA<VaultLocked>()));
    });
  });

  test('what is sealed to a key opens only with its secret, and no two sealings look alike', () async {
    final secret = Uint8List.fromList(List.generate(32, (i) => 255 - i));
    final public = await sealingKeyOf(secret);
    final data = Uint8List.fromList('a card\'s code'.codeUnits);
    final sealed = await sealTo(public, data);
    expect(sealed.values.join(), isNot(contains(toHex(data))));
    expect(await openSealed(sealed, secret), data);
    // Sealing needs no secret, so it can't be told from another sealing.
    final again = await sealTo(public, data);
    expect((again['from'], again['box']), isNot((sealed['from'], sealed['box'])));
    expect(await openSealed(again, secret), data);
    await expectLater(openSealed(sealed, seed), throwsA(anything), reason: 'another secret');
    await expectLater(openSealed({...sealed, 'from': again['from']!}, secret), throwsA(anything),
        reason: 'the sender\'s key is part of it');
  });

  test('the stored record holds no trace of the seed, and only the passphrase opens it', () async {
    final watch = Stopwatch()..start();
    final stored = await sealWithPassphrase(seed, TestPrompts('correct horse', null));
    print('seal with $passphraseRounds PBKDF2 rounds: ${watch.elapsedMilliseconds} ms');
    expect(stored['protection'], 'passphrase');
    expect(stored.values.join(), isNot(contains(toHex(seed))));
    expect(await openSeed(stored, TestPrompts(null, 'correct horse'), reason: 'test'), seed);
    await expectLater(openSeed(stored, TestPrompts(null, 'wrong horse'), reason: 'test'),
        throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrong passphrase', isTrue)));
    await expectLater(openSeed(stored, TestPrompts(null, null), reason: 'test'),
        throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrong passphrase', isFalse)));
  });

  test('a wallet is saved encrypted, and every unlock asks again', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final wallets = WalletController();
    await wallets.import(toHex(seed), TestPrompts('correct horse', null), reason: 'test');
    final expected = (await MurmurWallet.fromSeed(seed)).addressHex;
    expect(wallets.wallet!.addressHex, expected);
    expect(wallets.protection, 'passphrase');

    // A fresh start reads only the public side.
    final again = WalletController();
    await again.load();
    expect(again.wallet!.addressHex, expected);
    final prompts = TestPrompts(null, 'correct horse');
    expect((await again.unlock(prompts, reason: 'send')).addressHex, expected);
    expect((await again.unlock(prompts, reason: 'send')).addressHex, expected);
    expect(prompts.asked, 2, reason: 'ask every time');
  });

  test('a plaintext seed from an earlier version is moved to the vault at the next unlock', () async {
    FlutterSecureStorage.setMockInitialValues({'murmur_wallet_seed': toHex(seed)});
    final wallets = WalletController();
    await wallets.load();
    expect(wallets.protection, 'legacy');
    await wallets.unlock(TestPrompts('correct horse', null), reason: 'show');
    expect(wallets.protection, 'passphrase');
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'murmur_wallet_seed'), isNull, reason: 'the plaintext copy is gone');
    expect(await storage.read(key: 'murmur_wallet'), isNot(contains(toHex(seed))));
  });
}
