// How a signature comes out on the flavour at hand, beside the header
// nonces (header_nonce_checks.dart): a transaction's signature is part of
// its one encoding (rule 6), and a browser can bring a signer of its own.
//
// The wallet's signer (`MurmurWallet.signer`) must give RFC 8032's own
// signature for its first test vector everywhere. What the browser's Web
// Crypto gives (`Ed25519()`, which `package:cryptography` hands to it where
// it can) is only reported (`note`): the wallet doesn't use it, since
// Safari's signatures were never mined (2026-11-05), and the report says
// whether that signer differs, and whether its signature still verifies.

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';

/// RFC 8032, Section 7.1, TEST 1: the secret key, its public key, and the
/// signature of the empty message.
final _secret = fromHex('9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60');
const _public = 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a';
const _signature = 'e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555'
    'fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b';

void signatureTests(void Function(String note) note) {
  test("the wallet signs RFC 8032's first vector exactly", () async {
    final keys = await MurmurWallet.signer.newKeyPairFromSeed(_secret);
    expect(toHex((await keys.extractPublicKey()).bytes), _public);
    expect(toHex((await MurmurWallet.signer.sign(const [], keyPair: keys)).bytes), _signature);
  });

  test("what this platform's own Ed25519 signs (reported, not used)", () async {
    final own = Ed25519();
    try {
      final keys = await own.newKeyPairFromSeed(_secret);
      final signature = await own.sign(const [], keyPair: keys);
      final hex = toHex(signature.bytes);
      final verifies = await MurmurWallet.signer.verify(const [], signature: signature);
      note('${own.runtimeType}: '
          '${hex == _signature ? "RFC 8032's signature" : 'a different signature ($hex)'}, '
          '${verifies ? 'which verifies' : 'which does NOT verify'}');
    } catch (e) {
      note('${own.runtimeType} failed: $e');
    }
  });
}
