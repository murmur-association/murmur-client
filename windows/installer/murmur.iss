; The Windows installer (Inno Setup 6), built by the release from the same
; folder as the zip (tool/package_desktop.dart stages it):
;
;   iscc /DAppVersion=0.10.4 /DSourceDir=<staged folder> /DOutputDir=dist
;        /DOutputName=murmur-client-v0.10.4-windows-x64-setup windows\installer\murmur.iss
;
; Per user, without administrator rights: into %LOCALAPPDATA%\Programs\Murmur,
; with a Start menu entry and an entry in Settings > Apps. Running a newer
; installer updates in place: it closes a running app and its node first
; (Restart Manager), and the app's settings, wallet and chain stay where they
; are (they live under %APPDATA%, never in the program's folder). winget
; installs and upgrades with it (tool/winget_manifest.dart).
;
; The installer isn't signed yet: Windows' SmartScreen warns about an
; unknown publisher until it is (README, "Desktop updates").

#ifndef AppVersion
  #error Pass /DAppVersion=<x.y.z>
#endif
#ifndef SourceDir
  #error Pass /DSourceDir=<the staged app folder>
#endif
#ifndef OutputDir
  #define OutputDir "dist"
#endif
#ifndef OutputName
  #define OutputName "murmur-client-setup"
#endif

[Setup]
; Never change: Windows knows an installed Murmur by it, and so does winget.
AppId={{0B7D3E52-61A4-4C8F-9E2B-7F15A8C3D406}
AppName=Murmur
AppVersion={#AppVersion}
AppVerName=Murmur {#AppVersion}
AppPublisher=Murmur Association
AppPublisherURL=https://github.com/murmur-association
AppSupportURL=https://github.com/murmur-association/murmur-client
AppUpdatesURL=https://github.com/murmur-association/murmur-client/releases
DefaultDirName={localappdata}\Programs\Murmur
DisableDirPage=auto
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename={#OutputName}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\murmur_client.exe
UninstallDisplayName=Murmur
; Close the app and its node before replacing their files, and don't start
; them again behind the user's back: the installer's last page offers it.
CloseApplications=force
RestartApplications=no
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
VersionInfoVersion={#AppVersion}
VersionInfoCompany=Murmur Association
VersionInfoProductName=Murmur
VersionInfoDescription=Murmur setup

; Inno Setup's own translations of its pages, for the app's languages it has.
[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "ja"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "ko"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "pt"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

; The engine's assets change with every version: none of an older one stays.
[InstallDelete]
Type: filesandordirs; Name: "{app}\data"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; The shortcut carries the identity the app's notifications use
; (services/notifier.dart), so Windows keeps them in its notification centre.
[Icons]
Name: "{autoprograms}\Murmur"; Filename: "{app}\murmur_client.exe"; \
  AppUserModelID: "MurmurAssociation.Murmur"; AppUserModelToastActivatorCLSID: "6f3c2a51-9d84-4e0b-b7a2-5c1e8f04d3a9"
Name: "{autodesktop}\Murmur"; Filename: "{app}\murmur_client.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\murmur_client.exe"; Description: "{cm:LaunchProgram,Murmur}"; Flags: nowait postinstall skipifsilent
