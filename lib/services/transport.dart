// A byte-stream connection to a node. Native builds dial the node's TCP
// port directly; web builds can't open TCP sockets, so they reach the node
// through a WebSocket relay (tool/ws_bridge.dart).

import 'dart:typed_data';

import 'transport_io.dart' if (dart.library.js_interop) 'transport_web.dart' as impl;

abstract class Transport {
  /// Raw bytes from the node, in arbitrary chunks.
  Stream<Uint8List> get incoming;

  void add(Uint8List bytes);

  void close();

  /// Which of the name's nodes this reached (`address:port` natively, the
  /// URL on the web), so a failed handshake can move on to another.
  String get peer;
}

/// The node (or, on the web, the WebSocket bridge at `bridgeUrl`) couldn't be
/// reached. `detail` is the system's own error text, if any; the UI words the
/// rest.
class TransportException implements Exception {
  TransportException(this.detail, {this.bridgeUrl});

  final String detail;
  final String? bridgeUrl;

  @override
  String toString() => bridgeUrl == null ? 'could not reach the node: $detail' : 'could not reach $bridgeUrl';
}

/// An open connection broke (reset, or a write the other end no longer
/// takes), as when the node restarts: worth connecting again. `detail` is
/// the system's own error text.
class ConnectionLost implements Exception {
  ConnectionLost(this.detail);

  final String detail;

  @override
  String toString() => 'connection lost: $detail';
}

/// True when this build connects through the WebSocket bridge.
const viaBridge = impl.viaBridge;

/// Opens the connection. The client only ever talks to a node's P2P port,
/// never its control port. Natively, the addresses in `avoid` (peers
/// already tried) are skipped; a browser picks the address itself.
Future<Transport> openTransport(String host, int port, Duration timeout, {Set<String> avoid = const {}}) =>
    impl.openTransport(host, port, timeout, avoid: avoid);

/// Whether the client chooses the address itself, so a retry can go to a
/// node not tried yet. Not in a browser, which resolves names itself.
const canChooseAddress = !impl.viaBridge;
