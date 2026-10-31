// The Linux keyring check (lib/services/keyring_io.dart), against a stand-in
// Secret Service on a bus of the test's own: the app uses the keyring where
// that can't hang it, and gives up on one that is locked and can't ask,
// instead of freezing before it shows anything. Linux only: D-Bus is Linux's
// (CI's test job runs there; locally, in WSL).
@TestOn('linux')
library;

import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/keyring_io.dart';

const _secret = 'org.freedesktop.Secret';

/// How the stand-in keyring behaves.
enum _Keyring { unlocked, lockedAnswered, lockedDismissed, lockedNobodyAnswers, none, silent, unmade }

class _Service extends DBusObject {
  _Service(this.kind) : super(DBusObjectPath('/org/freedesktop/secrets'));

  final _Keyring kind;
  late final _Prompt prompt;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    final collection = DBusObjectPath('/org/freedesktop/secrets/collection/login');
    switch (call.name) {
      case 'ReadAlias':
        // Never answering: a keyring that hangs.
        if (kind == _Keyring.silent) await Completer<void>().future;
        return DBusMethodSuccessResponse([kind == _Keyring.unmade ? DBusObjectPath('/') : collection]);
      case 'CreateCollection':
        return DBusMethodSuccessResponse([DBusObjectPath('/'), prompt.path]);
      case 'Unlock':
        return DBusMethodSuccessResponse([DBusArray.objectPath(const []), prompt.path]);
    }
    return DBusMethodErrorResponse.unknownMethod();
  }
}

class _Collection extends DBusObject {
  _Collection(this.kind) : super(DBusObjectPath('/org/freedesktop/secrets/collection/login'));

  final _Keyring kind;

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async =>
      DBusGetPropertyResponse(DBusBoolean(kind != _Keyring.unlocked));
}

class _Prompt extends DBusObject {
  _Prompt(this.kind) : super(DBusObjectPath('/org/freedesktop/secrets/prompt/1'));

  final _Keyring kind;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.name != 'Prompt') return DBusMethodErrorResponse.unknownMethod();
    // The desktop's dialog: answered, dismissed, or nobody there to show it.
    if (kind != _Keyring.lockedNobodyAnswers) {
      Timer(const Duration(milliseconds: 50), () {
        emitSignal('$_secret.Prompt', 'Completed',
            [DBusBoolean(kind == _Keyring.lockedDismissed), const DBusVariant(DBusString(''))]);
      });
    }
    return DBusMethodSuccessResponse();
  }
}

/// A bus with the stand-in keyring on it (or none), and the check's answer.
Future<bool> _check(_Keyring kind) async {
  final server = DBusServer();
  addTearDown(server.close);
  final address = await server.listenAddress(DBusAddress.tcp('127.0.0.1', port: 0));
  if (kind != _Keyring.none) {
    final host = DBusClient(address);
    addTearDown(host.close);
    await host.requestName('org.freedesktop.secrets');
    final service = _Service(kind)..prompt = _Prompt(kind);
    await host.registerObject(service);
    await host.registerObject(_Collection(kind));
    await host.registerObject(service.prompt);
  }
  return linuxKeyringUsable(() => DBusClient(address),
      timeout: const Duration(milliseconds: 500), promptTimeout: const Duration(seconds: 1));
}

void main() {
  test('an unlocked keyring is used', () async => expect(await _check(_Keyring.unlocked), isTrue));

  test('a locked one is used once its password prompt is answered', () async {
    expect(await _check(_Keyring.lockedAnswered), isTrue);
  });

  test('a locked one whose prompt is dismissed is not', () async {
    expect(await _check(_Keyring.lockedDismissed), isFalse);
  });

  test('a locked one with nobody to answer its prompt is given up on, not waited for for ever', () async {
    final watch = Stopwatch()..start();
    expect(await _check(_Keyring.lockedNobodyAnswers), isFalse);
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('one that never answers is given up on too', () async {
    expect(await _check(_Keyring.silent), isFalse);
  });

  test('a keyring not made yet is made only through its prompt', () async {
    expect(await _check(_Keyring.unmade), isTrue);
  });

  test('no keyring at all is left to the plugin, which fails at once there', () async {
    expect(await _check(_Keyring.none), isTrue);
  });
}
