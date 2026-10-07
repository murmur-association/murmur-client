# Header nonces are full 64-bit numbers: the client corrupts large ones

For the client agent. Not committed: delete this file once it's fixed. Written 2026-10-07 from the node side, after `app.murmur.info` reported `header 27802 does not meet its proof-of-work target` on the testnet.

## What is wrong

A block header's `nonce` is a `u64` and may hold any value. The client reads it into a Dart `int` as two 32-bit halves and writes it back the same way when it builds the bytes to hash (`ByteReader.u64`, `ByteWriter.u64` in `lib/protocol/bytes.dart`). That round trip changes large values, so the client hashes different bytes from the ones that were mined and rejects a valid header.

| Platform | Nonces it corrupts | Why |
|---|---|---|
| Web | 2^53 and above | `int` is a double; `hi * 2^32 + lo` is rounded |
| Dart VM (desktop, mobile) | 2^63 and above, unless the low 32 bits are zero | the value wraps negative; `v ~/ 2^32` truncates toward zero, so the high half comes out one too large |

The comment on `ByteReader.u64` assumes only a peer's Hello nonce is ever that large. That held while every block was mined by the node's CPU miner, which counts nonces up from zero. `murmur-miner` (node v0.10.5 and later, the GPU miner the desktop client bundles) starts from a random 64-bit nonce.

## What it breaks today

- **Web, on 2026-10-07:** testnet blocks 27802 to 27875 included 73 with nonces between 2^53 and 2^63, and a browser client could not get past block 27801. Those 74 blocks were removed from the testnet by hand the same day (node CHANGELOG), so the web app works again for now. The bug is still there: the next block with such a nonce stops it again.
- **Desktop and mobile, at the next GPU-mined block with the top bit set:** none is on the chain yet (the largest nonce so far is 9044815288838094119, just under 2^63). About half of all `murmur-miner` runs will start above 2^63.
- **Anyone can do this on purpose:** one valid block with a nonce of 2^63 or more takes every current client off the chain.

## Where

- `lib/protocol/wire.dart`: header decode (`nonce: r.u64()`, near line 391) and encode (`..u64(h.nonce)`, near line 378).
- `lib/protocol/models.dart`: `BlockHeader.nonce` is an `int` (near line 199) and goes into the hash preimage with `..u64(nonce, Endian.little)` (near line 212).
- `lib/protocol/header_chain.dart` (near line 118) and `lib/protocol/network.dart` (genesis, `nonce: 0`) construct headers.

The other `nonce` in `models.dart` (near lines 78 and 113) is a transaction's account nonce. It counts an address's transactions and stays small.

## What to do

1. Carry the header nonce as its 8 bytes (or a `BigInt`) from the wire to the hash preimage, never through `int`. On the wire it is big-endian; in the hash preimage little-endian (PROTOCOL.md, Section 3.1).
2. Make `ByteReader.u64` refuse what it cannot represent instead of rounding: throw when the high half is 2^21 or more (the value would be 2^53 or more). Every other `u64` in consensus data is bounded far below that by the rules (heights, timestamps, amounts, fees, account nonces), so a larger one is either the header nonce, which now has its own path, or invalid data. Before doing this, give a peer's Hello nonce its own path too (read or skip its 8 bytes): it is a random 64-bit number, and a `u64()` that throws would refuse every node's Hello.
3. Run the header tests on the VM and in a browser (`flutter test --platform chrome`): the two fail at different values.

## Test vectors

Testnet block 27802 as sent on the wire (232 bytes; the nonce is bytes 192 to 199, `55e96d778ea4c761`):

```
0000000000006c9a0000003fbddd247dcc70a4a380e4d961de600da963d41c611400d4720bb0f10b0000000000000000000000000000000000000000000000000000000000000000f34c0e6bf382756779500d39a00a7821af4cc162825b1de8b3de4a3b1e69ea98df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b8111904717153a74686397cb63948d8a5f406af099169adaee20b435347433f4fead3000000006ac64dd6000001c0c0490469817b48c4f6d1a86755e96d778ea4c7617c2d9aee91b740ba61aa4ef61e0f853f67c3a292b065f1b3b77b6068066fee28
```

| Nonce | Block hash | Meets its target |
|---|---|---|
| 6190599523059156833 (as mined; above 2^53) | `00000148cb77708faa9b71e4242157a73ebf41e96855111e79f22bf6ec3a9c8a` | yes |
| 9223372036854788153 (2^63 + 12345) | `599e4207ee7b51341f34050d6f0bf36919044076002a54df36d8a922df0f7247` | no (hash check only) |
| 18446744073709551615 (2^64 − 1) | `f9aaf366c6f077b1a551f0587bee8b611994dca0fc26aa433a558b681fe19007` | no (hash check only) |

Block 27802 is no longer on the testnet's chain, but it remains a valid header and a good test. For the last two, replace bytes 192 to 199 of the header above with the nonce, big-endian, and check the hash. The first hash is the node's own (`murmur-node ctl checkpoint 27802`); the other two were computed with the same code that reproduced it.

The current behaviour, measured: a browser turns the first nonce into 6190599523059156992; the Dart VM turns `8000000000003039` into `8000000100003039` and `ffffffffffffffff` into `00000000ffffffff`.
