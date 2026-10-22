// Turning a picked image into a profile picture (services/picture.dart): its
// middle square at 32 x 32, in 16 colours, transparency on white; and what
// isn't an image gives none.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/profile.dart';
import 'package:murmur_client/services/picture.dart';

/// A PNG of `width` x `height`, drawn by `paint`.
Future<Uint8List> _png(int width, int height, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(width, height);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

/// A colour within 16 of `rgb` in each channel: resampling blurs a little.
Matcher _near(int rgb) => predicate<int>(
    (c) => [16, 8, 0].every((s) => ((c >> s & 0xff) - (rgb >> s & 0xff)).abs() <= 16), 'near ${rgb.toRadixString(16)}');

void main() {
  testWidgets('a picture is the middle square, at 32 x 32', (tester) async {
    await tester.runAsync(() async {
      // Wide: red at the sides, which the square leaves out; blue in the
      // middle, with a green top half.
      final bytes = await _png(300, 100, (c) {
        c.drawRect(const Rect.fromLTWH(0, 0, 300, 100), Paint()..color = const Color(0xFFFF0000));
        c.drawRect(const Rect.fromLTWH(100, 0, 100, 100), Paint()..color = const Color(0xFF0000FF));
        c.drawRect(const Rect.fromLTWH(100, 0, 100, 50), Paint()..color = const Color(0xFF00FF00));
      });
      final picture = (await pictureFromImage(bytes))!;
      // Inside the square: a crop's edge may take a trace of what it cut.
      expect(picture.rgbAt(2, 2), _near(0x00ff00));
      expect(picture.rgbAt(29, 8), _near(0x00ff00));
      expect(picture.rgbAt(2, 29), _near(0x0000ff));
      expect(picture.rgbAt(29, 24), _near(0x0000ff));
      for (var y = 0; y < profileSide; y++) {
        for (var x = 0; x < profileSide; x++) {
          expect(picture.rgbAt(x, y), isNot(0xff0000), reason: 'nothing of the sides at ($x, $y)');
        }
      }
    });
  });

  testWidgets('transparency comes out white; a small image is enlarged', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _png(8, 8, (c) {
        c.drawRect(const Rect.fromLTWH(0, 0, 4, 8), Paint()..color = const Color(0xFF000000));
      });
      final picture = (await pictureFromImage(bytes))!;
      expect(picture.rgbAt(2, 16), _near(0x000000));
      expect(picture.rgbAt(29, 16), _near(0xffffff));
    });
  });

  testWidgets("what isn't an image gives no picture", (tester) async {
    await tester.runAsync(() async {
      expect(await pictureFromImage(Uint8List.fromList('not an image'.codeUnits)), isNull);
      expect(await pictureFromImage(Uint8List(0)), isNull);
    });
  });

  test('16 colours at most; fewer are kept exactly', () {
    final few = [for (var i = 0; i < 1024; i++) [0x112233, 0xabcdef, 0x00ff00][i % 3]];
    final picture = pictureFromRgb(few);
    for (var i = 0; i < 1024; i++) {
      expect(picture.rgbAt(i % 32, i ~/ 32), few[i]);
    }
    final many = [for (var i = 0; i < 1024; i++) i * 0x3f1f]; // 1024 colours
    final reduced = pictureFromRgb(many);
    expect({for (var i = 0; i < 1024; i++) reduced.rgbAt(i % 32, i ~/ 32)}.length, lessThanOrEqualTo(16));
    // Each pixel takes a colour near its own: within the spread of a box.
    expect(reduced.palette.toSet().length, 16);
  });

  group('the middle square, from decoded pixels (nothing drawn)', () {
    /// `width` x `height` RGBA pixels, each `colour(x, y)` as (r, g, b, a).
    Uint8List pixels(int width, int height, List<int> Function(int x, int y) colour) => Uint8List.fromList([
          for (var y = 0; y < height; y++)
            for (var x = 0; x < width; x++) ...colour(x, y),
        ]);

    test('a wide image: the middle, each picture pixel the average of its block', () {
      // 192 x 64: red sides, and a middle square whose columns alternate
      // black and white, two pixels to a picture pixel: grey.
      final rgba = pixels(192, 64, (x, y) => x < 64 || x >= 128 ? [255, 0, 0, 255] : (x.isEven ? [0, 0, 0, 255] : [255, 255, 255, 255]));
      final square = middleSquare(rgba, 192, 64);
      expect(square, hasLength(1024));
      expect(square.toSet(), {0x808080}, reason: 'grey everywhere, no red: (0 + 255) / 2 rounds to 128');
    });

    test('a tall image: the middle rows', () {
      final rgba = pixels(32, 96, (x, y) => y >= 32 && y < 64 ? [0, 0, 255, 255] : [0, 255, 0, 255]);
      expect(middleSquare(rgba, 32, 96).toSet(), {0x0000ff});
    });

    test('transparency comes out on white', () {
      final rgba = pixels(32, 32, (x, y) => x < 16 ? [0, 0, 0, 0] : [0, 0, 0, 128]);
      final square = middleSquare(rgba, 32, 32);
      expect(square.first, 0xffffff, reason: 'fully transparent');
      expect(square.last, 0x7f7f7f, reason: 'half transparent black');
    });

    test('an image smaller than the picture: each pixel taken by the nearest', () {
      final rgba = pixels(4, 4, (x, y) => x == 0 && y == 0 ? [255, 0, 0, 255] : [0, 0, 0, 255]);
      final square = middleSquare(rgba, 4, 4);
      expect(square[0], 0xff0000);
      expect(square[7], 0xff0000, reason: 'a source pixel covers 8 x 8');
      expect(square[8], 0x000000);
      expect(square[7 * 32], 0xff0000);
      expect(square[8 * 32], 0x000000);
    });
  });
}
