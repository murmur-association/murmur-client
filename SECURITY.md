# Security policy

## Reporting a vulnerability

Please report vulnerabilities privately, not in a public issue: on this project's GitHub page, **Security → Report a vulnerability** opens a private advisory only the maintainers see. Include what is affected, which version or commit, how to reproduce it, and what an attacker gains.

We'll acknowledge the report within 7 days, keep you updated while we work on a fix, and credit you when the fix is released, unless you'd rather not be named. Please give us a reasonable time to release a fix before you disclose the issue publicly.

Issues in the node or the protocol itself belong to the [murmur repository](https://gitlab.com/murmur-association/murmur/-/blob/main/SECURITY.md).

## What counts

- **Keys:** anything that exposes a wallet seed, or signs something the user didn't ask for.
- **Verification:** anything that makes the client show as proven (a balance, a transaction, a header, a thread) what doesn't match the headers whose proof of work it checked.
- **Hostile nodes:** a node, or someone between the client and a node, that can crash the client, exhaust its memory or storage, or make it misrepresent what it received.
- **Local data:** the chain copy or settings leaking to anyone other than the user.

Not vulnerabilities: what the design accepts, such as peers not being authenticated by the transport (connect to a node you trust), or a node refusing to answer.

## Supported versions

Only the latest release is supported. Murmur has no mainnet; nothing here holds real value.
