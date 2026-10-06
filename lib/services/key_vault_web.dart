// In the browser: a passkey on this device (the platform authenticator:
// Windows Hello, Touch ID, the phone's lock screen) with the WebAuthn PRF
// extension. After the device's check, the authenticator returns a secret
// derived from the passkey and a salt we keep; that secret is the AES-GCM key
// the seed is encrypted with. Without the check, the key doesn't exist
// anywhere. No server: the passkey is only ever used here.
//
// Where the browser or authenticator lacks PRF (or the page isn't a secure
// context), this returns null and a passphrase is used instead.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:web/web.dart' as web;

import '../protocol/bytes.dart';
import 'key_vault.dart';

/// The PRF output for `salt` from the passkey `credential` (or any of this
/// site's passkeys when null), after the device's check; null if the
/// authenticator gave none.
Future<Uint8List?> _prf(Uint8List? credential, Uint8List salt) async {
  final options = web.PublicKeyCredentialRequestOptions(
    challenge: randomBytes(32).toJS,
    userVerification: 'required',
    timeout: 120000,
  );
  if (credential != null) {
    options.allowCredentials = [web.PublicKeyCredentialDescriptor(type: 'public-key', id: credential.toJS)].toJS;
  }
  options.extensions = {
    'prf': {
      'eval': {'first': salt.toJS},
    },
  }.jsify() as web.AuthenticationExtensionsClientInputs;
  final got = await web.window.navigator.credentials.get(web.CredentialRequestOptions(publicKey: options)).toDart;
  if (got == null) return null;
  return _first((got as web.PublicKeyCredential).getClientExtensionResults());
}

/// `results.prf.results.first`, if there.
Uint8List? _first(JSObject results) {
  final prf = results.getProperty<JSObject?>('prf'.toJS);
  final values = prf?.getProperty<JSObject?>('results'.toJS);
  final first = values?.getProperty<JSArrayBuffer?>('first'.toJS);
  return first?.toDart.asUint8List();
}

/// Protects `seed` with a new passkey, if this browser can. Returns null
/// when it can't make one at all (not a secure page, no platform
/// authenticator): the passphrase is then the protection, without asking.
/// Throws [PasskeyUnsupported] when a passkey was made but its manager
/// can't encrypt with it (a third-party manager without PRF, say), so the
/// user can try another, and [VaultLocked] when they dismiss the prompt.
Future<Map<String, String>?> sealWithDevice(Uint8List seed, String reason, VaultSlot slot) async {
  var created = false;
  try {
    if (!web.window.isSecureContext) return null;
    if (!(await web.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().toDart).toDart) return null;
    final salt = randomBytes(32);
    // A passkey for this wallet (or for the invitations) on this device,
    // asking for PRF support. Its name is what the passkey manager lists.
    final name = switch (slot) {
      VaultSlot.wallet => 'Murmur wallet',
      VaultSlot.invitations => 'Murmur invitations',
    };
    final creation = web.PublicKeyCredentialCreationOptions(
      challenge: randomBytes(32).toJS,
      rp: web.PublicKeyCredentialRpEntity(name: 'Murmur'),
      user: web.PublicKeyCredentialUserEntity(id: randomBytes(16).toJS, name: name, displayName: reason),
      pubKeyCredParams: [
        web.PublicKeyCredentialParameters(type: 'public-key', alg: -7),
        web.PublicKeyCredentialParameters(type: 'public-key', alg: -257),
      ].toJS,
      authenticatorSelection: web.AuthenticatorSelectionCriteria(
        authenticatorAttachment: 'platform',
        userVerification: 'required',
        residentKey: 'discouraged',
      ),
      timeout: 120000,
    );
    // Asking for the output already: some authenticators give it at
    // creation, which saves a second prompt.
    creation.extensions = {
      'prf': {
        'eval': {'first': salt.toJS},
      },
    }.jsify() as web.AuthenticationExtensionsClientInputs;
    final made = await web.window.navigator.credentials.create(web.CredentialCreationOptions(publicKey: creation)).toDart;
    if (made == null) throw const VaultLocked(false);
    created = true;
    final credential = made as web.PublicKeyCredential;
    final results = credential.getClientExtensionResults();
    final enabled = results.getProperty<JSObject?>('prf'.toJS)?.getProperty<JSBoolean?>('enabled'.toJS)?.toDart;
    // Only a clear "no" settles it now: some managers say nothing at
    // creation, yet give the output when asked.
    if (enabled == false) throw const PasskeyUnsupported();
    final id = credential.rawId.toDart.asUint8List();
    final secret = _first(results) ?? await _prf(id, salt);
    if (secret == null) throw const PasskeyUnsupported();
    return {'protection': 'passkey', 'credential': toHex(id), 'salt': toHex(salt), ...await seal(seed, SecretKey(secret))};
  } on VaultLocked {
    rethrow;
  } on PasskeyUnsupported {
    rethrow;
  } catch (e) {
    // The user dismissed the prompt: nothing is saved.
    if (e is JSObject && (e as web.DOMException).name == 'NotAllowedError') throw const VaultLocked(false);
    // Anything else once a passkey exists: that manager can't do it.
    if (created) throw const PasskeyUnsupported();
    return null;
  }
}

Future<Uint8List> openWithDevice(Map<String, String> stored, String reason) async {
  try {
    final secret = await _prf(fromHex(stored['credential']!), fromHex(stored['salt']!));
    if (secret == null) throw const VaultLocked(false);
    return await open(stored, SecretKey(secret));
  } on VaultLocked {
    rethrow;
  } catch (_) {
    throw const VaultLocked(false);
  }
}

/// The passkey stays in the device's passkey list (a page can't delete
/// one); without the stored salt and ciphertext it unlocks nothing.
Future<void> forgetDevice(Map<String, String> stored) async {}
