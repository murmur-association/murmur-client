// Light client for one Murmur node, over the node's encrypted peer-to-peer
// connection (PROTOCOL.md Section 7).
//
// The client handshakes like a peer that has no blocks (zero work), so the
// node never tries to sync from it. What it shows is checked against headers
// it has verified itself (linkage, proof of work, median-time-past, the
// difficulty retarget and each header's history root), because every header
// commits to its block's transactions, its filter and the state after it
// (Section 3.6):
//
// - balances, nonces, flags, the burn pool and the total issued come as
//   state proofs (GetState) against the tip's `state_root`: exact at once,
//   without the chain;
// - an address's history, and a thread's replies, are found with block
//   filters (GetFilters), checked against `filter_hash`: only the blocks
//   that match are fetched, and none can be hidden;
// - a transaction the client lacks (a reply's parent, a flagged message)
//   comes by id (GetTx) with a merkle branch to its header;
// - lists read newest first fetch blocks newest first, as far as the view
//   needs, then their message content (GetContent);
// - fees come from the node (GetFees), and a sent transaction is answered
//   (SubmitTx / TxStatus).
//
// With the user's consent to keep a local copy (ChainCache), the client
// also fetches the rest of the chain in the background, once, and replays
// it: that gives every history row its balance before and after, and lets
// the client check the node's state root against its own count.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../crypto/wallet.dart';
import '../protocol/alias.dart' as protocol_alias;
import '../protocol/bytes.dart';
import '../protocol/commitments.dart';
import '../protocol/consensus.dart';
import '../protocol/header_chain.dart';
import '../protocol/models.dart';
import '../protocol/network.dart';
import '../protocol/wire.dart';
import 'aliases.dart';
import 'chain_cache.dart';
import 'fees.dart';
import 'secure_channel.dart';
import 'threads.dart';
import 'transport.dart';

export '../protocol/wire.dart' show TxStatusCode;
export 'fees.dart' show FeeInfo, FeeSource, minFee;
export 'threads.dart' show ThreadSummary, activityTime;

enum LinkState { disconnected, connecting, syncing, live }

enum LinkErrorKind {
  unreachable,
  bridgeUnreachable,
  connection,
  closed,
  timeout,
  protocol,
  version,
  syncFailed,
  ignoredBlock,
  tampered,
  stateMismatch,
  checkpointMismatch,
  other,
}

/// Why the link to the node failed, for the UI to word. `detail` is technical
/// text (a system error, or what was wrong in the node's data) shown as is.
class LinkError implements Exception {
  const LinkError(this.kind, {this.detail = '', this.nodeVersion = 0, this.height = 0, this.cause});

  final LinkErrorKind kind;
  final String detail;

  /// The node's protocol version, for [LinkErrorKind.version].
  final int nodeVersion;

  /// The block whose state didn't match, for [LinkErrorKind.stateMismatch],
  /// or the checkpoint the chain doesn't lead to, for
  /// [LinkErrorKind.checkpointMismatch].
  final int height;

  /// What made a sync fail, for [LinkErrorKind.syncFailed].
  final LinkError? cause;

  @override
  String toString() => '${kind.name}: $detail';
}

enum TxProblemKind {
  feeTooLow,
  malformed,
  needsMessage,
  needsRecipient,
  amountBelowFee,
  replyParentNotMined,
  replyWrongRecipient,
  flagNotMessage,
  alreadyFlagged,
  messageTooLong,
  insufficientBalance,
  checkingBalance,
  notLive,
  connectionLost,
  duplicate,
}

/// Why a transaction can't be sent, for the UI to word. `a` and `b` carry the
/// numbers involved: the fee for [TxProblemKind.amountBelowFee], length and limit
/// for [TxProblemKind.messageTooLong], needed and available for
/// [TxProblemKind.insufficientBalance].
class TxProblem implements Exception {
  const TxProblem(this.kind, [this.a = 0, this.b = 0]);

  final TxProblemKind kind;
  final int a, b;

  @override
  String toString() => 'TxProblem(${kind.name}, $a, $b)';
}

/// A transaction that isn't in a block yet: gossiped by the node, or sent
/// from this client.
class PendingTx {
  PendingTx(this.tx, this.content, {required this.mine, this.sentAtHeight})
      : seenAt = DateTime.now();

  final Transaction tx;
  final Uint8List? content;
  final bool mine;
  final DateTime seenAt;

  /// Chain height when this client sent it (own transactions only).
  final int? sentAtHeight;
}

/// A transaction with where it sits: in a block (`height`) or pending.
class TxView {
  TxView(this.tx, {this.height, this.blockTime, this.content, this.pending, this.balanceAfter});

  final Transaction tx;
  final int? height;
  final int? blockTime;
  final Uint8List? content;
  final PendingTx? pending;

  /// In an address's history (`MurmurClient.activityOf`), that address's
  /// balance right after this transaction, when it's known.
  final int? balanceAfter;

  bool get confirmed => height != null;
}

/// An account as proven against a header's state root.
class AccountState {
  const AccountState(this.balance, this.nonce, this.height);

  final int balance;

  /// Transactions the account has sent: the nonce its next one must carry.
  final int nonce;

  /// The block whose state this is.
  final int height;
}

/// A value proven against block `height`'s state root; null value: absent.
class _Proven {
  _Proven(this.value, this.height);
  final Uint8List? value;
  final int height;
}

/// A transaction proven on the chain by its merkle branch, without its block.
class _LooseTx {
  _LooseTx(this.tx, this.height);
  final Transaction tx;
  final int height;
}

class _Aborted implements Exception {}

class MurmurClient extends ChangeNotifier {
  static const _connectTimeout = Duration(seconds: 10);
  static const _requestTimeout = Duration(seconds: 60);

  /// The node drops peers silent for 180 s, so ping well within that.
  static const _pingInterval = Duration(seconds: 60);
  static const _maxGossipPending = 5000;
  static const _gossipPendingTtl = Duration(hours: 1);

  /// Own transactions still unconfirmed this many blocks after sending are
  /// reported as possibly dropped.
  static const staleAfterBlocks = 10;

  LinkState state = LinkState.disconnected;
  LinkError? error;
  String? host;
  int? port;
  Uint8List? genesis;
  NetworkInfo? network;

  /// Best height the node has reported (in its Hello or by relaying blocks).
  int peerHeight = 0;

  // ---- chain data ---------------------------------------------------------------

  /// The best chain's headers: `_headers[i]` is at height i + 1. Started
  /// from a checkpoint, those below `_low` aren't known until the background
  /// check back to genesis has fetched them (null). Packed: long loops read
  /// fields with `prevHashAt`, `minerAt` and the like, not whole headers.
  final _headers = HeaderChain();

  /// The lowest height whose header is known: 1, or near the checkpoint
  /// until the headers back to genesis are checked.
  int _low = 1;

  /// The genesis block's header: the history's first leaf and the
  /// retarget's first input.
  BlockHeader? _genesisHeader;

  /// The checkpoint this session started from, if any, and the header
  /// history through it (to rebuild the history on a reorganization before
  /// the headers back to genesis are in).
  Checkpoint? _startedFrom;
  HistoryPeaks? _checkpointHistory;

  /// Headers from genesis up, checked in the background toward `_low`.
  final _backfill = HeaderChain();
  HistoryPeaks? _backfillHistory;

  /// Headers from genesis that a previous session back-filled but didn't
  /// finish (from the local copy): the back-fill resumes after them.
  HeaderChain? _resumeBackfill;

  /// Whether `_backfill` began with headers from the local copy. If they
  /// turn out not to lead to the checkpoint (another chain's, after a deep
  /// reorganization), they're dropped and the back-fill starts over.
  bool _backfillFromCache = false;

  /// How many back-filled headers are in the local copy already.
  int _backfillSaved = 0;

  /// A checkpoint to start from instead of the network's own (tests, or a
  /// release that ships one elsewhere).
  final Checkpoint? checkpoint;

  /// The checkpoint in force: this client's, or the network's.
  Checkpoint? get _checkpoint => checkpoint ?? network?.checkpoint;

  MurmurClient({this.checkpoint});

  /// The header history through the tip (genesis first): the next header's
  /// `history_root` must be its root.
  HistoryPeaks _history = HistoryPeaks();

  /// Copies of `_history` through every 1024th height, so a reorganization
  /// rebuilds it from the nearest one below the fork instead of from
  /// genesis: packed headers rebuilt as objects compute their work again,
  /// a 128-bit division each, slow on the web.
  /// Only the last few are kept: deeper reorganizations are rare enough to
  /// rebuild from genesis.
  final Map<int, HistoryPeaks> _historyMarks = {};
  static const _markEvery = 1024;

  /// Records `history`, through `height`, if it's a mark's height.
  void _markHistory(int height, HistoryPeaks history) {
    if (height % _markEvery != 0) return;
    _historyMarks[height] = history.copy();
    _historyMarks.removeWhere((at, _) => at <= height - 16 * _markEvery);
  }

  /// Blocks fetched so far, aligned with `_headers` (null: not fetched).
  final List<Block?> _blocks = [];
  int _fetched = 0;

  /// Blocks `_top..height` are all fetched: the newest stretch, which views
  /// read newest first. `height + 1` when the tip itself isn't fetched.
  int _top = 1;

  /// Blocks `1.._counted` are replayed into balances (background, with a
  /// local copy only).
  int _counted = 0;

  final Map<String, Uint8List> _contents = {};

  /// Location (height, index) of every transaction in a fetched block.
  final Map<String, (int, int)> _txIndex = {};

  /// Transactions proven by merkle branch (GetTx), without their block.
  final Map<String, _LooseTx> _loose = {};

  /// `address:flagged txid` of every flag in a fetched block.
  final Set<String> _flagKeys = {};

  /// Message hashes the node didn't serve when asked (it may have deleted
  /// the content); not asked for again this session.
  final Set<String> _contentUnavailable = {};

  /// Known transactions on the chain whose content isn't here yet, by
  /// message hash, with their height: what the next GetContent asks for,
  /// newest first.
  final Map<String, (int, Transaction)> _missingContent = {};

  /// Message hashes of messages their own author flagged, as seen in fetched
  /// blocks (a retraction): their content is deleted here, from memory and
  /// the local copy, and never asked for again.
  final Set<String> _withdrawnContent = {};

  // Replayed state, valid for blocks 1.._counted.
  final Map<String, int> _balances = {};
  final Map<String, int> _nonces = {};
  final Map<String, int> _blocksMined = {};
  final Set<String> _countedFlagEntries = {};
  int _issued = 0;

  /// The counted transactions involving each address, oldest first: sent by
  /// it, paid to it, or flagging its messages. Each entry is its location
  /// (height, index) and the address's balance right after it.
  final Map<String, List<(int, int, int)>> _byAddress = {};

  /// Burned tokens not yet paid back to miners, after block `_counted`.
  int _burnPool = 0;

  /// Burn-pool payout of each counted block: `_payouts[i]` is for height i + 1.
  final List<int> _payouts = [];
  final Map<String, PendingTx> _pending = {};

  /// What the node answered for each transaction this client submitted.
  final Map<String, TxStatus> _statuses = {};

  // ---- proofs -------------------------------------------------------------------

  /// State values proven against a header, by key (hex).
  final Map<String, _Proven> _proven = {};

  /// State keys views want kept current at the tip.
  final Map<String, Uint8List> _watchedKeys = {};

  /// The tip height each watched key was last asked about.
  final Map<String, int> _stateAsked = {};

  /// Verified block filters, by height.
  final Map<int, Uint8List> _filters = {};

  /// Items (addresses, txids) views follow, with the height to search from:
  /// every block whose filter matches one is fetched.
  final Map<String, (Uint8List, int)> _watchedItems = {};
  int _watchVersion = 0;

  /// Heights whose filter was tested against the watched items, and at
  /// which watch version.
  final Map<int, int> _filterTested = {};

  /// Cached filter tests: `height:item hex` -> match.
  final Map<String, bool> _filterMatches = {};

  final Set<String> _wantedTxids = {};

  /// Those the node is being asked for right now (see `_fetchTxs`).
  Set<String> _txAsking = const {};

  /// Txids the node placed below the headers checked so far: asked again
  /// once the headers back to genesis are in.
  final Set<String> _deferredTxids = {};
  final Set<String> _txUnknown = {};

