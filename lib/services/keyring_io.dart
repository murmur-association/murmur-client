// The keyring check for native builds (keyring.dart): only Linux asks.

import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

const _service = 'org.freedesktop.secrets';
const _serviceInterface = 'org.freedesktop.Secret.Service';
const _collectionInterface = 'org.freedesktop.Secret.Collection';
const _promptInterface = 'org.freedesktop.Secret.Prompt';

Future<bool> keyringUsable() async {
  if (!Platform.isLinux) return true;
  // Tests of the built app wait less for a prompt nobody will answer.
  final seconds = int.tryParse(Platform.environment['MURMUR_KEYRING_PROMPT_SECONDS'] ?? '');
  return linuxKeyringUsable(DBusClient.session,
      promptTimeout: seconds == null ? const Duration(seconds: 90) : Duration(seconds: seconds));
}

/// The check, against the session bus `open` gives: whether the default
/// collection (where libsecret stores) is or can be made unlocked. A call
/// gets `timeout`; a password prompt gets `promptTimeout`, the user typing.
Future<bool> linuxKeyringUsable(DBusClient Function() open,
    {Duration timeout = const Duration(seconds: 3), Duration promptTimeout = const Duration(seconds: 90)}) async {
  final DBusClient client;
  try {
    client = open();
  } catch (_) {
    return true; // no session bus: the plugin fails at once
  }
  final service = DBusRemoteObject(client, name: _service, path: DBusObjectPath('/org/freedesktop/secrets'));
  try {
    var collection = (await service
            .callMethod(_serviceInterface, 'ReadAlias', [const DBusString('default')],
                replySignature: DBusSignature('o'))
            .timeout(timeout))
        .returnValues
        .first
        .asObjectPath();
    if (collection.value == '/') {
      // None yet: libsecret would make it, which asks for a password.
      final made = await service
          .callMethod(
              _serviceInterface,
              'CreateCollection',
              [
                DBusDict.stringVariant({'$_collectionInterface.Label': const DBusString('Default keyring')}),
                const DBusString('default'),
              ],
              replySignature: DBusSignature('oo'))
          .timeout(timeout);
      collection = made.returnValues[0].asObjectPath();
      final prompt = made.returnValues[1].asObjectPath();
      if (prompt.value != '/') return await _prompted(client, prompt, timeout, promptTimeout);
      return collection.value != '/';
    }
    final locked = (await DBusRemoteObject(client, name: _service, path: collection)
            .getProperty(_collectionInterface, 'Locked', signature: DBusSignature('b'))
            .timeout(timeout))
        .asBoolean();
    if (!locked) return true;
    final unlock = await service
        .callMethod(_serviceInterface, 'Unlock', [DBusArray.objectPath([collection])],
            replySignature: DBusSignature('aoo'))
        .timeout(timeout);
    final prompt = unlock.returnValues[1].asObjectPath();
    if (prompt.value == '/') return unlock.returnValues[0].asObjectPathArray().isNotEmpty;
    return await _prompted(client, prompt, timeout, promptTimeout);
  } on DBusServiceUnknownException {
    return true; // no keyring at all: the plugin fails at once
  } on DBusMethodResponseException {
    // An answer, if an error: a keyring that answers at once doesn't hang
    // the plugin either (and other keyrings answer in their own ways).
    return true;
  } on SocketException {
    return true; // no session bus listening
  } on TimeoutException {
    return false;
  } catch (_) {
    // Anything else: not knowing, the plugin could hang.
    return false;
  } finally {
    await client.close();
  }
}

/// Shows the keyring's prompt (the desktop's password dialog) and waits for
/// it: whether it was answered, not dismissed, within `promptTimeout`.
Future<bool> _prompted(DBusClient client, DBusObjectPath path, Duration timeout, Duration promptTimeout) async {
  final prompt = DBusRemoteObject(client, name: _service, path: path);
  final completed = DBusRemoteObjectSignalStream(object: prompt, interface: _promptInterface, name: 'Completed')
      .first
      .timeout(promptTimeout);
  // Waiting from before it's shown: a quick answer isn't missed.
  final shown = prompt.callMethod(_promptInterface, 'Prompt', [const DBusString('')]).timeout(timeout);
  await shown;
  final signal = await completed;
  return !signal.values.first.asBoolean();
}
