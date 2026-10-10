// Reaching the public network: shipped checkpoints are well formed, a name
// standing for several nodes falls back from one that doesn't answer, and
// browsers use the right WebSocket URL.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/transport.dart';
import 'package:murmur_client/services/transport_io.dart';
import 'package:murmur_client/services/transport_web.dart' show webSocketUrl, isLoopback;
import 'package:murmur_client/ui/common.dart' show threadInRoute, threadLink;

import 'support/fake_node.dart';

/// A node that takes the connection and drops it: up for TCP, broken after.
Future<(ServerSocket, List<int>)> _brokenNode(InternetAddress address, int port) async {
  final server = await ServerSocket.bind(address, port);
  final accepted = <int>[];
  server.listen((s) {
    accepted.add(1);
    s.destroy();
  });
  return (server, accepted);
}

Future<void> _until(bool Function() done, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  tearDown(() => resolveOverride = null);

  group('a name standing for several nodes', () {
    test('a node that takes the connection but breaks the handshake is passed over', () async {
      final good = await FakeNode.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(good.close);
      final (broken, accepted) = await _brokenNode(InternetAddress('127.0.0.2'), good.port);
      addTearDown(broken.close);
      // The broken one first, as DNS might order them.
      resolveOverride = (_) async => [InternetAddress('127.0.0.2'), InternetAddress.loopbackIPv4];
      final client = MurmurClient();
      addTearDown(client.dispose);
      await client.connect('seed.test', good.port);
      await _until(() => client.state == LinkState.live);
      expect(accepted, hasLength(1), reason: 'the broken node was tried first');
      expect(client.network?.id, 'murmur-demo-11');
      expect(client.error, isNull);
    });

    test('so is a node on another protocol version', () async {
      final good = await FakeNode.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(good.close);
      final old = await FakeNode.bind(InternetAddress('127.0.0.2'), good.port, version: protocolVersion - 1);
      addTearDown(old.close);
      resolveOverride = (_) async => [InternetAddress('127.0.0.2'), InternetAddress.loopbackIPv4];
      final client = MurmurClient();
      addTearDown(client.dispose);
      await client.connect('seed.test', good.port);
      await _until(() => client.state == LinkState.live);
    });

    test('with every node failing, the error says why, and no retry is scheduled for a version mismatch', () async {
      final old = await FakeNode.bind(InternetAddress.loopbackIPv4, 0, version: protocolVersion - 1);
      addTearDown(old.close);
      final client = MurmurClient();
      addTearDown(client.dispose);
      await client.connect('127.0.0.1', old.port);
      await _until(() => client.error != null);
      expect(client.error!.kind, LinkErrorKind.version);
      expect(client.retryAt, isNull, reason: 'retrying cannot fix a version mismatch');
    });
  });

  test('a node that is down is tried again by itself, and the client goes live once it is back', () async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close(); // nothing listens there yet
    final client = MurmurClient();
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', port);
    await _until(() => client.error != null);
    expect(client.error!.kind, LinkErrorKind.unreachable);
    expect(client.retryAt, isNotNull);
    final node = await FakeNode.bind(InternetAddress.loopbackIPv4, port);
    addTearDown(node.close);
    await _until(() => client.state == LinkState.live, timeout: const Duration(seconds: 10));
    expect(client.error, isNull);
    // A user's disconnect stops the retries.
    client.disconnect();
    expect(client.retryAt, isNull);
  });

  group('checkpoints (PROTOCOL.md Section 7.7)', () {
    test('every shipped checkpoint has a height and a lowercase 32-byte hash', () {
      for (final net in NetworkInfo.all) {
        final cp = net.checkpoint;
        if (cp == null) continue;
        expect(cp.wellFormed, isTrue, reason: '${net.id}: Checkpoint(${cp.height}, ${cp.hash})');
        // Its context (the 11 headers before it) must exist on the chain.
        expect(cp.height, greaterThan(11), reason: net.id);
      }
    });

    test('the format check rejects what ctl checkpoint never prints', () {
      const hash = 'f92f97ba9a1d11ca92dd9c4a1e0358b263508a15605601d3e12fb304d8772cc0';
      expect(const Checkpoint(1200, hash).wellFormed, isTrue);
      expect(const Checkpoint(0, hash).wellFormed, isFalse, reason: 'genesis needs no checkpoint');
      expect(Checkpoint(1200, hash.toUpperCase()).wellFormed, isFalse);
      expect(Checkpoint(1200, hash.substring(2)).wellFormed, isFalse);
      expect(Checkpoint(1200, '0x${hash.substring(2)}').wellFormed, isFalse);
    });

    test('only the testnet is labelled as one', () {
      expect(NetworkInfo.whitepaper.isTestnet, isTrue);
      expect(NetworkInfo.demo.isTestnet, isFalse);
    });
  });

  group('dialing a name with several addresses', () {
    test('an address that does not answer is skipped for the next', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((s) => s.destroy());
      final started = DateTime.now();
      // 192.0.2.1 is TEST-NET-1: never routed, so the attempt times out.
      final socket = await connectFirst(
        [InternetAddress('192.0.2.1'), InternetAddress.loopbackIPv4],
        server.port,
        const Duration(seconds: 2),
        minPerAddress: const Duration(milliseconds: 500),
      );
      socket.destroy();
      expect(DateTime.now().difference(started), lessThan(const Duration(seconds: 3)));
    });

    test('with none answering, every address is reported', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close(); // nothing listens there now
      await expectLater(
        connectFirst([InternetAddress('192.0.2.1'), InternetAddress.loopbackIPv4], port, const Duration(seconds: 1),
            minPerAddress: const Duration(milliseconds: 300)),
        throwsA(isA<TransportException>()
            .having((e) => e.detail, 'detail', allOf(contains('192.0.2.1'), contains('127.0.0.1')))),
      );
    });
  });

  group('port 443 is a WebSocket natively too, as in a browser', () {
    /// A WebSocket server on this machine that sends back what it gets,
    /// and a text message when asked to misbehave (a single zero byte).
    Future<HttpServer> echo(InternetAddress address, int port) async {
      final server = await HttpServer.bind(address, port);
      server.transform(WebSocketTransformer()).listen((ws) {
        ws.listen((data) => data is List<int> && data.length == 1 && data[0] == 0 ? ws.add('text') : ws.add(data));
      });
      return server;
    }

    test('only port 443: every other port is a node\'s own, over TCP', () {
      expect(usesWebSocket(443), isTrue);
      expect([7878, 7880, 80, 8443].any(usesWebSocket), isFalse);
    });

    test('bytes go both ways, and the peer is the address reached', () async {
      final server = await echo(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final url = Uri(scheme: 'ws', host: 'localhost', port: server.port, path: '/');
      final transport = await openWebSocket(url, [InternetAddress.loopbackIPv4], const Duration(seconds: 5));
      addTearDown(transport.close);
      expect(transport.peer, '127.0.0.1:${server.port}');
      final got = <List<int>>[];
      Object? failure;
      transport.incoming.listen(got.add, onError: (Object e) => failure = e);
      transport.add(Uint8List.fromList([1, 2, 3]));
      await _until(() => got.isNotEmpty);
      expect(got.single, [1, 2, 3]);
      // A node never sends text: that's bad data, not a lost link.
      transport.add(Uint8List.fromList([0]));
      await _until(() => failure != null);
      expect(failure, isA<FormatException>());
    });

    test('an address that takes the connection but speaks no WebSocket is passed over', () async {
      final (broken, accepted) = await _brokenNode(InternetAddress('127.0.0.2'), 0);
      addTearDown(broken.close);
      final server = await echo(InternetAddress.loopbackIPv4, broken.port);
      addTearDown(() => server.close(force: true));
      final url = Uri(scheme: 'ws', host: 'localhost', port: broken.port, path: '/');
      final transport = await openWebSocket(
          url, [InternetAddress('127.0.0.2'), InternetAddress.loopbackIPv4], const Duration(seconds: 6));
      addTearDown(transport.close);
      expect(accepted, isNotEmpty, reason: 'the broken one was tried first');
      expect(transport.peer, '127.0.0.1:${broken.port}');
    });

    test('with none answering, every address is reported', () async {
      final (broken, _) = await _brokenNode(InternetAddress.loopbackIPv4, 0);
      addTearDown(broken.close);
      final url = Uri(scheme: 'ws', host: 'localhost', port: broken.port, path: '/');
      await expectLater(
        openWebSocket(url, [InternetAddress.loopbackIPv4], const Duration(seconds: 3)),
        throwsA(isA<TransportException>().having((e) => e.detail, 'detail', contains('127.0.0.1'))),
      );
    });
  });

  test('thread links open only a well-formed thread id', () {
    const id = 'f92f97ba9a1d11ca92dd9c4a1e0358b263508a15605601d3e12fb304d8772cc0';
    expect(threadInRoute('/thread/$id'), id);
    expect(threadLink(id), endsWith('/#/thread/$id'));
    for (final bad in ['/', '/thread', '/thread/', '/thread/${id.toUpperCase()}', '/thread/${id}00', '/tx/$id', null]) {
      expect(threadInRoute(bad), isNull, reason: '$bad');
    }
  });

  test('browsers use wss:// for port 443 and HTTPS pages, ws:// for the local bridge', () {
    expect('${webSocketUrl('node.murmur.info', 443, pageIsHttps: true)}', anyOf('wss://node.murmur.info/', 'wss://node.murmur.info:443/'));
    expect(webSocketUrl('node.murmur.info', 443, pageIsHttps: false).scheme, 'wss');
    expect('${webSocketUrl('127.0.0.1', 7880, pageIsHttps: false)}', 'ws://127.0.0.1:7880/');
    expect(isLoopback('127.0.0.1') && isLoopback('localhost') && !isLoopback('node.murmur.info'), isTrue);
  });
}