  /// Set when the node's state root at the counted tip disagrees with this
  /// client's own count: then the node (or the client) is wrong.
  int? _stateCheckedAt;

  // ---- fetching -----------------------------------------------------------------

  bool _needHeaders = false;
  bool _headersSyncing = false;
  bool _wantOlder = false;
  final Set<int> _wantedHeights = {};

  /// Extra batches of recent blocks to fetch once the view is served.
  int _prefetch = 0;
  Completer<void>? _wakeup;

  ChainCache? _cache;
  final List<Block> _unsavedBlocks = [];
  final Map<String, Uint8List> _unsavedContents = {};

  /// Content to delete from the local copy at the next flush.
  final Set<String> _unsavedRemovals = {};

  /// How long message content stays in the local copy, by its block's time,
  /// to save storage. Starred content, and content of starred threads,
  /// stays however old. Within a session, content is fetched as needed
  /// whatever its age.
  static const contentRetention = Duration(days: 90);

  /// Starred txids: messages, or thread roots (starring the whole thread).
  Set<String> _starred = const {};

  /// The message (txid and height) each held content belongs to.
  final Map<String, (String, int)> _contentOwner = {};

  /// Content hashes in the local copy.
  final Set<String> _onDisk = {};

  DateTime? _lastSweep;
  int? _headersChangedFrom;

  Transport? _socket;
  SecureChannel? _channel;
  StreamSubscription<Uint8List>? _sub;
  Timer? _pingTimer;
  Completer<Hello>? _helloWaiter;
  Completer<List<BlockHeader>>? _headersWaiter;
  Completer<List<BlockRecord>>? _blocksWaiter;
  Completer<List<MessageContent>>? _contentWaiter;
  Completer<State>? _stateWaiter;
  Completer<Filters>? _filtersWaiter;
  Completer<Tx>? _txWaiter;
  Completer<Fees>? _feesWaiter;
  Completer<HeaderProof>? _headerProofWaiter;
  (DateTime, FeeInfo)? _lastFees;

  /// Bumped on every disconnect, so work tied to an old socket stops.
  int _generation = 0;

  // ---- queries ------------------------------------------------------------------

  int get height => _headers.length;
  bool get isOnline => state == LinkState.syncing || state == LinkState.live;

  /// Whether every block is fetched and counted (background, with a local
  /// copy): what gives every history row its balances.
  bool get complete => _counted == height;

  /// Blocks counted so far (from genesis up).
  int get countedHeight => _counted;

  /// Blocks fetched so far, of `height`.
  int get fetchedBlocks => _fetched;

  /// Whether older blocks are still missing below the newest stretch, so
  /// lists read newest first can grow.
  bool get canLoadOlder => _top - 1 > _counted;

  /// Whether the whole chain is fetched in the background (only with a
  /// local copy: otherwise every visit would download it all again).
  bool get countsChain => _cache != null;

  /// A header known to be there (at or above `_low`, or genesis).
  BlockHeader _hdr(int h) => h == 0 ? _genesisHeader! : _headers[h - 1]!;

  Uint8List hashAt(int h) => h == 0 ? genesis! : _headers.hashAt(h - 1)!;

  /// The header at `h`, if it's known.
  BlockHeader? headerAt(int h) => h >= 1 && h <= height ? _headers[h - 1] : null;

  /// The block at height `h`, if it's fetched.
  Block? blockAt(int h) => h >= 1 && h <= height ? _blocks[h - 1] : null;

