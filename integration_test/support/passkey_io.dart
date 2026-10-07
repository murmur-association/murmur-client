// Outside a browser there are no passkeys: the vault uses the device's key
// store, or a passphrase.

Future<bool> passkeyAuthenticatorThere() async => false;
