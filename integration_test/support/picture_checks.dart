// How a picture file is read on the flavour at hand: the public name
// dialog reads the user's file with the engine (`pictureFromImage`), which
// must read the suite's sample and, in a browser, the page's own icon, a
// PNG from an ordinary encoder. `pictureFromImage` says only that it
// couldn't, so each step is also tried on its own and the one that fails
// is reported (`note`), with, in a browser, whether a plain canvas reads
// back at all: Safari, driven on GitHub's Mac, refused the engine every
// image's pixels (InvalidStateError, 2026-11-07).

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/picture.dart';

import 'app_driver.dart' show samplePictureFile;
import 'page_io.dart' if (dart.library.js_interop) 'page_web.dart';

void pictureTests(void Function(String note) note) {
  /// Each step of a decode, as `pictureFromImage` takes them, noting the
  /// first that fails; whether the whole read gave a picture.
  Future<bool> read(String what, Uint8List bytes) async {
    var step = 'the buffer';
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      step = 'the codec';
      final codec = await ui.instantiateImageCodecWithSize(buffer);
      step = 'the frame';
      final image = (await codec.getNextFrame()).image;
      step = 'the pixels (${image.width} x ${image.height})';
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (pixels == null) note('$what: no pixels from the decoded image');
    } catch (e) {
      note('$what: $step failed: $e');
    }
    return await pictureFromImage(bytes) != null;
  }

  test('a picture file is read', () async {
    final page = await pageFile('icons/Icon-192.png');
    final icon = page == null || await read("the page's icon", page);
    final sample = await read("the suite's sample", await samplePictureFile());
    if (page != null) note("the page's icon ${icon ? 'is' : 'is not'} read");
    if (!sample || !icon) {
      if (canvasReadBack() case final canvas?) note(canvas);
    }
    expect(sample, isTrue, reason: "the suite's sample picture");
    expect(icon, isTrue, reason: "the page's icon");
  });
}
