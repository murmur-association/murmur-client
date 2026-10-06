// The key vault's prompts, answered by a test: the passphrase to set up,
// the one to enter, and what to do when a passkey manager can't encrypt.

import 'package:murmur_client/services/key_vault.dart';

class TestPrompts implements VaultPrompts {
  TestPrompts(this.setup, this.entered, {this.onPasskeyUnsupported = const []});

  /// The answer to "choose a passphrase"; null cancels.
  final String? setup;

  /// The answer to "your passphrase"; null cancels.
  final String? entered;

  /// Answers to "this manager can't encrypt", in turn.
  final List<bool?> onPasskeyUnsupported;

  /// How often each was asked.
  int asked = 0, setupAsked = 0, passkeyAsked = 0;

  @override
  Future<String?> newPassphrase() async {
    setupAsked++;
    return setup;
  }

  @override
  Future<String?> passphrase(String reason) async {
    asked++;
    return entered;
  }

  @override
  Future<bool?> passkeyUnsupported() async => onPasskeyUnsupported[passkeyAsked++];
}
