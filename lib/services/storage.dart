// Persistence: the wallet seed, encrypted (key_vault.dart), and invitation
// cards go to the platform's secure storage; the node address and the
// display preferences go to plain preferences.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../crypto/wallet.dart';
import '../protocol/bytes.dart';
import 'activity.dart';
import 'local_node.dart' show defaultLocalNodeCpu;
import 'key_vault.dart';
import 'transport.dart';

class NodeSettings {
  /// The node a fresh install connects to. A local node by default; a
  /// release for a public network sets its own at build time:
  /// `--dart-define=MURMUR_NODE_HOST=<host> --dart-define=MURMUR_NODE_PORT=<port>`.
  static const defaultHost = String.fromEnvironment('MURMUR_NODE_HOST', defaultValue: '127.0.0.1');

  /// The node's P2P port natively; on the web, the WebSocket bridge's port
  /// (or a node's own `--ws-port`, or 443 behind a TLS proxy).
  static const defaultPort = int.fromEnvironment('MURMUR_NODE_PORT', defaultValue: viaBridge ? 7880 : 7878);

  /// The node to use: `?node=host:port` in the page address (web), else the
  /// one saved, else the default.
  static Future<(String, int)> load() async {
    final fromPage = Uri.base.queryParameters['node'];
    if (fromPage != null) {
      final colon = fromPage.lastIndexOf(':');
      final port = colon < 0 ? null : int.tryParse(fromPage.substring(colon + 1));
      if (port != null && port > 0 && port < 65536) return (fromPage.substring(0, colon), port);
    }
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getString('node_host') ?? defaultHost,
      prefs.getInt('node_port') ?? defaultPort,
    );
  }

  static Future<void> save(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('node_host', host);
    await prefs.setInt('node_port', port);
  }
}

/// Whether the downloaded chain may be kept on this device (ChainCache).
enum StorageConsent { allowed, rejected }

