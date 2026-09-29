import 'dart:async';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'transport.dart';

const viaBridge = true;

/// Connects over WebSocket: to a node's `--ws-port` (usually behind a TLS
/// proxy, such as wss://node.murmur.info), or to the local bridge. The
/// browser resolves the name and picks the address, so `avoid` can't apply.
/// Browsers skip an address that refuses or doesn't answer, but keep
/// reusing one that accepts and then fails TLS (README, "Web: limits").
Future<Transport> openTransport(String host, int port, Duration timeout, {Set<String> avoid = const {}}) async {
  final url = webSocketUrl(host, port, pageIsHttps: Uri.base.scheme == 'https');
  final channel = WebSocketChannel.connect(url);
  try {
    await channel.ready.timeout(timeout);
  } catch (_) {
    unawaited(channel.sink.close());
    // Only a bridge on this machine is worth telling the user to start.
    throw isLoopback(host) ? TransportException('', bridgeUrl: '$url') : TransportException('$url');
  }
  return _WebSocketTransport(channel, '$url');
}

/// `wss://` on a page served over HTTPS (browsers allow nothing else there)
/// and on port 443 (a TLS proxy); `ws://` otherwise, as for the local bridge.
Uri webSocketUrl(String host, int port, {required bool pageIsHttps}) =>
    Uri(scheme: pageIsHttps || port == 443 ? 'wss' : 'ws', host: host, port: port, path: '/');

bool isLoopback(String host) => host == 'localhost' || host == '::1' || host.startsWith('127.');

class _WebSocketTransport implements Transport {
  _WebSocketTransport(this._channel, this.peer);

  final WebSocketChannel _channel;

  @override
  final String peer;

  @override
  Stream<Uint8List> get incoming => _channel.stream.map((data) => switch (data) {
        Uint8List b => b,
        List<int> b => Uint8List.fromList(b),
        ByteBuffer b => b.asUint8List(),
        _ => throw const FormatException('the node sent a text message'),
      });

  @override
  void add(Uint8List bytes) => _channel.sink.add(bytes);

  @override
  void close() => _channel.sink.close();
}
