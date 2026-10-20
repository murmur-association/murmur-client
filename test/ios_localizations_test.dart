// The iPhone app's texts that iOS shows from Info.plist (the Face ID
// reason) come from the ARB files like every other text (rule 8), through
// tool/ios_localizations.dart: this fails when an ARB file changed and the
// tool wasn't run, or when one language lacks a text.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/ios_localizations.dart';

void main() {
  test('every language has every iOS text', () {
    for (final language in arbLanguages('.')) {
      final arb = jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, Object?>;
      for (final key in iosTexts.keys) {
        expect(arb[key], isA<String>().having((s) => s.trim(), 'text', isNotEmpty), reason: '$key in app_$language.arb');
      }
    }
  });

  test('the iOS files match the ARB files (else: dart run tool/ios_localizations.dart)', () {
    for (final MapEntry(key: path, value: content) in iosLocalizationFiles().entries) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.readAsStringSync().replaceAll('\r\n', '\n'), content, reason: path);
    }
  });
}
