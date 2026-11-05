// How this copy of the app gets updated. The app itself never asks anyone
// whether there's a newer version (AGENTS.md rule 2): it tells from the chain
// (MurmurClient.newerProtocolSeen, releaseLooksOld) and from its own node's
// output (LocalNode.peersNewer), and leaves the updating to the user, or to
// the system's package manager (winget, Flathub: README, "Desktop updates").

import 'updates_io.dart' if (dart.library.js_interop) 'updates_web.dart' as impl;

/// The client's repository, where every release is published.
const appRepositoryUrl = 'https://github.com/murmur-association/murmur-client';

/// The newest release's page: its downloads, opened on the user's tap only.
const latestReleaseUrl = '$appRepositoryUrl/releases/latest';

/// How this copy was installed, which decides what "update" means for it.
enum Installed {
  /// A page: reloading it gets the version app.murmur.info serves now.
  web,

  /// A desktop app from a release's download (the Windows installer, or an
  /// archive), or installed by winget from the same installer: the release
  /// page has the new one.
  download,

  /// A Flatpak (Flathub): the system's software updates bring the new one.
  flatpak,

  /// A phone, or a Mac: no published download yet, so nothing to point at.
  other,
}

/// How this copy was installed.
Installed get installed => impl.installed;

/// Whether the release page has a download for this copy.
bool get canDownloadUpdate => installed == Installed.download;

/// On Linux, the first time the app runs as a Flatpak: copies what the app
/// kept outside the sandbox before (its settings, and the user's own
/// messages) into the sandbox's own data folder, where the app now looks.
/// The chain's local copy and the app's node aren't copied: both are
/// fetched again. Does nothing anywhere else, or once the sandbox has data.
Future<void> moveIntoFlatpak() => impl.moveIntoFlatpak();
