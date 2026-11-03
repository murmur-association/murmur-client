// Whether the runner on the host has left a word for the app: a file it
// writes into the app's own folder (on Android with `adb shell run-as`,
// tool/android_system.dart), named by acceptance_protocol.dart.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<bool> runnerSaid(String name) async =>
    File('${(await getApplicationSupportDirectory()).path}/$name').exists();
