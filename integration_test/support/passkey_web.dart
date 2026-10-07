// In a browser: whether the device offers a passkey authenticator of its
// own, as the app's vault asks before making a passkey.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> passkeyAuthenticatorThere() async {
  if (!web.window.isSecureContext) return false;
  return (await web.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().toDart).toDart;
}
