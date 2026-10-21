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
// It also allows the page's notifications, as a user does when the app
// asks: the acceptance tests switch them on, and read back what the
// browser shows.

// ignore_for_file: avoid_print

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
  // As integration_test's own `integrationDriver` does from here, which
  // can't be given a driver that's already connected.
  final response = Response.fromJson(await driver.requestData(null, timeout: const Duration(minutes: 20)));
  await driver.close();
  if (response.allTestsPassed) {
    print('All tests passed.');
    exit(0);
  }
  print('Failure Details:\n${response.formattedFailureDetails}');
  exit(1);
}
