// A header's nonce is any 64-bit value, carried as its 8 bytes: the checks,
// with PROTOCOL.md's and the node's vectors, are shared with the acceptance
// tests, which run them in a browser too (where numbers round at 2^53).

import '../integration_test/support/header_nonce_checks.dart';

void main() => headerNonceTests();
