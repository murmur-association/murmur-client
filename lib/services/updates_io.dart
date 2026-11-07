// Native builds: how this copy was installed, and the move into a Flatpak.

import 'dart:io';

import 'updates.dart';

Installed get installed {
  if (Platform.isWindows) return storeBuild ? Installed.store : Installed.download;
  if (Platform.isLinux) return Platform.environment.containsKey('FLATPAK_ID') ? Installed.flatpak : Installed.download;
  return Installed.other;
}

Future<void> moveIntoFlatpak() async {
  if (!Platform.isLinux) return;
  await moveIntoFlatpakFolders(Platform.environment);
}

/// What the app kept in the user's data folder (`~/.local/share`) before it
/// ran as a Flatpak, by folder: the settings (path_provider names the folder
/// after the application id, or after the program in older versions), and
/// the user's own messages (services/own_messages_io.dart). The Flatpak's
/// manifest grants read-only access to exactly these
/// (linux/flatpak/info.murmur.client.yml).
const flatpakMoved = ['info.murmur.client', 'murmur_client', 'murmur-client/own'];

/// Copies each of [flatpakMoved] from `$HOME/.local/share` into the
/// sandbox's `XDG_DATA_HOME`, when running as a Flatpak (`FLATPAK_ID` set)
/// and the sandbox has none of it yet. Copied, not moved: the folders are
/// read-only from inside, and an archive of the app run beside the Flatpak
/// keeps working. Returns what was copied (public for tests).
Future<List<String>> moveIntoFlatpakFolders(Map<String, String> env) async {
  final home = env['HOME'], data = env['XDG_DATA_HOME'];
  if (!env.containsKey('FLATPAK_ID') || home == null || data == null) return const [];
  final outside = '$home/.local/share';
  if (outside == data) return const [];
  // Once the sandbox holds any of it, the app has run as a Flatpak before:
  // never copy over what it wrote since.
  for (final name in flatpakMoved) {
    if (FileSystemEntity.typeSync('$data/$name') != FileSystemEntityType.notFound) return const [];
  }
  final copied = <String>[];
  for (final name in flatpakMoved) {
    final from = Directory('$outside/$name');
    if (!from.existsSync()) continue;
    try {
      await _copyTree(from, Directory('$data/$name'));
      copied.add(name);
    } on FileSystemException catch (e) {
      // Not granted, or unreadable: the app starts afresh, as on a new
      // computer (the wallet itself stays in the keyring).
      stderr.writeln('could not copy $name into the Flatpak: ${e.message}');
    }
  }
  return copied;
}

Future<void> _copyTree(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is Directory) {
      await _copyTree(entity, Directory('${to.path}/$name'));
    } else if (entity is File) {
      await entity.copy('${to.path}/$name');
    }
  }
}
