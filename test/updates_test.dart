import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/wire.dart' show protocolVersion;
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/updates_io.dart';
import 'package:murmur_client/ui/l10n.dart';

void main() {
  test('a node ahead of the app says to update it; one behind says only the versions', () {
    final l = lookupAppLocalizations(const Locale('en'));
    // Not a Flatpak here (tests don't run in one): the plain wording.
    expect(linkErrorText(l, const LinkError(LinkErrorKind.version, nodeVersion: protocolVersion + 1)),
        l.errAppOutdated);
    expect(linkErrorText(l, const LinkError(LinkErrorKind.version, nodeVersion: protocolVersion - 1)),
        l.errVersion(protocolVersion - 1, protocolVersion));
  });

  group('the first run as a Flatpak', () {
    late Directory home;
    late String outside, inside;

    setUp(() {
      home = Directory.systemTemp.createTempSync('murmur-flatpak-');
      outside = '${home.path}/.local/share';
      inside = '${home.path}/.var/app/info.murmur.client/data';
      File('$outside/info.murmur.client/shared_preferences.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"flutter.consent":"allowed"}');
      File('$outside/murmur-client/own/messages.log')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      // The chain's local copy stays behind: it's fetched again.
      File('$outside/murmur-client/chain/headers.bin').createSync(recursive: true);
    });
    tearDown(() => home.deleteSync(recursive: true));

    Map<String, String> env({bool flatpak = true}) => {
          'HOME': home.path,
          'XDG_DATA_HOME': inside,
          if (flatpak) 'FLATPAK_ID': 'info.murmur.client',
        };

    test('takes the settings and the own messages along, not the chain', () async {
      expect(await moveIntoFlatpakFolders(env()), ['info.murmur.client', 'murmur-client/own']);
      expect(File('$inside/info.murmur.client/shared_preferences.json').readAsStringSync(),
          '{"flutter.consent":"allowed"}');
      expect(File('$inside/murmur-client/own/messages.log').readAsBytesSync(), [1, 2, 3]);
      expect(Directory('$inside/murmur-client/chain').existsSync(), isFalse);
      // Copied, not moved: an archive of the app still finds them.
      expect(File('$outside/murmur-client/own/messages.log').existsSync(), isTrue);
    });

    test('only once: what the Flatpak wrote since is never overwritten', () async {
      File('$inside/info.murmur.client/shared_preferences.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      expect(await moveIntoFlatpakFolders(env()), isEmpty);
      expect(File('$inside/info.murmur.client/shared_preferences.json').readAsStringSync(), '{}');
      expect(File('$inside/murmur-client/own/messages.log').existsSync(), isFalse);
    });

    test('nothing outside a Flatpak', () async {
      expect(await moveIntoFlatpakFolders(env(flatpak: false)), isEmpty);
      expect(Directory(inside).existsSync(), isFalse);
    });
  });
}
