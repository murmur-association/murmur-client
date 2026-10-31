// Whether the system's keyring can be used without hanging the app (Linux).
//
// On Linux the wallet's storage plugin (flutter_secure_storage) asks the
// keyring through libsecret on the app's main thread, and waits. A keyring
// that is locked, or not yet made, makes libsecret ask a prompter for the
// password; where there is none (some minimal desktops, a bare WSL session)
// the answer never comes, and the app froze before showing anything.
//
// So before the plugin is first used, the app asks the keyring itself over
// D-Bus (the Secret Service), with timeouts: unlocked, the plugin is used as
// before; locked, the app asks for it to be unlocked, which shows the
// desktop's own password prompt, and waits for the user a while; without
// an answer, the keyring counts as unusable and the plugin is never called
// (`Preferences` and `WalletController` then store nothing, and say why).
// No session bus or no keyring at all is left to the plugin, which fails at
// once there.

import 'keyring_io.dart' if (dart.library.js_interop) 'keyring_web.dart' as impl;

/// Whether the keyring may be used: false only where using it would hang.
/// Set once at startup by [checkKeyring].
bool keyringUsable = true;

/// Asks the keyring as said above; sets [keyringUsable].
Future<void> checkKeyring() async => keyringUsable = await impl.keyringUsable();
