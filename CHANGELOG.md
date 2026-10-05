# Changelog

Newest first. Each release is a `vX.Y.Z` tag matching `version` in `pubspec.yaml`; see [README](README.md#releases-and-deployment). Entries marked **Breaking** need action from users.

## Unreleased

- **Added: a testnet checkpoint** at block 16,000. A first visit lists threads after checking only the headers above it (about 2.4 seconds against the testnet today, instead of every header since genesis), and checks the rest back to genesis in the background.
- **Changed: headers are packed in memory.** The client keeps each checked header as its 232 wire bytes plus its hash, in one byte array, instead of an object of about 1,500 bytes in a browser. Measured on 100,000 testnet headers in headless Edge: about 376 bytes a header, four times less, so a year of testnet takes about 400 MB rather than 1.5 GB. Checking takes 11 to 17% longer per header. The local copy is loaded the same way, a header at a time. A reorganization rebuilds the header history from a copy kept every 1,024 blocks, not from genesis.
- **Fixed: a reply or transfer sent right after one's own transaction was mined could be refused** ("nonce already used"): the nonce proof lags a new block, and a transaction mined since counted neither as pending nor in the proof. Those transactions now count toward the next nonce and the available balance.
- **Fixed: on Android and iOS the local copy was kept in the temp folder,** which the system empties freely. It now goes in the app's cache folder (moved there if it exists), which device backups don't include; desktop folders are unchanged.
- **Fixed: the desktop and mobile apps stopped when the node dropped an open connection** (a node restarting, for one) instead of connecting again by themselves. A broken connection is now retried like an unreachable node, on the web too.
- **Changed: tests against the real node need no setup, and run in CI.** `test/node_test.dart` uses the pinned `murmur-node` release (v0.10.3, `tool/node_release.dart`; `dart run tool/bundle_node.dart --for-tests` downloads it and checks its `SHA256SUMS`), has it build the demo chains each test needs (`murmur-node demo-chain`), and starts it on them: sync, checkpoint, reorganization, sending and invitation tests in seconds, on chains the node built with its own rules. `test/live_node_test.dart` keeps only read-only checks of a public node.
- **Changed: `tool/header_bench.dart packed`** measures headers as the client now keeps them, in the Dart VM and in a browser (`?packed`).

## v0.2.0: protocol 10 (2026-10-04)

**Breaking: protocol 10.** The client needs nodes on protocol 10 (node v0.10.0 or later), and protocol 9 nodes refuse it. The networks (`murmur-testnet-9`, `murmur-demo-9`), their chains and the local copy are unchanged.

- **Changed:** `protocolVersion` is 10. The four messages of the node's compact block relay (PROTOCOL.md Section 7.9: SendCompact, CompactBlock, GetBlockTxs, BlockTxs) are decoded, with their 10,000 limit, and ignored: the client never sends SendCompact, so nodes keep sending it whole blocks.
- **Changed: an interrupted header back-fill resumes.** With the local copy allowed, the headers checked from genesis after a checkpoint start are stored batch by batch. A later session starts from the checkpoint again and carries on after them, instead of checking from genesis every time.
- **Added: `tool/header_bench.dart`**, which times the client's header checks and measures their memory on a long valid testnet chain, in the Dart VM and in a browser. The header rules moved into `checkHeaderRules` (`lib/protocol/consensus.dart`), unchanged, so the bench runs the client's own code.
- **Fixed:** after a change of wallet, a card cancelled back to the wallet that funded it said its tokens came back to "your wallet". The confirmation no longer names a destination, and the card's details name the wallet the tokens went to.

## v0.1.1: release pipeline, two fixes (2026-10-04)

No protocol or network change.

- **Added: a release pipeline**, like the node's. A `vX.Y.Z` tag that matches the version in `pubspec.yaml` builds the testnet page, publishes it as `murmur-web-vX.Y.Z.zip` with `SHA256SUMS` to the project's package registry, deploys it to app.murmur.info, and creates a GitLab Release. Other tags, and commits, are only checked.
- **Fixed:** a public name's own page called it a thread and offered a star; it now says "Public name".
- **Fixed:** cancelling several invitations asked "Cancel 2 invitations?" above a text about a single card.

## v0.1.0: first public testnet release (2026-09-30)

A light client for the Murmur chain, speaking protocol 9 (`murmur-testnet-9`, `murmur-demo-9`), on the web at app.murmur.info and as Windows, Linux, macOS, Android and iOS apps.

- **Checked, not trusted:** every header is checked from genesis (link, proof of work, median time, retarget, history root), and everything shown is proven against them: balances and nonces by state proofs, history through block filters, blocks, transactions and message content by their hashes.
- **Threads:** read threads and replies, most recently active first; start threads, reply, flag and send tokens. A summary of everything a transaction says comes before signing, and Ctrl+Enter sends.
- **Withdrawn messages:** a message its author flagged is withdrawn. Others no longer see it, and Murmur clients delete its text.
- **Wallet:** the key is encrypted on the device and unlocked for each use: the system key store on Android, iOS and macOS, a passkey with the WebAuthn PRF extension in browsers, a passphrase elsewhere. When a browser's passkey manager can't encrypt (Proton Pass, for one), the app says so and offers another manager or a passphrase.
- **Public names** (PROTOCOL.md Section 7.8): set yours in the Wallet tab. Others show as `bob · 3fa9c21e`, always with the start of the address. A name you give an address on your device comes first.
- **Invitations:** fund cards that let a newcomer join without spending anything. Print them as business cards with a QR code, and cancel unclaimed ones at any time. They don't expire.
- **People:** a picture drawn from each address, names in copper that open the address's page, mutes, and a language filter for threads, detected on the device.
- **Private by design:** no analytics, fonts or scripts from other sites; the only network peer is the node the user chooses.
- **Languages:** English, Spanish, Italian, Portuguese, German, Dutch, Arabic, Chinese and Japanese.
