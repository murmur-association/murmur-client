// One connection of the client's pool (`MurmurClient`): a node reached
// through one entry of the node list, its encrypted channel (PROTOCOL.md
// Section 7.4), the node's Hello, and the requests waiting on it. Each link
// has a waiter per reply type, so the pool can ask several nodes at once.

part of 'node_client.dart';

/// A link that went while a request waited on it: the pool asks another.
class _LinkGone implements Exception {
  const _LinkGone(this.cause);
  final LinkError cause;
}

class NodeLink {
  NodeLink._(this.id, this.entry, this._socket, this._channel);

  /// Opens one connection to `entry`, skipping the addresses in `avoid`
  /// (and adding the one it reaches, whatever follows), and waits for the
  /// node's Hello. Throws when the node can't be reached, the
  /// key exchange or the Hello doesn't come, or the node speaks another
  /// protocol version. `onMessage` gets every later message, and `onLost`
  /// the reason once the connection ends.
  static Future<NodeLink> open(
    int id,
    NodeAddress entry, {
    required Set<String> avoid,
    required Duration timeout,
    required void Function(NodeLink link, Message message) onMessage,
    required void Function(NodeLink link, LinkError reason) onLost,
  }) async {
    final socket = await openTransport(entry.host, entry.port, timeout, avoid: avoid);
    avoid.add(socket.peer);
    late final NodeLink link;
    try {
      // Every connection is encrypted (PROTOCOL.md Section 7.4).
      final channel = await SecureChannel.open(socket).timeout(_handshakeTimeout);
      link = NodeLink._(id, entry, socket, channel);
    } catch (_) {
      socket.close();
      rethrow;
    }
    final hello = Completer<Hello>();
    link._sub = link._channel.payloads.listen(
      (payload) {
        final Message message;
        try {
          message = decodeMessage(payload);
        } on FormatException catch (e) {
          link._lost(LinkError(LinkErrorKind.protocol, detail: e.message), onLost, hello);
          return;
        }
        if (!hello.isCompleted) {
          // The node speaks first, and its first message is its Hello.
          if (message is Hello) {
            hello.complete(message);
          } else {
            link._lost(const LinkError(LinkErrorKind.protocol, detail: 'the node did not start with Hello'), onLost, hello);
          }
          return;
        }
        if (!link._complete(message)) onMessage(link, message);
      },
      onError: (Object e) => link._lost(MurmurClient._describe(e), onLost, hello),
      onDone: () => link._lost(const LinkError(LinkErrorKind.closed), onLost, hello),
      cancelOnError: true,
    );
    try {
      final h = await hello.future.timeout(_handshakeTimeout);
      if (h.version != protocolVersion) throw LinkError(LinkErrorKind.version, nodeVersion: h.version);
      link.hello = h;
      link.height = h.height;
      return link;
    } catch (_) {
      link.close();
      rethrow;
    }
  }

  static const _handshakeTimeout = Duration(seconds: 30);

  /// Its place in the pool's order: earlier links are older.
  final int id;

  /// The node list's entry it came from.
  final NodeAddress entry;

  final Transport _socket;
  final SecureChannel _channel;
  StreamSubscription<Uint8List>? _sub;
  Timer? _pings;
  bool _closed = false;

  /// Which node it reached (`address:port` natively, the URL in a browser).
  String get peer => _socket.peer;

  /// The node's Hello.
  late final Hello hello;

  /// The height of the best chain the node has shown: its Hello's, raised by
  /// what it announces, and lowered when its headers stopped short of it.
  int height = 0;

  /// Whether the client's Hello went out (nothing else may go before it),
  /// whether Serving was sent on it (from then on its every GetContent is
  /// answered, since the node matches answers by order), and whether the
  /// user's messages were offered back to it (Restore).
  bool greeted = false;
  bool servingSent = false;
  bool restoreDone = false;

  /// Message contents it gave, and asked of it but not given: which node to
  /// ask first for content (`MurmurClient._fetchContentFromPool`).
  int contentGiven = 0;
  int contentMissed = 0;

  /// How well it has served content so far, from 0 to 1, a new link at 1/2.
  double get contentRecord => (contentGiven + 1) / (contentGiven + contentMissed + 2);

  final Map<Type, Completer<Message>> _waiting = {};

  void send(Message msg) {
    if (!_closed) _channel.send(encodePayload(msg));
  }

  /// Sends `msg` and waits up to `timeout` for its answer, of type `R`. One
  /// request of a type at a time per link: a second would take the first's
  /// answer.
  Future<R> request<R extends Message>(Message msg, Duration timeout) async {
    if (_closed) throw const _LinkGone(LinkError(LinkErrorKind.closed));
    final waiter = _waiting[R] = Completer<Message>();
    send(msg);
    try {
      return await waiter.future.timeout(timeout) as R;
    } finally {
      if (identical(_waiting[R], waiter)) _waiting.remove(R);
    }
  }

  /// Hands `message` to the request waiting for it; false if none was.
  bool _complete(Message message) {
    final waiter = _waiting.remove(message.runtimeType);
    if (waiter == null || waiter.isCompleted) return false;
    waiter.complete(message);
    return true;
  }

  /// Pings every `interval`, so the node (and a proxy) never sees it idle.
  void keepAlive(Duration interval) {
    _pings?.cancel();
    _pings = Timer.periodic(interval, (_) => send(const Ping()));
  }

  void _lost(LinkError reason, void Function(NodeLink, LinkError) onLost, Completer<Hello> hello) {
    if (_closed) return;
    if (!hello.isCompleted) {
      hello.completeError(reason);
      return;
    }
    close(reason);
    onLost(this, reason);
  }

  /// Ends the connection; requests waiting on it fail with `reason`.
  void close([LinkError reason = const LinkError(LinkErrorKind.closed)]) {
    if (_closed) return;
    _closed = true;
    _pings?.cancel();
    _sub?.cancel();
    _channel.close();
    _socket.close();
    for (final w in _waiting.values) {
      if (!w.isCompleted) w.completeError(_LinkGone(reason));
    }
    _waiting.clear();
  }

  bool get closed => _closed;
}
