# Changelog

Newest first. Each release is a `vX.Y.Z` tag matching `version` in `pubspec.yaml`; see [README](README.md#releases-and-deployment). Entries marked **Breaking** need action from users.

## Unreleased

- **Changed: the project lives on GitHub.** Releases, with the web page, the Windows and Linux apps and `SHA256SUMS`, are published at [github.com/murmur-association/murmur-client/releases](https://github.com/murmur-association/murmur-client/releases); earlier ones stay on GitLab. Security reports go through GitHub's private vulnerability reporting ([SECURITY.md](SECURITY.md)).
- **Fixed: "Copied" shows above dialogs.** Copying from a dialog, such as the seed of a new wallet, said so behind the dialog, where it couldn't be seen.
- **Fixed: amounts take a point or a comma for decimals, in every language.** A phone's numeric keyboard has only its region's separator (a Spanish one has no point), so "0,5" in the English app was refused. Either key now writes the language's own separator; amount fields take no thousands separator.

## v0.10.2: checkpoint refresh (2026-11-03)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 5,100, refreshed from the live network by the scheduled release.

## v0.10.1: checkpoint refresh (2026-11-02)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 2,200, refreshed from the live network by the scheduled release.

## v0.10.0: protocol 17, signatures checked, your messages kept available (2026-10-31)

**Breaking: protocol 17, on a new network** (`murmur-testnet-15`, started 2026-10-31): the app reaches only nodes of release v0.16.0 and later. The testnet starts over: a wallet keeps its seed and works on the new network, but starts with nothing there; the local copy of the old chain is dropped by itself.

- **Added: your messages stay available when nodes delete them.** The app keeps your own messages on this device for good, and gives a node back any of them it no longer has. With **Keep my messages available** (the Wallet tab, on by default), readers who ask a node for one of your messages get it from you, through the node, while the app is open. Only your own messages, never anyone else's.
- **Added: every transaction's signature is checked.** Signatures follow the same rule every node applies (ZIP 215). A transaction a node relays is shown only once its signature checks out, and a block holding one that doesn't makes the app stop and say not to trust that node.
- **Added: what others did about you is checked complete over the last day.** The flags against your messages, the answers to your replies and the messages that mention you come from the node's lists, which nothing proves complete. The app now checks the last day of blocks itself, shows anything the node left out, and says so in the Messages tab.
- **Fixed: on Linux, the app no longer hangs before showing anything when the system keyring is locked and can't ask for its password.** It asks the keyring first: a desktop's own password prompt appears as before, and with nobody to answer it the app starts without a stored wallet and says why it can't save one.
- **Changed: "Blocks mined" is the address's whole count, proven.** The chain now counts the blocks each address mines, so the count comes with the balance, in one request, however old the chain. It used to be counted from the block headers the app held: it climbed while they arrived, and after a start from a checkpoint it left out every block before it.

- **Changed: the desktop app's own node stays the same size however old the chain.** It still checks every block, then keeps only the latest day of them and the chain's state, where it used to keep every block and every header, which on a chain ten years old would come to several gigabytes on disk and in memory. It no longer keeps an index of threads and addresses either: the app never reads from its own node.
- **Changed: the app's own node starts in moments.** A new one starts at the newest blocks from the checkpoint the app's release carries, and checks every block from the first in the background, instead of checking them all before it takes part.
- **Added: the Chain tab shows how far the app's own node has come:** catching up with the chain, and checking the older blocks in the background, each with a bar.
- **Changed: the Starred tab's lists fit a phone.** "Threads and messages" is now "Messages" (a starred thread is its starred first message), and the underline under a list's name no longer runs past it.
- **Added: "Mark all as read"** in the Messages tab and in each of the Starred tab's lists.
- **Changed: the Threads tab has its Refresh button again**, beside pulling the list down, and the search box stays in place while the threads scroll. A refresh turns the arrow and brings the new list in gently.
- **Changed: a row's time is always shown in full**, under its reply and flag counts (or its amount), where the end of the line used to cut it off.
- **Added: a starred person's page marks what they wrote since you last opened their row**, with a line under it, when opened from the Starred tab.
- **Changed: the Wallet tab's "Set public name and picture"** shows your picture as others see it, with a pen on it, and says what it's for.
- **Added: a tap on the picture on an address's page shows it larger.** A page opened from a picture in a list now grows out of it.
- **Changed: on a desktop, names in message rows open their page again**, as the picture does. On phones they still don't, being easy to tap by mistake.
- **Changed: in a thread, the picture and name above a quoted reply open its author's page.** The rest of the quote still goes to the reply.
- **Changed: dialogs no longer put the cursor in their first field**, so a phone's keyboard doesn't cover them until a field is tapped.

## v0.9.12: checkpoint refresh (2026-10-31)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 27,400, refreshed from the live network by the scheduled release.

## v0.9.11: checkpoint refresh (2026-10-30)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 24,500, refreshed from the live network by the scheduled release.

## v0.9.10: checkpoint refresh (2026-10-29)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 21,700, refreshed from the live network by the scheduled release.

## v0.9.9: checkpoint refresh (2026-10-28)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 18,800, refreshed from the live network by the scheduled release.

## v0.9.8: checkpoint refresh (2026-10-27)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 15,900, refreshed from the live network by the scheduled release.

## v0.9.7: checkpoint refresh (2026-10-26)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 13,000, refreshed from the live network by the scheduled release.

## v0.9.6: checkpoint refresh (2026-10-25)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 10,100, refreshed from the live network by the scheduled release.

## v0.9.5: checkpoint refresh (2026-10-24)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 7,100, refreshed from the live network by the scheduled release.

## v0.9.4: checkpoint refresh (2026-10-23)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 4,200, refreshed from the live network by the scheduled release.

## v0.9.3: choosing a picture in the browser (2026-10-22)

No protocol or network change.

- **Fixed: choosing a profile picture on app.murmur.info did nothing.** The page's security policy kept it from reading the picked file. It may now, and a file that can't be read, for whatever reason, is said so.
- **Changed: the testnet checkpoint** is now block 2,500.

## v0.9.2: profile pictures on any graphics (2026-10-22)

No protocol or network change.

- **Fixed: choosing a profile picture on a computer drawing without a graphics card** could leave the Public name dialog waiting. The picked file is now read without drawing it, and a file that can't be read says so.
- **Changed: the testnet checkpoint** is now block 2,400.

## v0.9.1: checkpoint refresh (2026-10-22)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 1,400, refreshed from the live network by the scheduled release.

## v0.9.0: profile pictures, the first testnet-14 checkpoint (2026-10-21)

No protocol or network change: profiles are a convention between clients (PROTOCOL.md Section 7.8), and nodes carry them like any message.

- **Added: the first checkpoint of `murmur-testnet-14`**, block 500: a first session no longer checks every header from genesis before lists show.
- **Added: notifications on iPhones and Macs**, as on Android: the iPhone app also checks while closed, when iOS lets it. (Neither app is published yet.)
- **Added: a Mac app**, with its own node as on Windows and Linux. (Not published yet: it needs signing.)
- **Added: profile pictures.** Wallet → Public name now takes a picture too: from your photos or files on a phone, from a file elsewhere. It's shown at 32 × 32 pixels in 16 colours, wherever the app would draw your address's mark; with a picture, a name costs about three times as much. A muted person keeps the mark.

## v0.8.0: murmur-testnet-14, mentions, notifications, Starred in two lists (2026-10-21)

**Breaking: a new network and protocol.** The app speaks protocol 15 and joins `murmur-testnet-14`; it no longer reaches `murmur-testnet-12` (nor `murmur-testnet-13`, which no release of the app joined). Nothing carries over: wallets keep their keys, and start with nothing on the new chain. The desktop apps ship node release v0.15.0. No checkpoint while the network is under a day old.

- **Changed: the difficulty rule** follows the node's: a block that comes long after its parent eases the difficulty at the same rate as a slow parent (protocol 15).
- **Added: mentions.** Type `@` in a thread or a reply to name someone the app knows: up to four per message, each costing 8 bytes of fee. They learn of it in Messages (a new "Mentions" filter, counted in the badge), and a message shows whom it mentions under its text. A mention is public, and the summary before signing says so.
- **Changed: blocks hold at most 1 MB** on the new testnet, half of before.
- **Added: notifications.** The bell in Messages and Starred switches on notifications of replies and answers to you, mentions of you, and news on what you starred, each on its own; all are off until you choose. The app checks by itself, on your node, with no push service: nobody else learns what you follow. On Android it also checks while closed, about every 15 minutes, and the lock screen hides what they say; on Windows, Linux and in a browser they come while the app is open but not in front.
- **Fixed: one wallet on two devices.** Sending right after the other device had sent could use the same transaction number, and the node refused it; the app now waits until it has checked the wallet at the newest block.
- **Changed: Starred has two lists**, one for threads and messages and one for people, each on a tab of its own; a dot on a tab says that list has news.

## v0.7.2: checkpoint refresh (2026-10-20)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 5,000, refreshed from the live network by the scheduled release.

## v0.7.1: checkpoint refresh (2026-10-19)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 2,200, refreshed from the live network by the scheduled release.

## v0.7.0: murmur-testnet-12, threads from their first reply, unread marks, a fee that follows the chain (2026-10-17)

**Breaking: a new network and protocol.** The app speaks protocol 13 and joins `murmur-testnet-12`; it no longer reaches `murmur-testnet-11`. Nothing carries over: wallets keep their keys, and start with nothing on the new chain. The desktop apps ship node release v0.13.0. No checkpoint while the network is under a day old.

- **Changed: a thread shows its replies oldest first again**, under its first message, as a forum reads. Any page of a thread or of a history is now proven on its own, so a thread opens at its first reply however long it is, and further replies load as you scroll down; "Earlier replies" loads the ones before.
- **Added: a thread remembers where you left off.** The first visit opens at the top; the next ones go to the last reply you saw, and replies newer than that light up for a moment as they come into view. A thread opened for one reply, such as one you just sent, goes to it.
- **Added: unread messages are marked.** In Messages, what others wrote stays highlighted until you open it; in Starred, so does a thread or a person with news.
- **Changed: a row's picture opens its author's page**, in the Threads, Messages and Starred lists, where the name under the text used to. Messages shows the author's picture in place of the message kind.
- **Changed: pull the Threads list down to refresh it**, in place of its Refresh button.
- **Changed: the suggested fee follows the chain.** It is checked again at each new block. When it changes, "Use" and the fee field flash, and your fee stays as it is until you use it; the summary before signing says when your fee is below the suggestion (it may take a while to get into a block) or above it.
- **Fixed: a reply pays the thread's author the suggested fee by default**, not a fixed 1 token. You can still give more.
- **Changed: a quoted reply's highlight fades** after a moment.
- **Changed: on a phone, a message's sentences start with a capital** as you type, as the keyboard does elsewhere.

## v0.6.6: checkpoint refresh (2026-10-17)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 16,200, refreshed from the live network by the scheduled release.

## v0.6.5: checkpoint refresh (2026-10-16)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 13,300, refreshed from the live network by the scheduled release.

## v0.6.4: checkpoint refresh (2026-10-15)

No protocol or network change.

- **Changed: the testnet checkpoint** is now block 10,400, refreshed from the live network by the scheduled release.

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
