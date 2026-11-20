// The nodes a client may use, in order of preference (NodeSettings keeps
// the user's list). An entry is a name or an address and a port: a node's
// peer-to-peer port (7878 by default), or 443 for its secure WebSocket
// behind a TLS proxy, the only way a browser reaches a node.

import 'transport.dart' show viaBridge;

/// One entry of the node list.
class NodeAddress {
  const NodeAddress(this.host, this.port);

  final String host;
  final int port;

  /// The port an entry without one gets: 443 in a browser (secure
  /// WebSocket), the peer-to-peer port elsewhere.
  static const defaultPort = viaBridge ? 443 : 7878;

  /// An entry as typed: `host`, `host:port`, `[v6 address]:port`, or a
  /// `wss://` or `ws://` URL. Null when it isn't one. A `wss://` URL is a
  /// node behind TLS, so its port is 443 unless it says otherwise.
  static NodeAddress? parse(String text) {
    var s = text.trim();
    if (s.isEmpty || s.contains(RegExp(r'\s'))) return null;
    int? port;
    final scheme = RegExp(r'^(wss?)://', caseSensitive: false).firstMatch(s);
    if (scheme != null) {
      final uri = Uri.tryParse(s);
      if (uri == null || uri.host.isEmpty || (uri.path.isNotEmpty && uri.path != '/')) return null;
      if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
      final secure = scheme.group(1)!.toLowerCase() == 'wss';
      port = uri.hasPort ? uri.port : (secure ? 443 : 80);
      return _valid(uri.host, port);
    }
    String host;
    if (s.startsWith('[')) {
      final end = s.indexOf(']');
      if (end < 0) return null;
      host = s.substring(1, end);
      final rest = s.substring(end + 1);
      if (rest.isNotEmpty) {
        if (!rest.startsWith(':')) return null;
        port = int.tryParse(rest.substring(1));
        if (port == null) return null;
      }
    } else {
      final colon = s.lastIndexOf(':');
      // More than one colon without brackets: an IPv6 address on its own.
      if (colon >= 0 && s.indexOf(':') == colon) {
        port = int.tryParse(s.substring(colon + 1));
        if (port == null) return null;
        s = s.substring(0, colon);
      }
      host = s;
    }
    return _valid(host, port ?? defaultPort);
  }

  static NodeAddress? _valid(String host, int port) {
    if (port < 1 || port > 65535) return null;
    final h = host.toLowerCase();
    // Letters, digits, dots, hyphens; or an IPv6 address's hex and colons.
    if (h.isEmpty || h.length > 253 || !RegExp(r'^[a-z0-9.\-:]+$').hasMatch(h)) return null;
    if (h.startsWith('.') || h.endsWith('.') || h.contains('..')) return null;
    return NodeAddress(h, port);
  }

  /// A list as typed, one entry per comma or line; entries that don't parse
  /// are dropped, and so are repeats.
  static List<NodeAddress> parseList(String text) {
    final seen = <NodeAddress>{};
    return [
      for (final part in text.split(RegExp(r'[,\n]')))
        if (parse(part) case final a? when seen.add(a)) a,
    ];
  }

  @override
  bool operator ==(Object other) => other is NodeAddress && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  /// `host:port`, with an IPv6 address in brackets: what [parse] reads back.
  @override
  String toString() => host.contains(':') ? '[$host]:$port' : '$host:$port';
}
