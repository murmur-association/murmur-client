// The winget manifests for a release's Windows installer: the three files
// that a pull request to github.com/microsoft/winget-pkgs adds, under
// manifests/m/MurmurAssociation/Murmur/<version>/. Written by
// tool/winget_manifest.dart in the release, attached to the GitHub Release
// (README, "Desktop updates"); tested in test/winget_manifest_test.dart.
//
// winget then installs and upgrades Murmur from the release's own download,
// checked against the SHA-256 written here: the app itself asks nobody about
// updates (AGENTS.md rule 2).

/// The package's name in winget: never change it, or `winget upgrade` loses
/// every copy installed under the old one.
const wingetId = 'MurmurAssociation.Murmur';

/// The manifest schema the files follow.
const wingetManifestVersion = '1.10.0';

/// The installer's AppId (windows/installer/murmur.iss), as Windows lists
/// the installed app: how winget tells which version is installed.
const wingetProductCode = '{0B7D3E52-61A4-4C8F-9E2B-7F15A8C3D406}_is1';

const _repository = 'https://github.com/murmur-association/murmur-client';

/// The folder winget-pkgs keeps this version's manifests in.
String wingetFolder(String version) => 'manifests/m/${wingetId.replaceAll('.', '/')}/$version';

/// The three manifests for `version` (x.y.z), by file name: the installer
/// is the release's `installerName`, whose SHA-256 is `sha256` (hex), and
/// the release was made on `date`.
Map<String, String> wingetManifests({
  required String version,
  required String installerName,
  required String sha256,
  required DateTime date,
}) {
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) throw FormatException('not a version: $version');
  if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(sha256)) throw FormatException('not a SHA-256: $sha256');
  final tag = 'v$version';
  final day = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  String header(String type) =>
      '# yaml-language-server: \$schema=https://aka.ms/winget-manifest.$type.$wingetManifestVersion.schema.json\n\n';
  return {
    '$wingetId.yaml': '${header('version')}'
        'PackageIdentifier: $wingetId\n'
        'PackageVersion: $version\n'
        'DefaultLocale: en-US\n'
        'ManifestType: version\n'
        'ManifestVersion: $wingetManifestVersion\n',
    '$wingetId.installer.yaml': '${header('installer')}'
        'PackageIdentifier: $wingetId\n'
        'PackageVersion: $version\n'
        'InstallerType: inno\n'
        'Scope: user\n'
        'InstallModes:\n'
        '- interactive\n'
        '- silent\n'
        '- silentWithProgress\n'
        'UpgradeBehavior: install\n'
        'ProductCode: \'$wingetProductCode\'\n'
        'ReleaseDate: $day\n'
        'Installers:\n'
        '- Architecture: x64\n'
        '  InstallerUrl: $_repository/releases/download/$tag/$installerName\n'
        '  InstallerSha256: ${sha256.toUpperCase()}\n'
        'ManifestType: installer\n'
        'ManifestVersion: $wingetManifestVersion\n',
    // Nothing here about value or buying (AGENTS.md rule 10); the testnet's
    // tokens are said to be for testing, as in the app.
    '$wingetId.locale.en-US.yaml': '${header('defaultLocale')}'
        'PackageIdentifier: $wingetId\n'
        'PackageVersion: $version\n'
        'PackageLocale: en-US\n'
        'Publisher: Murmur Association\n'
        'PublisherUrl: https://github.com/murmur-association\n'
        'PublisherSupportUrl: $_repository/issues\n'
        'PackageName: Murmur\n'
        'PackageUrl: $_repository\n'
        'License: Apache-2.0\n'
        'LicenseUrl: $_repository/blob/$tag/LICENSE\n'
        'ShortDescription: A light client for the Murmur network, which checks everything it shows against the chain.\n'
        'Description: |-\n'
        '  Read and write threads and replies, keep a wallet and send transfers on the Murmur network.\n'
        '  Every block header is checked, and everything shown is proven against them.\n'
        '  The app can also run a Murmur node of its own beside it.\n'
        '  It runs on the public testnet, whose tokens are for testing only.\n'
        'Moniker: murmur\n'
        'Tags:\n'
        '- forum\n'
        '- light-client\n'
        '- murmur\n'
        'ReleaseNotesUrl: $_repository/releases/tag/$tag\n'
        'ManifestType: defaultLocale\n'
        'ManifestVersion: $wingetManifestVersion\n',
  };
}