/// Display preferences: light or dark mode and language (both follow the
/// system while null), the Messages and Wallet filters, and the storage
/// choice (null until the user makes it).
class Preferences extends ChangeNotifier {
  Brightness? brightness;
  Locale? locale;
  StorageConsent? storageConsent;
  Set<MessageFilter> messageFilters = {...MessageFilter.defaults};
  Set<WalletFilter> walletFilters = {...WalletFilter.defaults};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    brightness = switch (prefs.getString('brightness')) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => null,
    };
    storageConsent = switch (prefs.getString('storage_consent')) {
      'allowed' => StorageConsent.allowed,
      'rejected' => StorageConsent.rejected,
      _ => null,
    };
    final tag = prefs.getString('locale');
    locale = tag == null ? null : Locale(tag);
    messageFilters = _names(prefs.getStringList('message_filters'), MessageFilter.values) ?? messageFilters;
    walletFilters = _names(prefs.getStringList('wallet_filters'), WalletFilter.values) ?? walletFilters;
    await _loadOwnView(prefs);
    notifyListeners();
  }

  static Set<T>? _names<T extends Enum>(List<String>? names, List<T> values) =>
      names == null ? null : {for (final v in values) if (names.contains(v.name)) v};

  Future<void> setBrightness(Brightness value) async {
    brightness = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('brightness', value.name);
  }

  Future<void> setStorageConsent(StorageConsent value) async {
    storageConsent = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('storage_consent', value.name);
  }

  /// null follows the system language.
  Future<void> setLocale(Locale? value) async {
    locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('locale');
    } else {
      await prefs.setString('locale', value.languageCode);
    }
  }

  Future<void> setMessageFilters(Set<MessageFilter> value) async {
    messageFilters = value;
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setStringList('message_filters', [for (final f in value) f.name]);
  }

  Future<void> setWalletFilters(Set<WalletFilter> value) async {
    walletFilters = value;
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setStringList('wallet_filters', [for (final f in value) f.name]);
  }

  // ---- this device's own view of people and threads ------------------------------
  //
  // Everything below stays on this device: names, mutes and what's been
  // read are nobody else's business, and nothing on the chain changes.

  /// Languages the Threads tab shows (language codes, and
  /// `undetectedLanguage` for text whose language couldn't be told); null
  /// until the user chooses, which means the device's own languages.
  Set<String>? threadLanguages;

  /// Whether threads this wallet flagged are left out of the Threads tab.
  bool hideFlagged = true;

  /// Names the user gave addresses, by address (hex).
  Map<String, String> aliases = {};

  /// Addresses whose threads and replies the user doesn't want to see.
  Set<String> muted = {};

  /// Starred messages and threads (txids of messages, or of thread roots,
  /// which star the whole thread): easy to find, and their content is kept
  /// in the local copy however old it gets.
  Set<String> starred = {};

  /// Whether the Threads tab shows only starred threads.
  bool starredOnly = false;

  /// Desktop only: run a Murmur node on this computer, and use it.
  bool runLocalNode = false;

  /// Whether that node mines (to the wallet's address), and with what share
  /// of one CPU core.
  bool localNodeMining = false;
  int localNodeCpu = defaultLocalNodeCpu;

  /// Per wallet address, the newest reply time (Unix seconds) the user has
  /// seen in the Messages tab: what the new-reply badge counts from.
  Map<String, int> messagesSeen = {};

  Future<void> _loadOwnView(SharedPreferences prefs) async {
    threadLanguages = prefs.getStringList('thread_languages')?.toSet();
    hideFlagged = prefs.getBool('hide_flagged') ?? true;
    aliases = _jsonMap(prefs.getString('aliases')).map((k, v) => MapEntry(k, '$v'));
    muted = (prefs.getStringList('muted') ?? const []).toSet();
    starred = (prefs.getStringList('starred') ?? const []).toSet();
    starredOnly = prefs.getBool('starred_only') ?? false;
    runLocalNode = prefs.getBool('run_local_node') ?? false;
    localNodeMining = prefs.getBool('local_node_mining') ?? false;
    localNodeCpu = prefs.getInt('local_node_cpu') ?? defaultLocalNodeCpu;
    messagesSeen = _jsonMap(prefs.getString('messages_seen')).map((k, v) => MapEntry(k, v is int ? v : 0));
  }

  static Map<String, Object?> _jsonMap(String? json) {
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> setThreadLanguages(Set<String> value) async {
    threadLanguages = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList('thread_languages', value.toList());
  }

  Future<void> setHideFlagged(bool value) async {
    hideFlagged = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('hide_flagged', value);
  }

  /// Names `address` (an empty name removes it).
  Future<void> setAlias(String address, String name) async {
    final trimmed = name.trim();
    aliases = {...aliases}..removeWhere((k, _) => k == address);
    if (trimmed.isNotEmpty) aliases[address] = trimmed;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('aliases', jsonEncode(aliases));
  }

  Future<void> setMuted(String address, bool mute) async {
    muted = {...muted};
    mute ? muted.add(address) : muted.remove(address);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList('muted', muted.toList());
  }

  Future<void> setStarred(String txid, bool star) async {
    starred = {...starred};
    star ? starred.add(txid) : starred.remove(txid);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList('starred', starred.toList());
  }

  Future<void> setStarredOnly(bool value) async {
    starredOnly = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('starred_only', value);
  }

  Future<void> setRunLocalNode(bool value) async {
    runLocalNode = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('run_local_node', value);
  }

  Future<void> setLocalNodeMining(bool value) async {
    localNodeMining = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('local_node_mining', value);
  }

  Future<void> setLocalNodeCpu(int value) async {
    localNodeCpu = value.clamp(1, 100);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setInt('local_node_cpu', localNodeCpu);
  }

  Future<void> setMessagesSeen(String address, int until) async {
    if ((messagesSeen[address] ?? 0) >= until) return;
    messagesSeen = {...messagesSeen, address: until};
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('messages_seen', jsonEncode(messagesSeen));
  }
}

/// An invitation this device made: its card's code (which holds the card's
/// key), when it was made, and how much it was funded with.
class InviteRecord {
  InviteRecord(
      {required this.code,
      required this.amount,
      required this.serial,
      required this.batch,
      this.funder,
      this.tookBack = false});

  final String code;
  final int amount;

  /// "n of batch", as printed on the card.
  final int serial, batch;

  /// The wallet that funded it (hex), which may no longer be the one on
  /// this device. Null for cards made before this was kept: the chain
  /// tells (`inviterOf`).
  final String? funder;

  /// Whether the inviter cancelled it, taking its tokens back.
  bool tookBack;

  Map<String, Object> toJson() => {
        'code': code,
        'amount': amount,
        'serial': serial,
        'batch': batch,
        if (funder != null) 'funder': funder!,
        'tookBack': tookBack,
      };

  static InviteRecord? fromJson(Object? j) {
    if (j is! Map) return null;
    final code = j['code'], amount = j['amount'], serial = j['serial'], batch = j['batch'], funder = j['funder'];
    if (code is! String || amount is! int || serial is! int || batch is! int) return null;
    return InviteRecord(
        code: code,
        amount: amount,
        serial: serial,
        batch: batch,
        funder: funder is String ? funder : null,
        tookBack: j['tookBack'] == true);
  }
}

