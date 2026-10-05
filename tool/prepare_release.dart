// Prepares the next patch release around a refreshed checkpoint, for the
// scheduled release job (.gitlab-ci.yml, scheduled-release): raises
// `version:` in pubspec.yaml, gives CHANGELOG.md a section for it (taking
// the notes waiting under "Unreleased" along), and writes the version to
// build/release-version for the job to commit and tag.
//
//   dart run tool/prepare_release.dart
//
// It changes files only: committing, pushing and tagging are the job's.

import 'dart:io';

import 'release/notes.dart';

void main() {
  final pubspec = File('pubspec.yaml'), changelog = File('CHANGELOG.md');
  final (height, _) = shippedCheckpoint(File('lib/protocol/network.dart').readAsStringSync());
  final (raised, version) = nextPatch(pubspec.readAsStringSync());
  final now = DateTime.now().toUtc();
  final date = '${now.year}-${'${now.month}'.padLeft(2, '0')}-${'${now.day}'.padLeft(2, '0')}';
  changelog.writeAsStringSync(withRelease(changelog.readAsStringSync(), version: version, date: date, height: height));
  pubspec.writeAsStringSync(raised);
  File('build/release-version')
    ..createSync(recursive: true)
    ..writeAsStringSync(version);
  stdout.writeln('prepared v$version: checkpoint at block $height');
}
