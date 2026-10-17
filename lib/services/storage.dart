// Persistence: the wallet seed and the invitation cards' codes, encrypted
// (key_vault.dart), go to the platform's secure storage; the node address and the
// display preferences go to plain preferences.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../crypto/wallet.dart';
import '../protocol/bytes.dart';
import '../protocol/invite.dart';
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

  /// Starred people (addresses), in the order they were starred: followed
  /// in the Starred tab.
  Set<String> starredPeople = {};

  /// The newest activity (Unix seconds) on starred threads and people that
  /// the user has seen in the Starred tab: what its badge counts from. Null
  /// until there's something starred, which starts it at "now".
  int? starredSeen;

  /// Whether the Threads tab shows only starred threads.
  bool starredOnly = false;

  /// Desktop only: run a Murmur node on this computer, and use it.
  bool runLocalNode = false;

  /// Whether that node mines (to the wallet's address), and with what share
  /// of one CPU core.
  bool localNodeMining = false;
  int localNodeCpu = defaultLocalNodeCpu;

  /// Whether it mines on the graphics card, where its miner is there.
  bool localNodeGpu = false;

  /// Per wallet address, the newest reply time (Unix seconds) the user has
  /// seen in the Messages tab: what the new-reply badge counts from.
  Map<String, int> messagesSeen = {};

  /// What came before this (Unix seconds) counts as read: set the first
  /// time the app runs with unread marks, so a wallet's whole past isn't
  /// marked. Null until then, and in a fresh session's tests.
  int? unreadFrom;

  /// Per row of the Messages and Starred tabs (a message's txid, or a
  /// starred person's address), the time of the newest activity it had
  /// when last opened: what is newer stays marked as unread until opened.
  Map<String, int> opened = {};

  /// How many rows `opened` keeps: the ones opened longest ago go first.
  static const maxOpened = 2000;

  /// Per thread (its first message's txid), where its reader left off: the
  /// last reply seen, and its place among the thread's events when the
  /// node's index gave it. The next visit opens there, and marks what is
  /// newer.
  Map<String, ({String txid, int? place})> threadsRead = {};

  /// How many threads `threadsRead` keeps.
  static const maxThreadsRead = 1000;

  /// Whether a row with activity at `time` (Unix seconds) is unread: newer
  /// than when it was last opened, and than [unreadFrom].
  bool isUnread(String key, int time) {
    final from = unreadFrom;
    if (from == null || time <= from) return false;
    return time > (opened[key] ?? 0);
  }

  /// Marks a row read, up to its activity at `time`.
  Future<void> markOpened(String key, int time) async {
    if ((opened[key] ?? -1) >= time) return;
    final kept = {...opened}..remove(key);
    while (kept.length >= maxOpened) {
      kept.remove(kept.keys.first); // the first kept is the oldest opened
    }
    opened = kept..[key] = time;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('opened', jsonEncode(opened));
  }

  /// Where the reader of thread `root` left off.
  Future<void> setThreadRead(String root, String txid, int? place) async {
    final now = threadsRead[root];
    if (now != null && now.txid == txid && now.place == place) return;
    final kept = {...threadsRead}..remove(root);
    while (kept.length >= maxThreadsRead) {
      kept.remove(kept.keys.first);
    }
    threadsRead = kept..[root] = (txid: txid, place: place);
    await (await SharedPreferences.getInstance()).setString('threads_read',
        jsonEncode({for (final MapEntry(:key, :value) in threadsRead.entries) key: [value.txid, value.place]}));
  }

  Future<void> _loadOwnView(SharedPreferences prefs) async {
    threadLanguages = prefs.getStringList('thread_languages')?.toSet();
    hideFlagged = prefs.getBool('hide_flagged') ?? true;
    aliases = _jsonMap(prefs.getString('aliases')).map((k, v) => MapEntry(k, '$v'));
    muted = (prefs.getStringList('muted') ?? const []).toSet();
    starred = (prefs.getStringList('starred') ?? const []).toSet();
    starredPeople = (prefs.getStringList('starred_people') ?? const []).toSet();
    starredSeen = prefs.getInt('starred_seen');
    starredOnly = prefs.getBool('starred_only') ?? false;
    runLocalNode = prefs.getBool('run_local_node') ?? false;
    localNodeMining = prefs.getBool('local_node_mining') ?? false;
    localNodeCpu = prefs.getInt('local_node_cpu') ?? defaultLocalNodeCpu;
    localNodeGpu = prefs.getBool('local_node_gpu') ?? false;
    messagesSeen = _jsonMap(prefs.getString('messages_seen')).map((k, v) => MapEntry(k, v is int ? v : 0));
    unreadFrom = prefs.getInt('unread_from');
    if (unreadFrom == null) {
      unreadFrom = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('unread_from', unreadFrom!);
    }
    opened = {
      for (final MapEntry(:key, :value) in _jsonMap(prefs.getString('opened')).entries)
        if (value is int) key: value,
    };
    threadsRead = {
      for (final MapEntry(:key, :value) in _jsonMap(prefs.getString('threads_read')).entries)
        if (value is List && value.length == 2 && value[0] is String && (value[1] == null || value[1] is int))
          key: (txid: value[0] as String, place: value[1] as int?),
    };
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

  Future<void> setStarredPerson(String address, bool star) async {
    starredPeople = {...starredPeople};
    star ? starredPeople.add(address) : starredPeople.remove(address);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList('starred_people', starredPeople.toList());
  }

  /// Moves what's been seen in the Starred tab forward, never back.
  Future<void> setStarredSeen(int until) async {
    if ((starredSeen ?? -1) >= until) return;
    starredSeen = until;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setInt('starred_seen', until);
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

  Future<void> setLocalNodeGpu(bool value) async {
    localNodeGpu = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('local_node_gpu', value);
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

/// An invitation this device made: its card's address, how much it was
/// funded with, and the card's code, which holds the card's key and so is
/// kept encrypted ([InviteStore]).
class InviteRecord {
  InviteRecord(
      {required this.address,
      required this.amount,
      required this.serial,
      required this.batch,
      this.funder,
      this.tookBack = false,
      this.sealed,
      this.plainCode});

  /// The card's address (hex): public, and what tells cards apart.
  final String address;
  final int amount;

  /// "n of batch", as printed on the card.
  final int serial, batch;

  /// The wallet that funded it (hex), which may no longer be the one on
  /// this device. Null for cards made before this was kept: the chain
  /// tells (`inviterOf`).
  final String? funder;

  /// Whether the inviter cancelled it, taking its tokens back.
  bool tookBack;

  /// The card's code, sealed to the store's key (`sealTo`).
  Map<String, String>? sealed;

  /// The code in the clear, as earlier versions stored it: sealed at the
  /// next unlock, or when cards are next made.
  String? plainCode;

  Map<String, Object> toJson() => {
        'address': address,
        'amount': amount,
        'serial': serial,
        'batch': batch,
        if (funder != null) 'funder': funder!,
        'tookBack': tookBack,
        if (sealed != null) 'sealed': sealed!,
        if (plainCode != null) 'code': plainCode!,
      };

  /// A stored record; null for one that can't be read. `address` is given
  /// for records of earlier versions, which held only the code.
  static InviteRecord? fromJson(Object? j, {String? address}) {
    if (j is! Map) return null;
    final amount = j['amount'], serial = j['serial'], batch = j['batch'], funder = j['funder'];
    final code = j['code'], sealed = j['sealed'];
    final at = address ?? j['address'];
    if (at is! String || amount is! int || serial is! int || batch is! int) return null;
    if (sealed is! Map && code is! String) return null;
    return InviteRecord(
        address: at,
        amount: amount,
        serial: serial,
        batch: batch,
        funder: funder is String ? funder : null,
        tookBack: j['tookBack'] == true,
        sealed: sealed is Map ? sealed.map((k, v) => MapEntry('$k', '$v')) : null,
        plainCode: code is String ? code : null);
  }
}

/// The invitations this device made. A card's code holds a spendable key,
/// so the codes are kept encrypted, like the wallet's seed: each is sealed
/// to a key whose secret is in the vault (`VaultSlot.invitations`). That
/// key isn't the wallet's: cards stay on the device when the wallet
/// changes. Its passphrase or passkey is the wallet's, though (one for the
/// app): whichever of the two records is made second takes the first's.
/// - **Listing and making cards asks nothing:** addresses are public, and
///   sealing needs only the public key.
/// - **Reading a code asks every time** ([unlock]): to show its QR code or
///   link, to print it, or to cancel it (which signs with the card's key).
class InviteStore extends ChangeNotifier {
  static const _key = 'murmur_invitations';
  final _storage = const FlutterSecureStorage();

  /// The vault's record of the cards' key as stored now, if any: what a
  /// new wallet goes alongside.
  static Future<Map<String, String>?> storedVault() async {
    try {
      final json = await const FlutterSecureStorage().read(key: _key);
      final decoded = json == null ? null : jsonDecode(json);
      final key = decoded is Map ? decoded['key'] : null;
      return key is Map ? key.map((k, v) => MapEntry('$k', '$v')) : null;
    } on FormatException {
      return null;
    }
  }

  List<InviteRecord> invites = [];

  /// The vault's record of the key's secret, with the public key
  /// (`publicKey`) the codes are sealed to. Null until cards need it.
  Map<String, String>? _vault;

  Future<void> load() async {
    var loaded = <InviteRecord>[];
    Map<String, String>? vault;
    try {
      final json = await _storage.read(key: _key);
      final decoded = json == null ? null : jsonDecode(json);
      if (decoded is Map) {
        final key = decoded['key'];
        if (key is Map) vault = key.map((k, v) => MapEntry('$k', '$v'));
        loaded = [
          if (decoded['cards'] case final List cards)
            for (final j in cards)
              if (InviteRecord.fromJson(j) case final InviteRecord r) r,
        ];
      } else if (decoded is List) {
        // Earlier versions: a list of records with their codes in the clear.
        for (final j in decoded) {
          final code = j is Map ? j['code'] : null;
          final invite = code is String ? Invite.parse(code) : null;
          if (invite == null) continue;
          final address = (await MurmurWallet.fromSeed(invite.seed)).addressHex;
          if (InviteRecord.fromJson(j, address: address) case final InviteRecord r) loaded.add(r);
        }
      }
    } on FormatException {
      loaded = [];
    }
    invites = loaded;
    _vault = vault;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    await _storage.write(
        key: _key,
        value: jsonEncode({
          if (_vault != null) 'key': _vault,
          'cards': [for (final r in invites) r.toJson()],
        }));
  }

  /// Makes the key the codes are sealed to, if there's none yet, which sets
  /// up its protection (prompts), and seals the codes earlier versions left
  /// in the clear. Returns the key's secret when it was just made, so the
  /// caller needn't ask for it again. Throws [VaultLocked] if the user
  /// cancels: then nothing changes.
  Future<Uint8List?> _protect(VaultPrompts prompts, String reason) async {
    if (_vault != null) return null;
    final secret = randomBytes(32);
    final sealed = await sealSeed(secret, prompts,
        reason: reason, slot: VaultSlot.invitations, alongside: await WalletController.storedVault());
    final public = await sealingKeyOf(secret);
    for (final r in invites) {
      final code = r.plainCode;
      if (code == null) continue;
      r.sealed = await sealTo(public, utf8.encode(code));
      r.plainCode = null;
    }
    _vault = {...sealed, 'publicKey': toHex(public)};
    return secret;
  }

  /// Keeps new cards, each with its code. Saved before the cards are
  /// funded, so a key that's been paid to is never lost. Asks only the
  /// first time, to set up the protection; throws [VaultLocked] if that's
  /// cancelled.
  Future<void> add(List<InviteRecord> records, List<String> codes, VaultPrompts prompts,
      {required String reason}) async {
    await _protect(prompts, reason);
    final public = fromHex(_vault!['publicKey']!);
    for (final (i, r) in records.indexed) {
      r.sealed = await sealTo(public, utf8.encode(codes[i]));
    }
    invites = [...invites, ...records];
    await _save();
  }

  /// The codes of `records`, for one use, after the device's check or the
  /// passphrase (every time). Throws [VaultLocked].
  Future<List<String>> unlock(List<InviteRecord> records, VaultPrompts prompts, {required String reason}) async {
    var secret = await _protect(prompts, reason);
    if (secret != null) {
      await _save();
    } else {
      secret = await openSeed(_vault!, prompts, reason: reason);
    }
    return [for (final r in records) utf8.decode(await openSealed(r.sealed!, secret))];
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

  /// The vault's record of the wallet as stored now, if any: what the
  /// cards' key goes alongside.
  static Future<Map<String, String>?> storedVault() async =>
      decodeStored(await const FlutterSecureStorage().read(key: _key));

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
    final sealed = await sealSeed(w.seed, prompts, reason: reason, alongside: await InviteStore.storedVault());
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