/// The invitations this device made. Their codes hold spendable keys, so
/// they're kept in secure storage like the wallet seed.
class InviteStore extends ChangeNotifier {
  static const _key = 'murmur_invitations';
  final _storage = const FlutterSecureStorage();

  List<InviteRecord> invites = [];

  Future<void> load() async {
    try {
      final json = await _storage.read(key: _key);
      final decoded = json == null ? null : jsonDecode(json);
      invites = [
        if (decoded is List)
          for (final j in decoded)
            if (InviteRecord.fromJson(j) case final InviteRecord r) r,
      ];
    } on FormatException {
      invites = [];
    }
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    await _storage.write(key: _key, value: jsonEncode([for (final r in invites) r.toJson()]));
  }

  /// Saved before the cards are funded, so a key that's been paid to is
  /// never lost.
  Future<void> add(List<InviteRecord> records) async {
    invites = [...invites, ...records];
    await _save();
  }

  Future<void> markTookBack(InviteRecord r) async {
    r.tookBack = true;
    await _save();
  }
}

/// The wallet on this device. Only its public side ([wallet]) is kept at
/// hand; the seed is stored encrypted (services/key_vault.dart) and
/// [unlock] decrypts it for one use, asking the device's check or the
/// passphrase every time.
class WalletController extends ChangeNotifier {
  /// Where earlier versions kept the seed in the clear; moved to the vault
  /// at the next unlock.
  static const _legacyKey = 'murmur_wallet_seed';

  /// The vault's record: protection, its parameters, the ciphertext, and
  /// the wallet's address and public key.
  static const _key = 'murmur_wallet';
  final _storage = const FlutterSecureStorage();

  WalletId? wallet;
  Map<String, String>? _stored;
  bool _legacy = false;
  bool loaded = false;

  /// How the seed is protected: 'device', 'passkey', 'passphrase', or
  /// 'legacy' until it's moved to the vault.
  String? get protection => _legacy ? 'legacy' : _stored?['protection'];

  Future<void> load() async {
    try {
      final stored = decodeStored(await _storage.read(key: _key));
      if (stored != null) {
        _stored = stored;
        wallet = WalletId(fromHex(stored['address']!), fromHex(stored['publicKey']!));
      } else {
        final hex = await _storage.read(key: _legacyKey);
        if (hex != null) {
          wallet = (await MurmurWallet.fromSeed(fromHex(hex))).id;
          _legacy = true;
        }
      }
    } finally {
      loaded = true;
      notifyListeners();
    }
  }

  /// A new wallet, saved encrypted (prompts to set up its protection).
  /// Throws [VaultLocked] if the user cancels: then nothing is saved.
  /// Returns it with its key, this once, so its seed can be shown for the
  /// user to keep; afterwards the key comes only from [unlock].
  Future<MurmurWallet> create(VaultPrompts prompts, {required String reason}) async {
    final wallet = await MurmurWallet.generate();
    await _save(wallet, prompts, reason);
    return wallet;
  }

  /// Imports a 64-hex-char seed, e.g. the contents of a `murmur.key` file.
  Future<void> import(String seedHex, VaultPrompts prompts, {required String reason}) async =>
      _save(await MurmurWallet.fromSeed(fromHex(seedHex)), prompts, reason);

  Future<void> _save(MurmurWallet w, VaultPrompts prompts, String reason) async {
    final sealed = await sealSeed(w.seed, prompts, reason: reason);
    final stored = {...sealed, 'address': toHex(w.address), 'publicKey': toHex(w.publicKey)};
    await _storage.write(key: _key, value: encodeStored(stored));
    await _storage.delete(key: _legacyKey);
    _stored = stored;
    _legacy = false;
    wallet = w.id;
    notifyListeners();
  }

  /// The wallet with its key, for one use: after the device's check or the
  /// passphrase (every time). A wallet from an earlier version is moved to
  /// the vault first, which sets up its protection. Throws [VaultLocked].
  Future<MurmurWallet> unlock(VaultPrompts prompts, {required String reason}) async {
    if (_legacy) {
      final hex = await _storage.read(key: _legacyKey);
      if (hex == null) throw const VaultLocked(false);
      final w = await MurmurWallet.fromSeed(fromHex(hex));
      await _save(w, prompts, reason);
      return w;
    }
    final stored = _stored;
    if (stored == null) throw const VaultLocked(false);
    return MurmurWallet.fromSeed(await openSeed(stored, prompts, reason: reason));
  }

  Future<void> forget() async {
    final stored = _stored;
    if (stored != null) await forgetSeed(stored);
    await _storage.delete(key: _key);
    await _storage.delete(key: _legacyKey);
    _stored = null;
    _legacy = false;
    wallet = null;
    notifyListeners();
  }
}
