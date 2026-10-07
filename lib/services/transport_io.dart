import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'transport.dart';

const viaBridge = false;

/// Replaces DNS in tests: the addresses `host` stands for, in the order to
/// try them.
@visibleForTesting
Future<List<InternetAddress>> Function(String host)? resolveOverride;

/// Dials `host`. A name can stand for several nodes (a DNS seed such as
/// testnet-seed.murmur.info lists every node it knows), so each address it
/// resolves to is tried in turn, in random order to spread the load, until
/// one answers; those in `avoid` (`address:port`, already tried) are
/// skipped. `timeout` bounds the whole attempt.
///
/// Port 443 is a node's WebSocket port behind a TLS proxy (such as
/// node.murmur.info, the address browsers use): it's spoken to the same
/// way here, so one address works in every build. Any other port is a
/// node's own peer-to-peer port, over TCP.
Future<Transport> openTransport(String host, int port, Duration timeout, {Set<String> avoid = const {}}) async {
  final List<InternetAddress> addresses;
  final literal = InternetAddress.tryParse(host);
  final override = resolveOverride;
  if (literal != null) {
    addresses = [literal];
  } else if (override != null) {
    addresses = await override(host);
  } else {
    try {
      addresses = (await InternetAddress.lookup(host).timeout(timeout)).toList()..shuffle();
    } on SocketException catch (e) {
      throw TransportException(e.osError?.message ?? e.message);
    } on TimeoutException {
      throw TransportException('no answer from DNS for $host');
    }
  }
  final left = [
    for (final a in addresses)
      if (!avoid.contains(_peerName(a, port))) a,
  ];
  if (left.isEmpty) throw TransportException('every address of $host was tried');
  if (usesWebSocket(port)) return openWebSocket(Uri(scheme: 'wss', host: host, port: port, path: '/'), left, timeout);
  final socket = await connectFirst(left, port, timeout);
  return _TcpTransport(socket, _peerName(socket.remoteAddress, port));
}

/// Whether `port` is reached over a secure WebSocket rather than TCP: 443,
/// as in a browser (`webSocketUrl`).
bool usesWebSocket(int port) => port == 443;

/// Opens the WebSocket at `url` (`wss://`, or `ws://` in tests) on the first
/// of `addresses` that takes it, one at a time, each with its share of
/// `timeout` (at least 3 s). The address is dialled here, not left to the
/// HTTP client, so the caller can move on from a node that fails later;
/// the certificate is still checked against the name in `url`.
Future<Transport> openWebSocket(Uri url, List<InternetAddress> addresses, Duration timeout,
    {Duration minPerAddress = const Duration(seconds: 3)}) async {
  if (addresses.isEmpty) throw TransportException('the name resolved to no address');
  final share = timeout ~/ addresses.length;
  final perAddress = share < minPerAddress ? minPerAddress : share;
  final errors = <String>[];
  for (final address in addresses) {
    final http = HttpClient()
      ..connectionFactory = (uri, proxyHost, proxyPort) {
        final plain = Socket.connect(address, url.port, timeout: perAddress);
        final socket = url.scheme == 'wss' ? plain.then<Socket>((s) => SecureSocket.secure(s, host: url.host)) : plain;
        return Future.value(ConnectionTask.fromSocket(socket, () {}));
      };
    try {
      final socket = await WebSocket.connect('$url', customClient: http).timeout(perAddress);
      return _WebSocketTransport(socket, http, _peerName(address, url.port));
    } on Exception catch (e) {
      // Unreachable, not TLS, a wrong certificate, or no WebSocket there.
      http.close(force: true);
      errors.add('${address.address}: ${e is SocketException ? e.osError?.message ?? e.message : e}');
    }
  }
  throw TransportException(errors.join('; '));
}

String _peerName(InternetAddress a, int port) =>
    a.type == InternetAddressType.IPv6 ? '[${a.address}]:$port' : '${a.address}:$port';

/// Connects to the first of `addresses` that accepts, one at a time. An
/// address that doesn't answer gets its share of `timeout` (at least 3 s),
/// so one unreachable node can't use up the whole attempt.
Future<Socket> connectFirst(List<InternetAddress> addresses, int port, Duration timeout,
    {Duration minPerAddress = const Duration(seconds: 3)}) async {
  if (addresses.isEmpty) throw TransportException('the name resolved to no address');
  final share = timeout ~/ addresses.length;
  final perAddress = share < minPerAddress ? minPerAddress : share;
  final errors = <String>[];
  for (final address in addresses) {
    try {
      final socket = await Socket.connect(address, port, timeout: perAddress);
      socket.setOption(SocketOption.tcpNoDelay, true);
      return socket;
    } on SocketException catch (e) {
      errors.add('${address.address}: ${e.osError?.message ?? e.message}');
    }
  }
  throw TransportException(errors.join('; '));
}

class _TcpTransport implements Transport {
  _TcpTransport(this._socket, this.peer) {
    // A write the node no longer takes fails here, out of reach of any
    // caller; the incoming stream reports the same broken link.
    unawaited(_socket.done.then<void>((_) {}, onError: (Object _) {}));
  }

  final Socket _socket;

  @override
  final String peer;

  // A socket error after connecting means the link broke, not bad data.
  @override
  Stream<Uint8List> get incoming => _socket.handleError(
      (Object e) => throw ConnectionLost((e as SocketException).osError?.message ?? e.message),
      test: (e) => e is SocketException);

  @override
  void add(Uint8List bytes) => _socket.add(bytes);

  @override
  void close() => _socket.destroy();
}
class _WebSocketTransport implements Transport {
  _WebSocketTransport(this._socket, this._http, this.peer);

  final WebSocket _socket;
  final HttpClient _http;

  @override
  final String peer;

  // An error after connecting means the link broke, not bad data.
  @override
  Stream<Uint8List> get incoming => _socket
      .handleError((Object e) => throw ConnectionLost(e is SocketException ? e.osError?.message ?? e.message : '$e'),
          test: (e) => e is SocketException || e is WebSocketException || e is TlsException)
      .map((data) => switch (data) {
            Uint8List b => b,
            List<int> b => Uint8List.fromList(b),
            _ => throw const FormatException('the node sent a text message'),
          });

  @override
  void add(Uint8List bytes) => _socket.add(bytes);

  @override
  void close() {
    unawaited(_socket.close().then<void>((_) {}, onError: (Object _) {}));
    _http.close(force: true);
  }
}
