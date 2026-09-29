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
  final socket = await connectFirst(left, port, timeout);
  return _TcpTransport(socket, _peerName(socket.remoteAddress, port));
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
  _TcpTransport(this._socket, this.peer);

  final Socket _socket;

  @override
  final String peer;

  @override
  Stream<Uint8List> get incoming => _socket;

  @override
  void add(Uint8List bytes) => _socket.add(bytes);

  @override
  void close() => _socket.destroy();
}
