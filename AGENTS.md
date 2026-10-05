# AGENTS.md

Working notes for anyone changing this repository, human or agent. [README.md](README.md) says what the app does for its users. This file says how the code is built, which rules it must keep, and what is still missing.

## What this is

A Flutter light client for the Murmur chain. The node, and the protocol's source of truth, live in the sibling repository [`../murmur`](https://gitlab.com/elc4no/murmur): `PROTOCOL.md` (wire format, consensus, test vectors) and `CHANGELOG.md`. The client speaks **protocol 10** (`murmur-testnet-9`, `murmur-demo-9`: the networks kept their names from protocol 9). Of protocol 10's compact block relay (Section 7.9) it only decodes the four messages and ignores them: it never sends `SendCompact`, so nodes keep sending it whole blocks (`NewBlock`). **Where this code and PROTOCOL.md disagree, PROTOCOL.md wins.** Section numbers in comments (for example "Section 3.6") refer to it. Don't edit `../murmur` from here: propose node changes to its owner instead.

Targets: the web (the main one), plus Windows, Linux, macOS, Android and iOS. `web/`, `windows/` and `linux/` are committed (the desktop apps show as Murmur, with the app's icon, written by `tool/render_brand.dart`); generate the other platform folders with `flutter create` (see README).

## Commands

CI (`.gitlab-ci.yml`) runs `flutter gen-l10n` with a clean-diff check, `flutter analyze`, `flutter test` and a web build on every push. Run the same locally before committing:

```
flutter pub get                       # also regenerates lib/l10n/app_localizations*.dart from the ARB files
flutter analyze                       # must report no issues
flutter test test/protocol_test.dart test/threads_test.dart test/ui_test.dart   # offline, a few seconds
flutter build web --release --no-web-resources-cdn   # CanvasKit served locally
dart run tool/fetch_fallback_fonts.dart   # copies the engine's fallback fonts next to the page (rule 2)
dart run tool/serve_web.dart          # serves build/web on http://localhost:8080
dart run tool/ws_bridge.dart --node 127.0.0.1:7878   # only for nodes without --ws-port
flutter test tool/render_brand.dart   # regenerates web icons and build/brand_preview.png
flutter test tool/refresh_checkpoint.dart   # the testnet checkpoint, from the live network (before a release)
flutter test tool/check_checkpoint.dart     # what the release job checks: the shipped checkpoint, against the live network
dart run tool/header_bench.dart generate 100000 build/headers.bin   # a valid testnet header chain
dart run tool/header_bench.dart check build/headers.bin             # times the header checks (also in a browser: header_bench_web.dart)
```

Tests against the node use the **pinned node release** (`tool/node_release.dart`, now v0.10.3), downloaded from the node project's package registry and checked against its `SHA256SUMS`. The node's specification is its code, so the tests use the node itself rather than restating its rules. Without the download they're skipped (CI sets `MURMUR_REQUIRE_NODE`, which makes that a failure):

```
dart run tool/bundle_node.dart --for-tests    # into build/node; again after raising the pinned release
flutter test                                  # node_test.dart and local_node_test.dart run too
```

`MURMUR_NODE_BIN=<murmur-node>` uses another binary instead, such as one built from `../murmur` while a node change isn't released yet.

- **Nothing to set up or wait for.** `node_test.dart` has the node build the demo chains it needs (`murmur-node demo-chain`, through `test/support/test_node.dart`): a chain, an extension, or a heavier branch for a reorganization, built and checked with the node's own rules. It then starts the node on them through the app's `ProcessLocalNode`. Headers a test needs as objects come from syncing a client, never from the node's files.
- **What it covers:** checkpoint start, back-fill (stored, resumed, restarted), reorganizations (the node restarts on a heavier branch, and the client reconnects), state proofs and filters, the local copy and its state-root check, sending with proven nonces, threads and flags, invitations. The node mines to the chain's wallet, at 1% of a core (a node mining flat out at the easy demo target races ahead of its clock and stalls).
- **Branches need room:** `demo-chain` spaces new blocks 2 s apart, never in the future, so a branch or extension of `n` blocks needs `n × 2 s` after the block it builds on. Without that room it refuses at once, writing nothing, and says how much earlier the chain must end. Build a chain that will get long branches with an earlier end (`TestNode.build(…, endTime:)`).
- **Read-only against a public node:** two files, both skipped without `MURMUR_NODE`, neither sending anything (never send testnet transactions from tests without the user asking).
  - `test/live_release_test.dart` is what a release waits on (`public-node-tests`, the only place CI sets `MURMUR_NODE`): sync from the shipped checkpoint, then the supply, the burn pool, an account and the fees (`checkProvenBasics`). It's **bounded**: a few requests whatever the chain's length. Keep it so; anything that grows with the chain would one day fail every release, and after a scheduled release has already pushed its tag.
  - `test/live_node_test.dart` is for runs by hand (`MURMUR_NODE=testnet-seed.murmur.info:7878 flutter test test/live_node_test.dart`): a filter scan of the whole chain and every block downloaded and counted (`test/support/client_checks.dart`). They take longer every day, so no pipeline runs them.
- `test/support/fake_node.dart` remains for what a real node can't be made to do: answer on another protocol version, or on an address a test picks.

**Paths with an apostrophe** (for example `C:\Users\o'brien`) break `flutter test` and web builds, because Flutter pastes the path into generated Dart code. Map a drive letter to the parent folder and work from it:

```
subst M: "C:\Users\o'brien"
cd M:\murmur-client
set TEMP=M:\AppData\Local\Temp
set TMP=%TEMP%
```

## Rules the code must keep

1. **Never use the node's control port** (`--rpc-port`, 7879) from `lib/`. The client talks only to the P2P port, or to `--ws-port`. Tests may use the control port.
2. **Nothing goes to third parties.** No analytics, remote fonts, CDNs or crash reporters. The only network peer is the node the user chose, or the local bridge. Flutter web fetches from Google by default, so two settings stop it:
   - `--no-web-resources-cdn` serves CanvasKit from the page;
   - `web/flutter_bootstrap.js` sets `fontFallbackBaseUrl` to `fallback-fonts/`, which `tool/fetch_fallback_fonts.dart` fills after every web build. Pages built without that step fetch fallback fonts from fonts.gstatic.com, or lose glyphs.

   To check a build, load it in headless Edge with `--log-net-log` and list the origins. Only the page's own origin and the node may appear, apart from the browser's own traffic. Links out (`openLink`) open only on the user's tap.
3. **The chain cache needs consent.** `ChainCache` is used only when `Preferences.storageConsent == allowed`. Turning it off deletes it. The wallet seed (secure storage) and preferences are always stored.
4. **Never print, log or send a wallet seed, and never store it in the clear.** It lives encrypted in the key vault (`services/key_vault.dart`):
   - **Android, iOS and macOS:** the system's hardware key store via `biometric_storage`. Every read needs biometrics; Apple devices also accept the device passcode, while Android with "every time" allows biometrics only.
   - **Browsers:** a passkey with the WebAuthn PRF extension; its secret after the device check is the AES-GCM key. The user picks the passkey manager (on iOS, Apple Passwords or a third-party one such as Proton Pass), and not all of them support PRF. Only an explicit `prf.enabled: false` rejects one at creation; otherwise the output is asked for (already at creation, else with a get). If none comes, `PasskeyUnsupported` makes `sealSeed` ask (`VaultPrompts.passkeyUnsupported`): try another manager, use a passphrase, or cancel. The user found the old silent fallback to a passphrase confusing.
   - **Otherwise** (including browsers without PRF, such as Firefox): a passphrase, stretched with PBKDF2-SHA256 over 600,000 rounds into an AES-GCM key.

   The Wallet tab shows which one is used (`WalletController.protection`).

   `WalletController.wallet` holds only the public side (`WalletId`). `unlock()` decrypts the key for one use, **asking every time**: each signature (Compose, and funding invitations as one batch), **Show seed** and **Remove wallet**. The user chose that over an unlock window; nothing may keep it unlocked.
   - **Remove wallet** falls back to a plain destructive confirmation when it can't unlock, so a forgotten passphrase can still be replaced from the seed backup.
   - **Earlier plaintext seeds** (`murmur_wallet_seed`) move into the vault at the next unlock.
   - **The seed is never offered to other apps:** copy only, no share. Invitation cards' keys are separate small wallets, kept in secure storage, and not vaulted.
5. **Check before showing.** Every header is checked fully: link, proof of work, median-time-past, retarget, and `history_root`. Everything shown is proven against checked headers:
   - state proofs against `state_root`;
   - filters against `filter_hash`;
   - blocks against `merkle_root` and `filter_hash`;
   - transactions against merkle branches;
   - content against its hash and length.

   Two things can't be checked, and are shown as the node's word: `Fees`, and `TxStatus`.
6. **Byte-exact encodings.** Hash preimages are little-endian, wire integers big-endian, both exactly as in the Rust core. A node penalizes malformed messages. Any change to hashing or encoding needs a PROTOCOL.md test vector in `test/protocol_test.dart`.
7. **Web integers are JavaScript doubles:**
   - `<<` and `>>` wrap at 32 bits;
   - `ByteData` has no 64-bit accessors;
   - integers are exact only up to 2^53.

   So use `~/`, `*` and `%` for anything past 32 bits, `ByteWriter.u64` and `ByteReader.u64` for u64, and `BigInt` for u128 (targets, work). Past bugs: `1 << 40` became 0, which froze a timer, and a 64-bit shift broke the subsidy.
8. **No user-facing text in Dart.** Strings live in `lib/l10n/app_*.arb`, in ICU format with plurals. Arabic has six plural forms. The client layer returns codes (`LinkError`, `TxProblem`, `TxStatusCode`), and `lib/ui/l10n.dart` words them. A new key goes into **all nine** ARB files. Format numbers with `formatAmount`, times with `formatTime`, `formatClock` and `formatElapsed`, and never with `toString()` in the UI.
   - **Emphasis:** in explanations, `**key words**` in an ARB string show in bold copper (`Emphasized` in `ui/common.dart`). Each language marks its own key words, and translations keep the markers.
   - **Structure over paragraphs:** the user asked for no big blocks of text. Explain with short points, each an icon plus one emphasized line (`InfoPoint`), as in the fee card, the Invitations page and the Public name dialog. Fold details that only some want (the fee card's "Why this fee").
   - **Copper is the only accent colour.** A second colour (teal and others) was tried and rejected by the user.
9. **Salt every message.** Content is `salt(16) ‖ message`, from `Random.secure()`. The salt is never shown (`messageOf`).
10. **Keep the legal posture.** Nowhere in the app, the docs or the ARB files: token prices, value in money, returns, or buying. The testnet line says only that the tokens are for testing, in every language (`testnetLabel`).

## Architecture

```
lib/
  protocol/   pure Dart, no Flutter: bytes, models (tx, header, block), wire codec (tags 0–23),
              commitments (state tree, block filter, header-history MMR), consensus (MTP, LWMA retarget),
              header_chain (headers packed in memory),
              network parameters and checkpoints, alias messages (Section 7.8), invitation codes
  crypto/     Ed25519 wallet; address = SHA-256(public key)
  services/   node_client (everything stateful), secure_channel (X25519 + HKDF + ChaCha20-Poly1305),
              transport_{io,web} (TCP, or WebSocket), chain_cache_{io,web} (files, or IndexedDB),
              fees, threads (reply/flag rules of Section 2.4), aliases (resolving, Section 7.8),
              activity (filter classifiers), storage
  ui/         tabs (threads, messages, wallet, chain), detail pages, compose, paged list, brand, glyphs, l10n
  l10n/       app_<lang>.arb (source) and the generated app_localizations*.dart (committed; CI checks
              they match the ARB files, so run `flutter gen-l10n` or `flutter pub get` after editing an ARB)
test/         protocol vectors, network (checkpoint form, address fallback, WebSocket URL), thread rules,
              aliases (Section 7.8 vector, validation, resolving), widget tests, node tests (the real node on
              generated demo chains, support/), read-only checks of a public node
tool/         ws_bridge (WebSocket to TCP relay), serve_web, fetch_fallback_fonts (+ the fonts' OFL), render_brand,
              bundle_node + node_release (the pinned murmur-node release, for desktop builds and tests),
              refresh_checkpoint + check_checkpoint (the testnet checkpoint, from and against the live network),
              prepare_release (the scheduled release's version and changelog section),
              package_desktop (the Windows and Linux apps as archives, for the release),
              linux_smoke_test.sh (the built Linux app and its node, without a screen)
web/          index.html, flutter_bootstrap.js (loader config: local fallback fonts), manifest, icons
```

### `MurmurClient` (lib/services/node_client.dart)

One connection to one node.
- **Connecting** (`_handshake`): a try counts only once the node is through the key exchange and has sent a Hello for this protocol version (`protocolVersion`). A node that fails anywhere before that is passed over for the name's next address: unreachable, dropping the connection, silent, or on another version. Natively the client picks untried addresses itself. On the web the browser picks, and keeps reusing the same address, so the 3 tries there only help with passing failures (see the web limit under Known gaps).
- **Reconnecting** (`_fail`, `retryAt`): after a failure retrying can fix (unreachable, closed, timeout, a tampered frame), the client connects again by itself, waiting 2 s, then 4, 8… up to a minute. The wait resets once live, and the banner counts it down. Everything fetched and checked is kept. A version mismatch, a checkpoint mismatch or a state-root mismatch is not retried, and neither is anything after the user's Disconnect.
- **Native** (`transport_io.dart`): the client dials a `host:port`. A name is resolved, and every address it returns is tried in random order (`connectFirst`), so a DNS seed works as the node. `resolveOverride` replaces DNS in tests.
- **Web** (`transport_web.dart`): the client uses `wss://` on port 443 or on an HTTPS page, and `ws://` otherwise (the local bridge).
- **Defaults:** without `--dart-define=MURMUR_NODE_HOST` and `MURMUR_NODE_PORT`, the default node is `127.0.0.1`; testnet builds set the public ones (README).

It's a `ChangeNotifier` that the UI rebuilds from (`AppBuilder`). The client handshakes with zero work and `listen_port` 0, so the node never syncs from it and never gossips its address.

**The worker.** `_work` runs one request at a time. Each `_step` does the most useful thing left, in this order:
1. header sync;
2. state proofs for watched keys;
3. message content for everything already fetched, newest first (`_missingContent`), so each batch of blocks is followed by its text and lists fill in while older blocks still arrive;
4. blocks a page, or a filter match, asked for;
5. settling own pending transactions, and GetTx for wanted txids;
6. the newest stretch of blocks a list needs;
7. back-filling headers to genesis (after a checkpoint start);
8. the filter scan for watched items;
9. one prefetch batch;
10. with a cache only, the rest of the chain, oldest first.

When nothing is left, it waits. `_wake()` resumes it: views call things like `requestOlder`, `requestTx`, `requestBlock`, `watchAddress` and `account(...)`, which only record what they want and wake the worker. **Views never await the network.** Each request type has a single waiter (`_headersWaiter`, `_stateWaiter`, and so on), so two concurrent requests of the same type would clash. `feeInfo()` is the only request made from outside the worker, and it shares one in-flight future for that reason.

**Heights and indexes:**
- `_headers[i]` is height `i + 1`. It's packed (`HeaderChain`): `_headers[i]` rebuilds a `BlockHeader`, so loops over many heights read fields instead (`_headers.prevHashAt(h - 1)`, `minedBy`, `hashIs`).
- `_low` is the lowest known header: 1, or near the checkpoint until back-filled. Below it, entries are null. Use `_hdr(h)` only for `h >= _low`, and `headerAt(h)` otherwise.
- `_blocks` is aligned with `_headers`; null means not fetched.
- `_top..height` is the fetched newest stretch.
- Blocks `1.._counted` have been replayed into `_balances`, `_nonces`, `_byAddress` and the rest. This happens only with a cache, and gives history rows their before/after balances and the state-root self-check (`_checkStateRoot`).

**Proven state.** `account()`, `provenPool`, `provenIssued` and `provenFlagged()` return proven values, or null until the proof arrives. Calling them also watches the key, so it's re-proven at each new tip. Balances and nonces come from proofs, never from counting, unless the whole chain is counted.

**Filters.** `watchAddress` and `watchThread` add items. `_scanFilters` downloads filters (1000 per request), checks each against its header, and queues matching blocks. `historyPending(address)` says whether a matching block is still unfetched. `activityOf` yields history newest first, and stops at the first block that may match but isn't fetched yet.

**Checkpoint start** (Section 7.7). Only when the network or the constructor has a checkpoint and nothing is cached:
1. Fetch the checkpoint block.
2. Fetch the 90 headers before it, with GetHeaderProof, checked by linkage.
3. Take the history peaks through it.
4. Check every header after it fully.
5. `_backfillHeaders` checks from genesis up in the background, and must join `_low` exactly; otherwise `checkpointMismatch` stops the client. With a local copy, each batch it checks is stored (`_flushCache`, as a header chain from genesis that stops short of the checkpoint), so a later session starts from the checkpoint again and resumes the back-fill after those headers (`_resumeBackfill`). Stored headers that don't lead to the checkpoint are dropped and the back-fill starts over from genesis (`_restartBackfill`), rather than blaming the checkpoint.

A branch that would replace the checkpoint's block is refused. A cached chain that doesn't contain the checkpoint is ignored. The testnet ships one (`network.dart`, refreshed with every release); the demo network can't, since every demo chain is different.

**Sending.** `checkTransaction` applies consensus rules, the proven balance and Section 2.4's rules. `submit`:
1. salts the content;
2. signs with `nextNonce`: the proven nonce, plus own transactions the proof doesn't count yet, in contiguous nonce order: pending ones, and those mined above the block the proof is from (`_notYetProven`; a proof lags a new block, and without them a reply sent right after one's thread is mined would reuse its nonce);
3. sends SubmitTx;
4. keeps the transaction in `_pending` (mine: true).

A TxStatus of invalid or refused takes the transaction out of nonce and balance accounting (`_inPlay`). Once the proven nonce passes an own pending transaction, `_settleOwnPending` asks for it by id: on the chain, it becomes a proven transaction; unknown, it was replaced and is dropped. On a reorganization, own transactions in the dropped blocks become pending again.

**Composing** (`ui/compose_page.dart`). Each entry point fixes the kind; there's no switch on the page:
- **New thread:** the Threads tab's button. Only that tab has it.
- **New transaction:** the Wallet tab's button, once there's a wallet. Also **Send** on an address's page.
- **Reply and Flag:** from a message.

**Sign and send**, or Ctrl+Enter (Cmd+Enter on Apple), follows the same steps:
1. the form is validated;
2. `checkTransaction`, so what can't be sent is said before anything else;
3. `_SendSummary`, a full summary as the final confirmation (the user asked for it). It rebuilds with the client: the balance and what's left follow new blocks and transactions, and the same check runs again. If sending stops being possible, it shows why and disables signing. `_confirming` changes through `setState`, so the page's button comes back after the summary closes;
4. `unlockWallet`;
5. `submit`, with exactly the values the summary showed.

**Threads tab.** It shows a snapshot: `threads(upTo: height)` fixes the order at one block. Own sent messages are always included. A new snapshot is taken on Refresh, when the tab comes into view (`refreshToken`), and when returning from a pushed page (`RouteAware.didPopNext`). Message text is read live (`messageOrUnavailable`), because content arrives after the list.

**The user's own view** (`Preferences`, all on the device, never sent):
- **Thread languages:** detected by `services/language.dart`. The script settles Arabic, Japanese and Chinese; Latin-script text is scored by common words and telltale letters. Short, mixed or other-language text is "undetected" rather than guessed. Detection is by the thread's first message, cached per txid.
- **The Threads filter:** by default it shows the device's languages plus undetected. It also hides muted authors and, optionally, threads this wallet flagged (`flaggedKnown`: fetched blocks and pending only, never a state proof per row). That option covers the user's own threads too; otherwise their own threads show whatever the language. The header counts what's hidden.
- **Withdrawn messages:** a message whose author flagged it (`selfFlagged`, from `MessageIndex.isSelfFlagged`) is withdrawn.
  - **Its text is deleted here**, on every device, the author's included: `_withdraw` in `node_client.dart`, triggered when a fetched block holds the author's flag, whether the flag or the message was fetched first. The content goes from memory and from the local copy (`ChainCache.removeContents`), `_withdrawnContent` keeps it from being fetched again, and views show `contentWithdrawn`. The user decided this: a retracted message isn't displayed or served by any Murmur client. Pending flags don't count until mined.
  - Nobody but its author sees it listed, and it isn't counted as hidden, since hiding it wasn't the reader's choice.
  - The author sees the thread faded and without its text (`threadWithdrawnMine`), unless they hide flagged threads.
  - Its thread page, reached by a link, says so and shows it faded.
  - Flagging one's own message says what it does (`flagOwnInfo`).
  - This is the user's design for the app, not a consensus rule; the node decides for itself what content to keep.
- **Names and pictures:** `ui/people.dart`. `nameOf` gives, in order, the local name, the published alias shown as "bob · 3fa9c21e" (`publicNameOf`), then the short hex. Use it wherever an address is shown. `AddressAvatar` (`AddressMarkPainter`) draws a mark from the address bytes, so it looks the same on every device:
  - a zigzag of five to seven nodes in the logo's style. It is not mirrored, on purpose: a mirrored mark was only half unique, and the user asked for more variety while keeping the rune-like look;
  - details: filled ends (some with an eye), rings (some with a seed), one doubled "heart" ring, beads on some segments, and up to two stems ending in a dot or a diamond;
  - four colours, as the user asked: the line shades between two of one family, and rings and accents take two of the other. The families are the copper-family warm colours and their cool complements (`_warm`, `_cool`);
  - a tinted tile with two ripples and a faint echo of the path (only at 32 px and up).

  The user asked for this over the earlier 5×5 pixel grid, which broke the app's style. `flutter test tool/render_brand.dart` previews them in `build/brand_preview.png`.
- **Published aliases** (PROTOCOL.md Section 7.8, a client convention).
  - **Format:** `protocol/alias.dart` encodes, parses and validates the 71-byte alias message: prefix, UTF-8, forbidden code points, edge spaces. It's tested with the spec's `bob` vector in `alias_test.dart`.
  - **Candidates:** `MessageIndex.aliasCandidatesOf` lists an address's mined Orphans with `content_size` 87, latest first.
  - **Resolving:** `services/aliases.dart` (`resolveAlias`), through `MurmurClient.publishedAlias`, cached per data version. The rule that matters is never to show a replaced alias. So:
    - the latest candidate decides;
    - it's trusted only if no block from the tip down to it (its own included) is unfetched while it could hold one of the address's transactions (filter matches, or isn't known);
    - content that's missing means no known alias, never the older one.

    The address then shows as hex until it's known, which is the safe side.
  - **Coverage:** resolution covers what's fetched. The wallet's own address and any open address page are watched, so they resolve. Authors in lists resolve when their blocks are among those fetched. Don't watch every displayed author: watching fetches every block touching the address, and for a miner that's every block it mined.
  - **Setting one:** Wallet tab → **Public name** (`_PublicName`). The name is checked with `aliasProblem`, then sent through `ComposePage(alias:)`: same fee card, check, summary and unlock. An empty name clears it.
  - **Not text** (Section 2.4: a message whose first byte is `0x00`, such as an alias):
    - it's never a thread (`MessageIndex` skips known ones, and the Threads tab checks `isNonText` live, since content arrives after the snapshot);
    - it's never replied to (Reply buttons are hidden), and a Reply to one is a payment;
    - it's shown as "Public name: bob" or "(not text…)" (`messageText`).
- **Muted addresses:** hidden in Threads, in thread pages (with a count) and in Messages. Wallet history still shows them: money movements are never hidden.
- **The new-reply badge:** counts replies to the wallet newer than `messagesSeen[address]`. It starts at "now" for a new wallet, and moves forward while the Messages tab is open.
- **Search:** only over what's loaded (thread text, replies, author names). A full-text search of the chain isn't something a light client can keep up with.

**Invitations** (`protocol/invite.dart`, `services/invitations.dart`, `ui/invitations_page.dart`, `ui/claim_page.dart`). A card is a wallet of its own. No protocol change is involved.
- **Making cards:** the inviter funds each card with a plain transfer: five threads at today's suggested fee for a 280-byte message, plus a claim fee. The card keys go into secure storage (`InviteStore`) before any funding is sent.
- **Claiming:** the newcomer's app (`#/invite/<code>`, or "I have an invitation") creates a wallet if needed, then moves the card's whole balance to it in one Raw transfer. The fee comes out of the card, so the newcomer spends nothing.
- **Cancelling:** the inviter can cancel a card at any time, after confirming. It's the same sweep, signed with the card's own key, so it can send anywhere. The destination (`_CancelDialog`, `ReturnTo`):
  - when every selected card was funded by the wallet here now, the tokens go back there and nothing more is asked;
  - otherwise the dialog asks, as the user wanted: back to the wallet that funded each card (`funderOf`), or to the wallet here now.

  Each option is disabled while it has no address: a funder still being looked up on the chain, or no wallet on the device. With no wallet here, a card can still be cancelled back to its funder.
- **No expiry, on purpose.** The chain has no time locks, so a date on a card would only be an app convention that another app could ignore. The user rejected that illusion of enforcement. A card works until it's claimed or cancelled; don't reintroduce an expiry without a protocol-level time lock.
- **The code:** Crockford base32 of `version(2) ‖ genesis[0..4] ‖ seed:32 ‖ sha256[0..4]`, 66 characters. Version-1 codes, which had a 2-byte expiry day after the network, still parse, with the day ignored. Typing is forgiven: case, dashes, O/0, I/L/1.
- **Status comes from the card's proven balance:** waiting, claimed, cancelled. "Invited by" is whoever funded the card, found through its filter.
- **One view** (the user asked for it; no separate cards page). It's a list of cards with checkboxes and select-all. **Print** (web) and **Cancel invitation** act on the selected cards, with one confirmation for Cancel. Each row has the card's account picture, its state and amount (with `Glyph.coin`), a QR icon (`Glyph.qr`, not a miniature code) that shows the code large in a dialog over the list, with the typed code, and a copy-link button. Claimed and cancelled cards fold into a second, collapsible "Claimed or cancelled (n)" list. Tapping one of those opens its details (`_InviteDetails`), read from the card's history through its filter:
  - when it was funded, and how much;
  - who claimed it (their picture and name, which open their page) and when, with what they received;
  - or, if it went to this wallet, that it was cancelled, when, and what came back.
  - New cards come selected, ready to print, and only waiting cards can be selected. The cancel confirmation always states how many cards it cancels.
  - Amounts show a coin and the number in bold (`_Amount`). The create dialog shows "Each card" and "You pay" with their explanations in small print.
- **The printed card** (`cardSheet`): an 85×55 mm business card on the app's paper tone, with a copper band on the leading edge. It carries the logo and "Murmur", the slogan (`inviteCardSlogan`, never about money or value), a faded logo as a watermark, the QR code on white with "Scan to join", "From … · n of N", and the typed code (always left-to-right). `print-color-adjust: exact` keeps the colours when printing.
- **Printing** (web only): a self-contained HTML page with SVG QR codes (`package:qr`), opened from a blob URL. Native builds copy the links instead.
- **The name on the cards** (`_FromDialog`) is asked before every print. The cards stay on the device when the wallet changes, so the wallet here now may not be the one that funded them. The options:
  - the funding wallet's address, the name given to it on this device, or its public name;
  - the current wallet's address, name or public name, offered only when it differs from the funder;
  - any text, where empty leaves the "From" line out.

  A public name can be picked once it's known (`publishedAlias`; the dialog watches the funders so their history, and so their alias, is found). An option some selected card has no value for is disabled, with the reason. One that differs between cards says so, and prints each card's own. The last choice is offered first for the rest of the session. The funder is kept in `InviteRecord.funder`; older cards find it through `inviterOf`, the oldest transfer in.
- **A card is a bearer token**, and the chain publicly links inviter → card → newcomer. Both are said in the UI.

**Sharing** (`ui/share.dart`). Every link, address and hash has a `ShareButton` (`Glyph.share`) instead of a copy button.
- **Where the system has a real share sheet**, the button offers "Copy" and "Share…": Android, iOS and macOS through `share_plus`, and browsers with the Web Share API through `navigator.share`.
- **Elsewhere it simply copies.** That's Windows and Linux, where the plugin would fall back to a mail link, and Firefox on desktop.
- **The wallet seed** keeps a plain copy button on purpose: it must never be offered to other apps.

**Links:** `#/thread/<txid>` opens a thread over the home page (`onGenerateRoute` in `main.dart`, `threadInRoute`). An unknown root is asked for by id (GetTx). Native builds share `https://app.murmur.info/#/thread/<txid>`.

**Times:** lists show relative times (`formatAgo`: "5 min ago", the date after 30 days); detail pages show full ones (`formatTime`).

**Paging** (`ui/paged_list.dart`). A list shows a screenful plus one row, then ten more at the bottom. `fetch(n)` must be cheap for small `n`, since sources are lazy iterables over the chain. `loadingMore` plus `onNeedMore` pull older blocks.

**Cache** (`services/chain_cache*.dart`):
- Headers are saved only once they're known from genesis (`_low == 1`).
- Blocks and content are saved as they arrive.
- Everything is re-checked on load: link, PoW, history root, checkpoint, merkle root, filter, content hash.
- A cache from another network (by genesis hash) is dropped.

**The app's own node** (`services/local_node*.dart`, desktop only). The user asked for it: a desktop app can run a Murmur node, so the user validates the chain on their own machine and keeps their own messages available.
- `LocalNode` starts `murmur-node` (next to the executable, placed by `tool/bundle_node.dart`; `MURMUR_NODE_BIN` overrides it) as a child process, with the options in `localNodeArgs`:
  - `--port 127.0.0.1:0 --rpc-port 0`: local only, on free ports, so no firewall prompt and no clash with another node; the port is read from the node's startup line (`listeningPort`);
  - `--prune-content --prune-retracted --keep-author <wallet>`: it keeps nobody's content past the one-hour check except the user's own, and deletes withdrawn messages. The user wanted desktop users kept out of hosting other people's content; don't change these defaults unasked;
  - `--mine-to <wallet> --mine-cpu <n>` only when the user switches mining on.
- `LocalNodeLink` keeps it in line with the settings (`Preferences.runLocalNode`, `localNodeMining`, `localNodeCpu`) and the wallet. **Any change restarts the node** with new options: rule 1 still holds, so the app never uses its control port. While it runs, the client connects to it; when it's switched off, the client goes back to the user's chosen node.
- A pid file in its data folder lets a new session stop a node left running by a crashed one (only if that pid is still a `murmur-node`). The app stops the node on exit (`AppLifecycleListener`).
- The Chain tab's card (`_LocalNodeCard`) appears only when the binary is present.
- `test/local_node_test.dart` covers the options and port parsing offline, and with `MURMUR_NODE_BIN` runs a real demo node, syncs a client from it and stops it.

## Recipes

- **New protocol version:**
  1. Update `protocolVersion` and the codec in `wire.dart`.
  2. Update the models, and the network ids and genesis parameters in `network.dart` (genesis hashes are pinned in `protocol_test.dart`).
  3. Add PROTOCOL.md's vectors to `protocol_test.dart`.
  4. Raise `nodeRelease` in `tool/node_release.dart` to the node release that speaks it, run `dart run tool/bundle_node.dart --for-tests`, and run all the tests (Commands).
- **New wire message:** add the class and its encoder and decoder in `wire.dart`, and enforce its limits while decoding. Add a round trip to `protocol_test.dart`'s "messages have the node layout". Handle it in `MurmurClient._handle`: every tag must appear there, since the switch is exhaustive over a sealed class.
- **Every release refreshes the checkpoint** of each public network (not the demo network, whose chains are all different). A first session checks every header after the checkpoint before showing anything: a two-month-old checkpoint on the testnet means about 170,000 headers. The checkpoint must come from the release, never from a node or the user: a node could hand the client a fake chain's block, and the user only chooses nodes. A newer release's checkpoint that isn't in a user's local copy makes the client drop the copy and start over from it.
- **Shipping a checkpoint:** `flutter test tool/refresh_checkpoint.dart` rewrites the testnet's `checkpoint:` line in `network.dart` from the live network, without taking a node's word (`tool/checkpoint/live.dart`): every address behind `testnet-seed.murmur.info` is asked separately, by a client that starts from the checkpoint shipped now (so the chain must hold it) and checks every header back to genesis, and at least two must answer and all agree. It picks a round height a day below the lowest tip. Review and commit the one-line change (the scheduled release, below, commits it by itself once the tests pass); never write a checkpoint by hand, except a network's first, which comes from `murmur-node ctl checkpoint <height>` on a node you trust. The release job runs `tool/check_checkpoint.dart`, which stops a release whose checkpoint isn't on the live chain or is over a week old. `network_test.dart` checks its form and that it lies above the retarget window.
- **Making a release by hand** (the user asked for it to work like the node's):
  1. Refresh the checkpoint: `flutter test tool/refresh_checkpoint.dart`, and review its one-line change.
  2. Raise `version:` in `pubspec.yaml`.
  3. Move CHANGELOG.md's "Unreleased" notes under `## vX.Y.Z: <summary> (<date>)`.
  4. Commit, then push the tag `vX.Y.Z`.

  The pipeline (`.on-release-tag` in `.gitlab-ci.yml`) checks the shipped checkpoint against the live network (`check-checkpoint`), runs the bounded public-node test against the testnet (`public-node-tests`), refuses a tag that doesn't match the version, builds the testnet page and the desktop apps (`build-windows` on GitLab's Windows runner, `build-linux` after `tool/linux_smoke_test.sh` passes: the app, the pinned node, the notices and on Windows the Visual C++ runtime, archived by `tool/package_desktop.dart`; both allowed to fail, so they never hold back the page), packages them with one `SHA256SUMS` to the package registry (`murmur-web`, `murmur-client-windows`, `murmur-client-linux`), deploys the page to Cloudflare Pages, and creates the GitLab Release. Commits never deploy. `v*` tags must stay protected, since the Cloudflare variables are protected. Keep CHANGELOG.md up to date with every change users notice, except the topics the user keeps out of the docs.
- **The scheduled release** (the user asked for it: no flags, no waiting branch, nobody in the loop). A scheduled pipeline holds one job, `scheduled-release`, and the usual checks leave themselves out of it (`.checks`, `workflow`). In order: `tool/refresh_checkpoint.dart`; if the checkpoint changed, the generated localizations, the analyzer and every test on that change; `tool/prepare_release.dart` (the next patch version, and the CHANGELOG section, taking the "Unreleased" notes along: `tool/release/notes.dart`, tested in `release_notes_test.dart`); then the commit to the default branch (unforced, with `ci.skip`) and its tag, which releases as any other. With a checkpoint under a day old it ends without a release, and a failure leaves nothing pushed. It needs `RELEASE_BOT_TOKEN`, a Maintainer project access token (README, "Releases and deployment"). So **the default branch must stay releasable**: whatever is on it goes out with the next scheduled release, unreviewed. Deactivating the schedule stops it.
- **When mainnet launches** (the user asked for this list; today everything public is the testnet's). The node project decides the network's id and parameters; take them from its PROTOCOL.md Section 6.
  1. **The network:** add it to `NetworkInfo` in `network.dart` (and to `all`), pin its genesis hash in `protocol_test.dart`, and take its first checkpoint from `murmur-node ctl checkpoint` on a node the project trusts. `isTestnet` and the testing-only line (`testnetLabel`, rule 10) must stay off for it, and on for the testnet.
  2. **The checkpoint tools** know one network and one checkpoint line: `tool/checkpoint/live.dart` (`network`, `defaultNodes`), the single-line pattern in `refresh_checkpoint.dart` and `tool/release/notes.dart` (`shippedCheckpoint`), and the "testnet checkpoint" wording in `withRelease`. Make them work per network: its own seed name, its own line, each refreshed and checked.
  3. **The release pipeline** builds one page, for the testnet (`build-web-testnet`: `node.murmur.info`, deployed to `app.murmur.info`, packaged as `murmur-web`), `check-checkpoint` and `scheduled-release` cover the testnet's checkpoint only, and `public-node-tests` names the testnet's seed. Decide which network the main page serves, where the other lives, and build, check, package and deploy each.
  4. **The scheduled release** publishes the default branch unreviewed. Decide whether that still suits a network whose tokens aren't for testing, or whether mainnet releases need a person.
  5. **The public-node tests:** `live_node_test.dart` and its documented command name the testnet's seed; run the read-only checks against mainnet's nodes too. Sending stays on chains the tests build themselves: never send on a public network from tests without the user asking.
  6. **The docs and defaults:** README's build commands and node names, the default node of release builds, and `tool/header_bench` (it generates a chain with the testnet's parameters).
- **New language:**
  1. Copy `app_en.arb` to `app_<code>.arb` and translate the values; keep the placeholders and ICU plural forms.
  2. Add the code to `languageNames` in `lib/ui/l10n.dart`.
  3. Run `flutter pub get`.

  `ui_test.dart` builds every language.
- **New text:** add the key, with an `@key` description and placeholders, to `app_en.arb`, then to the eight others. Use it as `context.l10n.key`.
- **New icon:** add it to `Glyph` in `ui/glyphs.dart`, drawn in the logo's node-and-line style. Glyphs that point sideways mirror in right-to-left locales. The fee is a pickaxe and the burn a flame. A "miner head" glyph was tried and rejected; don't reintroduce it unasked.

## Style

- Comments say why, in plain sentences, and name the PROTOCOL.md section they follow. Public members have doc comments. Match the density of the surrounding code.
- Keep `lib/protocol/` free of Flutter imports, so it stays testable and reusable.
- Keep `flutter analyze` clean (`flutter_lints`). Don't add dependencies without a good reason: the client's security depends on how little it pulls in.

## Security model, briefly

- Transport: encrypted and integrity-protected (BIP 324-like), but **peers aren't authenticated**. A man in the middle can't forge chain data, since everything is proven against checked headers and proof of work. It can withhold data, show an older chain, or learn which accounts the client asks about.
- Filters don't reveal what the client watches. `GetState` does name the account.
- `tipLooksOld` shows a banner when the tip is more than 20 block intervals old.
- Defences still missing: several nodes (gap 1 below), and node identity pinning for a trusted node.

## Known gaps and next steps

1. **One node only.** Section 7.7 recommends at least three, from different sources, following the heaviest valid chain and retrying requests elsewhere. `MurmurClient` would need a node pool, and a way to route each request.
2. **Little peer discovery.** Natively, a seed name such as `testnet-seed.murmur.info` works as the node: every address it resolves to is tried, through the handshake, and a lost link reconnects by itself (possibly to another of them). There's no `Addr` handling. Browsers can reach only nodes with `--ws-port`, behind TLS for `wss://`.
   - **Web limit, accepted:** in a browser, page code can't see a name's addresses or choose among them. The browser resolves the name, caches the answer, and reuses the same address. It moves on from an address that refuses or doesn't answer, but not from one that accepts the connection and then fails TLS.
   - A web client can't get past such a node by itself. Measured: 72 retries against `node.murmur.info` all went to the same broken address, while the native client reached all three nodes. `node.murmur.info` includes broken nodes on purpose, to test this.
   - **Rejected workarounds:** DNS over HTTPS (a third party), connecting by IP (TLS rejects it), per-node names (the network keeps one name). Don't reintroduce them unasked.
3. **The testnet checkpoint ages.** A first session checks every header after it before lists show (about 3,000 a second in a browser), and the gap grows by 2,880 a day, so every release refreshes it (Recipes), and the release job refuses one over a week old. Its trust rests on the chain of checkpoints back to the first, and on the testnet's nodes agreeing when it's refreshed: they're all behind one name, run by the project. Checkpoints come only with releases; users choose nodes, never checkpoints, and a running client never takes one from a node.
4. **Headers in memory: packed; the filter maps aren't.** `_headers` and `_backfill` are `HeaderChain`s (`lib/protocol/header_chain.dart`): 264 bytes a header (wire bytes plus hash) in one byte array, with the last 1,024 used kept as objects. Long loops read fields from the bytes (`prevHashAt`, `minerAt`, `hashIs`…). Measured with `tool/header_bench.dart` on 100,000 valid testnet headers (2026-10-04, `check` against `packed`):
   - **Memory in a browser** (headless Edge): about 376 bytes a header packed, spare capacity included, against 1,500 as objects. A year of testnet (about 1.05 million headers) is about 400 MB rather than 1.5 GB.
   - **Checking:** about 360 µs a header in a browser and 165 µs in the Dart VM, decoding included (11 to 17% slower than checking objects already decoded).
   - **Rollbacks** rebuild the header history from a copy kept every 1,024 heights (`_historyMarks`, the last 16), not from genesis: rebuilt headers compute their work again.
   - **The local copy loads packed too:** the stores hand over headers as they decode them (`storedHeaders`), and `_loadCache` checks and packs each in turn.
   - **Still to do:** the per-height filter maps (`_filters`, `_filterTested`) hold an entry per block scanned, and aren't packed.
5. **Flags received aren't found.** An address's history is found through filters, which index `from`, `to` and `reference`. Flags against the address's messages reference the message's txid, not the address. They show only if the flagged messages are watched: a thread page is open, or the chain is counted.
6. **No node release for macOS.** The node publishes Linux (x86_64, arm64) and Windows builds only, so on a Mac the node tests need `MURMUR_NODE_BIN` pointing at a node built from `../murmur`, and the macOS desktop build can't bundle a release (gap 9). The chains `demo-chain` builds have empty blocks: a test that needs transactions on the chain before it starts sends them and lets the node mine them.
7. **The phones' storage path isn't tried on a device.** On Android and iOS the local copy goes under the app's cache folder (`path_provider`'s `getApplicationCacheDirectory`, in `chainCacheBase`): not the support folder, which device backups include, since the copy never leaves the device. The system may clear it when storage runs short, and the copy is then downloaded again. An earlier copy in the temp folder is moved along. Only the choice of folder is unit-tested; a build on a phone should confirm it.
8. **Transaction signatures in blocks aren't checked.** Merkle roots, filters and PoW are. A block's validity rests on the proof-of-work majority.
9. **The app's own node works in built Windows and Linux apps; macOS isn't tried.** Checked with release builds and the pinned node beside them (2026-10-05, `--dart-define=MURMUR_LOCAL_NODE_SPEC=demo`), on Windows 11 and on Ubuntu 24.04 (WSL): the node starts as the app's child with `localNodeArgs` (no console window on Windows), the client goes live through it, and closing the window stops it. On Windows, after the app is killed the next start stops the node left behind and starts a new one; that's not tried on Linux. `tool/linux_smoke_test.sh` repeats the Linux check without a screen, and the release job runs it. Still open:
   - **Linux with a locked keyring that can't ask hangs the app before it shows anything.** The wallet's storage plugin (`flutter_secure_storage`) calls the keyring on the app's main thread and waits. A desktop unlocks the keyring at login, and with no session bus at all the call fails at once and the app starts; a session bus whose keyring is locked and has no prompter (some minimal setups, a bare WSL session) leaves the app frozen and invisible. Not fixed. What saving a wallet does with no keyring at all isn't tried either, nor the app on a real Linux desktop (fonts, window decorations, the launcher icon: the window's icon is set from `data/app_icon.png`, which Wayland desktops ignore in favour of a `.desktop` entry the archive doesn't install).
   - **macOS** isn't tried, and there's no published macOS node binary (`tool/bundle_node.dart --from` a self-built one).
   - **The desktop apps' identity.** `windows/` and `linux/` are committed. What the user sees is "Murmur" (the window title; on Windows also `FileDescription` and `ProductName` in `Runner.rc`, shown in Task Manager and the file's properties); technical names keep the package's (`murmur_client`, `murmur_client.exe`), as the user asked: `murmur-client`, `murmur_client` or `MurmurClient` by each convention, never shortened. The company is "Murmur Association", and the application identifier `info.murmur.client` (Linux's `APPLICATION_ID`). Both carry the app's icon (`tool/render_brand.dart` writes `app_icon.ico` and `app_icon.png`). Settings live under `%APPDATA%\Murmur Association\Murmur` on Windows (`CompanyName` and `ProductName` decide it) and `~/.local/share/info.murmur.client` on Linux (the identifier decides it): changing those moves the settings. macOS, Android and iOS folders are still generated per machine with Flutter's defaults; before their builds are given to anyone, commit them too with the same names, identifier and icon.
   - **Building on Windows** needs Developer Mode (plugins need symlinks; `start ms-settings:developers`) and Visual Studio's "Desktop development with C++" workload (Flutter builds through CMake). `flutter create` for a platform also edits `.metadata` and `pubspec.lock` and adds a sample `test/widget_test.dart`: don't commit those. After changing `BINARY_NAME` or other CMake settings, delete `build/windows` before building.
   - **Building on Linux** needs `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev` and a C++ standard library (`g++`); the smoke test also `xvfb openbox wmctrl dbus-x11 gnome-keyring` and Mesa's software renderer (`libgl1-mesa-dri libegl1 libgles2`). From a Windows checkout, build in a copy on the Linux side (WSL: `rsync` to `~/murmur-client`), not under `/mnt/c`.
