# Changelog

Newest first. Each release is a `vX.Y.Z` tag matching `version` in `pubspec.yaml`; see [README](README.md#releases-and-deployment). Entries marked **Breaking** need action from users.

## Unreleased

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