  int? heightOfBlock(String hashHex) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hashHex)) return null;
    final hash = fromHex(hashHex);
    for (var h = height; h >= _low; h--) {
      if (_headers.hashIs(h - 1, hash)) return h;
    }
    return null;
  }

  /// The checkpoint this session started from, while the headers below it
  /// are still being checked back to genesis; null once they are (or when
  /// it started from genesis or a local copy).
  int? get checkingFromCheckpoint => _low > 1 ? _startedFrom?.height : null;

  /// Headers checked from genesis so far, toward the checkpoint.
  int get checkedTowardGenesis => _backfill.length;

  /// Headers this session took from the node and checked in full (link,
  /// work, time, retarget, history). Those reloaded from the local copy
  /// aren't counted: a back-fill resumed after them fetches only the rest.
  int get headersFromNode => _headersFromNode;
  int _headersFromNode = 0;

  /// Whether the newest block is old for this network (about 20 block
  /// intervals): this node may be behind, or cut off from the others.
  bool get tipLooksOld {
    final net = network;
    if (net == null || height == 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - _headers.timestampAt(height - 1)! > 20 * net.targetBlockSecs;
  }

  // ---- proven state -------------------------------------------------------------

  /// Keeps `key` proven at the tip; returns what's proven so far, if anything.
  _Proven? _watchKey(Uint8List key) {
    final hex = toHex(key);
    if (!_watchedKeys.containsKey(hex)) {
      _watchedKeys[hex] = key;
      _wake();
    }
    return _proven[hex];
  }

  /// `address`'s balance and nonce, proven against a recent header's state
  /// root; null until the node's proof has arrived. Keeps it current.
  AccountState? account(String address) {
    final p = _watchKey(accountKey(fromHex(address)));
    if (p == null) return null;
    final v = p.value;
    return v == null ? AccountState(0, 0, p.height) : AccountState(readU64le(v), readU64le(v, 8), p.height);
  }

  /// `address`'s balance: proven, or counted once the whole chain is.
  int? knownBalance(String address) => account(address)?.balance ?? (complete ? _balances[address] ?? 0 : null);

  /// The burn pool and the total issued, proven at the tip; null until then.
  int? get provenPool => _provenU64(poolKey);
  int? get provenIssued => _provenU64(issuedKey);

  int? _provenU64(Uint8List key) {
    final p = _watchKey(key);
    if (p == null) return null;
    return p.value == null ? 0 : readU64le(p.value!);
  }

  /// Tokens in circulation: everything issued, less what waits in the pool.
  int? get circulating {
    final issued = provenIssued, pool = provenPool;
    return issued == null || pool == null ? null : issued - pool;
  }

  /// The next block's reward before fees: subsidy plus burn-pool payout.
  int? get nextBlockReward {
    final pool = provenPool;
    return network == null || pool == null ? null : network!.subsidyAt(height + 1) + network!.burnPayout(pool);
  }

  /// Whether `address` has flagged `txid` on the chain, proven; null until
  /// the proof arrives.
  bool? provenFlagged(String address, String txid) {
    final p = _watchKey(flagEntryKey(flagKeyOf(fromHex(address), fromHex(txid))));
    return p == null ? null : p.value != null;
  }

  int blocksMinedBy(String address) => _blocksMined[address] ?? 0;

  /// What block `h` paid its miner out of the burn pool, once it's counted.
  int? payoutAt(int h) => h >= 1 && h <= _payouts.length ? _payouts[h - 1] : null;

  /// Whether a pending transaction may still be mined: the node didn't
  /// answer that it's invalid or refused it (a refused one isn't in its
  /// mempool, so its nonce is free for the next one).
  bool _inPlay(PendingTx p) {
    final code = _statuses[p.tx.id]?.code;
    return code != TxStatusCode.invalid && code != TxStatusCode.refused;
  }

  /// `address`'s transactions not yet in its proven state: pending ones that
  /// may still be mined, and those already mined above the block the proof
  /// is from (a proof lags a new block until it's asked again). Without the
  /// latter, a transaction mined a moment ago would count neither as
  /// pending nor in the proof, and the next one would reuse its nonce.
  List<Transaction> _notYetProven(String address, AccountState proven) {
    final txs = <String, Transaction>{
      for (final p in _pending.values)
        if (p.tx.fromAddress == address && _inPlay(p) && p.tx.nonce >= proven.nonce) p.tx.id: p.tx,
      for (var h = proven.height + 1; h <= height; h++)
        for (final tx in _blocks[h - 1]?.transactions ?? const <Transaction>[])
          if (tx.fromAddress == address && tx.nonce >= proven.nonce) tx.id: tx,
      for (final loose in _loose.values)
        if (loose.height > proven.height && loose.tx.fromAddress == address && loose.tx.nonce >= proven.nonce)
          loose.tx.id: loose.tx,
    };
    return txs.values.toList()..sort((a, b) => a.nonce.compareTo(b.nonce));
  }

  /// `fee + amount` of `address`'s transactions not yet in the proven state:
  /// pending, or mined since the proof.
  int pendingDebitOf(String address) {
    final proven = account(address);
    if (proven == null) {
      return _pending.values
          .where((p) => p.tx.fromAddress == address && _inPlay(p))
          .fold(0, (sum, p) => sum + p.tx.fee + p.tx.amount);
    }
    return _notYetProven(address, proven).fold(0, (sum, tx) => sum + tx.fee + tx.amount);
  }

  /// What `address` can spend now, or null until its balance is proven.
  int? availableTo(String address) {
    final proven = account(address);
    return proven == null ? null : proven.balance - pendingDebitOf(address);
  }

  /// The nonce `address`'s next transaction must carry: the proven one, or
  /// past its own transactions the proof doesn't count yet (pending, or
  /// mined since the block it's from). Null until proven.
  int? nextNonce(String address) {
    final proven = account(address);
    if (proven == null) return null;
    var next = proven.nonce;
    // In nonce order, so each one found moves the next along.
    for (final tx in _notYetProven(address, proven)) {
      if (tx.nonce == next) next++;
    }
    return next;
  }

  /// What the node answered when this client submitted `txid`.
  TxStatus? statusOf(String txid) => _statuses[txid];

  // ---- content and lookups ------------------------------------------------------

  Uint8List? contentFor(Uint8List? messageHash) =>
      messageHash == null ? null : _contents[toHex(messageHash)];

  Uint8List? _contentOf(Transaction tx) => contentFor(tx.messageHash);

  /// A message's content as the client holds it now. Content often arrives
  /// after the view was made, so anything shown from a kept view should read
  /// it through this. A withdrawn message has none, even if the view kept it.
  Uint8List? liveContent(TxView v) => contentWithdrawn(v.tx) ? null : v.content ?? _contentOf(v.tx);

  /// Whether `tx` is a message its own author flagged (a retraction, seen in
  /// a fetched block): its content is deleted here and never fetched again.
  bool contentWithdrawn(Transaction tx) {
    final hash = tx.messageHash;
    return hash != null && _withdrawnContent.contains(toHex(hash));
  }

  /// Whether content the client doesn't hold may still come: it's online,
  /// and the node hasn't already answered that it doesn't have it.
  bool contentExpected(Transaction tx) {
    final hash = tx.messageHash;
    if (hash == null || tx.contentSize == 0 || !isOnline) return false;
    final key = toHex(hash);
    return !_contents.containsKey(key) && !_contentUnavailable.contains(key) && !_withdrawnContent.contains(key);
  }

  /// Whether `address` has flagged transaction `txid`: proven on the chain,
  /// seen in a fetched block, or pending. Consensus allows one flag per
  /// address per transaction.
  bool hasFlagged(String address, String txid) {
    final key = '$address:$txid';
    return (provenFlagged(address, txid) ?? false) ||
        _flagKeys.contains(key) ||
        _pending.values.any((p) => p.tx.kind == TxKind.flag && '${p.tx.fromAddress}:${p.tx.referenceId}' == key);
  }

  /// Whether a flag from `address` on `txid` is known without asking the
  /// node: in a fetched block (an address's own flags are, through its
  /// filter) or pending. For lists, where proving each would cost a state
  /// query per row; [hasFlagged] proves it.
  bool flaggedKnown(String address, String txid) {
    final key = '$address:$txid';
    return _flagKeys.contains(key) ||
        _pending.values.any((p) => p.tx.kind == TxKind.flag && '${p.tx.fromAddress}:${p.tx.referenceId}' == key);
  }

  TxView _viewAt(int h, int i, {int? balanceAfter}) {
    final b = _blocks[h - 1]!;
    final tx = b.transactions[i];
    return TxView(tx, height: h, blockTime: b.header.timestamp, content: _contentOf(tx), balanceAfter: balanceAfter);
  }

  /// A transaction by id, if it's pending, in a fetched block, or proven by
  /// GetTx.
  TxView? lookupTx(String txid) {
    final loc = _txIndex[txid];
    if (loc != null) return _viewAt(loc.$1, loc.$2);
    final loose = _loose[txid];
    if (loose != null && loose.height <= height) {
      return TxView(loose.tx,
          height: loose.height, blockTime: _headers.timestampAt(loose.height - 1)!, content: _contentOf(loose.tx));
    }
    final p = _pending[txid];
    if (p != null) return TxView(p.tx, content: p.content, pending: p);
    return null;
  }

  /// Asks the node for a transaction the client doesn't have (GetTx).
  void requestTx(String txid) {
    if (lookupTx(txid) != null || _txUnknown.contains(txid) || _txAsking.contains(txid)) return;
    if (!_wantedTxids.add(txid)) return;
    _wake();
  }

  /// Whether the node was asked for `txid` and doesn't know it.
  bool isUnknownTx(String txid) => _txUnknown.contains(txid);

  /// What a Reply or Flag references, fetching it if the client lacks it.
  TxView? referenced(TxView v) {
    final ref = v.tx.referenceId;
    if (ref == null) return null;
    final found = lookupTx(ref);
    if (found == null) requestTx(ref);
    return found;
  }

  /// Who wrote the transaction `txid`, if the client knows it.
  String? authorOf(String txid) => lookupTx(txid)?.tx.fromAddress;

  bool _involves(Transaction t, String address) =>
      t.fromAddress == address ||
      t.toAddress == address ||
      (t.kind == TxKind.flag && t.referenceId != null && authorOf(t.referenceId!) == address);

  // ---- filters ------------------------------------------------------------------

  /// Follows `address`: every block touching it is found by its filter and
  /// fetched, so its history is complete.
  void watchAddress(String address) => _watchItem(fromHex(address), 1);

  /// Follows a thread: blocks referencing its root or any of its replies,
  /// from the root's height on.
  void watchThread(TxView root, Iterable<TxView> messages) {
    final from = root.height ?? height;
    _watchItem(root.tx.hash, from);
    for (final m in messages) {
      _watchItem(m.tx.hash, from);
    }
  }

  void _watchItem(Uint8List item, int fromHeight) {
    final hex = toHex(item);
    final current = _watchedItems[hex];
    if (current != null && current.$2 <= fromHeight) return;
    _watchedItems[hex] = (item, fromHeight);
    _watchVersion++;
    _wake();
  }

  /// Whether block `h`'s filter may hold `item`; null if the filter isn't
  /// known yet.
  /// `itemHex` is `item` in hex, which callers looping over heights compute
  /// once.
  bool? _filterMatch(int h, Uint8List item, String itemHex) {
    final filter = _filters[h];
    if (filter == null) return null;
    return _filterMatches['$h:$itemHex'] ??= filterMatchesAny(filter, _headers.prevHashAt(h - 1)!, [item]) ?? true;
  }

  /// Whether `address`'s history is still being looked for: some block not
  /// fetched yet may hold one of its transactions.
  bool historyPending(String address) {
    final item = fromHex(address);
    for (var h = height; h > _counted; h--) {
      if (_blocks[h - 1] != null) continue;
      if (_filterMatch(h, item, address) != false) return true;
    }
    return false;
  }

  /// Transactions involving `address` (sent by it, paid to it, or flagging
  /// one of its messages), newest first: pending, then the chain from the tip
  /// down, as far as its history is known (fetched blocks, and blocks whose
  /// filter shows they don't touch it). Lazy, so the newest few cost only
  /// those few.
  ///
  /// Each view carries `address`'s balance right after it when that's known:
  /// counted from the chain, or worked back from the proven balance at the
  /// tip (until a block the address mined, whose reward isn't known).
  Iterable<TxView> activityOf(String address) sync* {
    final item = fromHex(address);
    final pending = _pending.values.where((p) => _involves(p.tx, address)).toList()
      ..sort((a, b) => b.seenAt.compareTo(a.seenAt));
    // Refused or invalid ones are shown, but move no balance.
    final pendingChange = pending.where(_inPlay).fold<int>(0, (sum, p) => sum + balanceChange(p.tx, address));
    final proven = account(address);
    int? running = proven != null && proven.height == height
        ? proven.balance + pendingChange
        : (complete ? balanceOfCounted(address) + pendingChange : null);
    for (final p in pending) {
      final inPlay = _inPlay(p);
      yield TxView(p.tx, content: p.content, pending: p, balanceAfter: inPlay ? running : null);
      if (running != null && inPlay) running -= balanceChange(p.tx, address);
    }
    // Not counted yet: fetched blocks, and filters for the rest.
    var rewardsCheckedTo = height; // blocks above this were checked for rewards to the address
    for (var h = height; h > _counted; h--) {
      final b = _blocks[h - 1];
      if (b == null) {
        if (_filterMatch(h, item, address) == false) continue;
        return; // may hold its transactions: they come once it's fetched
      }
      for (var i = b.transactions.length - 1; i >= 0; i--) {
        final tx = b.transactions[i];
        if (!_involves(tx, address)) continue;
        if (running != null) {
          // A block the address mined paid it a reward we can't know here.
          for (var m = rewardsCheckedTo; m >= h; m--) {
            if (_headers.minedBy(m - 1, item)) {
              running = null;
              break;
            }
          }
          rewardsCheckedTo = h - 1;
        }
        yield _viewAt(h, i, balanceAfter: running);
        if (running != null) running -= balanceChange(tx, address);
      }
    }
    final entries = _byAddress[address];
    if (entries == null) return;
    for (var i = entries.length - 1; i >= 0; i--) {
      final (h, j, balance) = entries[i];
      if (h > _counted) continue; // rolled back while iterating
      yield _viewAt(h, j, balanceAfter: balance);
    }
  }

  int balanceOfCounted(String address) => _balances[address] ?? 0;

  /// What `tx` does to `address`'s balance: the sender pays amount and fee,
  /// the recipient gets the amount (both, for a payment to oneself).
  static int balanceChange(Transaction tx, String address) =>
      (tx.toAddress == address ? tx.amount : 0) - (tx.fromAddress == address ? tx.amount + tx.fee : 0);

  /// Every known message (threads, replies, flags), newest first: pending
  /// ones, then fetched blocks from the tip down, then those proven by GetTx.
  /// With `upTo` (the Threads tab's fixed view), only blocks up to that
  /// height, plus what this device sent: pending or mined since, so your own
  /// new thread or reply shows at once and stays once mined.
  List<TxView> _messagesKnown({int? upTo}) {
    final out = <TxView>[];
    // Not what the node refused: it won't be mined.
    final pending = _pending.values
        .where((p) => p.tx.kind != TxKind.raw && _inPlay(p) && (upTo == null || p.mine))
        .toList()
      ..sort((a, b) => b.seenAt.compareTo(a.seenAt));
    out.addAll([for (final p in pending) TxView(p.tx, content: p.content, pending: p)]);
    final limit = min(upTo ?? height, height);
    for (var h = height; h >= 1; h--) {
      final b = _blocks[h - 1];
      if (b == null) continue;
      for (var i = b.transactions.length - 1; i >= 0; i--) {
        final tx = b.transactions[i];
        if (tx.kind == TxKind.raw) continue;
        if (h <= limit || _sentHere.contains(tx.id)) out.add(_viewAt(h, i));
      }
    }
    for (final MapEntry(key: id, value: loose) in _loose.entries) {
      if ((loose.height <= limit || _sentHere.contains(id)) && !_txIndex.containsKey(id) && loose.tx.kind != TxKind.raw) {
        out.add(lookupTx(id)!);
      }
    }
    return out;
  }

  // ---- threads, replies and flags ----------------------------------------------

  int _dataVersion = 0;
  int _indexVersion = -1;
  MessageIndex? _index;
  (int, int, int, int, int, int)? _snapshotKey;

  /// Txids of transactions this device sent this session.
  final Set<String> _sentHere = {};

  /// Own pending transactions asked for by id because the proven nonce has
  /// passed theirs (see `_settleOwnPending`).
  final Set<String> _settling = {};
  MessageIndex? _snapshotIndex;
  int _reorgs = 0;

  @override
  void notifyListeners() {
    _dataVersion++;
    super.notifyListeners();
  }

  /// Everything known, pending included. Rebuilt at most once per change.
  MessageIndex get _messages {
    if (_index == null || _indexVersion != _dataVersion) {
      _index = MessageIndex.build(_messagesKnown());
      _indexVersion = _dataVersion;
    }
    return _index!;
  }

  /// Threads, most recently active first (a new reply bumps its thread).
  /// With `upTo`, only what's in blocks up to that height: the Threads tab's
  /// fixed view, which grows only as older blocks arrive.
  ///
  /// That view never moves a thread it has shown. A reply can arrive before
  /// its thread, which is older and so in a block not fetched yet: the
  /// thread is asked for by id at once, and the threads less recent than
  /// that reply wait for it ([threadsHeldBack]), instead of showing first
  /// and being pushed down.
  List<ThreadSummary> threads({int? upTo}) {
    if (upTo == null) return _messages.threads;
    var fetchedBelow = 0;
    for (var h = min(upTo, height); h >= 1; h--) {
      if (_blocks[h - 1] != null) fetchedBelow++;
    }
    // Own messages count too: sent (pending), and mined since.
    final ownPending = _pending.values.where((p) => p.mine && _inPlay(p)).length;
    final ownMined = _sentHere.where((id) => _txIndex.containsKey(id) || _loose.containsKey(id)).length;
    final key = (upTo, fetchedBelow, _loose.length, _reorgs, ownPending, ownMined);
    if (_snapshotIndex == null || _snapshotKey != key) {
      _snapshotIndex = MessageIndex.build(_messagesKnown(upTo: upTo));
      _snapshotKey = key;
    }
    final index = _snapshotIndex!;
    index.missingParents.keys.forEach(requestTx);
    final settled = index.settledThreads(_stillComing);
    _threadsHeldBack = settled.held;
    return settled.threads;
  }

  /// Whether the last `threads(upTo:)` left threads out, waiting for a more
  /// recently active one that's on its way.
  bool get threadsHeldBack => _threadsHeldBack;
  bool _threadsHeldBack = false;

  /// Whether a transaction asked of the node may still arrive: not while
  /// offline, not once the node said it doesn't know it, and not while it
  /// waits for the headers below a checkpoint (that can take minutes, and
  /// the list shouldn't).
  bool _stillComing(String txid) =>
      isOnline && lookupTx(txid) == null && !_txUnknown.contains(txid) && !_deferredTxids.contains(txid);

  int replyCountOf(TxView v) => _messages.replyCountOf(v);

  int flagCountOf(TxView v) => _messages.flagCountOf(v);

  /// Whether a message is known not to be text (PROTOCOL.md Section 2.4:
  /// first byte 0x00, as in aliases), reading its content live.
  bool isNonText(TxView v) {
    final content = liveContent(v);
    return content != null && protocol_alias.isNonText(messageOf(content));
  }

  final Map<String, String?> _aliases = {};
  int _aliasVersion = -1;

  /// The alias `address` published (PROTOCOL.md Section 7.8), when the
  /// client can tell it's the latest: see `services/aliases.dart`. Null for
  /// none, or none known yet. Resolved again whenever the client changes
  /// (new blocks, content, a reorganization).
  String? publishedAlias(String address) {
    if (_aliasVersion != _dataVersion) {
      _aliases.clear();
      _aliasVersion = _dataVersion;
    }
    return _aliases.putIfAbsent(address, () {
      final item = fromHex(address);
      return resolveAlias(
        _messages.aliasCandidatesOf(address),
        tip: height,
        unknown: (h) => h < _low || (_blocks[h - 1] == null && _filterMatch(h, item, address) != false),
        contentOf: (v) => _contentOf(v.tx),
      );
    });
  }

  /// Whether a message's author flagged it themselves, as far as fetched
  /// blocks and pending transactions tell: a withdrawal. The app lists such
  /// a thread only to its author, and nodes may stop keeping its content.
  bool selfFlagged(TxView v) => _messages.isSelfFlagged(v);

  /// Whether a Reply is part of a thread (PROTOCOL.md Section 2.4); if not,
  /// it's shown as a payment.
  bool isThreadedReply(TxView v) => _messages.isThreadedReply(v);

  /// Direct replies to a message, oldest first.
  List<TxView> repliesOf(TxView v) => _messages.repliesOf(v);

  /// Every reply under a message, at any depth, among what's fetched.
  Iterable<TxView> repliesUnder(TxView v) => _messages.repliesUnder(v);

  /// The threads and replies `address` wrote, among what's fetched, newest
  /// first.
  List<TxView> messagesBy(String address) => _messages.messagesBy(address);

  /// The message a reply answers, if the client knows it.
  TxView? parentOf(TxView v) => _messages.parentOf(v);

  /// The thread at the top of a message's reply chain, if known.
  TxView? threadRootOf(TxView v) => _messages.threadRootOf(v);

  // ---- what views ask for -----------------------------------------------------

  /// A list read newest first needs more: fetch the next older batch.
  void requestOlder() {
    if (!canLoadOlder || _wantOlder) return;
    _wantOlder = true;
    _wake();
  }

  /// A page shows block `h`: fetch it if it isn't.
  void requestBlock(int h) {
    if (h < 1 || h > height || _blocks[h - 1] != null || !_wantedHeights.add(h)) return;
    _wake();
  }

  // ---- cache --------------------------------------------------------------------

  /// Starts (or, with null, stops) keeping what's fetched in `cache`. What's
  /// already in memory is stored right away.
  void useCache(ChainCache? cache) {
    _cache = cache;
    if (cache == null || genesis == null) return;
    // Headers are stored from genesis up: from a checkpoint, once the ones
    // below it are checked.
    _headersChangedFrom = _low == 1 ? 1 : null;
    _unsavedBlocks
      ..clear()
      ..addAll(_blocks.whereType<Block>());
    _unsavedContents
      ..clear()
      ..addAll(_contents);
    _wake();
  }

  Future<void> _flushCache() async {
    final cache = _cache;
    final g = genesis;
    if (cache == null || g == null) return;
    final from = _low == 1 ? _headersChangedFrom : null;
    // During a back-fill, the headers checked from genesis so far are kept,
    // so a later session resumes after them instead of starting over.
    final backfillFrom = _low > 1 && _backfill.length > _backfillSaved ? _backfillSaved + 1 : null;
    final backfill = backfillFrom == null ? null : _backfill.snapshot();
    if (backfill != null) _backfillSaved = backfill.length;
    final blocks = List.of(_unsavedBlocks);
    // Storage saving: old content goes to the local copy only if starred.
    final contents = Map.of(_unsavedContents)..removeWhere((key, _) => !_keepOnDisk(key));
    final now = DateTime.now();
    if (_lastSweep == null || now.difference(_lastSweep!) > const Duration(minutes: 10)) {
      _lastSweep = now;
      _unsavedRemovals.addAll(_onDisk.where((key) => !_keepOnDisk(key)));
    }
    final removals = Set.of(_unsavedRemovals);
    _onDisk
      ..addAll(contents.keys)
      ..removeAll(removals);
    final headers = from == null ? null : _headers.snapshot();
    if (from != null) _headersChangedFrom = null;
    _unsavedBlocks.clear();
    _unsavedContents.clear();
    _unsavedRemovals.clear();
    try {
      if (headers != null) await cache.saveHeaders(toHex(g), headers, from!);
      if (backfill != null) await cache.saveHeaders(toHex(g), backfill, backfillFrom!);
      await cache.saveBlocks(blocks);
      await cache.saveContents(contents);
      await cache.removeContents(removals);
    } catch (e) {
      // Storage full or unavailable: carry on without it.
      debugPrint('chain cache: $e');
      _cache = null;
    }
  }

  /// Takes in what a previous session stored, checking it again: headers
  /// must link up from genesis, meet their targets, carry the right history
  /// root and lead to the checkpoint; blocks must match their headers, merkle
  /// roots and filters; content its hash.
  Future<void> _loadCache() async {
    final cache = _cache;
    if (cache == null || _headers.isNotEmpty) return;
    final CachedChain? cached;
    try {
      cached = await cache.load(toHex(genesis!));
    } catch (e) {
      debugPrint('chain cache: $e');
      return;
    }
    if (cached == null) return;
    // Checked and packed one at a time: the stored chain is never held as
    // objects.
    final headers = HeaderChain();
    final history = _history.copy();
    for (final h in cached.headers) {
      if (h.height != headers.length + 1 ||
          !(headers.isEmpty ? bytesEqual(h.prevHash, genesis!) : headers.hashIs(headers.length - 1, h.prevHash)) ||
          !h.meetsTarget ||
          !bytesEqual(h.historyRoot, history.root)) {
        break;
      }
      headers.add(h);
      history.pushHeader(h);
      _markHistory(headers.length, history);
    }
    // A copy that doesn't lead to the checkpoint in force (a newer release
    // may ship one) is of another chain: start over from the checkpoint.
    final cp = _checkpoint;
    if (cp != null && headers.length >= cp.height && !headers.hashIs(cp.height - 1, fromHex(cp.hash))) {
      _historyMarks.clear();
      return;
    }
    // A copy that stops short of the checkpoint is a back-fill a previous
    // session didn't finish (or a copy from before the checkpoint shipped).
    // Start from the checkpoint as usual, so lists show at once, and let the
    // back-fill resume after these headers instead of from genesis.
    if (cp != null && headers.length < cp.height) {
      _historyMarks.clear(); // of a back-fill, not of the chain's history
      if (headers.isNotEmpty) _resumeBackfill = headers;
      cached.contents.forEach((hash, content) {
        if (toHex(sha256Bytes(content)) == hash) _contents[hash] = content;
      });
      _onDisk.addAll(cached.contents.keys);
      return;
    }
    final loaded = headers.length;
    _headers.takeFrom(headers);
    _blocks.addAll(List<Block?>.filled(loaded, null));
    _history = history;
    _top = height + 1;
    cached.contents.forEach((hash, content) {
      if (toHex(sha256Bytes(content)) == hash) _contents[hash] = content;
    });
    _onDisk.addAll(cached.contents.keys);
    for (final MapEntry(key: h, value: b) in cached.blocks.entries) {
      try {
        if (h >= 1 && h <= height) _storeBlock(b, const [], save: false);
      } on FormatException {
        // Doesn't match its header: fetched again when needed.
      }
    }
    _advance();
  }

  // ---- connection -------------------------------------------------------------

  /// Connects to the node at `host:port` (a name may stand for several).
  /// Called by the user: automatic retries start over from a short wait.
  Future<void> connect(String host, int port) {
    _retries = 0;
    return _connect(host, port);
  }

  Future<void> _connect(String host, int port) async {
    _cancelRetry();
    _teardown();
    final gen = _generation;
    this.host = host;
    this.port = port;
    error = null;
    state = LinkState.connecting;
    notifyListeners();
    try {
      final hello = await _handshake(host, port, gen);
      if (hello == null) return; // another connect or a disconnect came first
      if (genesis != null && !bytesEqual(genesis!, hello.genesis)) {
        _resetChain();
      }
      genesis = hello.genesis;
      network = NetworkInfo.forGenesis(hello.genesis);
      peerHeight = hello.height;
      _send(Hello(
        version: protocolVersion,
        genesis: hello.genesis,
        nonce: _randomNonce(),
        listenPort: 0, // not listening: keeps us out of the node's address book
        height: 0,
        work: BigInt.zero, // so the node never tries to sync from us
      ));
      _pingTimer = Timer.periodic(_pingInterval, (_) => _send(const Ping()));
      // The genesis header: derived for the built-in networks, else fetched.
      if (_genesisHeader == null) {
        final known = network!.known ? network!.genesisHeader() : null;
        final header = known ?? (await _getBlocks([hello.genesis])).firstOrNull?.block.header;
        if (header == null || !bytesEqual(header.hash, hello.genesis)) {
          throw const FormatException('the node did not serve its genesis block');
        }
        _genesisHeader = header;
      }
      if (_history.count == 0) _history.pushHeader(_genesisHeader!);
      state = LinkState.syncing;
      notifyListeners();
      await _loadCache();
      if (gen != _generation) return;
      _needHeaders = true;
      _prefetch = 1;
      notifyListeners();
      unawaited(_work(gen));
    } catch (e) {
      if (gen == _generation) _fail(gen, _describe(e));
    }
  }

  /// Opens the connection and runs it through the key exchange and the
  /// node's Hello, trying the name's other nodes when one fails at any
  /// point: unreachable, a broken key exchange, silence, a wrong protocol
  /// version. Natively each try goes to an address not tried yet. In a
  /// browser, which picks the address itself (and keeps picking the same
  /// one), a few more tries only help with passing failures. Returns null
  /// if a newer connect or a disconnect took over;
  /// throws the last failure once there's nothing left to try.
  Future<Hello?> _handshake(String host, int port, int gen) async {
    final tried = <String>{};
    Object? lastFailure;
    for (var attempt = 0; attempt < _maxConnectTries; attempt++) {
      if (attempt > 0 && !canChooseAddress) await Future<void>.delayed(const Duration(seconds: 1));
      if (gen != _generation) return null;
      final Transport socket;
      try {
        socket = await openTransport(host, port, _connectTimeout, avoid: tried);
      } catch (e) {
        // Natively every address left was tried, and none answered; what
        // went wrong with an earlier one says more than that.
        if (canChooseAddress) {
          lastFailure ??= e;
          break;
        }
        lastFailure = e;
        continue;
      }
      if (gen != _generation) {
        socket.close();
        return null;
      }
      tried.add(socket.peer);
      _socket = socket;
      try {
        // Every connection is encrypted (PROTOCOL.md Section 7.4).
        final channel = await SecureChannel.open(socket).timeout(const Duration(seconds: 30));
        if (gen != _generation) {
          channel.close();
          return null;
        }
        _channel = channel;
        final helloWaiter = _helloWaiter = Completer<Hello>();
        _sub = channel.payloads.listen(
          (payload) => _onPayload(payload, gen),
          onError: (Object e) => _linkLost(gen, _describe(e)),
          onDone: () => _linkLost(gen, const LinkError(LinkErrorKind.closed)),
          cancelOnError: true,
        );
        // The node speaks first.
        final hello = await helloWaiter.future.timeout(const Duration(seconds: 30));
        if (hello.version != protocolVersion) {
          throw LinkError(LinkErrorKind.version, nodeVersion: hello.version);
        }
        return hello;
      } catch (e) {
        if (e is _Aborted || gen != _generation) return null;
        lastFailure = e;
        await _sub?.cancel();
        _sub = null;
        _channel?.close();
        _channel = null;
        socket.close();
        _socket = null;
        _helloWaiter = null;
      }
    }
    throw lastFailure ?? TransportException('no address to try');
  }

  /// Tries per connect: natively, one per address (a DNS seed lists a few);
  /// in a browser, the same name again (a passing failure may clear).
  static const _maxConnectTries = canChooseAddress ? 8 : 3;

  /// The connection ended or broke. During the handshake that's for
  /// `_handshake` to handle (it tries another node); after it, the link is
  /// lost.
  void _linkLost(int gen, LinkError e) {
    final hello = _helloWaiter;
    if (gen == _generation && hello != null && !hello.isCompleted) {
      hello.completeError(e);
      return;
    }
    _fail(gen, e);
  }

  void disconnect() {
    _cancelRetry();
    _teardown();
    notifyListeners();
  }

  /// Brings the header chain up to the node's (the Sync button).
  void sync() {
    _needHeaders = true;
    _wake();
  }

  // ---- reconnecting ---------------------------------------------------------------

  /// When the client will try the node again by itself, after the link was
  /// lost or couldn't be made; null when it won't (a user's disconnect, or a
  /// failure retrying can't fix).
  DateTime? retryAt;
  Timer? _retryTimer;

  /// Tries in a row since the link was last live: each waits twice as long
  /// as the one before (2 s up to a minute).
  int _retries = 0;

  /// Failures a later try may not meet: the network or the node, not the
  /// data. A wrong protocol version, a checkpoint the chain doesn't lead
  /// to, or a node lying about its state are not retried: they need the
  /// user (or another release).
  static bool _worthRetrying(LinkError e) => switch (e.kind) {
        LinkErrorKind.unreachable ||
        LinkErrorKind.bridgeUnreachable ||
        LinkErrorKind.connection ||
        LinkErrorKind.closed ||
        LinkErrorKind.timeout ||
        LinkErrorKind.tampered =>
          true,
        LinkErrorKind.syncFailed => e.cause != null && _worthRetrying(e.cause!),
        _ => false,
      };

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    retryAt = null;
  }

  void _fail(int gen, LinkError e) {
    if (gen != _generation) return;
    _teardown();
    error = e;
    final h = host, p = port;
    if (h != null && p != null && _worthRetrying(e)) {
      final delay = Duration(seconds: min(60, 2 * pow(2, min(_retries, 5)).toInt()));
      _retries++;
      retryAt = DateTime.now().add(delay);
      _retryTimer = Timer(delay, () => _connect(h, p));
    }
    notifyListeners();
  }

  void _teardown() {
    _generation++;
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.close();
    _channel = null;
    _socket?.close();
    _socket = null;
    for (final c in [
      _helloWaiter,
      _headersWaiter,
      _blocksWaiter,
      _contentWaiter,
      _stateWaiter,
      _filtersWaiter,
      _txWaiter,
      _feesWaiter,
      _headerProofWaiter,
    ]) {
      if (c != null && !c.isCompleted) c.completeError(_Aborted());
    }
    _helloWaiter = null;
    _headersWaiter = null;
    _blocksWaiter = null;
    _contentWaiter = null;
    _stateWaiter = null;
    _filtersWaiter = null;
    _txWaiter = null;
    _feesWaiter = null;
    _headerProofWaiter = null;
    _headersSyncing = false;
    _wake();
    state = LinkState.disconnected;
  }

  static int _randomNonce() {
    final rng = Random.secure();
    // 50 random bits, never 0 (the node treats 0 as "no handshake"). Kept
    // below 2^53 and built without shifts so it's exact on the web too.
    return rng.nextInt(1 << 30) * (1 << 20) + rng.nextInt(1 << 20) + 1;
  }

  static LinkError _describe(Object e) => switch (e) {
        LinkError() => e,
        TamperedFrame() => const LinkError(LinkErrorKind.tampered),
        TransportException(bridgeUrl: final String url) => LinkError(LinkErrorKind.bridgeUnreachable, detail: url),
        TransportException(:final detail) => LinkError(LinkErrorKind.unreachable, detail: detail),
        ConnectionLost(:final detail) => LinkError(LinkErrorKind.connection, detail: detail),
        TimeoutException() => const LinkError(LinkErrorKind.timeout),
        FormatException(:final message) => LinkError(LinkErrorKind.protocol, detail: message),
        _ => LinkError(LinkErrorKind.other, detail: e.toString()),
      };

  void _send(Message msg) => _channel?.send(encodePayload(msg));

  void _onPayload(Uint8List payload, int gen) {
    if (gen != _generation) return;
    try {
      _handle(decodeMessage(payload));
    } on FormatException catch (e) {
      _linkLost(gen, LinkError(LinkErrorKind.protocol, detail: e.message));
    }
  }

  void _complete<T>(Completer<T>? waiter, T value) {
    if (waiter != null && !waiter.isCompleted) waiter.complete(value);
  }

  void _handle(Message message) {
    switch (message) {
      case final Hello msg:
        _complete(_helloWaiter, msg);
      case final Headers msg:
        _complete(_headersWaiter, msg.headers);
        _headersWaiter = null;
      case final Blocks msg:
        _complete(_blocksWaiter, msg.blocks);
        _blocksWaiter = null;
      case final NewBlock msg:
        _onNewBlock(msg);
      case final NewTx msg:
        _onNewTx(msg);
      case final Content msg:
        _complete(_contentWaiter, msg.items);
        _contentWaiter = null;
      case final State msg:
        _complete(_stateWaiter, msg);
        _stateWaiter = null;
      case final Filters msg:
        _complete(_filtersWaiter, msg);
        _filtersWaiter = null;
      case final Tx msg:
        _complete(_txWaiter, msg);
        _txWaiter = null;
      case final Fees msg:
        _complete(_feesWaiter, msg);
        _feesWaiter = null;
      case final HeaderProof msg:
        _complete(_headerProofWaiter, msg);
        _headerProofWaiter = null;
      case final TxStatus msg:
        _statuses[toHex(msg.txid)] = msg;
        notifyListeners();
      // The node never asks a peer with zero work and no blocks for anything,
      // and unsolicited light-client replies are ignored (Section 7.6).
      case GetHeaders() ||
            GetBlocks() ||
            GetContent() ||
            GetAddr() ||
            Addr() ||
            Ping() ||
            GetFees() ||
            GetTx() ||
            SubmitTx() ||
            GetState() ||
            GetFilters() ||
            GetHeaderProof():
        break;
      // Compact block relay is between nodes (Section 7.9): every node sends
      // SendCompact after its Hello, and the client never asks for compact
      // blocks, so it keeps receiving NewBlock. Ignored.
      case SendCompact() || CompactBlock() || GetBlockTxs() || BlockTxs():
        break;
    }
  }

  // ---- requests -----------------------------------------------------------------

  Future<T> _request<T>(Completer<T> waiter, Message msg) {
    _send(msg);
    return waiter.future.timeout(_requestTimeout);
  }

  Future<List<BlockHeader>> _getHeaders(List<Uint8List> locator) =>
      _request(_headersWaiter = Completer(), GetHeaders(locator));

  Future<List<BlockRecord>> _getBlocks(List<Uint8List> hashes) =>
      _request(_blocksWaiter = Completer(), GetBlocks(hashes));

  Future<List<MessageContent>> _getContent(List<Uint8List> hashes) =>
      _request(_contentWaiter = Completer(), GetContent(hashes));

  // ---- the worker -----------------------------------------------------------------

  /// Set by `_wake`, so a request made while the worker is busy (not
  /// waiting) isn't lost.
  bool _poked = false;

  void _wake() {
    _poked = true;
    final w = _wakeup;
    _wakeup = null;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// One request at a time, most useful first, until there's nothing left;
  /// then waits for a view, the node or the user to want something.
  Future<void> _work(int gen) async {
    try {
      while (gen == _generation) {
        _poked = false;
        final didSomething = await _step(gen);
        if (gen != _generation) return;
        await _flushCache();
        if (didSomething) {
          notifyListeners();
          continue;
        }
        if (_poked) continue;
        final wakeup = _wakeup = Completer<void>();
        await wakeup.future;
      }
    } on _Aborted {
      // Disconnected; what was fetched is kept.
    } catch (e) {
      _fail(gen, LinkError(LinkErrorKind.syncFailed, cause: _describe(e)));
    }
  }

  Future<bool> _step(int gen) async {
    if (_needHeaders) {
      await _syncHeaders(gen);
      return true;
    }
    // What's on screen: proven balances and flags first.
    if (await _proveWatched(gen)) return true;
    // Then the text of what's already fetched, before fetching more: each
    // batch of blocks is followed by its messages, so lists fill in while
    // older blocks keep arriving (however many a filter or the local copy
    // still wants).
    if (await _fetchContent(gen)) return true;
    final wanted = _wantedHeights
        .where((h) => h >= _low && h <= height && _blocks[h - 1] == null)
        .take(maxBatchBlocks)
        .toList();
    _wantedHeights.removeAll(wanted);
    if (wanted.isNotEmpty) {
      await _fetchBlocks(wanted, gen);
      return true;
    }
    _settleOwnPending();
    if (await _fetchTxs(gen)) return true;
    // The newest stretch, as far back as the open view needs.
    final older = _olderBatch();
    if (height > 0 && (_top > height || _wantOlder) && older.isNotEmpty) {
      _wantOlder = false;
      await _fetchBlocks(older, gen);
      return true;
    }
    _wantOlder = false;
    // Started from a checkpoint: check the headers back to genesis.
    if (await _backfillHeaders(gen)) return true;
    // Histories and threads being followed: filters, then matching blocks.
    if (await _scanFilters(gen)) return true;
    if (_prefetch > 0 && _olderBatch().isNotEmpty) {
      _prefetch--;
      await _fetchBlocks(_olderBatch(), gen);
      return true;
    }
    // With a local copy, the rest of the chain, oldest first, counted as it
    // arrives: done once, then kept.
    if (countsChain && !complete && _low == 1) {
      final batch = [
        for (var h = _counted + 1; h < _top && h <= _counted + maxBatchBlocks; h++)
          if (_blocks[h - 1] == null) h,
      ];
      if (batch.isEmpty) {
        _advance();
      } else {
        await _fetchBlocks(batch, gen);
      }
      return true;
    }
    return false;
  }

  /// The next batch below the newest stretch, newest first (not below the
  /// known headers).
  List<int> _olderBatch() => [
        for (var h = _top - 1; h > _counted && h >= _low && h > _top - 1 - maxBatchBlocks; h--)
          if (_blocks[h - 1] == null) h,
      ];

  /// Our tip back to genesis, dense near the tip then exponentially sparser,
  /// like `ChainState::locator`: the node answers from the first entry on
  /// its best chain, which is where a reorg (if any) forked. Only known
  /// headers, then genesis.
  List<Uint8List> _locator() {
    final out = <Uint8List>[];
    var h = height;
    var step = 1;
    while (h >= _low && h > 0) {
      out.add(hashAt(h));
      if (out.length >= 10) step *= 2;
      h -= step;
    }
    out.add(genesis!);
    if (out.length > maxLocator) {
      return [...out.sublist(0, maxLocator - 1), out.last];
    }
    return out;
  }

  Future<void> _syncHeaders(int gen) async {
    _needHeaders = false;
    _headersSyncing = true;
    state = LinkState.syncing;
    notifyListeners();
    try {
      // A first session with a checkpoint starts there, not at genesis.
      final start = _checkpoint;
      if (height == 0 && start != null) await _startFromCheckpoint(start, gen);
      while (true) {
        final headers = await _getHeaders(_locator());
        if (gen != _generation) throw _Aborted();
        if (headers.isEmpty) break;
        _attachHeaders(headers);
        peerHeight = max(peerHeight, height);
        notifyListeners();
        if (headers.length < maxHeaders) break;
      }
    } finally {
      if (gen == _generation) _headersSyncing = false;
    }
    peerHeight = max(peerHeight, height);
    _prunePending();
    state = LinkState.live;
    _retries = 0; // the next loss starts again from a short wait
  }

  void _appendHeader(BlockHeader h) {
    _headers.add(h);
    _blocks.add(null);
    _history.pushHeader(h);
    _markHistory(height, _history);
  }

  /// Checks `h`, the header after `parent`, as a node does (PROTOCOL.md
  /// Section 7.2): it links to its parent, meets its target, is later than
  /// the median of the last 11 timestamps, carries the retarget's target,
  /// and commits to the header history through its parent (`history`).
  /// `at` looks up the earlier headers (genesis included).
  void _checkHeader(BlockHeader h, BlockHeader? Function(int height) at, HistoryPeaks history) {
    checkHeaderRules(h, at, history, network!);
    _headersFromNode++;
    // Reaching the checkpoint's height (from a local copy that stopped
    // short of it), the chain must hold the checkpoint.
    final cp = _checkpoint;
    if (cp != null && h.height == cp.height && h.id != cp.hash) {
      throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
    }
  }

  /// Checks a batch of headers, rolls the chain back to where they attach if
  /// that's below our tip, and appends them. Headers we already have (a
  /// relayed block may have arrived meanwhile) are skipped.
  void _attachHeaders(List<BlockHeader> headers) {
    var i = 0;
    while (i < headers.length) {
      final at = headers[i].height;
      final known = at >= 1 && at <= height ? _headers[at - 1] : null;
      if (known == null || !bytesEqual(known.hash, headers[i].hash)) break;
      i++;
    }
    if (i == headers.length) return;
    final first = headers[i];
    final fork = first.height - 1;
    // Below the known headers (a chain that doesn't contain the checkpoint)
    // nothing can attach.
    if (fork > 0 && fork < _low) throw LinkError(LinkErrorKind.checkpointMismatch, height: _startedFrom?.height ?? 0);
    // Nor can a branch that replaces the checkpoint's block.
    final cp = _checkpoint;
    if (cp != null && fork < cp.height && height >= cp.height) {
      throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
    }
    if (fork < 0 || fork > height || !bytesEqual(hashAt(fork), first.prevHash)) {
      throw const FormatException('the node sent headers that do not connect to our chain');
    }
    for (var j = i + 1; j < headers.length; j++) {
      if (headers[j].height != headers[j - 1].height + 1) {
        throw const FormatException('the node sent headers that are not a chain');
      }
    }
    if (fork < height) _truncate(fork);
    for (var j = i; j < headers.length; j++) {
      _checkHeader(headers[j], headerOrGenesis, _history);
      _appendHeader(headers[j]);
    }
    // The new tip isn't fetched yet, so the newest stretch starts over.
    _top = height + 1;
    _headersChangedFrom = min(_headersChangedFrom ?? fork + 1, fork + 1);
  }

  /// A known header by height, genesis included.
  BlockHeader? headerOrGenesis(int h) => h == 0 ? _genesisHeader : headerAt(h);

  /// Starts from a checkpoint (PROTOCOL.md Section 7.7): its block, checked
  /// against the checkpoint's hash; the headers before it that the difficulty
  /// and median-time-past checks need, checked by their links back from it;
  /// and the header history through it, checked against its `history_root`.
  /// The headers back to genesis are checked later, in the background.
  Future<void> _startFromCheckpoint(Checkpoint cp, int gen) async {
    final hash = fromHex(cp.hash);
    final block = (await _getBlocks([hash])).firstOrNull?.block;
    if (gen != _generation) throw _Aborted();
    final header = block?.header;
    if (header == null || !bytesEqual(header.hash, hash) || header.height != cp.height || !header.meetsTarget) {
      throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
    }
    final from = max(1, cp.height - network!.lwmaWindow);
    final context = <int, BlockHeader>{};
    List<HistoryNode>? peaks;
    final heights = [for (var h = from; h < cp.height; h++) h];
    for (var i = 0; i < heights.length || peaks == null; i += maxHeaderProofs) {
      final batch = heights.skip(i).take(maxHeaderProofs).toList();
      final reply = await _request(_headerProofWaiter = Completer<HeaderProof>(), GetHeaderProof(hash, batch));
      if (gen != _generation) throw _Aborted();
      if (!reply.available || !bytesEqual(reply.at, hash)) {
        throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
      }
      peaks = reply.peaks;
      for (final (h, _) in reply.entries) {
        context[h.height] = h;
      }
      if (batch.isEmpty) break;
    }
    // The context links back from the checkpoint, hash by hash.
    var expected = header.prevHash;
    for (var h = cp.height - 1; h >= from; h--) {
      final c = context[h];
      if (c == null || !bytesEqual(c.hash, expected)) {
        throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
      }
      expected = c.prevHash;
    }
    if (from == 1 && !bytesEqual(expected, genesis!)) {
      throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
    }
    // The history through the checkpoint's parent is what it commits to.
    final history = HistoryPeaks.fromPeaks(peaks, cp.height);
    if (history == null || !bytesEqual(history.root, header.historyRoot)) {
      throw LinkError(LinkErrorKind.checkpointMismatch, height: cp.height);
    }
    _headers
      ..clear()
      ..addAll([for (var h = 1; h < cp.height; h++) context[h]])
      ..add(header);
    _historyMarks.clear();
    _blocks
      ..clear()
      ..addAll(List<Block?>.filled(cp.height, null));
    _low = from;
    _history = history..pushHeader(header);
    _checkpointHistory = _history.copy();
    _startedFrom = cp;
    _top = height + 1;
    _counted = 0;
    _storeBlock(block!, const []);
    _advance();
  }

  /// Checks the headers from genesis up to the checkpoint's context, one
  /// batch per call: each fully (links, proof of work, median-time-past,
  /// retarget, history root), and the last must lead to the known headers,
  /// and so to the checkpoint. If it doesn't, the release's checkpoint or
  /// every node reached is wrong: the client stops and says so.
  Future<bool> _backfillHeaders(int gen) async {
    if (_low <= 1) return false;
    // A previous session's unfinished back-fill, from the local copy: resume
    // after it (up to the checkpoint's context, where it joins).
    final resume = _resumeBackfill;
    if (resume != null && _backfill.isEmpty) {
      _resumeBackfill = null;
      resume.truncate(_low - 1);
      _backfill.takeFrom(resume);
      _backfillHistory = HistoryPeaks()..pushHeader(_genesisHeader!);
      _backfill.snapshot().forEach(_backfillHistory!.pushHeader);
      _backfillSaved = _backfill.length;
      _backfillFromCache = true;
    }
    final history = _backfillHistory ??= HistoryPeaks()..pushHeader(_genesisHeader!);
    final locator = [_backfill.isEmpty ? genesis! : _backfill.hashAt(_backfill.length - 1)!];
    final headers = await _getHeaders(locator);
    if (gen != _generation) throw _Aborted();
    // Headers from the local copy the node doesn't continue: not the chain
    // anymore. Start over from genesis rather than blame the checkpoint.
    if (_backfillFromCache && headers.isNotEmpty && headers.first.height != _backfill.length + 1 && headers.first.height < _low) {
      _restartBackfill();
      return true;
    }
    BlockHeader? at(int h) => h == 0 ? _genesisHeader : (h <= _backfill.length ? _backfill[h - 1] : null);
    for (final h in headers) {
      if (h.height >= _low) break;
      if (h.height != _backfill.length + 1) throw const FormatException('the node sent headers that are not a chain');
      _checkHeader(h, at, history);
      _backfill.add(h);
      history.pushHeader(h);
    }
    if (_backfill.length < _low - 1) {
      if (headers.isEmpty) throw LinkError(LinkErrorKind.checkpointMismatch, height: _startedFrom?.height ?? 0);
      return true;
    }
    // Joined: the first known header must follow, and commit to this history.
    final joint = _hdr(_low);
    if (!_backfill.hashIs(_backfill.length - 1, joint.prevHash) || !bytesEqual(joint.historyRoot, history.root)) {
      if (_backfillFromCache) {
        _restartBackfill();
        return true;
      }
      throw LinkError(LinkErrorKind.checkpointMismatch, height: _startedFrom?.height ?? 0);
    }
    _headers.copyStart(_backfill, _low - 1);
    _low = 1;
    _backfill.clear();
    _backfillHistory = null;
    _backfillFromCache = false;
    _backfillSaved = 0;
    _checkpointHistory = null;
    _headersChangedFrom = 1; // now the whole chain can be kept
    _wantedTxids.addAll(_deferredTxids);
    _deferredTxids.clear();
    _advance();
    return true;
  }

  /// Drops a back-fill begun from the local copy (it didn't lead to the
  /// checkpoint) and starts it again from genesis, checking every header.
  void _restartBackfill() {
    _backfill.clear();
    _backfillHistory = null;
    _backfillFromCache = false;
    _backfillSaved = 0;
  }

  /// Fetches the blocks at `heights` (≤ 128). A reply may stop early at the
  /// node's 8 MiB cap; the rest is asked for again.
  Future<void> _fetchBlocks(List<int> heights, int gen) async {
    var rest = heights;
    while (rest.isNotEmpty) {
      final records = await _getBlocks([for (final h in rest) hashAt(h)]);
      if (gen != _generation) throw _Aborted();
      if (records.isEmpty) {
        throw const FormatException('the node did not serve blocks from its own headers');
      }
      for (var i = 0; i < records.length; i++) {
        if (i >= rest.length || !bytesEqual(records[i].block.header.hash, hashAt(rest[i]))) {
          throw const FormatException('the node sent a block that was not requested');
        }
        _storeBlock(records[i].block, records[i].contents);
      }
      rest = rest.sublist(records.length);
    }
    _advance();
  }

  /// Keeps a block whose header is on our chain, after checking its merkle
  /// root and filter against the header, with whatever content came with it
  /// or with its transactions.
  void _storeBlock(Block b, List<MessageContent> contents, {bool save = true}) {
    final h = b.header.height;
    if (h < 1 || h > height || !_headers.hashIs(h - 1, b.header.hash)) {
      throw FormatException('block $h is not on our chain');
    }
    if (_blocks[h - 1] != null) return;
    if (!bytesEqual(merkleRoot([for (final t in b.transactions) t.hash]), b.header.merkleRoot)) {
      throw FormatException('block $h transactions do not match its merkle root');
    }
    if (!bytesEqual(sha256Bytes(blockFilter(b)), b.header.filterHash)) {
      throw FormatException('block $h does not match its filter');
    }
    _blocks[h - 1] = b;
    _fetched++;
    if (save) _unsavedBlocks.add(b);
    final byHash = {for (final c in contents) toHex(c.hash): c.content};
    for (var i = 0; i < b.transactions.length; i++) {
      final tx = b.transactions[i];
      _txIndex[tx.id] = (h, i);
      if (tx.kind == TxKind.flag && tx.referenceId != null) {
        _flagKeys.add('${tx.fromAddress}:${tx.referenceId}');
        // A flag from the author of the message it names: a retraction.
        final target = lookupTx(tx.referenceId!)?.tx;
        if (target != null && target.fromAddress == tx.fromAddress) _withdraw(target);
      }
      final pending = _pending.remove(tx.id);
      if (tx.messageHash == null) continue;
      final key = toHex(tx.messageHash!);
      _contentOwner[key] = (tx.id, h);
      // The author's flag may have come in an earlier fetched block.
      if ((tx.kind == TxKind.orphan || tx.kind == TxKind.reply) && _flagKeys.contains('${tx.fromAddress}:${tx.id}')) {
        _withdraw(tx);
        continue;
      }
      if (_contents.containsKey(key)) continue;
      final content = byHash[key] ?? pending?.content;
      if (content != null && tx.isContent(content)) {
        _contents[key] = content;
        if (save) _unsavedContents[key] = content;
      } else {
        _wantContent(tx, h);
      }
    }
  }

  /// Notes that `tx` (at height `h`) has content to fetch.
  void _wantContent(Transaction tx, int h) {
    final hash = tx.messageHash;
    if (hash == null || tx.contentSize == 0) return;
    final key = toHex(hash);
    if (!_contents.containsKey(key) && !_contentUnavailable.contains(key) && !_withdrawnContent.contains(key)) {
      _missingContent[key] = (h, tx);
    }
  }

  /// Whether content `key` belongs in the local copy: its block is within
  /// [contentRetention], or its message or thread is starred. Content whose
  /// message isn't known yet stays until a later sweep can tell.
  bool _keepOnDisk(String key) {
    final owner = _contentOwner[key];
    if (owner == null) return true;
    final (txid, h) = owner;
    if (_starred.contains(txid)) return true;
    final time = headerAt(h)?.timestamp;
    if (time != null) {
      final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - time;
      if (age < contentRetention.inSeconds) return true;
    }
    final view = lookupTx(txid);
    final root = view == null ? null : threadRootOf(view);
    return root != null && _starred.contains(root.tx.id);
  }

  /// The user's starred messages and threads (txids; a thread root stars the
  /// whole thread). Newly starred content held now goes into the local copy
  /// at the next flush, whatever its age; content that's no longer starred
  /// leaves it at a later sweep if it's old.
  void setStarred(Set<String> starred) {
    final added = starred.difference(_starred);
    _starred = Set.of(starred);
    for (final txid in added) {
      final view = lookupTx(txid);
      if (view == null) continue;
      final stack = [view];
      final seen = <String>{};
      while (stack.isNotEmpty) {
        final v = stack.removeLast();
        if (!seen.add(v.tx.id)) continue;
        final hash = v.tx.messageHash;
        final key = hash == null ? null : toHex(hash);
        final content = key == null ? null : _contents[key];
        if (key != null && content != null && !_onDisk.contains(key)) _unsavedContents[key] = content;
        stack.addAll(repliesOf(v));
      }
    }
  }

  /// A message withdrawn by its author (their own flag is on the chain):
  /// deletes its content here, in memory and in the local copy, and never
  /// asks for it again. Only Orphans and Replies carry content to withdraw.
  void _withdraw(Transaction message) {
    final hash = message.messageHash;
    if (hash == null || (message.kind != TxKind.orphan && message.kind != TxKind.reply)) return;
    final key = toHex(hash);
    if (!_withdrawnContent.add(key)) return;
    _contents.remove(key);
    _unsavedContents.remove(key);
    _missingContent.remove(key);
    _unsavedRemovals.add(key);
  }

  /// Grows the newest stretch down over blocks already fetched, and counts
  /// every block that now follows the counted ones.
  void _advance() {
    while (_top > 1 && _blocks[_top - 2] != null) {
      _top--;
    }
    final wasComplete = complete;
    while (_counted < height && _blocks[_counted] != null) {
      _applyBlock(_blocks[_counted]!);
      _counted++;
    }
    if (!wasComplete && complete && height > 0 && _stateCheckedAt != height) _checkStateRoot();
  }

  /// Once the whole chain is counted, the state tree this client computes
  /// must have the root the tip's header commits to. If not, the node served
  /// a chain whose state it lied about (or this client has a bug): either
  /// way, nothing it says can be trusted.
  void _checkStateRoot() {
    _stateCheckedAt = height;
    final entries = <String, Uint8List>{};
    final addresses = {..._balances.keys, ..._nonces.keys};
    for (final address in addresses) {
      final balance = _balances[address] ?? 0, nonce = _nonces[address] ?? 0;
      if (balance == 0 && nonce == 0) continue;
      entries[toHex(accountKey(fromHex(address)))] = Uint8List.fromList([...u64le(balance), ...u64le(nonce)]);
    }
    for (final flag in _countedFlagEntries) {
      entries[flag] = Uint8List.fromList([1]);
    }
    if (_burnPool > 0) entries[toHex(poolKey)] = u64le(_burnPool);
    if (_issued > 0) entries[toHex(issuedKey)] = u64le(_issued);
    if (!bytesEqual(stateRootOf(entries), _headers.stateRootAt(height - 1)!)) {
      error = LinkError(LinkErrorKind.stateMismatch, height: height);
    }
  }

  /// Balance effects (PROTOCOL.md Section 5): the sender's nonce goes up and
  /// it pays `fee + amount`; the recipient gets `amount`, or it's burned into
  /// the pool (Orphan). The miner gets subsidy + ceil(pool before / K) + fees,
  /// and only then do this block's burns enter the pool.
  void _applyBlock(Block b) {
    void credit(String addr, int delta) => _balances[addr] = (_balances[addr] ?? 0) + delta;
    var burned = 0;
    for (var i = 0; i < b.transactions.length; i++) {
      final tx = b.transactions[i];
      _nonces[tx.fromAddress] = (_nonces[tx.fromAddress] ?? 0) + 1;
      credit(tx.fromAddress, -(tx.fee + tx.amount));
      if (tx.toAddress != null) credit(tx.toAddress!, tx.amount);
      if (tx.kind == TxKind.flag && tx.reference != null) {
        _countedFlagEntries.add(toHex(flagEntryKey(flagKeyOf(tx.from, tx.reference!))));
      }

      // Indexed after the balance changes, so each entry holds the balance
      // right after the transaction.
      void index(String? address) {
        if (address == null) return;
        _byAddress.putIfAbsent(address, () => []).add((b.header.height, i, _balances[address] ?? 0));
      }

      index(tx.fromAddress);
      if (tx.toAddress != tx.fromAddress) index(tx.toAddress);
      if (tx.kind == TxKind.flag && tx.referenceId != null) {
        // A flag also concerns the author of the message it reports.
        final author = authorOf(tx.referenceId!);
        if (author != tx.fromAddress) index(author);
      }
      burned += tx.burned;
    }
    final payout = network!.burnPayout(_burnPool);
    _payouts.add(payout);
    _burnPool = _burnPool - payout + burned;
    final subsidy = network!.subsidyAt(b.header.height);
    _issued += subsidy;
    final miner = toHex(b.header.miner);
    credit(miner, subsidy + payout + b.totalFees);
    _blocksMined[miner] = (_blocksMined[miner] ?? 0) + 1;
  }

  void _resetCounted() {
    _counted = 0;
    _byAddress.clear();
    _balances.clear();
    _nonces.clear();
    _blocksMined.clear();
    _countedFlagEntries.clear();
    _payouts.clear();
    _burnPool = 0;
    _issued = 0;
    _stateCheckedAt = null;
  }

  /// Drops everything above height `h` (a reorganization).
  void _truncate(int h) {
    // What this device sent in the dropped blocks is pending again: the node
    // puts it back in its mempool, and the heavier branch may mine it.
    void unmine(Transaction tx) {
      if (_sentHere.contains(tx.id)) {
        _pending.putIfAbsent(tx.id, () => PendingTx(tx, _contentOf(tx), mine: true, sentAtHeight: h));
      }
    }

    for (var i = h; i < _blocks.length; i++) {
      final b = _blocks[i];
      if (b == null) continue;
      _fetched--;
      b.transactions.forEach(unmine);
    }
    for (final loose in _loose.values) {
      if (loose.height > h) unmine(loose.tx);
    }
    _settling.clear();
    _headers.truncate(h);
    _blocks.removeRange(h, _blocks.length);
    // The history through the new tip: from the nearest mark below it, from
    // genesis, or (before the headers below the checkpoint are in) from the
    // checkpoint's.
    _historyMarks.removeWhere((at, _) => at > h);
    final mark = _historyMarks.keys.fold(0, max);
    final base = _checkpointHistory;
    if (mark > 0) {
      _history = _historyMarks[mark]!.copy();
      for (var at = mark + 1; at <= h; at++) {
        _history.pushHeader(_hdr(at));
      }
    } else if (_low > 1 && base != null) {
      _history = base.copy();
      for (var at = _startedFrom!.height + 1; at <= h; at++) {
        _history.pushHeader(_hdr(at));
      }
    } else {
      _history = HistoryPeaks()..pushHeader(_genesisHeader!);
      for (var at = 1; at <= h; at++) {
        _history.pushHeader(_hdr(at));
      }
    }
    _top = min(_top, h + 1);
    _wantedHeights.removeWhere((w) => w > h);
    _filters.removeWhere((at, _) => at > h);
    _filterTested.removeWhere((at, _) => at > h);
    _filterMatches.clear();
    _loose.removeWhere((_, t) => t.height > h);
    _missingContent.removeWhere((_, e) => e.$1 > h);
    _proven.clear();
    _stateAsked.clear();
    _reorgs++;
    _txIndex.clear();
    _flagKeys.clear();
    for (var at = 1; at <= h; at++) {
      final b = _blocks[at - 1];
      if (b == null) continue;
      for (var i = 0; i < b.transactions.length; i++) {
        final tx = b.transactions[i];
        _txIndex[tx.id] = (at, i);
        if (tx.kind == TxKind.flag && tx.referenceId != null) _flagKeys.add('${tx.fromAddress}:${tx.referenceId}');
      }
    }
    if (_counted > h) {
      // The payout rounds up, so the pool can't be unwound: count again.
      _resetCounted();
      _advance();
    }
    _unsavedBlocks.removeWhere((b) => b.header.height > h);
    final cache = _cache;
    if (cache != null) unawaited(cache.dropBlocksAbove(h).catchError((Object _) {}));
  }

  void _resetChain() {
    _headers.clear();
    _history = HistoryPeaks();
    _historyMarks.clear();
    _genesisHeader = null;
    _low = 1;
    _startedFrom = null;
    _checkpointHistory = null;
    _backfill.clear();
    _backfillHistory = null;
    _resumeBackfill = null;
    _backfillFromCache = false;
    _backfillSaved = 0;
    _blocks.clear();
    _fetched = 0;
    _top = 1;
    _contents.clear();
    _contentUnavailable.clear();
    _missingContent.clear();
    _withdrawnContent.clear();
    _unsavedRemovals.clear();
    _contentOwner.clear();
    _onDisk.clear();
    _lastSweep = null;
    _txIndex.clear();
    _loose.clear();
    _flagKeys.clear();
    _filters.clear();
    _filterTested.clear();
    _filterMatches.clear();
    _proven.clear();
    _stateAsked.clear();
    _statuses.clear();
    _sentHere.clear();
    _settling.clear();
    _txUnknown.clear();
    _deferredTxids.clear();
    _resetCounted();
    _pending.clear();
    _wantedHeights.clear();
    _unsavedBlocks.clear();
    _unsavedContents.clear();
    _headersChangedFrom = null;
    _reorgs++;
    peerHeight = 0;
  }

  void _prunePending() {
    final cutoff = DateTime.now().subtract(_gossipPendingTtl);
    _pending.removeWhere((_, p) => !p.mine && p.seenAt.isBefore(cutoff));
  }

  // ---- proofs, filters and lookups ------------------------------------------------

  /// Proves the watched state keys at the tip, if they aren't already.
  Future<bool> _proveWatched(int gen) async {
    if (height == 0) return false;
    final stale = [
      for (final MapEntry(key: hex, value: key) in _watchedKeys.entries)
        if ((_stateAsked[hex] ?? -1) < height) key,
    ].take(maxStateKeys).toList();
    if (stale.isEmpty) return false;
    final at = height;
    for (final key in stale) {
      _stateAsked[toHex(key)] = at; // asked once per tip, whatever the answer
    }
    final reply = await _request(_stateWaiter = Completer<State>(), GetState(hashAt(at), stale));
    if (gen != _generation) throw _Aborted();
    // The tip may have moved on (or been reorganized) meanwhile.
    if (!reply.available || at > height || !bytesEqual(hashAt(at), reply.block)) return true;
    final h = at;
    final root = _headers.stateRootAt(h - 1)!;
    for (final (key, proof) in reply.proofs) {
      final hex = toHex(key);
      if (!_watchedKeys.containsKey(hex)) continue;
      final fact = verifyStateProof(root, key, proof);
      if (fact == null) throw FormatException('the node sent a state proof that does not match block $h');
      _proven[hex] = _Proven(fact.value, h);
    }
    return true;
  }

  /// Downloads (and checks) filters for blocks not fetched yet, where a
  /// watched item may be, then queues the blocks whose filter matches one.
  Future<bool> _scanFilters(int gen) async {
    if (_watchedItems.isEmpty || height == 0) return false;
    // Filters are checked against headers: only where those are known.
    final from = max(_low, min(height, _watchedItems.values.map((w) => w.$2).reduce(min)));
    // Test what's known against the watched items.
    var queued = false;
    for (var h = height; h >= from; h--) {
      if (_blocks[h - 1] != null || _filters[h] == null || _filterTested[h] == _watchVersion) continue;
      _filterTested[h] = _watchVersion;
      final items = [
        for (final (item, start) in _watchedItems.values)
          if (start <= h) item,
      ];
      if (items.isNotEmpty && (filterMatchesAny(_filters[h]!, _headers.prevHashAt(h - 1)!, items) ?? true)) {
        queued |= _wantedHeights.add(h);
      }
    }
    if (queued) return true;
    // The highest stretch without filters, newest first.
    var top = height;
    while (top >= from && (_blocks[top - 1] != null || _filters.containsKey(top))) {
      top--;
    }
    if (top < from) return false;
    final start = max(from, top - maxFilters + 1);
    final reply = await _request(_filtersWaiter = Completer<Filters>(), GetFilters(start, top - start + 1));
    if (gen != _generation) throw _Aborted();
    if (reply.start != start || reply.filters.isEmpty) {
      throw const FormatException('the node sent filters that were not requested');
    }
    for (var i = 0; i < reply.filters.length; i++) {
      final h = start + i;
      if (h > height) break;
      if (!bytesEqual(sha256Bytes(reply.filters[i]), _headers.filterHashAt(h - 1)!)) {
        throw FormatException('the filter of block $h does not match its header');
      }
      _filters[h] = reply.filters[i];
    }
    return true;
  }

  /// An own pending transaction whose nonce the proven state has passed was
  /// mined (in a block not fetched), or replaced by another with the same
  /// nonce. Either way it's no longer pending: ask for it by id, so it shows
  /// as mined, or drops out.
  void _settleOwnPending() {
    for (final p in _pending.values) {
      if (!p.mine || _settling.contains(p.tx.id)) continue;
      final proven = _proven[toHex(accountKey(p.tx.from))];
      if (proven == null) continue;
      final nonce = proven.value == null ? 0 : readU64le(proven.value!, 8);
      if (nonce > p.tx.nonce) {
        _settling.add(p.tx.id);
        _wantedTxids.add(p.tx.id);
      }
    }
  }

  /// Fetches wanted transactions by id, checking each confirmed one's merkle
  /// branch against its header.
  Future<bool> _fetchTxs(int gen) async {
    final ids = _wantedTxids.take(maxTxRequest).toList();
    if (ids.isEmpty) return false;
    _wantedTxids.removeAll(ids);
    _txAsking = ids.toSet();
    final Tx reply;
    try {
      reply = await _request(_txWaiter = Completer<Tx>(), GetTx([for (final id in ids) fromHex(id)]));
    } finally {
      _txAsking = const {};
    }
    if (gen != _generation) throw _Aborted();
    final answered = <String>{};
    for (final (txid, lookup) in reply.entries) {
      final id = toHex(txid);
      if (!ids.contains(id)) continue;
      answered.add(id);
      switch (lookup) {
        case TxUnknown():
          _txUnknown.add(id);
          // Own and settling: replaced by another with its nonce, so it can
          // never be mined.
          if (_settling.contains(id)) _pending.remove(id);
        case TxPendingEntry(:final tx):
          if (tx.id != id) throw const FormatException('the node sent another transaction than asked for');
          _pending.putIfAbsent(id, () => PendingTx(tx, null, mine: false));
        case TxOnChain(:final tx, :final blockHash, height: final h, :final index, :final branch):
          final header = headerAt(h);
          // In a block below the headers checked so far (started from a
          // checkpoint): proven once they're in.
          if (header == null && h >= 1 && h < _low) {
            _deferredTxids.add(id);
            continue;
          }
          if (tx.id != id ||
              header == null ||
              !bytesEqual(header.hash, blockHash) ||
              !bytesEqual(merkleRootFromBranch(txid, index, branch), header.merkleRoot)) {
            throw FormatException('the node sent a transaction not proven in block $h');
          }
          _loose[id] = _LooseTx(tx, h);
          _pending.remove(id);
          _wantContent(tx, h);
      }
    }
    // What the reply left out (it may stop early) is asked for again.
    _wantedTxids.addAll(ids.where((id) => !answered.contains(id)));
    return true;
  }

  // ---- gossip -------------------------------------------------------------------

  void _onNewBlock(NewBlock m) {
    final h = m.block.header;
    peerHeight = max(peerHeight, h.height);
    try {
      if (h.height >= _low && h.height <= height && bytesEqual(hashAt(h.height), h.hash)) {
        // A header we have: keep the block if we lacked it.
        _storeBlock(m.block, const []);
        _advance();
      } else if (!_headersSyncing && height > 0 && h.height == height + 1 && bytesEqual(h.prevHash, hashAt(height))) {
        // Checked like any header: link, work, time, retarget, history.
        _checkHeader(h, headerOrGenesis, _history);
        // The newest stretch ends at the old tip (or is empty, starting at the
        // new height), so it simply grows by this block.
        _appendHeader(h);
        _headersChangedFrom = min(_headersChangedFrom ?? h.height, h.height);
        _storeBlock(m.block, const []);
        _advance();
      } else {
        // A block we can't attach means the node's chain moved (a reorg, or
        // blocks we missed): fetch the headers properly.
        _needHeaders = true;
      }
    } on FormatException catch (e) {
      error = LinkError(LinkErrorKind.ignoredBlock, detail: e.message);
    } on LinkError catch (e) {
      _fail(_generation, e);
      return;
    }
    _wake();
    notifyListeners();
  }

  void _onNewTx(NewTx m) {
    final id = m.tx.id;
    if (_txIndex.containsKey(id) || _pending.containsKey(id)) return;
    var content = m.content;
    if (content != null && !m.tx.isContent(content)) content = null;
    if (_pending.length >= _maxGossipPending) {
      final oldest = _pending.entries
          .where((e) => !e.value.mine)
          .fold<MapEntry<String, PendingTx>?>(
              null, (a, e) => a == null || e.value.seenAt.isBefore(a.value.seenAt) ? e : a);
      if (oldest == null) return;
      _pending.remove(oldest.key);
    }
    _pending[id] = PendingTx(m.tx, content, mine: false);
    notifyListeners();
  }

  // ---- content ------------------------------------------------------------------

  /// Asks the node for up to 256 missing contents, newest first, of every
  /// transaction known on the chain (fetched blocks and GetTx). Returns
  /// whether it asked. The node serves what it has (possibly nothing: it may
  /// have deleted it); what it didn't send isn't asked for again.
  Future<bool> _fetchContent(int gen) async {
    _missingContent.removeWhere((key, _) =>
        _contents.containsKey(key) || _contentUnavailable.contains(key) || _withdrawnContent.contains(key));
    if (_missingContent.isEmpty) return false;
    final newestFirst = _missingContent.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));
    final wanted = {for (final e in newestFirst.take(maxContentRequest)) e.key: e.value.$2};
    final items = await _getContent([for (final k in wanted.keys) fromHex(k)]);
    if (gen != _generation) throw _Aborted();
    for (final item in items) {
      final key = toHex(item.hash);
      final tx = wanted[key];
      // Only what we asked for, and only valid content (hash and length).
      if (tx == null ||
          !tx.isContent(item.content) ||
          _contents.containsKey(key) ||
          _withdrawnContent.contains(key)) {
        continue;
      }
      _contents[key] = item.content;
      _unsavedContents[key] = item.content;
    }
    // 256 contents are at most 266 KB, well under the reply's 8 MiB cap, so
    // what's missing from the reply is what the node doesn't serve.
    for (final key in wanted.keys) {
      if (!_contents.containsKey(key)) _contentUnavailable.add(key);
      _missingContent.remove(key);
    }
    return true;
  }

  // ---- fees -----------------------------------------------------------------------

  /// What a transaction currently costs: the node's own fee bars (GetFees),
  /// which it answers at most every 10 s, or this client's estimate if it
  /// doesn't answer.
  Future<FeeInfo> feeInfo() {
    final last = _lastFees;
    if (last != null && DateTime.now().difference(last.$1) < const Duration(seconds: 10)) return Future.value(last.$2);
    // One question at a time: a second one would replace the first's waiter.
    return _feesAsked ??= _askFees().whenComplete(() => _feesAsked = null);
  }

  Future<FeeInfo>? _feesAsked;

  Future<FeeInfo> _askFees() async {
    if (state == LinkState.live) {
      try {
        final fees = await _request(_feesWaiter = Completer<Fees>(), const GetFees())
            .timeout(const Duration(seconds: 3));
        final info = feeInfoFromNode(fees);
        _lastFees = (DateTime.now(), info);
        return info;
      } catch (_) {
        // No answer: estimate locally.
      }
    }
    return localFeeEstimate();
  }

  /// The node's fee rules over this client's own view: pending transactions
  /// relayed since it connected (not the node's whole mempool) and the
  /// lowest fee of each of the last `feeWindow` blocks it has.
  FeeInfo localFeeEstimate() {
    final recentMins = <int>[];
    for (var h = height; h >= 1 && h > height - feeWindow; h--) {
      final txs = _blocks[h - 1]?.transactions;
      if (txs != null && txs.isNotEmpty) recentMins.add(txs.map((t) => t.fee).reduce(min));
    }
    return estimateFees(
      pending: [for (final p in _pending.values) (p.tx.fee, p.tx.weight)],
      maxBlockBytes: network?.maxBlockBytes ?? NetworkInfo.whitepaper.maxBlockBytes,
      recentBlockMins: recentMins,
    );
  }

  // ---- submitting -----------------------------------------------------------

  /// Checks a transaction against consensus (PROTOCOL.md Section 2.3), the
  /// proven balance, and the client rules of Section 2.4 (a reply that
  /// doesn't pay its parent's author, or a flag of something that isn't a
  /// message, would be valid but ignored by every client). Returns a
  /// problem, or null if valid. `message` is the text, without salt.
  TxProblem? checkTransaction({
    required String fromAddress,
    required TxKind kind,
    required Uint8List? to,
    required int amount,
    required int fee,
    required Uint8List? message,
    String? reference,
  }) {
    const malformed = TxProblem(TxProblemKind.malformed);
    const checking = TxProblem(TxProblemKind.checkingBalance);
    if (fee <= 0) return const TxProblem(TxProblemKind.feeTooLow);
    if (amount < 0) return malformed;
    final target = reference == null ? null : lookupTx(reference);
    bool isMessage(TxView? v) => v != null && (v.tx.kind == TxKind.orphan || v.tx.kind == TxKind.reply);
    switch (kind) {
      case TxKind.orphan:
        if (to != null || reference != null || amount != orphanBurn(fee)) return malformed;
        if (message == null) return const TxProblem(TxProblemKind.needsMessage);
      case TxKind.reply:
        if (to == null) return const TxProblem(TxProblemKind.needsRecipient);
        if (amount < fee) return TxProblem(TxProblemKind.amountBelowFee, fee);
        if (message == null) return const TxProblem(TxProblemKind.needsMessage);
        if (reference == null) return malformed;
        if (!isMessage(target) || !target!.confirmed) return const TxProblem(TxProblemKind.replyParentNotMined);
        if (target.tx.fromAddress != toHex(to)) return const TxProblem(TxProblemKind.replyWrongRecipient);
      case TxKind.raw:
        if (to == null) return const TxProblem(TxProblemKind.needsRecipient);
        if (amount < fee) return TxProblem(TxProblemKind.amountBelowFee, fee);
        if (message != null || reference != null) return malformed;
      case TxKind.flag:
        if (to != null || amount != 0 || message != null || reference == null) return malformed;
        if (!isMessage(target)) return const TxProblem(TxProblemKind.flagNotMessage);
        if (hasFlagged(fromAddress, reference)) return const TxProblem(TxProblemKind.alreadyFlagged);
        // Earlier flags anywhere on the chain are proven, not searched for.
        if (provenFlagged(fromAddress, reference) == null) return checking;
    }
    if (message != null && message.length > maxMessageSize) {
      return TxProblem(TxProblemKind.messageTooLong, message.length, maxMessageSize);
    }
    final available = availableTo(fromAddress);
    if (available == null) return checking;
    if (fee + amount > available) {
      return TxProblem(TxProblemKind.insufficientBalance, fee + amount, available);
    }
    return null;
  }

  /// Salts `message` (PROTOCOL.md Section 2.4), signs the transaction with
  /// the sender's next nonce, and submits it (SubmitTx; the node answers
  /// with a TxStatus, see [statusOf]). Throws a [TxProblem] if it would be
  /// refused or the client is offline.
  Future<Transaction> submit({
    required MurmurWallet wallet,
    required TxKind kind,
    Uint8List? to,
    int amount = 0,
    required int fee,
    Uint8List? message,
    String? reference,
  }) async {
    if (state != LinkState.live) {
      throw const TxProblem(TxProblemKind.notLive);
    }
    final problem = checkTransaction(
        fromAddress: wallet.addressHex,
        kind: kind,
        to: to,
        amount: amount,
        fee: fee,
        message: message,
        reference: reference);
    if (problem != null) throw problem;
    final nonce = nextNonce(wallet.addressHex);
    if (nonce == null) throw const TxProblem(TxProblemKind.checkingBalance);
    final content = message == null ? null : saltedContent(message);

    final tx = await wallet.sign(
      kind: kind,
      nonce: nonce,
      to: to,
      amount: amount,
      fee: fee,
      messageHash: content == null ? null : sha256Bytes(content),
      contentSize: content?.length ?? 0,
      reference: reference == null ? null : fromHex(reference),
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    if (state != LinkState.live) throw const TxProblem(TxProblemKind.connectionLost);
    if (_txIndex.containsKey(tx.id) || _pending.containsKey(tx.id)) {
      throw const TxProblem(TxProblemKind.duplicate);
    }
    _send(SubmitTx(tx, content));
    _pending[tx.id] = PendingTx(tx, content, mine: true, sentAtHeight: height);
    _sentHere.add(tx.id);
    notifyListeners();
    return tx;
  }

  /// Convenience for UI text inputs.
  static Uint8List encodeText(String s) => Uint8List.fromList(utf8.encode(s));

  @override
  void dispose() {
    _cancelRetry();
    _teardown();
    super.dispose();
  }
}
