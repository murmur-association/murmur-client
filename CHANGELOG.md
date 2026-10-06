# Changelog

Newest first. Each release is a `vX.Y.Z` tag matching `version` in `pubspec.yaml`; see [README](README.md#releases-and-deployment). Entries marked **Breaking** need action from users.

## v0.2.11: the Windows test's own bug (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Fixed: the Windows test miscounted a single node.** v0.2.10's report showed the app doing the right thing on the release runner: one node, the new app's own. The test still failed, because PowerShell gives a single result back without a count, so "exactly one" was never true. The count is now taken from a list, and was tried here with real node processes: none, one, another app's, two. v0.2.10 has no Windows download either.

## v0.2.10: the Windows test's count of nodes (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Fixed: the Windows test counted nodes at one instant.** With software Direct3D beside it, the app ran on the release runner in v0.2.9: its window, its own node, and both stopped with the window. The second check (a node left by a killed app is replaced) then failed where it counts the nodes, at the moment the app was replacing the old one. It now waits for exactly one node, this app's, and names every node it sees if that doesn't happen. v0.2.9 has no Windows download either.

## v0.2.9: software Direct3D for the Windows release test (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Fixed: the Windows app can draw on the release runner.** v0.2.8's test kept the engine's words: no Direct3D device, on a server with no graphics card and without Windows' software Direct3D (WARP). The release job now also puts Microsoft's WARP package beside the copy it tries, pinned by its SHA-256 like the OpenGL library, and for the test only. v0.2.8 has no Windows download either.

## v0.2.8: why the Windows app stops on the release runner (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Changed: the Windows app's test keeps what the app says.** With an OpenGL library beside it, the app started on the release runner and made its window, then stopped by itself before starting its node: its engine couldn't set itself up there. The test now keeps the app's output, where the engine says why, and lists the graphics libraries the system has. v0.2.7 has no Windows download either.

## v0.2.7: an OpenGL library for the Windows release test (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Fixed: the Windows app can be tried on the release runner.** v0.2.6's test named what that system lacks: `OPENGL32.dll`, which every desktop Windows has and the app's engine loads at start. The release job now puts a software OpenGL (Mesa, pinned by its SHA-256) beside the copy it tries. It's for the test only: the released package is built afresh, and checked to hold none of it. v0.2.6 has no Windows download either.

## v0.2.6: what the Windows release runner lacks (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Changed: the Windows app's test says which system libraries are missing.** On the release runner the packaged app still couldn't start, with the Visual C++ runtime beside it: some other library it loads isn't on that system. Before starting the app, the test now lists the libraries its programs need that are neither beside them nor in the system. v0.2.5 has no Windows download either.

## v0.2.5: the Windows app, tried as packaged (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Fixed: the Windows app's test on the release runner, again.** v0.2.4's test started the app from the build folder, where it couldn't load the Visual C++ runtime the runner lacks. It now tries the packaged folder, which carries that runtime: the same files a user unpacks. v0.2.4 has no Windows download either.

## v0.2.4: the Windows app's release test (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Changed: the testnet checkpoint** is now block 21,400.
- **Fixed: the Windows app's test on the release runner.** v0.2.3 built the app there, but its test looked for a window on screen, and the runner has no desktop to show one on. It now finds and closes the app's window whether it's shown or not, and says what it found when it fails. v0.2.3 has no Windows download either.

## v0.2.3: the Windows app's release build (2026-10-06)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 21,200.
- **Fixed: the Windows app's release build.** v0.2.1 and v0.2.2 have no Windows download: the release runner's Visual Studio lacked a component (ATL) the secure-storage plugin needs, so the app didn't compile there. The job now adds it.

## v0.2.2: checkpoint refresh (2026-10-06)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 20,600, refreshed from the live network by the scheduled release.

## v0.2.1: a checkpoint, desktop apps, lighter on memory (2026-10-05)

No protocol or network change. The client needs nodes on protocol 10, as before.

- **Added: a testnet checkpoint,** at block 19,800. A first visit lists threads after checking only the headers above it (a few seconds, instead of every header since genesis), and checks the rest back to genesis in the background.
- **Added: the checkpoint is refreshed from the live network, and checked before a release.** `tool/refresh_checkpoint.dart` asks every testnet node separately, with a client that starts from the checkpoint shipped before and checks every header back to genesis, and writes a block a day below the tip only if they agree. The release job (`tool/check_checkpoint.dart`) stops a release whose checkpoint isn't on the live chain, or is over a week old.
- **Added: releases include the Windows and Linux apps** (testnet builds, x64), as `murmur-client-vX.Y.Z-windows-x64.zip` and `murmur-client-vX.Y.Z-linux-x64.tar.gz`, listed in the page's `SHA256SUMS`: unpack one and run `murmur_client`. Each holds the app, its own node (the pinned `murmur-node` release) and the notices; the Windows one also the Visual C++ runtime. The Linux app (shown as Murmur, identifier `info.murmur.client`) keeps the wallet in the desktop's keyring.
- **Added: the Windows app has its own name and icon.** The `windows/` folder is now part of the repository: the app shows as Murmur (its program file is `murmur_client.exe`), carries the app's icon and keeps its settings under `%APPDATA%\Murmur Association\Murmur`. A release build with the bundled node was tried on Windows 11: the node starts with the app without a console window, and stops with it.
- **Added: the release pipeline tests against the live testnet** (`public-node-tests`, `test/live_release_test.dart`): the client syncs from the shipped checkpoint and proves the supply, the burn pool and an account, read-only, before anything is built. It takes a few seconds whatever the chain's length. Ordinary pushes still don't depend on the public network, and the longer checks in `test/live_node_test.dart` stay for runs by hand.
- **Added: a scheduled release.** A scheduled pipeline's one job (`scheduled-release`) refreshes the checkpoint, runs the analyzer and every test on it, raises the patch version, writes the CHANGELOG section and pushes the commit and its tag, which releases as any other; a checkpoint under a day old means no release, and a failure pushes nothing. It releases everything on the default branch, with nobody in the loop.
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
