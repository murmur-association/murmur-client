// The winget manifests the release writes (tool/release/winget.dart).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../tool/release/winget.dart';

void main() {
  final sha = 'ab12' * 16;
  final manifests = wingetManifests(
    version: '0.10.4',
    installerName: 'murmur-client-v0.10.4-windows-x64-setup.exe',
    sha256: sha,
    date: DateTime.utc(2026, 11, 5),
  );
  YamlMap read(String name) => loadYaml(manifests[name]!) as YamlMap;

  test('three manifests of one package and version, in the folder winget-pkgs keeps', () {
    expect(manifests.keys, {
      'MurmurAssociation.Murmur.yaml',
      'MurmurAssociation.Murmur.installer.yaml',
      'MurmurAssociation.Murmur.locale.en-US.yaml',
    });
    for (final name in manifests.keys) {
      final m = read(name);
      expect(m['PackageIdentifier'], wingetId, reason: name);
      expect(m['PackageVersion'], '0.10.4', reason: name);
      expect(m['ManifestVersion'], wingetManifestVersion, reason: name);
    }
    expect(wingetFolder('0.10.4'), 'manifests/m/MurmurAssociation/Murmur/0.10.4');
  });

  test('the installer is the release download, by its hash, installed per user', () {
    final m = read('MurmurAssociation.Murmur.installer.yaml');
    expect(m['InstallerType'], 'inno');
    expect(m['Scope'], 'user');
    expect(m['ReleaseDate'], '2026-11-05');
    final installer = (m['Installers'] as YamlList).single as YamlMap;
    expect(installer['InstallerUrl'],
        'https://github.com/murmur-association/murmur-client/releases/download/v0.10.4/murmur-client-v0.10.4-windows-x64-setup.exe');
    expect(installer['InstallerSha256'], sha.toUpperCase());
  });

  test("the product code is the installer's AppId, as Windows lists it", () {
    final iss = File('windows/installer/murmur.iss').readAsStringSync();
    final appId = RegExp(r'^AppId=\{(\{[0-9A-F-]+\})$', multiLine: true).firstMatch(iss)!.group(1);
    expect(read('MurmurAssociation.Murmur.installer.yaml')['ProductCode'], '${appId}_is1');
  });

  test('nothing about value or buying, and the testnet tokens are for testing (rule 10)', () {
    final text = manifests['MurmurAssociation.Murmur.locale.en-US.yaml']!.toLowerCase();
    for (final word in ['price', 'buy', 'invest', 'return', 'profit', 'money']) {
      expect(text, isNot(contains(word)), reason: word);
    }
    expect(text, contains('for testing only'));
  });

  test('a malformed version or hash is refused', () {
    expect(() => wingetManifests(version: 'v1.0', installerName: 'x.exe', sha256: sha, date: DateTime(2026)),
        throwsFormatException);
    expect(() => wingetManifests(version: '1.0.0', installerName: 'x.exe', sha256: 'abc', date: DateTime(2026)),
        throwsFormatException);
  });
}
