// Browsers can't run programs: no node of the app's own on the web.

import 'local_node.dart';

LocalNode createLocalNode() => _NoLocalNode();

class _NoLocalNode extends LocalNode {
  _NoLocalNode() : super.base();

  @override
  LocalNodeState get state => LocalNodeState.unavailable;

  @override
  int? get port => null;

  @override
  String? get problem => null;

  @override
  String get dataDir => '';

  @override
  Future<void> start(List<String> args) async {}

  @override
  Future<void> stop() async {}
}
