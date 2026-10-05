// The murmur-node release this client is built and tested with: what
// tool/bundle_node.dart downloads by default, for desktop builds and for the
// tests against the node (test/support/test_node.dart). Raise it when the
// client moves to a newer node; the node's CHANGELOG says what changed.

const nodeRelease = 'v0.10.1';

/// Where `dart run tool/bundle_node.dart --for-tests` puts the release, from
/// the project root.
const testNodeDir = 'build/node';
