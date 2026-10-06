// The wallet seed at rest: always encrypted, with a key that only the
// device's own check (or the user's passphrase) releases. Every signature,
// "Show seed" and "Remove wallet" unlocks it anew; nothing keeps it
// unlocked (ask every time). It's never written anywhere in the clear.
//
// How, by platform (the first available is used when a wallet is saved):
// - device: Android, iOS and macOS keep the seed in the system's hardware
//   key store (Keystore, Keychain with the Secure Enclave), which releases it
//   only after biometrics or the device passcode (package biometric_storage);
// - passkey: in the browser, a passkey on this device with the WebAuthn PRF
//   extension yields, after the device's check, a secret that is the AES-GCM
//   key (no server; see key_vault_web.dart);
// - passphrase: everywhere else (Windows and Linux apps, browsers without
//   PRF), a passphrase the user chooses, stretched with PBKDF2-SHA256 into
//   an AES-GCM key.
//
// Losing the device key or forgetting the passphrase makes the stored seed
// unreadable: the seed backup is then the only way back.
//
// The vault has a second slot, with a protection of its own: the key of the
// invitation cards this device made (see [VaultSlot.invitations]). Cards
// outlive the wallet that funded them, so their key can't hang on its seed.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../protocol/bytes.dart';
import 'key_vault_io.dart' if (dart.library.js_interop) 'key_vault_web.dart' as impl;

/// What the vault needs from the interface: passphrases, when that's the
/// protection. Device and passkey checks show the system's own prompt.
abstract class VaultPrompts {
  /// A new passphrase, typed twice; null if the user cancels.
  Future<String?> newPassphrase();

  /// The passphrase, to `reason`; null if the user cancels.
  Future<String?> passphrase(String reason);

  /// A passkey was made, but its manager can't encrypt with it (no PRF):
  /// true to try again (another manager), false to use a passphrase, null
  /// to cancel.
  Future<bool?> passkeyUnsupported();
}

/// A passkey was created, but the passkey manager the user picked can't
/// derive an encryption key from it (the WebAuthn PRF extension). Unlike a
/// device with no passkeys at all, this is worth telling the user: another
/// manager on the same device may well support it.
class PasskeyUnsupported implements Exception {
  const PasskeyUnsupported();
}

/// The user cancelled, or the check or passphrase failed.
class VaultLocked implements Exception {
  const VaultLocked(this.wrongPassphrase);

  /// A passphrase was given but didn't decrypt the seed.
  final bool wrongPassphrase;
}

/// What a vault record protects. Each has its own entry in the device's key
/// store, or its own passkey or passphrase.
enum VaultSlot {
  /// The wallet's seed.
  wallet,

  /// The key that opens the invitation cards' codes ([sealTo]): asked for
  /// to show, print or cancel a card, never to make or list them.
  invitations,
}

/// Encrypts `seed`, choosing the strongest protection this device has;
/// returns what to store (never the seed). May prompt. When the chosen
/// passkey manager can't encrypt, the user picks: another try, or a
/// passphrase. `device` replaces the platform's own protection in tests.
Future<Map<String, String>> sealSeed(Uint8List seed, VaultPrompts prompts,
    {required String reason,
    VaultSlot slot = VaultSlot.wallet,
    Future<Map<String, String>?> Function(Uint8List, String)? device}) async {
  final seal = device ?? (Uint8List seed, String reason) => impl.sealWithDevice(seed, reason, slot);
  while (true) {
    try {
      return await seal(seed, reason) ?? await sealWithPassphrase(seed, prompts);
    } on PasskeyUnsupported {
      switch (await prompts.passkeyUnsupported()) {
        case true:
          continue; // another manager
        case false:
          return sealWithPassphrase(seed, prompts);
        case null:
          throw const VaultLocked(false);
      }
    }
  }
}

/// Decrypts what [sealSeed] stored; prompts every time. Throws [VaultLocked].
Future<Uint8List> openSeed(Map<String, String> stored, VaultPrompts prompts, {required String reason}) async {
  return switch (stored['protection']) {
    'passphrase' => openWithPassphrase(stored, prompts, reason),
    'device' || 'passkey' => impl.openWithDevice(stored, reason),
    _ => throw const VaultLocked(false),
  };
}

/// Forgets whatever the device keeps for this wallet (its key-store entry).
Future<void> forgetSeed(Map<String, String> stored) => impl.forgetDevice(stored);

// ---- passphrase --------------------------------------------------------------------

/// PBKDF2 rounds: OWASP's figure for PBKDF2-HMAC-SHA256. Stored with each
/// wallet, so it can be raised for new ones.
const passphraseRounds = 600000;

