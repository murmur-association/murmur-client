// Resolving an address's alias, PROTOCOL.md Section 7.8, over what a light
// client knows. The rule that matters: never show a replaced alias. So the
// latest candidate decides, and a candidate is only trusted when no block
// above it that could hold a newer one is missing; otherwise the address has
// no known alias for now (it shows as hex), which is safe.

import 'dart:typed_data';

import '../protocol/alias.dart';
import '../protocol/models.dart';
import 'node_client.dart' show TxView;

/// The alias `candidates` (an address's mined Orphans with `content_size`
/// 87) resolve to, or null for none known.
/// - `tip`: the best chain's height.
/// - `unknown(h)`: whether block `h` isn't fetched and may hold one of the
///   address's transactions (its filter matches, or isn't known).
/// - `contentOf`: the candidate's verified content, if at hand.
String? resolveAlias(
  List<TxView> candidates, {
  required int tip,
  required bool Function(int height) unknown,
  required Uint8List? Function(TxView v) contentOf,
}) {
  // Latest first: by height, then as listed (a block's own order).
  final order = [for (var i = 0; i < candidates.length; i++) i]..sort((a, b) {
      final byHeight = candidates[b].height!.compareTo(candidates[a].height!);
      return byHeight != 0 ? byHeight : a.compareTo(b);
    });
  var top = tip;
  for (final i in order) {
    final v = candidates[i];
    final h = v.height!;
    // A newer candidate may hide in a block not fetched, including this
    // candidate's own block (a later transaction in it).
    for (var k = top; k >= h; k--) {
      if (unknown(k)) return null;
    }
    top = h;
    final content = contentOf(v);
    // Loading, or gone: no known alias, and no falling back to an older one.
    if (content == null) return null;
    final name = aliasOf(messageOf(content));
    if (name == null) continue; // an ordinary 71-byte message
    return name.isEmpty ? null : name;
  }
  return null;
}
