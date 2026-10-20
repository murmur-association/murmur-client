// A notifier for tests: records what it was asked to show, and answers the
// permission question as told.

import 'package:murmur_client/services/notifier.dart';

class RecordingNotifier implements Notifier {
  RecordingNotifier({this.grant = true});

  bool grant;
  final shown = <({int id, String title, String body, String payload})>[];
  var asked = 0;

  @override
  Future<void> init({required String openLabel, void Function(String payload)? open}) async {}

  @override
  Future<bool> requestPermission() async {
    asked++;
    return grant;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channel,
    int? when,
  }) async =>
      shown.add((id: id, title: title, body: body, payload: payload));

  @override
  Future<String?> launchPayload() async => null;
}
