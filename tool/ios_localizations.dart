// The iPhone app's own texts in every language the app has (rule 8: they
// live in lib/l10n/app_*.arb like every other text): what iOS shows from
// Info.plist rather than from the app, which today is the reason Face ID
// asks with (NSFaceIDUsageDescription). Writes, from the ARB files:
//
// - ios/Runner/<language>.lproj/InfoPlist.strings, one per language;
// - in ios/Runner/Info.plist, the English text and the languages the app
//   has (CFBundleLocalizations, so iOS knows it speaks them);
// - in ios/Runner.xcodeproj/project.pbxproj, the strings files as one
//   localized resource of the app, and its known regions.
//
//   dart run tool/ios_localizations.dart
//
// Run it after changing an ARB file's iOS texts or adding a language;
// test/ios_localizations_test.dart fails until it's run.

import 'dart:convert';
import 'dart:io';

/// The ARB keys that become Info.plist keys.
const iosTexts = {'faceIdReason': 'NSFaceIDUsageDescription'};

const _plist = 'ios/Runner/Info.plist';
const _project = 'ios/Runner.xcodeproj/project.pbxproj';

// Fixed ids for what this adds to the Xcode project, so running it again
// changes nothing ("MURM" in hex, then a number).
const _buildFile = '4D55524D0000000000000001';
const _group = '4D55524D0000000000000002';
String _fileRef(int i) => '4D55524D00000000000001${i.toRadixString(16).padLeft(2, '0').toUpperCase()}';

/// iOS's name for an ARB file's language: Chinese here is simplified.
String _lproj(String language) => language == 'zh' ? 'zh-Hans' : language;

/// The languages of the ARB files, English first, then by code.
List<String> arbLanguages(String root) {
  final codes = [
    for (final f in Directory('$root/lib/l10n').listSync().whereType<File>())
      if (RegExp(r'app_([a-z]+)\.arb$').firstMatch(f.path.replaceAll('\\', '/')) case final m?) m.group(1)!,
  ]..sort();
  return ['en', ...codes.where((c) => c != 'en')];
}

String _quote(String s) => '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';

String _xml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _read(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');

/// Every file this writes, by path from `root`, with what it must hold:
/// the strings files, and Info.plist and the Xcode project as they are now
/// with this tool's parts brought up to date.
Map<String, String> iosLocalizationFiles([String root = '.']) {
  final languages = arbLanguages(root);
  final texts = {
    for (final l in languages)
      l: (jsonDecode(File('$root/lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, Object?>),
  };
  final files = <String, String>{};
  for (final l in languages) {
    files['ios/Runner/${_lproj(l)}.lproj/InfoPlist.strings'] = [
      '/* Generated from lib/l10n/app_$l.arb by tool/ios_localizations.dart: edit those. */',
      for (final MapEntry(key: arb, value: plist) in iosTexts.entries) '${_quote(plist)} = ${_quote('${texts[l]![arb]}')};',
      '',
    ].join('\n');
  }

  // Info.plist: the English texts, and the languages.
  var plist = _read('$root/$_plist');
  for (final MapEntry(key: arb, value: key) in iosTexts.entries) {
    final entry = '\t<key>$key</key>\n\t<string>${_xml('${texts['en']![arb]}')}</string>\n';
    final existing = RegExp('\t<key>$key</key>\n\t<string>[^<]*</string>\n');
    plist = existing.hasMatch(plist)
        ? plist.replaceFirst(existing, entry)
        : plist.replaceFirst('\t<key>UIApplicationSceneManifest</key>\n', '$entry\t<key>UIApplicationSceneManifest</key>\n');
  }
  final localizations =
      '\t<key>CFBundleLocalizations</key>\n\t<array>\n${[for (final l in languages) '\t\t<string>${_lproj(l)}</string>\n'].join()}\t</array>\n';
  final existingLocalizations = RegExp('\t<key>CFBundleLocalizations</key>\n\t<array>\n(\t\t<string>[^<]*</string>\n)*\t</array>\n');
  plist = existingLocalizations.hasMatch(plist)
      ? plist.replaceFirst(existingLocalizations, localizations)
      : plist.replaceFirst('\t<key>CFBundleName</key>\n', '$localizations\t<key>CFBundleName</key>\n');
  files[_plist] = plist;

  // The Xcode project: this tool's entries taken out, then put back as they
  // must be now.
  // (The group's block first: its first line looks like the one-line entries.)
  var project = _read('$root/$_project')
      .replaceAll(RegExp('\t\t$_group /\\* InfoPlist.strings \\*/ = \\{\n.*?\n\t\t\\};\n', dotAll: true), '')
      .replaceAll(RegExp('^(\t\t|\t\t\t\t)4D55524D[0-9A-F]{16} [^\n]*\n', multiLine: true), '');
  String before(String marker, String text) {
    if (!project.contains(marker)) throw StateError('$_project has no "$marker"');
    return project = project.replaceFirst(marker, '$text$marker');
  }

  before('/* End PBXBuildFile section */',
      '\t\t$_buildFile /* InfoPlist.strings in Resources */ = {isa = PBXBuildFile; fileRef = $_group /* InfoPlist.strings */; };\n');
  before('/* End PBXFileReference section */', [
    for (final (i, l) in languages.indexed)
      '\t\t${_fileRef(i)} /* ${_lproj(l)} */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
          'name = ${_quoteName(_lproj(l))}; path = ${_lproj(l)}.lproj/InfoPlist.strings; sourceTree = "<group>"; };\n',
  ].join());
  before('/* End PBXVariantGroup section */', [
    '\t\t$_group /* InfoPlist.strings */ = {\n',
    '\t\t\tisa = PBXVariantGroup;\n',
    '\t\t\tchildren = (\n',
    for (final (i, l) in languages.indexed) '\t\t\t\t${_fileRef(i)} /* ${_lproj(l)} */,\n',
    '\t\t\t);\n',
    '\t\t\tname = InfoPlist.strings;\n',
    '\t\t\tsourceTree = "<group>";\n',
    '\t\t};\n',
  ].join());
  // In the Runner group, after Info.plist; among the app's resources.
  const infoPlist = '\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,\n';
  if (!project.contains(infoPlist)) throw StateError('$_project: no Info.plist in the Runner group');
  project = project.replaceFirst(infoPlist, '$infoPlist\t\t\t\t$_group /* InfoPlist.strings */,\n');
  const assets = '\t\t\t\t97C146FE1CF9000F007C117D /* Assets.xcassets in Resources */,\n';
  if (!project.contains(assets)) throw StateError('$_project: no Assets.xcassets among the resources');
  project = project.replaceFirst(assets, '$assets\t\t\t\t$_buildFile /* InfoPlist.strings in Resources */,\n');
  project = project.replaceFirst(RegExp('knownRegions = \\(\n(\t\t\t\t[^\n]*,\n)*\t\t\t\\);'),
      'knownRegions = (\n${[for (final r in [...languages.map(_lproj), 'Base']) '\t\t\t\t${_quoteName(r)},\n'].join()}\t\t\t);');
  files[_project] = project;
  return files;
}

/// A name in an Xcode project: quoted when it holds a dash.
String _quoteName(String name) => name.contains('-') ? '"$name"' : name;

void main() {
  for (final MapEntry(key: path, value: content) in iosLocalizationFiles().entries) {
    final file = File(path);
    final old = file.existsSync() ? file.readAsStringSync().replaceAll('\r\n', '\n') : null;
    if (old == content) continue;
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    stdout.writeln('wrote $path');
  }
}
