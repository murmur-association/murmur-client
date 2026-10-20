// The pipeline's configuration (.gitlab-ci.yml), checked before a push
// meets GitLab's own check: a line GitLab refuses fails the whole pipeline
// at once, with no job run. (A script line holding ": " outside quotes is
// read as a mapping: that refused a push once.)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final config = loadYaml(File('.gitlab-ci.yml').readAsStringSync()) as YamlMap;

  test('every script line of every job is a string', () {
    final bad = [
      for (final MapEntry(:key, :value) in config.entries)
        if (value is YamlMap)
          for (final part in ['before_script', 'script', 'after_script'])
            if (value[part] case final YamlList lines)
              for (final line in lines)
                if (line is! String) '$key.$part: $line',
    ];
    expect(bad, isEmpty);
  });

  test('each job extends only templates that are there', () {
    final missing = [
      for (final MapEntry(:key, :value) in config.entries)
        if (value is YamlMap)
          if (value['extends'] case final Object extended)
            for (final Object? name in extended is YamlList ? extended : [extended])
              if (!config.containsKey(name)) '$key extends $name',
    ];
    expect(missing, isEmpty);
  });
}
