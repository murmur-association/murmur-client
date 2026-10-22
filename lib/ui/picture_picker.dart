// Choosing an image to publish as a profile picture. Phones offer their
// photos (image_picker) and their files (file_selector); desktops and
// browsers, a file (file_selector). Both are the Flutter team's plugins and
// work on the device alone: nothing is sent anywhere.

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/picture.dart';

/// Where a picture comes from.
enum PictureSource { photos, files }

/// Whether this device has a photo library to choose from: phone apps.
/// A browser's own file input already offers photos on a phone.
bool get hasPhotoLibrary =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Why a picked file can't be used.
enum PictureProblem { tooLarge, unreadable }

/// What was picked: the file's bytes, or why they can't be used.
typedef PickedPicture = ({Uint8List? bytes, PictureProblem? problem});

/// Takes the place of [pickPicture] in the acceptance tests: where the
/// system's chooser can be worked from outside the app it calls
/// [pickPictureFromSystem] and watches what comes back; elsewhere (macOS,
/// iOS) it hands over the file a user would have picked.
@visibleForTesting
Future<PickedPicture?> Function(PictureSource source)? pickPictureOverride;

/// Asks the user for an image from `source`. Null when they cancel.
Future<PickedPicture?> pickPicture(PictureSource source) =>
    (pickPictureOverride ?? pickPictureFromSystem)(source);

/// [pickPicture] through the system's own chooser.
Future<PickedPicture?> pickPictureFromSystem(PictureSource source) async {
  final XFile? file = switch (source) {
    // Already shrunk by the system (and HEIC turned into JPEG on iPhones),
    // without asking for the library's metadata, so no permission is asked.
    PictureSource.photos => await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, requestFullMetadata: false),
    PictureSource.files => await openFile(acceptedTypeGroups: const [
        XTypeGroup(
          label: 'images',
          extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/bmp'],
          uniformTypeIdentifiers: ['public.png', 'public.jpeg', 'com.compuserve.gif', 'org.webmproject.webp', 'com.microsoft.bmp'],
        ),
      ]),
  };
  if (file == null) return null;
  // In a browser the file is read from a blob: URL, which the page's
  // Content-Security-Policy must allow (web/_headers); a read that fails
  // for any reason is a file that can't be used, said so, never silence.
  try {
    if (await file.length() > maxPictureFileBytes) return (bytes: null, problem: PictureProblem.tooLarge);
    return (bytes: await file.readAsBytes(), problem: null);
  } catch (_) {
    return (bytes: null, problem: PictureProblem.unreadable);
  }
}
