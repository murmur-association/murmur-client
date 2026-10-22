// What the scheduled release writes (tool/release/notes.dart): the next
// version, and its section in the changelog.

import 'package:flutter_test/flutter_test.dart';

import '../tool/release/notes.dart';

void main() {
  test('the version goes to the next patch release', () {
    expect(nextPatch('name: x\nversion: 0.2.1\nenvironment:\n'), ('name: x\nversion: 0.2.2\nenvironment:\n', '0.2.2'));
    expect(nextPatch('version: 1.9.9+4\n').$2, '1.9.10');
    // The lines around it are left alone, whatever the line endings.
    expect(nextPatch('version: 0.2.0\n\nenvironment:\n').$1, 'version: 0.2.1\n\nenvironment:\n');
    expect(nextPatch('version: 0.2.0\r\n\r\nenvironment:\r\n').$1, 'version: 0.2.1\r\n\r\nenvironment:\r\n');
    expect(() => nextPatch('name: x\n'), throwsFormatException);
    expect(() => nextPatch('version: 1.0\n'), throwsFormatException);
  });

  test('the shipped checkpoint is read from the source', () {
    final hash = 'ab' * 32;
    expect(shippedCheckpoint("    checkpoint: Checkpoint(19000, '$hash'),\n"), (19000, hash));
    expect(() => shippedCheckpoint('// checkpoint: none\n'), throwsFormatException);
    expect(grouped(19000), '19,000');
    expect(grouped(1234567), '1,234,567');
    expect(grouped(900), '900');
  });

  test('waiting notes are released with the checkpoint', () {
    const before = '# Changelog\n\nNewest first.\n\n## Unreleased\n\n- **Fixed:** a thing.\n\n## v0.2.1: older (2026-10-05)\n\n- x\n';
    final after = withRelease(before, version: '0.2.2', date: '2026-10-12', height: 21900);
    expect(
        after,
        '# Changelog\n\nNewest first.\n\n'
        '## v0.2.2: scheduled release, with what was waiting (2026-10-12)\n\n'
        '- **Changed: the testnet checkpoint** is now block 21,900, refreshed from the live network by the scheduled release.\n'
        '- **Fixed:** a thing.\n\n## v0.2.1: older (2026-10-05)\n\n- x\n');
    expect(after, isNot(contains('Unreleased')));
  });

  test('with nothing waiting, the release gets a section of its own, above the newest', () {
    const before = '# Changelog\n\nNewest first.\n\n## v0.2.1: older (2026-10-05)\n\n- x\n';
    expect(
        withRelease(before, version: '0.2.2', date: '2026-10-12', height: 21900),
        '# Changelog\n\nNewest first.\n\n'
        '## v0.2.2: checkpoint refresh (2026-10-12)\n\nNo protocol or network change.\n\n'
        '- **Changed: the testnet checkpoint** is now block 21,900, refreshed from the live network by the scheduled release.\n\n'
        '## v0.2.1: older (2026-10-05)\n\n- x\n');
  });

  test('an empty "Unreleased" heading is nothing waiting, and goes', () {
    // As a release by hand left it once (v0.9.0), which v0.9.1 then
    // released as "what was waiting", run into the section below.
    const expected = '# Changelog\n\nNewest first.\n\n'
        '## v0.2.2: checkpoint refresh (2026-10-12)\n\nNo protocol or network change.\n\n'
        '- **Changed: the testnet checkpoint** is now block 21,900, refreshed from the live network by the scheduled release.\n\n'
        '## v0.2.1: older (2026-10-05)\n\n- x\n';
    for (final heading in ['## Unreleased\n\n', '## Unreleased\n', '## Unreleased\n\n\n']) {
      final before = '# Changelog\n\nNewest first.\n\n$heading## v0.2.1: older (2026-10-05)\n\n- x\n';
      expect(withRelease(before, version: '0.2.2', date: '2026-10-12', height: 21900), expected, reason: heading);
    }
  });

  test('line endings are kept', () {
    const before = '# Changelog\r\n\r\n## Unreleased\r\n\r\n- a\r\n\r\n## v0.1.0: first (2026-09-30)\r\n';
    final after = withRelease(before, version: '0.1.1', date: '2026-10-12', height: 100);
    expect(after.replaceAll('\r\n', ''), isNot(contains('\n')));
    expect(after, contains('(2026-10-12)\r\n\r\n- **Changed: the testnet checkpoint** is now block 100,'));
  });
}
