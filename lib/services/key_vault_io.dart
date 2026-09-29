// Native: the system's hardware key store on Android, iOS and macOS
// (biometric_storage), which releases the seed only after biometrics or the
// device passcode, every time. Windows and Linux fall back to a passphrase.

import 'dart:io';
import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';

import '../protocol/bytes.dart';
import 'key_vault.dart';

const _file = 'murmur_wallet_seed_v2';

bool get _supported => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

Future<BiometricStorageFile> _storage() => BiometricStorage().getStorage(
      _file,
      options: StorageFileInitOptions(
        authenticationRequired: true,
        authenticationValidityDurationSeconds: -1, // every time
        androidBiometricOnly: true, // required by Android for "every time"
        darwinBiometricOnly: false, // the passcode also unlocks on Apple devices
      ),
    );

PromptInfo _prompt(String reason) => PromptInfo(
      androidPromptInfo: AndroidPromptInfo(title: reason),
      iosPromptInfo: IosPromptInfo(saveTitle: reason, accessTitle: reason),
      macOsPromptInfo: IosPromptInfo(saveTitle: reason, accessTitle: reason),
    );

Future<Map<String, String>?> sealWithDevice(Uint8List seed, String reason) async {
  if (!_supported) return null;
  try {
    if (await BiometricStorage().canAuthenticate() != CanAuthenticateResponse.success) return null;
    await (await _storage()).write(toHex(seed), promptInfo: _prompt(reason));
    return {'protection': 'device'};
  } on AuthException {
    throw const VaultLocked(false);
  } catch (_) {
    return null; // no usable key store: a passphrase instead
  }
}

Future<Uint8List> openWithDevice(Map<String, String> stored, String reason) async {
  try {
    final hex = await (await _storage()).read(promptInfo: _prompt(reason));
    if (hex == null) throw const VaultLocked(false);
    return fromHex(hex);
  } on AuthException {
    throw const VaultLocked(false);
  }
}

Future<void> forgetDevice(Map<String, String> stored) async {
  if (stored['protection'] != 'device') return;
  try {
    await (await _storage()).delete();
  } catch (_) {}
}
