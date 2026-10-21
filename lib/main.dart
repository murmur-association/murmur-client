import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';

import 'services/chain_cache.dart';
import 'services/local_node.dart';
import 'services/local_node_link.dart';
import 'services/node_client.dart';
import 'services/notifier.dart';
import 'services/storage.dart';
import 'ui/address_page.dart';
import 'ui/brand.dart';
import 'ui/common.dart';
import 'services/invitations.dart' show inviteInRoute;
import 'ui/claim_page.dart';
import 'ui/home_page.dart';
import 'ui/notifications.dart';
import 'ui/thread_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = Preferences();
  await prefs.load();
  final client = MurmurClient();
  // Starred content is kept in the local copy however old; the client
  // follows the user's stars as they change.
  client.setStarred(prefs.starred);
  prefs.addListener(() => client.setStarred(prefs.starred));
  // With consent, the chain downloaded in earlier sessions is the starting point.
  if (prefs.storageConsent == StorageConsent.allowed) client.useCache(await ChainCache.open());
  final wallets = WalletController();
  // Desktop builds with the node program beside them can run a node of
  // their own; it's stopped when the app closes.
  final localNode = LocalNode();
  if (localNode.available) {
    final link = LocalNodeLink(node: localNode, prefs: prefs, wallets: wallets);
    AppLifecycleListener(onExitRequested: () async {
      await link.close();
      return AppExitResponse.exit;
    });
  }
  // Notifications the app raises itself.
  final notifier = SystemNotifier();
  runApp(MurmurApp(client: client, wallets: wallets, prefs: prefs, localNode: localNode, notifier: notifier));
  await startNotifications(client: client, prefs: prefs, wallets: wallets, notifier: notifier);
}

class MurmurApp extends StatelessWidget {
  const MurmurApp(
      {super.key, required this.client, required this.wallets, required this.prefs, this.localNode, this.notifier});

  final MurmurClient client;
  final WalletController wallets;
  final Preferences prefs;
  final LocalNode? localNode;
  final Notifier? notifier;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      client: client,
      wallets: wallets,
      prefs: prefs,
      localNode: localNode,
      notifier: notifier,
      child: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: switch (prefs.brightness) {
            Brightness.light => ThemeMode.light,
            Brightness.dark => ThemeMode.dark,
            null => ThemeMode.system,
          },
          // Null follows the system language, falling back to English.
          locale: prefs.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: appNavigator,
          navigatorObservers: [routeObserver],
          home: const HomePage(),
          onGenerateRoute: routeOfLink,
        ),
      ),
    );
  }
}

/// The page a shared link opens, over the home page: a thread
/// (`#/thread/<txid>`), an address (`#/address/<address>`, what its QR code
/// holds) or an invitation card (`#/invite/<code>`). Null for anything else.
Route<void>? routeOfLink(RouteSettings settings) {
  final txid = threadInRoute(settings.name);
  if (txid != null) return MaterialPageRoute(settings: settings, builder: (_) => ThreadPage(rootTxid: txid));
  final address = addressInRoute(settings.name);
  if (address != null) return MaterialPageRoute(settings: settings, builder: (_) => AddressPage(address: address));
  final code = inviteInRoute(settings.name);
  if (code != null) return MaterialPageRoute(settings: settings, builder: (_) => ClaimPage(code: code));
  return null;
}
