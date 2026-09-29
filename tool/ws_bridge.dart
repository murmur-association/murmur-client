// WebSocket-to-TCP relay so the web build can reach a node that has no
// `--ws-port`: browsers can't open raw TCP sockets. Each WebSocket
// connection gets its own TCP connection to the node's P2P port, and bytes
// are copied both ways unchanged. They're the encrypted stream (key exchange
// included, PROTOCOL.md Section 7.4), so the bridge sees nothing of them.
//
//   dart run tool/ws_bridge.dart [--listen 7880] [--node 127.0.0.1:7878]
//
// It binds to 127.0.0.1 only, always dials the one configured node (so it
// can't be used as an open proxy), accepts only pages served from localhost,
// and never touches the node's control port.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  var listenPort = 7880;
  var nodeHost = '127.0.0.1';
  var nodePort = 7878;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--listen':
        listenPort = int.parse(args[++i]);
      case '--node':
        final parts = args[++i].split(':');
        nodeHost = parts.first;
        nodePort = int.parse(parts.last);
      default:
        stderr.writeln('usage: dart run tool/ws_bridge.dart [--listen <port>] [--node <host:port>]');
        exit(2);
    }
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, listenPort);
  print('bridge: ws://127.0.0.1:$listenPort -> tcp://$nodeHost:$nodePort');

  await for (final request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request) || !_localOrigin(request)) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      continue;
    }
    unawaited(_relay(request, nodeHost, nodePort));
  }
}

bool _localOrigin(HttpRequest request) {
  final origin = request.headers.value('origin');
  if (origin == null) return true;
  final host = Uri.tryParse(origin)?.host;
  return host == 'localhost' || host == '127.0.0.1' || host == '[::1]' || host == '::1';
}

Future<void> _relay(HttpRequest request, String nodeHost, int nodePort) async {
  final ws = await WebSocketTransformer.upgrade(request);
  final Socket tcp;
  try {
    tcp = await Socket.connect(nodeHost, nodePort, timeout: const Duration(seconds: 10));
  } catch (e) {
    print('bridge: cannot reach node at $nodeHost:$nodePort: $e');
    await ws.close(WebSocketStatus.internalServerError, 'node unreachable');
    return;
  }
  tcp.setOption(SocketOption.tcpNoDelay, true);
  print('bridge: client connected');

  tcp.listen(
    ws.add,
    onDone: () => ws.close(),
    onError: (_) => ws.close(),
    cancelOnError: true,
  );
  ws.listen(
    (message) {
      if (message is List<int>) tcp.add(message);
    },
    onDone: () {
      print('bridge: client disconnected');
      tcp.destroy();
    },
    onError: (_) => tcp.destroy(),
    cancelOnError: true,
  );
}
