// The other end of a browser run of integration_test/ (`flutter drive`,
// which tool/acceptance_test.dart starts): it waits for the tests in the
// page and passes their result on. Desktops and phones need no driver;
// `flutter test` runs them directly.
//
// With ACCEPTANCE_PASSKEY set it first gives the browser a virtual
// authenticator: a passkey device that exists only in this session and
// passes its own check, with the PRF extension the app's vault needs
// (lib/services/key_vault_web.dart). The app then takes its real passkey
// path, with nobody at the keyboard.
//
// It gives the page's file inputs the runner's picture (ACCEPTANCE_PICTURE_FILE),
// as a user picking it in the browser's chooser would.
//
// It also allows the page's notifications, as a user does when the app
// asks: the acceptance tests switch them on, and read back what the
// browser shows.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  // WebDriver's "Set Permission" (the Permissions specification). Not every
  // browser's driver has it: then the notification test says it was refused.
  try {
    await driver.webDriver.postRequest('permissions', {
      'descriptor': {'name': 'notifications'},
      'state': 'granted',
    });
  } catch (e) {
    print('This browser\'s WebDriver could not grant notifications: $e');
  }
  if (Platform.environment['ACCEPTANCE_PASSKEY'] != null) {
    // WebDriver's "Add Virtual Authenticator": built into the device
    // ("internal"), with a user check that always passes.
    await driver.webDriver.postRequest('webauthn/authenticator', {
      'protocol': 'ctap2',
      'transport': 'internal',
      'hasResidentKey': true,
      'hasUserVerification': true,
      'isUserConsenting': true,
      'isUserVerified': true,
      'extensions': ['prf'],
    });
    print('A virtual passkey authenticator is in place.');
  }
  // The page's file inputs (a picture chooser, file_selector_web) get the
  // runner's picture as soon as they appear, as a user picking it would.
  final picture = Platform.environment['ACCEPTANCE_PICTURE_FILE'];
  var running = true;
  if (picture != null) unawaited(_fillFileInputs(driver, picture, () => running));
  // As integration_test's own `integrationDriver` does from here, which
  // can't be given a driver that's already connected.
  final response = Response.fromJson(await driver.requestData(null, timeout: const Duration(minutes: 20)));
  running = false;
  await driver.close();
  if (response.allTestsPassed) {
    print('All tests passed.');
    exit(0);
  }
  print('Failure Details:\n${response.formattedFailureDetails}');
  // The failures' own messages, which a release build's details leave out
  // (integration_test/acceptance_test.dart hands them over).
  if (response.data?['failures'] case final Map failures) {
    failures.forEach((test, why) {
      print('Why "$test" failed:\n$why\n');
      // Also as a GitHub annotation (a workflow command in the job's output),
      // which the run's page lists, and its API serves without signing in.
      String escaped(String s) => s.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
      print('::error title=${escaped('$test').replaceAll(':', '%3A').replaceAll(',', '%2C')}::${escaped('$why')}');
    });
  }
  exit(1);
}

/// Gives every file input that appears in the page `file`, through
/// WebDriver's "Element Send Keys" (which sets a file input's files and
/// fires its change event), until `running` says the tests are over.
Future<void> _fillFileInputs(FlutterDriver driver, String file, bool Function() running) async {
  final given = <String>{};
  while (running()) {
    try {
      // The driver's library answers with its own element objects (package
      // webdriver's WebElement, not a dependency of this project's).
      final inputs = await driver.webDriver.postRequest('elements', {'using': 'css selector', 'value': 'input[type=file]'});
      for (final dynamic input in inputs as List) {
        final id = input.id as String;
        if (!given.add(id)) continue;
        await input.sendKeys(file);
        print('The page asked for a file: given $file');
      }
    } catch (e) {
      // An input removed while it was being given its file: the next look
      // finds the page as it is.
      print('Giving the page a file: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
