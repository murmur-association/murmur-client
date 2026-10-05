// Saving a wallet for real: inside the built app, through the platform's
// own secure storage (the desktop's keyring on Linux), not the in-memory
// stand-in the unit tests use (test/key_vault_test.dart). Run on a desktop:
//
//   flutter test integration_test/wallet_storage_test.dart -d linux
//
// It needs a throwaway session, since it writes and removes the app's
// wallet record: tool/linux_smoke_test.sh --wallet-storage gives it one (its
// own home folder, session bus and keyring) and is how the release job runs
// it. As a guard, it refuses to run where a wallet is already stored, and
// then touches nothing.

import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/key_vault.dart';
import 'package:murmur_client/services/storage.dart';

class _Prompts implements VaultPrompts {
  _Prompts(this.answer);

  final String? answer;
  int asked = 0;

  @override
  Future<String?> newPassphrase() async => answer;

  @override
  Future<String?> passphrase(String reason) async {
    asked++;
    return answer;
  }

  @override
  Future<bool?> passkeyUnsupported() async => false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a wallet is saved in the system keyring, found again, unlocked only by its passphrase, and removed',
      (tester) async {
    const storage = FlutterSecureStorage();
    final before = WalletController();
    await before.load();
    if (before.wallet != null || (await storage.readAll()).isNotEmpty) {
      fail('this session already holds a wallet or other app secrets: run it in a throwaway session '
          '(tool/linux_smoke_test.sh --wallet-storage). Nothing was changed.');
    }

    // A fixed seed, so the address is known. Never a real wallet's.
    final seed = Uint8List.fromList(List.generate(32, (i) => 200 - i));
    final expected = (await MurmurWallet.fromSeed(seed)).addressHex;
    final wallets = WalletController();
    await wallets.import(toHex(seed), _Prompts('correct horse'), reason: 'test');
    expect(wallets.wallet!.addressHex, expected);

    // What the keyring holds says nothing of the seed.
    final stored = await storage.readAll();
    expect(stored.keys, ['murmur_wallet']);
    expect(stored.values.single, isNot(contains(toHex(seed))));

    // A later start of the app finds the wallet's public side.
    final again = WalletController();
    await again.load();
    expect(again.wallet!.addressHex, expected);
    expect(again.protection, isNotNull);

    // Its key comes back only with the right answer, asked every time.
    final right = _Prompts('correct horse');
    expect((await again.unlock(right, reason: 'send')).addressHex, expected);
    expect((await again.unlock(right, reason: 'send')).addressHex, expected);
    if (again.protection == 'passphrase') {
      expect(right.asked, 2, reason: 'ask every time');
      await expectLater(again.unlock(_Prompts('wrong'), reason: 'send'), throwsA(isA<VaultLocked>()));
    }

    // Removing it leaves nothing behind.
    await again.forget();
    expect(await storage.readAll(), isEmpty);
    final after = WalletController();
    await after.load();
    expect(after.wallet, isNull);
  });
}