/// Shortest passphrase accepted.
const minPassphraseLength = 8;

Future<SecretKey> _stretch(String passphrase, List<int> salt, int rounds) =>
    Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: rounds, bits: 256)
        .deriveKeyFromPassword(password: passphrase, nonce: salt);

Future<Map<String, String>> sealWithPassphrase(Uint8List seed, VaultPrompts prompts) async {
  final passphrase = await prompts.newPassphrase();
  if (passphrase == null) throw const VaultLocked(false);
  final salt = randomBytes(16);
  final key = await _stretch(passphrase, salt, passphraseRounds);
  return {'protection': 'passphrase', 'rounds': '$passphraseRounds', 'salt': toHex(salt), ...await seal(seed, key)};
}

Future<Uint8List> openWithPassphrase(Map<String, String> stored, VaultPrompts prompts, String reason) async {
  final passphrase = await prompts.passphrase(reason);
  if (passphrase == null) throw const VaultLocked(false);
  final key = await _stretch(passphrase, fromHex(stored['salt']!), int.parse(stored['rounds']!));
  try {
    return await open(stored, key);
  } on SecretBoxAuthenticationError {
    throw const VaultLocked(true);
  }
}

// ---- AES-GCM ---------------------------------------------------------------------------

final _aes = AesGcm.with256bits();

/// `seed` under `key`: nonce and ciphertext (with its tag), hex.
Future<Map<String, String>> seal(Uint8List seed, SecretKey key) async {
  final box = await _aes.encrypt(seed, secretKey: key);
  return {'nonce': toHex(box.nonce), 'box': toHex([...box.cipherText, ...box.mac.bytes])};
}

/// What [seal] stored, under `key`. Throws [SecretBoxAuthenticationError]
/// with the wrong key.
Future<Uint8List> open(Map<String, String> stored, SecretKey key) async {
  final box = fromHex(stored['box']!);
  final plain = await _aes.decrypt(
    SecretBox(box.sublist(0, box.length - 16), nonce: fromHex(stored['nonce']!), mac: Mac(box.sublist(box.length - 16))),
    secretKey: key,
  );
  return Uint8List.fromList(plain);
}

// ---- sealing to a public key ----------------------------------------------------------
//
// So that something can be put away without unlocking anything: whoever
// holds the public key can seal, and only the secret, kept in the vault,
// opens. X25519 with a key pair made for each sealing, HKDF-SHA256 over the
// shared secret and both public keys, then AES-GCM as above.

final _x25519 = X25519();

/// The public key of the 32-byte `secret`, to [sealTo].
Future<Uint8List> sealingKeyOf(Uint8List secret) async =>
    Uint8List.fromList((await (await _x25519.newKeyPairFromSeed(secret)).extractPublicKey()).bytes);

Future<SecretKey> _sharedKey(SimpleKeyPair mine, Uint8List theirs, Uint8List sender, Uint8List recipient) async {
  final shared = await _x25519.sharedSecretKey(
      keyPair: mine, remotePublicKey: SimplePublicKey(theirs, type: KeyPairType.x25519));
  return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared, nonce: [...sender, ...recipient], info: utf8.encode('murmur sealed to a key'));
}

/// `data` for the holder of `publicKey`'s secret alone.
Future<Map<String, String>> sealTo(Uint8List publicKey, Uint8List data) async {
  final once = await _x25519.newKeyPair();
  final sender = Uint8List.fromList((await once.extractPublicKey()).bytes);
  return {'from': toHex(sender), ...await seal(data, await _sharedKey(once, publicKey, sender, publicKey))};
}

/// What [sealTo] sealed, with the `secret` of its public key. Throws
/// [SecretBoxAuthenticationError] with another secret.
Future<Uint8List> openSealed(Map<String, String> sealed, Uint8List secret) async {
  final mine = await _x25519.newKeyPairFromSeed(secret);
  final sender = fromHex(sealed['from']!);
  final recipient = Uint8List.fromList((await mine.extractPublicKey()).bytes);
  return open(sealed, await _sharedKey(mine, sender, sender, recipient));
}

Uint8List randomBytes(int n) => Uint8List.fromList(SecretKeyData.random(length: n).bytes);

String encodeStored(Map<String, String> stored) => jsonEncode(stored);

Map<String, String>? decodeStored(String? json) {
  if (json == null) return null;
  try {
    return (jsonDecode(json) as Map).map((k, v) => MapEntry('$k', '$v'));
  } on FormatException {
    return null;
  }
}
