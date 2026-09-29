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

class _Prompts implements VaultPrompts {
  _Prompts(this.setup, this.entered);

  final String? setup;
  final String? entered;
  int asked = 0;

  @override
  Future<String?> newPassphrase() async => setup;

  @override
  Future<String?> passphrase(String reason) async {
    asked++;
    return entered;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));

  test('the stored record holds no trace of the seed, and only the passphrase opens it', () async {
    final watch = Stopwatch()..start();
    final stored = await sealWithPassphrase(seed, _Prompts('correct horse', null));
    print('seal with $passphraseRounds PBKDF2 rounds: ${watch.elapsedMilliseconds} ms');
    expect(stored['protection'], 'passphrase');
    expect(stored.values.join(), isNot(contains(toHex(seed))));
    expect(await openSeed(stored, _Prompts(null, 'correct horse'), reason: 'test'), seed);
    await expectLater(openSeed(stored, _Prompts(null, 'wrong horse'), reason: 'test'),
        throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrong passphrase', isTrue)));
    await expectLater(openSeed(stored, _Prompts(null, null), reason: 'test'),
        throwsA(isA<VaultLocked>().having((e) => e.wrongPassphrase, 'wrong passphrase', isFalse)));
  });

  test('a wallet is saved encrypted, and every unlock asks again', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final wallets = WalletController();
    await wallets.import(toHex(seed), _Prompts('correct horse', null), reason: 'test');
    final expected = (await MurmurWallet.fromSeed(seed)).addressHex;
    expect(wallets.wallet!.addressHex, expected);
    expect(wallets.protection, 'passphrase');

    // A fresh start reads only the public side.
    final again = WalletController();
    await again.load();
    expect(again.wallet!.addressHex, expected);
    final prompts = _Prompts(null, 'correct horse');
    expect((await again.unlock(prompts, reason: 'send')).addressHex, expected);
    expect((await again.unlock(prompts, reason: 'send')).addressHex, expected);
    expect(prompts.asked, 2, reason: 'ask every time');
  });

  test('a plaintext seed from an earlier version is moved to the vault at the next unlock', () async {
    FlutterSecureStorage.setMockInitialValues({'murmur_wallet_seed': toHex(seed)});
    final wallets = WalletController();
    await wallets.load();
    expect(wallets.protection, 'legacy');
    await wallets.unlock(_Prompts('correct horse', null), reason: 'show');
    expect(wallets.protection, 'passphrase');
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'murmur_wallet_seed'), isNull, reason: 'the plaintext copy is gone');
    expect(await storage.read(key: 'murmur_wallet'), isNot(contains(toHex(seed))));
  });
}
