# Changelog

Newest first. Each release is a `vX.Y.Z` tag matching `version` in `pubspec.yaml`; see [README](README.md#releases-and-deployment). Entries marked **Breaking** need action from users.

## v0.6.3: checkpoint refresh (2026-10-14)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 7,600, refreshed from the live network by the scheduled release.

## v0.6.2: checkpoint refresh (2026-10-13)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 4,700, refreshed from the live network by the scheduled release.

## v0.6.1: checkpoint refresh (2026-10-12)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 1,800, refreshed from the live network by the scheduled release.

## v0.6.0: murmur-testnet-11, answers, newest replies first, lighter on memory (2026-10-10)

**Breaking: a new network and protocol.** The app speaks protocol 12 and joins `murmur-testnet-11`; it no longer reaches `murmur-testnet-10`. Nothing carries over: wallets keep their keys, and start with nothing on the new chain. The desktop apps ship node release v0.12.0. No checkpoint while the network is under a day old.

- **Added: you are told when someone answers your reply**, in anyone's thread. Such answers show in Messages with the replies you received, and the badge counts them. A reply to a reply now says which one on the chain (4 bytes of it), where it used to say so in a line of its text; the chain still pays the thread's author. The node could leave some out: like flags received, that list can't be proven complete.
- **Changed: a long history loads as you scroll.** The Wallet and Messages tabs and an address's page read the newest 500 entries, and further back as you reach the end.
- **Changed: the app stays light when left open.** It lets go of the oldest blocks it loaded once it holds a week of them, keeping your own messages and the threads and addresses you follow, and it no longer rebuilds its message lists at every new block.
- **Changed: the app's memory no longer grows with the chain.** It used to keep every block header since the chain began once it had checked them. It now checks them and lets them go, keeps the ones from the release's checkpoint on, and fetches an older one, proven, when a page needs it. The local copy shrinks the same way, and a later start resumes the check where it stopped.
- **Changed: a thread shows its newest replies first**, under its first message, and says so. A long thread opens at once with its latest replies; "Earlier replies" at the foot loads the ones before.
- **Changed: tapping a quote goes to the quoted reply** and marks it, where it used to open it in a dialog. If that reply is older than the ones loaded, the tap loads back to it.
- **Fixed: replies mined in blocks with the same time** could show in the wrong order when they were read from the node's index.
- **Changed: scrolling back past the checkpoint** in Threads loads older blocks a batch at a time, without waiting for the check from genesis to finish.

## v0.5.1: checkpoint refresh (2026-10-10)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 1,500, refreshed from the live network by the scheduled release.

## v0.5.0: murmur-testnet-10, flat threads with quotes, old threads at once (2026-10-08)

**Breaking: a new network and protocol.** The app speaks protocol 11 and joins `murmur-testnet-10`; it no longer reaches `murmur-testnet-9`. Nothing carries over: wallets keep their keys, and start with nothing on the new chain. The desktop apps ship node release v0.11.0.

- **Changed: tokens have decimals.** Amounts are shown and typed in tokens with up to six decimals. The least fee is 0.5 token: a reply costs at least 1 token, a new thread or a public name at least 5.5.
- **Changed: threads are flat.** A reply goes in its thread, whichever message it answers, and pays **the author of the thread**, not the author of the message answered. A thread page shows the first message and its replies, oldest first.
- **Added: quotes.** Reply to a reply, and your answer shows that reply above it; tap it to read it whole. The answer names it in a short first line (`>3fa9c21e`), so nothing is copied and it costs ten bytes of the fee.
- **Added: flags against your messages** show in Messages and on an address's page wherever they are on the chain, read from the node. The node could leave some out: unlike the rest, that list can't be proven complete.
- **Changed: old threads and histories open at once.** A thread's replies and flags, and what an address sent and received, are read from the node in a couple of requests and proven, however old they are, where the app used to search the chain since they began. A node that keeps no such index is still searched the old way.
- **Changed: public names are proven, and show for everyone.** A name is now a transaction of its own kind, and the app proves which name an address has, where it had to find the address's messages first. Names set on the old network don't carry over.
- **Changed: the app no longer downloads the whole chain** with "keep a local copy" on. The copy holds what was fetched and checked. With the download went a block's reward breakdown, the balance beside old history rows of an address that mines, and the app's own recount of the chain's state.
- **Changed: a message's time is its block's.** A transaction no longer carries a time of its own.
- **Changed: no checkpoint while the testnet is young.** For its first day the app checks the chain from its first block, which takes a moment; releases after that ship a checkpoint again.
- **Added: an engine for emoji of the app's own**, written as `:name:` in a message. It has no emoji yet, so nothing shows.

## v0.4.2: large header nonces, and copying on an iPhone (2026-10-07)

No protocol or network change, and the same testnet checkpoint (block 24,800). **Update: earlier versions can be taken off the chain by one valid block.**

- **Fixed: a valid block could take the app off the chain.** A header's nonce can be any 64-bit number, and the app read it as a number of its own: a browser rounded nonces from 2^53 up, the desktop apps wrapped those from 2^63 up, and the block was then refused as not meeting its proof of work. Blocks mined on a graphics card start from a random nonce, and on 2026-10-07 testnet block 27802 stopped every browser. The nonce is now carried as its bytes, unchanged.
- **Fixed: "Copy" copied nothing in an iPhone's browser.** The share menu copied, and opened the share sheet, only once the menu had closed; by then Safari no longer takes the tap for the user's and refuses both. They now happen in the tap itself, and copying in a browser first uses the way every browser takes there.

## v0.4.1: the Windows app of v0.4.0 (2026-10-07)

No protocol or network change, and the same testnet checkpoint (block 24,800).

- **Fixed: v0.4.0 came without its Windows app.** The project moved to `gitlab.com/murmur-association` while that release was being built, and the Windows build could not download the node from the old address. The node's releases are now fetched from the new one, and the links to the node's repository follow it.

## v0.4.0: mining on the graphics card, one passphrase, threads that stay put (2026-10-07)

No protocol or network change. The testnet checkpoint moves to block 24,800. The desktop apps now ship node release v0.10.5.

- **Added: mining on the graphics card, in the desktop apps.** With the app's own node mining, "Mine on the graphics card" has the node mine through the card's OpenCL driver, far faster than on the processor. The card says which card mines; when it can't be used, mining goes on with the processor and the reason is shown. Off by default. The apps now ship `murmur-miner` beside `murmur-node`, both from node release v0.10.5.
- **Fixed: Arabic on devices in other languages.** A device set to a language the app doesn't have (French, Korean, or none at all) got the app in Arabic, the first in its list. It now gets English, as intended.
- **Added: acceptance tests.** One suite does what a user does (a wallet, a thread, a reply, an invitation card, a restart) inside the built app, the same on Windows, Linux and in a browser, against a node of its own. The browser runs it twice, with a passphrase and with a passkey (a virtual authenticator); the desktops also try the app's own node and its mining.
- **Changed: one passphrase, or one passkey, for the app.** Invitation cards no longer get a passphrase or passkey of their own: making the first cards asks for the wallet's, and a wallet made while cards are kept takes theirs. Cards already under a second passphrase keep it.
- **Fixed: the dialog that makes invitation cards follows the balance.** "Not enough" and the button now update when a block or a transfer changes what the wallet can spend, without reopening the dialog.
- **Changed: the desktop app no longer reads from its own node.** With "Run a Murmur node on this computer" on, the app used to connect to that node, which keeps nobody else's messages, so threads came up without their text. The app now stays on the node you chose, and its own node only takes part in the network, mining or not. The Chain tab shows where that node listens (`127.0.0.1` and its port).
- **Fixed: `node.murmur.info` in the desktop app.** Port 443 is now reached as a secure WebSocket in every build, as in a browser. The Node dialog also no longer starts from the app's own node's port, which made a typed address fail.

- **Fixed: listed threads still moved in some cases.** A reply now keeps its thread's place until the thread is loaded, even when the thread is older than the checkpoint and has to wait for the headers below it; nothing less recent shows before. Threads also wait for every block more recent than them, so one loaded early can't be overtaken later.

## v0.3.1: scheduled release, with what was waiting (2026-10-07)

- **Changed: the testnet checkpoint** is now block 23,500, refreshed from the live network by the scheduled release.

## v0.3.0: seed words, encrypted invitation cards, addresses as QR codes (2026-10-06)

No protocol or network change. The testnet checkpoint moves to block 22,700.

- **Changed: invitation cards are stored encrypted.** A card's code is its key, so the codes this device keeps are now encrypted like the wallet's seed, under a protection of their own (the device's check, a passkey or a passphrase, set up when cards are first made or next unlocked). The list of cards needs nothing; showing a card's QR code and link, printing and cancelling ask to unlock. Cards made with earlier versions are encrypted at the next unlock. A card's link is now shared from its QR dialog.
- **Fixed: threads no longer jump while the list loads.** An old thread with a recent reply used to show up late, pushing down the threads already listed. Its reply now has the thread fetched at once, and the less recent threads wait for it.
- **Added: an address as a QR code.** The share button of an address (the wallet's own, or any address page) offers "QR code": a code of the link to that address's page, large on screen for another device to scan, with a share button to pass the link on. Links of the form `#/address/<address>` open that page.
- **Added: the seed as 24 words.** A wallet's seed is shown both as its 64 characters and as 24 English words (the BIP39 encoding of the same 32 bytes), and either form is taken wherever a seed is asked for. A mistyped or misplaced word is caught and named.
- **Added: a new wallet is shown its seed.** Creating a wallet, from the Wallet tab or by claiming an invitation, now ends with its seed on screen and why it must be kept: it's the only way back if the device is lost or the passphrase forgotten. The dialog closes once the user confirms it's saved.
- **Added: Enter confirms dialogs.** Enter presses a dialog's copper button (Ctrl+Enter while writing a text of several lines); a red button is never pressed by a key.
- **Fixed: dialogs under the on-screen keyboard.** On a phone, a dialog with a text field (the Public name prompt, for one) spilled out of its box when the keyboard came up. Dialogs now scroll.
- **Changed: one test tries both desktop apps.** `tool/desktop_smoke_test.dart` replaces the two scripts that made the same checks, one for each system. Both release jobs now try the packaged folder, the files a user unpacks, with the same steps.

## v0.2.12: the Windows wallet check, where Windows allows it (2026-10-06)

No protocol or network change, and nothing new in the app.

- **Changed: the Windows wallet check asks Windows first.** In v0.2.11 the first two checks passed on the release runner: the app's node starts and stops with it, and a node left by a killed app is replaced. The third, saving a wallet, stopped where the storage asks Windows to encrypt with the account's own key, which Windows gives only to a logged-on user. The test now asks Windows itself whether that works for the account: where it does, the check runs and must pass; where it doesn't, it's reported as not tried, with Windows' reason. v0.2.11 has no Windows download either.

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
