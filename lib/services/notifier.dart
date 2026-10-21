// The system's notifications, raised by the app itself on this device
// (flutter_local_notifications): nothing goes through a push service, so
// no third party learns what the user follows (AGENTS.md rule 2). Android
// and iOS also check while the app is closed (ui/notifications.dart);
// elsewhere notifications come only while the app is open.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Where notifications go. The app's is [SystemNotifier]; tests give their own.
abstract class Notifier {
  /// Starts it: `open` is called with a notification's payload when the user
  /// taps one. `openLabel` names that action where the system shows it.
  Future<void> init({required String openLabel, void Function(String payload)? open});

  /// Whether the system lets the app notify, asking the user if it hasn't
  /// yet. On the web only a tap may ask, so call it from one.
  Future<bool> requestPermission();

  /// Shows a notification, replacing the one with the same `id`. `channel`
  /// names the kind of notification in the system's settings (Android).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channel,
    int? when,
  });

  /// The payload of the notification whose tap started the app, if one did.
  Future<String?> launchPayload();
}

/// Whether this platform checks for news while the app is closed: Android
/// (WorkManager) and iOS (background app refresh, when iOS decides).
bool get backgroundChecks =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Whether this is an Apple platform, whose notification centre the app
/// reaches through the same settings on iOS and macOS.
bool get _darwin =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

/// The system's own notifications.
class SystemNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _started = false;

  /// The Android channel every news notification goes to.
  static const _channelId = 'news';

  /// Told of every notification shown, after the system took it: the
  /// acceptance tests check what reached the system this way where they
  /// can't read it back from the system itself.
  @visibleForTesting
  static void Function(({int id, String title, String body, String payload}) shown)? onShown;

  /// Asks Apple's notification centre for quiet ("provisional") permission,
  /// which needs no answer: for the acceptance tests in a simulator, where
  /// nobody can answer the system's question.
  @visibleForTesting
  static bool quietPermission = false;

  /// Apple's settings: nothing asked at start; the user switches a topic on
  /// first ([requestPermission]).
  static const _darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestSoundPermission: false,
    requestBadgePermission: false,
  );

  @override
  Future<void> init({required String openLabel, void Function(String payload)? open}) async {
    if (_started) return;
    _started = true;
    await _plugin.initialize(
      settings: InitializationSettings(
        // A white silhouette, which Android tints (tool/render_brand.dart).
        android: const AndroidInitializationSettings('@drawable/ic_stat_murmur'),
        linux: LinuxInitializationSettings(defaultActionName: openLabel),
        // An app installed without a package names itself to Windows here:
        // the company and product the app's settings live under.
        windows: const WindowsInitializationSettings(
          appName: 'Murmur',
          appUserModelId: 'MurmurAssociation.Murmur',
          guid: '6f3c2a51-9d84-4e0b-b7a2-5c1e8f04d3a9',
        ),
        web: const WebInitializationSettings(),
        iOS: _darwinSettings,
        macOS: _darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && open != null) open(payload);
      },
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return await _plugin
              .resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? await android?.areNotificationsEnabled() ?? false;
    }
    if (_darwin) {
      final quiet = quietPermission;
      return await (defaultTargetPlatform == TargetPlatform.iOS
              ? _plugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true, provisional: quiet)
              : _plugin
                  .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true, provisional: quiet)) ??
          false;
    }
    // Windows and Linux ask nothing: the user turns an app's notifications
    // off in the system's settings.
    return true;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channel,
    int? when,
  }) async {
    await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            channel,
            // The lock screen says a notification came, not what it says.
            visibility: NotificationVisibility.private,
            category: AndroidNotificationCategory.message,
            onlyAlertOnce: true,
            when: when == null ? null : when * 1000,
          ),
          linux: const LinuxNotificationDetails(category: LinuxNotificationCategory.imReceived),
          // One thread in the notification centre for all of them.
          iOS: const DarwinNotificationDetails(threadIdentifier: _channelId),
          macOS: const DarwinNotificationDetails(threadIdentifier: _channelId),
        ),
      );
    onShown?.call((id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? details?.notificationResponse?.payload : null;
  }
}
