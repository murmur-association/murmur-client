# Murmur client

A Flutter light client for the Murmur chain, speaking **protocol 10** (networks `murmur-demo-9` and `murmur-testnet-9`, which keep their names). The node, the whitepaper and the protocol specification live in the [murmur repository](https://gitlab.com/elc4no/murmur); section numbers below refer to its [PROTOCOL.md](https://gitlab.com/elc4no/murmur/-/blob/main/PROTOCOL.md). With the client you can:

- read threads and their replies, newest activity first, with reply and flag counts;
- browse blocks, transactions and addresses, and search by height, txid, block hash or address;
- keep a wallet, and sign and send threads (Orphans), Replies, transfers (Raw) and Flags;
- use it in English, Spanish, Italian, Portuguese, German, Dutch, Arabic, Chinese or Japanese.

## The four tabs

- **Threads:** every thread, most recently active first, as of one block. The order stays put while new blocks arrive, so the list can be read; **Refresh** takes a new snapshot at the tip and goes back to the top. The header says which block the list is from and how many blocks have come since.
  - **Filters:** a search box covers the threads already loaded, including their replies and authors' names. The filter menu picks languages and whether to hide threads you flagged, your own included.
  - **Withdrawn messages:** flagging your own message withdraws it. Nobody else sees it listed any more, the app deletes its text from every device that has it (this one included) and never fetches it again, and nodes may stop keeping it and its replies. You still see a withdrawn thread in your list, faded and without its text, unless you hide flagged threads.
  - **New thread:** the button at the bottom starts one.
  - **Languages** are detected on the device from each thread's text. By default the list shows your device's languages, plus text too short to tell. The header counts what's hidden.
- **Messages:** the wallet's own messages, newest first, following new blocks: threads it started, replies it sent or received, and flags it raised or received. Filter chips choose which; flags are off by default. Plain transfers aren't messages and live in the Wallet tab. A badge on the tab counts new replies to you.

**People.**
- Every address has a small picture drawn from it, the same on every device: a zigzag of nodes and lines like the logo's, with its own details and four colours.
- On an address's page you can give it a name, which then replaces the hex everywhere in the app.
- **Public names** (PROTOCOL.md Section 7.8). An address can publish a name for itself, which apps show as `bob · 3fa9c21e`, always with the start of the address, since anyone can publish any name. Set yours in **Wallet → Public name**. It costs as much as a new thread, and leaving it empty clears it. A name you gave an address yourself comes first. The app shows a public name only once it can tell it's the latest one, so a replaced name never comes back.
- You can also mute it: its threads and replies are hidden, though payments still show in the wallet.
- Names and mutes are kept on this device only.

**Invitations.** A newcomer can join without buying anything.
- **Making cards:** in **Wallet → Invitations**, choose how many cards to make. Each holds enough for five threads at today's fee, plus the fee to claim it; you pay that and the funding fees.
- **The cards:** the Invitations page lists your cards, each with its picture, state, a small QR code (tap it to see it large, with the typed code) and a copy-link button. Tick cards to **Print** them (in the browser, as 85×55 mm cards) or **Cancel** them. Before printing, you choose the name the cards show: the address or name of the wallet that funded them, those of the wallet on the device now, or your own text.
- **Claiming:** scanning a card, opening its link, or entering the code under "I have an invitation" creates the newcomer's wallet and moves the card's tokens into it.
- **No expiry:** a card works until it's claimed. You can cancel an unclaimed card at any time, and its tokens come back to you. If the wallet on the device isn't the one that funded the card, you choose where they go: back to the funding wallet, or to this one. There's no expiry date, because the chain couldn't enforce one.
- **Keep them safe:** a card is like cash, and whoever claims it first gets it, so keep cards private (a scratch-off panel over the code helps). The chain shows who funded each card and which wallet claimed it.

**Links.** The copy button on a thread copies a link (`…/#/thread/<txid>`) that opens it directly.
- **Wallet:** balance, address, how the key is protected on this device, and the seed, then the history of token movements. A checkbox menu picks what the history shows: transfers sent and received (the default), what replies paid or earned, thread costs and flag fees. The **New transaction** button sends tokens.

**Sending.** **Sign and send**, or Ctrl+Enter (⌘ Enter on Apple devices), first shows a summary of everything that will be signed: type, sender, recipient, the message in full, weight, fee, burn or amount, total, and what's left. Only after that does the app unlock the key.
- **Chain:** the network, height, next reward, burn pool and supply, a search box, and every block, newest first.

Every list shows as many rows as fill the screen plus one, and ten more each time it's scrolled to the bottom, so it only ever builds what's on screen. Messages and Wallet find the wallet's transactions through block filters, so they fetch only the blocks that touch it. The filters are remembered.

## Languages

All text is in ARB files in `lib/l10n` (one per language, ICU message format with plurals), compiled by Flutter's `gen-l10n` into `AppLocalizations` on every build. Numbers use the language's digit grouping (1,234,567 in English, 1.234.567 in Spanish) and dates its format. Arabic is laid out right to left, and the arrow-like icons mirror. The language follows the system until one is picked from the globe menu in the top bar. The client itself returns error codes (`LinkError`, `TxProblem`) that the interface words, so no user-facing text lives outside the ARB files. To add a language, copy `app_en.arb` to `app_<code>.arb`, translate the values, and add the code to `languageNames` in `lib/ui/l10n.dart`.

## How it talks to the chain

The client connects to a node like a peer that has no blocks, and every connection is **encrypted** (PROTOCOL.md Section 7.4): an X25519 key exchange, then each message sealed with ChaCha20-Poly1305. Natively it dials the node's P2P port (`--port`, 7878 by default). In the browser it opens a WebSocket: to a node's own `--ws-port`, or to the local bridge. Nodes hold no keys, so the client signs everything itself, and it never uses the node's control port.

Every header is checked as a node checks it (Section 7.2): it links to its parent, meets its proof of work, is later than the median of the last 11 timestamps, carries the difficulty retarget's target, and commits to the header history before it (a Merkle Mountain Range whose nodes also carry work, times and targets, as in ZIP 221).

**Starting from a checkpoint** (Section 7.7): a network can ship a checkpoint (a height and block hash from `murmur-node ctl checkpoint`) in `lib/protocol/network.dart`. A first session then starts there instead of at genesis: it fetches the checkpoint block, the 90 headers before it (checked by their links back from it, and giving the retarget its context) and the header history through it (checked against its `history_root`), then checks everything after it fully. Usable within a second, whatever the chain's length. In the background it then fetches and checks every header from genesis up; they must lead to the checkpoint, or the client stops and says the release or every node reached is wrong. Neither network ships a checkpoint yet: every demo node mines its own chain, and there is no public testnet chain to take one from.

If the newest block is old for the network (about 20 block intervals), a banner says the node may be behind or cut off.

What it shows is checked against those headers, because every header commits to its block's transactions, its **filter** and the **state** after it (Section 3.6):

- **Balances, nonces, flags, the burn pool and the supply** come as state proofs (`GetState`) against the tip's `state_root`. They're exact at once, without the chain, and a node can't lie about them.
- **An address's history, and a thread's replies,** are found with block filters (`GetFilters`), each checked against its header's `filter_hash`. Only the blocks that match are fetched, and a node can't hide one. The node never learns which address the client looks for.
- **A transaction the client lacks** (a reply's parent, a flagged message, a page opened by id) comes by id (`GetTx`) with a merkle branch to its block.
- **Lists read newest first** (threads, blocks) fetch blocks newest first, as far as the screen needs, then their message content (`GetContent`), then one more batch.
- **Fees** come from the node's mempool (`GetFees`); if it doesn't answer, the client estimates from what it has seen.
- **Sending:** transactions are signed on the device with the sender's next **nonce** (proven, plus its own pending transactions) and submitted with `SubmitTx`. The node answers accepted, already known, invalid or refused (with its reason), shown on the transaction's page. The answer is advisory: the client still waits for the block.
- **Local copy:** with the user's consent (a banner on first visit, and a switch in the Chain tab), everything fetched is kept on the device: IndexedDB in the browser, files natively. With it, the client also fetches the rest of the chain once in the background and replays it. That gives every history row its balance before and after, and lets the client check the node's `state_root` against its own count; a mismatch is reported. Without it, nothing beyond what's needed is downloaded. Nothing is sent to anyone else; turning it off deletes it. The wallet seed and settings are always kept locally, since the app needs them to work.

The client rolls back on reorgs, follows the blocks and transactions the node relays, and sends a `Ping` every 60 s.

- **Message content:** blocks travel without content. The client takes it from relayed transactions and sync replies, and asks for the rest with `GetContent`. It keeps content only if its hash and length match the transaction. Any node may delete content, so an old message can show as "content not available".
- **Salted messages:** content is a 16-byte salt followed by the message (at most 1024 bytes), and the transaction's hash covers both, so once content is deleted its hash can't be matched against guesses of the text. The client draws a fresh salt from the platform's secure random source for every message, and never shows it.
- **Threads:** a Reply names its parent by transaction ID, and a Flag names the message it reports the same way. The client applies PROTOCOL.md §2.4: a reply belongs to a thread only if its parent is a mined thread or reply and the reply pays that message's author; a flag counts only against a thread or reply, once per address (proven with the state tree before flagging).
- **Thread cost:** a thread (Orphan) burns 10× its fee, so starting one costs 11× the fee. Burned tokens go to a burn pool that pays each block's miner `ceil(pool / K)`.
- **Fees** are per byte, and a transaction weighs 264 bytes plus its content, so the send form suggests a fee for the message you're writing.

The client doesn't check the signatures inside blocks, but everything it shows is tied to headers it checked fully (proof of work, time, retarget and history). Peers aren't authenticated by the transport, so connect to a node you trust; a TLS proxy in front of a node's `--ws-port` gives browsers `wss://`, which the client uses automatically on pages served over HTTPS.

A page opened with `?node=host:port` (for example `http://localhost:8080/?node=127.0.0.1:7880`) connects to that node or bridge.

## Running

The repo holds the Dart code (`lib/`, `test/`, `tool/`), the web shell (`web/`) and `pubspec.yaml`, but not the native platform folders. Generate them once:

```
flutter create . --platforms=windows,linux,macos,android,ios --project-name murmur_client
flutter pub get
flutter test
flutter run -d windows
```

`flutter create .` only adds missing files; it leaves `lib/` and `pubspec.yaml` alone.

Platform notes:

- **Android:** add `<uses-permission android:name="android.permission.INTERNET"/>` and `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` to `android/app/src/main/AndroidManifest.xml`. Make `MainActivity` extend `FlutterFragmentActivity`: the key store (`biometric_storage`) needs it. From the emulator, the host machine's node is at `10.0.2.2`.
- **iOS:** add `NSFaceIDUsageDescription` ("Confirm it's you before your wallet seed is shown") to `ios/Runner/Info.plist`.
- **macOS:** add `com.apple.security.network.client` = `true` to both `macos/Runner/*.entitlements` files.
- **Linux:** secure storage needs `libsecret-1-dev` to build.
- **Web:** browsers can't open raw TCP sockets, so the web build connects to a local WebSocket bridge (default `ws://127.0.0.1:7880`), and the bridge relays to the node:

  ```
  dart run tool/ws_bridge.dart --node 127.0.0.1:7878   # listens on 127.0.0.1:7880
  flutter run -d edge --web-port 8080                  # or -d chrome
  ```

  Debug mode's hot-reload connection can drop and end the session. For a stable page, build a release bundle and serve it: `flutter build web --no-web-resources-cdn`, then `dart run tool/fetch_fallback_fonts.dart` and `dart run tool/serve_web.dart`, then open http://localhost:8080.

  The bridge binds to localhost only, always dials the one configured node, and accepts only pages served from localhost.
- **Paths with an apostrophe** (such as `C:\Users\o'brien`) break `flutter test` and web builds, because Flutter pastes the path into generated Dart code. Work around it by mapping a drive letter: `subst M: "C:\Users\o'brien"`, then work from `M:\murmur-client` with `TEMP`/`TMP` set to `M:\AppData\Local\Temp`.

**Which node a fresh install uses:** `127.0.0.1:7878` natively and `127.0.0.1:7880` (the bridge) on the web, until the user picks another. Builds for the public testnet (`murmur-testnet-9`) set their own default:

```
# Web: the TLS proxy in front of node 1's WebSocket listener
flutter build web --release --no-web-resources-cdn --base-href / \
  --dart-define=MURMUR_NODE_HOST=node.murmur.info --dart-define=MURMUR_NODE_PORT=443
dart run tool/fetch_fallback_fonts.dart

# Native: the DNS seed, which lists every testnet node
flutter build windows --dart-define=MURMUR_NODE_HOST=testnet-seed.murmur.info --dart-define=MURMUR_NODE_PORT=7878
```

- **Web:** the client opens `wss://` on port 443, and on any page served over HTTPS; the URL is `wss://node.murmur.info:443/`.
- **Native:** the client resolves the name and tries each address in turn, in random order. It moves on from a node that doesn't answer, drops the connection, fails the encrypted handshake or runs another protocol version, so one bad node doesn't stop it.
- **Both:** when the connection is lost, or can't be made, the client tries again by itself, waiting 2 s, then 4, 8… up to a minute. The banner shows the countdown, and everything already downloaded is kept.

**Web: limits.** A web page can't see which addresses a name stands for, or choose among them: the browser does that. Browsers resolve `node.murmur.info` once, cache the answer, and keep using the same address.
- **A node that's down** (it refuses the connection or doesn't answer) is skipped: the browser tries the next address.
- **A node that accepts the connection and then fails TLS is not skipped.** The browser keeps returning to it, and the page shows "Could not reach the node" until the browser's DNS cache expires or the node is fixed. Retries and Reconnect reach the same node.

Nothing in the page can work around this without a third party, such as a DNS-over-HTTPS service. The native apps don't have this limit: they resolve the name themselves and try every address, through the handshake, until one works.
- **Testnet label:** while connected to a testnet, a line under the top bar says so ("Testnet: tokens have no value").

**No requests to other sites.** The page loads everything from its own origin, and its only other connection is the node. Two build steps make that true:
- `--no-web-resources-cdn` serves CanvasKit from the page instead of gstatic.com.
- `tool/fetch_fallback_fonts.dart` copies the Noto fonts the engine falls back to (Arabic, Chinese, Japanese, emoji, other scripts) into `build/web/fallback-fonts/`. That's about 20 MiB, of which a browser downloads only the slices on screen. `web/flutter_bootstrap.js` points the engine there instead of fonts.gstatic.com.

Without these steps the page still works, but fetches from Google's servers.

## Releases and deployment

The page is served at **app.murmur.info** by Cloudflare Pages, like the project's site. Cloudflare's build machines have no Flutter, so GitLab CI builds the page and uploads it.

**Making a release**, the same way as the node's:
1. Raise `version:` in `pubspec.yaml` (for example to `0.1.1`), and move the "Unreleased" notes in [CHANGELOG.md](CHANGELOG.md) under a heading for it.
2. Commit, then tag and push: `git tag v0.1.1 && git push origin main v0.1.1`.

A tag of the form `vX.Y.Z` runs these jobs, in order; other tags and plain commits are only checked (analysis, tests, a web build):

- `build-web-testnet` stops if the tag isn't `v` plus the version in `pubspec.yaml`. Otherwise it builds the testnet page as above, with `--base-href /`.
- `package` zips the page with LICENSE and NOTICE as `murmur-web-vX.Y.Z.zip`, writes `SHA256SUMS`, and uploads both to the project's package registry, so anyone can check the live page against a release, or host it themselves.
- `deploy-web` uploads the page with `wrangler pages deploy` to the Pages project `murmur-app` (`CF_PAGES_PROJECT` in `.gitlab-ci.yml`).
- `release` then creates the GitLab Release "Murmur client vX.Y.Z", linking the archive, `SHA256SUMS` and the live page.

`web/_headers`, copied into the build, sets the response headers: a Content-Security-Policy that allows only the page's own files and `wss://` connections (to any node, since users can pick theirs), plus `no-referrer`, `nosniff` and HSTS. The engine needs `'wasm-unsafe-eval'` for CanvasKit and `'unsafe-inline'` styles.

One-time setup:

1. In Cloudflare, **Workers & Pages → Create → Pages → Direct Upload**, named `murmur-app`. It needs a first upload; any placeholder folder will do, and the first CI deploy replaces it.
2. In the project, **Custom domains → Set up a custom domain**: `app.murmur.info`. The DNS record is created for you.
3. **My Profile → API Tokens → Create Token → Custom token**, with only **Account → Cloudflare Pages → Edit**.
4. In GitLab, **Settings → CI/CD → Variables**, both with **Protect variable** ticked:
   - `CLOUDFLARE_API_TOKEN`: the token, **Masked and hidden**;
   - `CLOUDFLARE_ACCOUNT_ID`: the account ID from any domain's Overview page, **Masked**.
5. In GitLab, **Settings → Repository → Protected tags**: protect `v*`, allowed to create for Maintainers. Protected variables reach only protected branches and tags, so an unprotected tag's deploy would have no token.

The page is built for the root of its domain; to serve it from a subfolder, change `--base-href` to match.

`test/live_node_test.dart` runs against a live node when `MURMUR_NODE=host:port` is set, for example `MURMUR_NODE=testnet-seed.murmur.info:7878` for the public testnet (read-only). It checks sync, proofs, filters, the local copy against the state root, and the fee report. With `MURMUR_SEED` set to a funded seed, it also posts threads, replies, a transfer and a flag, and checks the threads once they're mined.

## Trying it locally

```
git clone https://gitlab.com/elc4no/murmur.git && cd murmur
cargo run --release -p murmur-node -- keygen                     # writes murmur.key, prints its address
cargo run --release -p murmur-node -- --spec demo --mine-to <that address>
```

Then start the client, which connects to `127.0.0.1:7878` by default. To spend the mining rewards, open **Wallet → Import seed** and paste the contents of `murmur.key`.

## A node on this computer (desktop)

Desktop builds can run a Murmur node of their own: **Chain → Run a Murmur node on this computer**. The app then starts `murmur-node` in the background, connects to it, and stops it when it closes. The computer checks the chain itself and helps relay it. Mining can be switched on, paying the wallet's address, with a limit on how much of one processor core it uses.

The node is set up to keep the user out of hosting other people's content: it listens only on this machine (`--port 127.0.0.1:0`), keeps message content only for the one-hour check (`--prune-content`) except the user's own messages (`--keep-author`), and deletes withdrawn messages (`--prune-retracted`). It holds no key. Its data is in `murmur-client/node` in the user's application data folder.

The option appears only when `murmur-node` is next to the app's executable. After `flutter build windows` (or `linux`, `macos`), put it there:

```
dart run tool/bundle_node.dart --version v0.10.0     # a published release, checked against SHA256SUMS
dart run tool/bundle_node.dart --from <murmur-node>  # or a binary you built
```

App stores don't allow mining on the device, so builds for them should leave the node out, or at least mining.

## Layout

For how the code works, the rules it keeps, recipes and known gaps, see [AGENTS.md](AGENTS.md).

| Path | Contents |
|---|---|
| `lib/protocol/` | Byte helpers, transactions and blocks (hashing must match the Rust core exactly), wire codec, network parameters |
| `lib/crypto/wallet.dart` | Ed25519 key, address, signing |
| `lib/services/node_client.dart` | Connection, headers-first sync, balances, gossip, submission |
| `lib/services/storage.dart` | Wallet seed in secure storage; node address, theme, language and filters in preferences |
| `lib/services/chain_cache*.dart` | The local copy of the chain: IndexedDB in the browser, files natively |
| `lib/services/local_node*.dart` | The app's own node on desktops: starting `murmur-node`, and keeping it in line with the settings and wallet |
| `tool/bundle_node.dart` | Puts `murmur-node` next to a built desktop app |
| `lib/protocol/commitments.dart` | The state tree, block filter and header history verifiers (PROTOCOL.md Section 3.6) |
| `lib/protocol/consensus.dart` | The header rules the client checks: median-time-past and the difficulty retarget (Sections 3.5 and 4) |
| `lib/services/secure_channel.dart` | The encrypted transport: X25519, HKDF, ChaCha20-Poly1305 (Section 7.4) |
| `lib/services/activity.dart` | What a transaction is to an address, for the Messages and Wallet filters |
| `lib/ui/` | Threads, messages, wallet and chain tabs, detail pages, compose form |
| `lib/ui/paged_list.dart` | The list that fills the screen plus one and grows by ten at the bottom |
| `lib/l10n/` | `app_<language>.arb`: every text in the interface, per language |
| `lib/ui/l10n.dart` | Language list, number and date formatting, wording of client errors |
| `lib/ui/brand.dart` | Copper-on-ink palette and themes, and the logo (from `murmur-logo.svg` / `murmur-logo-badge.svg`) |
| `lib/ui/glyphs.dart` | The app's icons, drawn in the logo's node-and-line style |
| `tool/render_brand.dart` | `flutter test tool/render_brand.dart` regenerates the web icons from the logo and writes a glyph preview to `build/brand_preview.png` |
| `test/protocol_test.dart` | Genesis hashes pinned in `consensus.rs`, RFC 8032 vector, wire round-trips |
| `test/ui_test.dart` | Every language builds, digit grouping per locale, the paging rule |

## Legal

- **License:** [Apache License 2.0](LICENSE); see also [NOTICE](NOTICE). The software is provided "as is", without warranty of any kind, and its authors accept no liability for its use (License Sections 7 and 8). The app lists every bundled package's license under **Chain → Licenses**.
- **Software, not a service.** The client connects to whichever node its user chooses; its authors run no service through it and see nothing it does.
- **Keys stay on the device, encrypted.** The wallet seed is never stored in the clear, and never sent anywhere. Each signature, and showing or removing the seed, unlocks it anew. Transactions are signed on the device. How it's protected:
  - **Android, iOS and macOS:** the system's hardware key store, which asks for fingerprint, face or the device code.
  - **Browsers:** a passkey on the device, with Windows Hello, Touch ID or the phone's lock screen, where the browser supports passkey encryption (the WebAuthn PRF extension; not yet Firefox).
  - **Otherwise:** a passphrase you choose.

  The Wallet tab says which one protects the key.

  If the passkey or the passphrase is lost, only the seed backup restores the wallet.
- **Cryptography:** digital signatures (Ed25519), hashing, and encryption of the connection to the node (X25519, ChaCha20-Poly1305), all from published open-source libraries. Messages themselves are public by design.
- **Security issues:** report them privately, as described in [SECURITY.md](SECURITY.md).
- **Not legal advice.** What a user may post, keep or show depends on where they are.
