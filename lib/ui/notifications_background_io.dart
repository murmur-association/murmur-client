// Android's background checks for news (WorkManager): about every 15
// minutes, as the system allows, a short run starts a client of its own,
// syncs from the local copy (with the user's consent) on the node the user
// chose, reads the wallet's lists and what's starred, tells of what's new,
// and stops. It's skipped while the app runs, whose own watcher tells
// (ui/notifications.dart): the two would share the local copy.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../services/chain_cache.dart';
import '../services/node_client.dart';
import '../services/notifier.dart';
import '../services/storage.dart';
import 'notifications.dart';

/// The name the app's isolate answers under while it runs.
const _appPortName = 'murmur_app';

/// The background job's name.
const _task = 'murmur-news';

ReceivePort? _appPort;

/// Lets a background run see the app is running: it answers any port sent
/// to it. Once per process, however often the app starts in it.
void registerAppPort() {
  if (!backgroundChecks || _appPort != null) return;
  final port = _appPort = ReceivePort();
  IsolateNameServer.removePortNameMapping(_appPortName);
  IsolateNameServer.registerPortWithName(port.sendPort, _appPortName);
  port.listen((message) {
    if (message is SendPort) message.send(true);
  });
}

/// Whether the app runs in this process: its isolate answers. A name left
/// by an app that has stopped doesn't answer, and is dropped.
Future<bool> _appRunning() async {
  final app = IsolateNameServer.lookupPortByName(_appPortName);
  if (app == null) return false;
  final reply = ReceivePort();
  try {
    app.send(reply.sendPort);
    await reply.first.timeout(const Duration(seconds: 1));
    return true;
  } on TimeoutException {
    IsolateNameServer.removePortNameMapping(_appPortName);
    return false;
  } finally {
    reply.close();
  }
}

/// Starts or stops the background checks.
Future<void> scheduleBackgroundChecks(bool on) async {
  if (!backgroundChecks) return;
  final work = Workmanager();
  await work.initialize(newsTask);
  if (on) {
    await work.registerPeriodicTask(
      _task,
      _task,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } else {
    await work.cancelByUniqueName(_task);
  }
}

/// Where WorkManager starts a background run.
@pragma('vm:entry-point')
void newsTask() {
  Workmanager().executeTask((task, input) async {
    debugPrint(backgroundCheckLog);
    try {
      await checkNewsInBackground();
    } catch (e) {
      debugPrint('background news check failed: $e');
    }
    // Done either way: the next check comes at its time, not sooner.
    return true;
  });
}

/// One background run: at most `limit` long, and stopped as soon as the
/// app starts. Returns how many notifications it showed. Tests give their
/// own `notifier`.
Future<int> checkNewsInBackground({Duration limit = const Duration(minutes: 2), Notifier? notifier}) async {
  if (await _appRunning()) return 0;
  final prefs = Preferences();
  await prefs.load();
  if (prefs.notifyTopics.isEmpty) return 0;
  final wallets = WalletController();
  await wallets.load();
  final me = wallets.wallet?.addressHex;
  if (me == null && prefs.starred.isEmpty && prefs.starredPeople.isEmpty) return 0;

  final client = MurmurClient()..setStarred(prefs.starred);
  if (prefs.storageConsent == StorageConsent.allowed) client.useCache(await ChainCache.open());
  final l = localizationsFor(prefs.locale);
  final to = notifier ?? SystemNotifier();
  await to.init(openLabel: l.notifyOpen);
  final news = NewsNotifications(client: client, prefs: prefs, notifier: to, me: () => me);
  client.addListener(news.follow);
  news.follow();
  final (host, port) = await NodeSettings.load();
  unawaited(client.connect(host, port));
  try {
    // Settled for a few seconds in a row: what follows a step (the lists'
    // entries' blocks and texts) has been asked for too.
    final end = DateTime.now().add(limit);
    var calm = 0;
    while (calm < 3 && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (await _appRunning()) return 0;
      calm = client.settled ? calm + 1 : 0;
    }
    return calm >= 3 ? await news.check(l) : 0;
  } finally {
    client.removeListener(news.follow);
    client.disconnect();
  }
}
