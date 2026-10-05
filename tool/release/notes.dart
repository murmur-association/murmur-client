// What a scheduled release changes besides the checkpoint: the version in
// pubspec.yaml and the notes in CHANGELOG.md. Text in, text out, so it's
// tested without touching files (test/release_notes_test.dart).

/// `pubspec` with its `version:` raised to the next patch release, and that
/// version: 0.2.1 becomes 0.2.2. A build suffix (`+3`) is dropped.
(String pubspec, String version) nextPatch(String pubspec) {
  // Up to the line's end, not past it: the blank line after stays.
  final line = RegExp(r'^version:[ \t]*(\d+)\.(\d+)\.(\d+)(\+\S+)?[ \t]*(?=\r?$)', multiLine: true);
  final found = line.allMatches(pubspec).toList();
  if (found.length != 1) throw const FormatException('pubspec.yaml needs exactly one `version: X.Y.Z` line');
  final m = found.single;
  final version = '${m[1]}.${m[2]}.${int.parse(m[3]!) + 1}';
  return (pubspec.replaceRange(m.start, m.end, 'version: $version'), version);
}

/// The checkpoint a `network.dart` ships for the testnet: (height, hash).
(int, String) shippedCheckpoint(String networkSource) {
  final found = RegExp(r"checkpoint: Checkpoint\((\d+), '([0-9a-f]{64})'\),").allMatches(networkSource).toList();
  if (found.length != 1) throw const FormatException('network.dart needs exactly one shipped checkpoint line');
  return (int.parse(found.single[1]!), found.single[2]!);
}

/// `1234567` as `1,234,567`, as the changelog writes heights.
String grouped(int n) => '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');

/// `changelog` with a section for `version`, dated `date` (YYYY-MM-DD),
/// saying the testnet checkpoint is now `height`. Notes waiting under
/// "## Unreleased" are released with it: that heading becomes the
/// version's, since the release holds everything on the default branch.
/// Otherwise the section goes above the newest release.
String withRelease(String changelog, {required String version, required String date, required int height}) {
  final note = '- **Changed: the testnet checkpoint** is now block ${grouped(height)}, '
      'refreshed from the live network by the scheduled release.';
  final unreleased = RegExp(r'^## Unreleased[ \t]*\r?\n(\r?\n)?', multiLine: true);
  final waiting = unreleased.firstMatch(changelog);
  final eol = changelog.contains('\r\n') ? '\r\n' : '\n';
  if (waiting != null) {
    return changelog.replaceRange(waiting.start, waiting.end,
        '## v$version: scheduled release, with what was waiting ($date)$eol$eol$note$eol');
  }
  final newest = RegExp(r'^## v\d', multiLine: true).firstMatch(changelog);
  if (newest == null) throw const FormatException('CHANGELOG.md has no release section to go above');
  return changelog.replaceRange(newest.start, newest.start,
      '## v$version: checkpoint refresh ($date)$eol${eol}No protocol or network change.$eol$eol$note$eol$eol');
}
