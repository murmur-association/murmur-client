// The workflows' configuration (.github/workflows), checked before a push
// meets GitHub's own check: a workflow GitHub refuses runs no job at all,
// and a release or the scheduled release would then never start. (A run
// line holding ": " outside quotes is read as a mapping: that refused a
// push once, on the earlier CI.)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final files = Directory('.github/workflows')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final workflows = {for (final f in files) f.uri.pathSegments.last: loadYaml(f.readAsStringSync()) as YamlMap};

  Iterable<(String, String, YamlMap)> jobs() sync* {
    for (final MapEntry(key: file, value: workflow) in workflows.entries) {
      for (final MapEntry(:key, :value) in (workflow['jobs'] as YamlMap).entries) {
        yield (file, key as String, value as YamlMap);
      }
    }
  }

  test('the regression, the release and the scheduled release are there', () {
    expect(workflows.keys, containsAll(['regression.yml', 'release.yml', 'scheduled-release.yml']));
  });

  test('every step runs a string or uses an action', () {
    final bad = [
      for (final (file, job, value) in jobs())
        if (value['steps'] case final YamlList steps)
          for (final (i, step) in steps.indexed)
            if (step is! YamlMap || (step['run'] is! String && step['uses'] is! String)) '$file $job step ${i + 1}: $step',
    ];
    expect(bad, isEmpty);
  });

  test('each job needs only jobs of its own workflow', () {
    final missing = [
      for (final (file, job, value) in jobs())
        if (value['needs'] case final Object needs)
          for (final Object? name in needs is YamlList ? needs : [needs])
            if (!(workflows[file]!['jobs'] as YamlMap).containsKey(name)) '$file $job needs $name',
    ];
    expect(missing, isEmpty);
  });

  test('a workflow used by another is there, and can be called', () {
    final bad = <String>[];
    for (final (file, job, value) in jobs()) {
      final uses = value['uses'];
      if (uses is! String || !uses.startsWith('./.github/workflows/')) continue;
      final called = workflows[uses.split('/').last];
      if (called == null) {
        bad.add('$file $job: $uses is missing');
      } else if ((called['on'] as YamlMap?)?.containsKey('workflow_call') != true) {
        bad.add('$file $job: $uses is not callable');
      } else {
        // Every input the called workflow requires is given.
        final inputs = ((called['on'] as YamlMap)['workflow_call'] as YamlMap?)?['inputs'] as YamlMap? ?? YamlMap();
        final given = value['with'] as YamlMap? ?? YamlMap();
        for (final MapEntry(:key, :value) in inputs.entries) {
          if ((value as YamlMap)['required'] == true && !given.containsKey(key)) bad.add('$file $job: $uses needs $key');
        }
      }
    }
    expect(bad, isEmpty);
  });

  // The local actions (.github/actions/<name>/action.yml), which the jobs
  // share their setup through.
  final actions = {
    for (final dir in Directory('.github/actions').listSync().whereType<Directory>())
      if (File('${dir.path}/action.yml').existsSync())
        './.github/actions/${dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty)}':
            loadYaml(File('${dir.path}/action.yml').readAsStringSync()) as YamlMap,
  };

  test('a local action used by a job is there, after the checkout, and given only what it takes', () {
    final bad = <String>[];
    for (final (file, job, value) in jobs()) {
      var checkedOut = false;
      for (final (i, step) in ((value['steps'] as YamlList?) ?? YamlList()).indexed) {
        final uses = (step as YamlMap)['uses'];
        if (uses is! String) continue;
        if (uses.startsWith('actions/checkout@')) checkedOut = true;
        if (!uses.startsWith('./.github/actions/')) continue;
        final action = actions[uses];
        if (action == null) {
          bad.add('$file $job step ${i + 1}: $uses is missing');
          continue;
        }
        // The action is read from the checkout, so it must come first.
        if (!checkedOut) bad.add('$file $job step ${i + 1}: $uses before the checkout');
        final inputs = action['inputs'] as YamlMap? ?? YamlMap();
        for (final key in ((step['with'] as YamlMap?) ?? YamlMap()).keys) {
          if (!inputs.containsKey(key)) bad.add('$file $job step ${i + 1}: $uses takes no input $key');
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('every step of a local action runs a string, in a shell, or uses an action', () {
    final bad = [
      for (final MapEntry(key: name, value: action) in actions.entries)
        for (final (i, step) in ((action['runs'] as YamlMap)['steps'] as YamlList).indexed)
          if (step is! YamlMap ||
              (step['uses'] is! String && (step['run'] is! String || step['shell'] is! String)))
            '$name step ${i + 1}: $step',
    ];
    expect(bad, isEmpty);
  });

  test('only the shared action sets up Flutter, so every job builds with the same version', () {
    final bad = [
      for (final (file, job, value) in jobs())
        for (final step in ((value['steps'] as YamlList?) ?? YamlList()))
          if ((step as YamlMap)['uses'] case final String uses when uses.startsWith('subosito/flutter-action'))
            '$file $job',
    ];
    expect(bad, isEmpty, reason: 'use ./.github/actions/flutter instead');
  });
}
