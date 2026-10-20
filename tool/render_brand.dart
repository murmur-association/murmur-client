// Renders the app icons from the logo (ui/brand.dart), plus a preview sheet
// of every glyph, using Flutter's own renderer. Run from the project root:
//
//   flutter test tool/render_brand.dart
//
// Writes web/favicon.png, web/icons/Icon-{192,512}.png (the rounded badge),
// web/icons/Icon-maskable-{192,512}.png (full bleed, logo inside the maskable
// safe zone), windows/runner/resources/app_icon.ico and
// linux/runner/resources/app_icon.png (the badge, for the desktop apps),
// ios/Runner/Assets.xcassets/AppIcon.appiconset (the iPhone's, opaque), its
// launch screen's logo and background (LaunchImage, LaunchBackground), the
// Android app's icons, launch logo and colours (android/app/src/main/res) and
// build/brand_preview.png.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/glyphs.dart';
import 'package:murmur_client/ui/people.dart';

Future<void> _writePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _renderIcon(String path, int size, {required bool maskable}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (maskable) {
    // Launchers crop maskable icons to shapes as small as a circle of radius
    // 0.4 x size, so the logo stays within the middle ~56%.
    canvas.drawRect(Offset.zero & Size(s, s), Paint()..color = BrandColors.ink);
    final logo = s * 0.56;
    canvas.translate((s - logo) / 2, (s - logo) / 2 - s * 0.02);
    paintLogo(canvas, Size(logo, logo), BrandColors.copper);
  } else {
    paintBadge(canvas, Size(s, s));
  }
  final image = await recorder.endRecording().toImage(size, size);
  await _writePng(image, path);
}

/// Writes `image` as a PNG without an alpha channel (colour type 2), as
/// Apple requires of an app icon: Flutter's own encoder always writes one.
Future<void> _writeOpaquePng(ui.Image image, String path) async {
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final w = image.width, h = image.height;
  // Each row: filter type 0, then its pixels' red, green and blue.
  final raw = Uint8List(h * (1 + w * 3));
  for (var y = 0, o = 0; y < h; y++) {
    raw[o++] = 0;
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
    }
  }
  final out = BytesBuilder();
  void chunk(String type, List<int> data) {
    final typed = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(typed)
      ..add(_u32(_crc32(typed)));
  }

  out.add(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  chunk('IHDR', [..._u32(w), ..._u32(h), 8, 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw));
  chunk('IEND', const []);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(out.takeBytes());
}

List<int> _u32(int v) => [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

int _crc32(List<int> bytes) {
  var c = 0xffffffff;
  for (final b in bytes) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1;
    }
  }
  return c ^ 0xffffffff;
}

/// The iPhone's app icon: one 1024-pixel image that Xcode scales (a
/// single-size icon set), full bleed on the app's ink, which iOS rounds
/// itself; opaque, as Apple requires. Any other images in the set go.
Future<void> _writeIosIcon(String set) async {
  const size = 1024, s = 1024.0, logo = s * 0.6;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & const Size(s, s), Paint()..color = BrandColors.ink);
  canvas.translate((s - logo) / 2, (s - logo) / 2 - s * 0.02);
  paintLogo(canvas, const Size(logo, logo), BrandColors.copper);
  for (final f in Directory(set).listSync().whereType<File>()) {
    if (f.path.endsWith('.png')) f.deleteSync();
  }
  await _writeOpaquePng(await recorder.endRecording().toImage(size, size), '$set/AppIcon-1024.png');
  File('$set/Contents.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'images': [
      {'filename': 'AppIcon-1024.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'},
    ],
    'info': {'author': 'xcode', 'version': 1},
  }));
}

/// The iPhone's launch screen (ios/Runner/Base.lproj/LaunchScreen.storyboard):
/// the copper logo, 120 points wide, on the background the app's first
/// frame has, paper in light mode and ink in dark (a named colour with both).
Future<void> _writeIosLaunch(String assets) async {
  for (final scale in [1, 2, 3]) {
    final size = 120 * scale;
    final recorder = ui.PictureRecorder();
    paintLogo(Canvas(recorder), Size(size.toDouble(), size.toDouble()), BrandColors.copper);
    final name = scale == 1 ? 'LaunchImage.png' : 'LaunchImage@${scale}x.png';
    await _writePng(await recorder.endRecording().toImage(size, size), '$assets/LaunchImage.imageset/$name');
  }
  Map<String, Object> colour(Color c) => {
        'color-space': 'srgb',
        'components': {
          for (final (name, value) in [('red', c.r), ('green', c.g), ('blue', c.b)])
            name: '0x${(value * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase()}',
          'alpha': '1.000',
        },
      };
  File('$assets/LaunchBackground.colorset/Contents.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'colors': [
        {'idiom': 'universal', 'color': colour(BrandColors.paper)},
        {
          'idiom': 'universal',
          'appearances': [
            {'appearance': 'luminosity', 'value': 'dark'},
          ],
          'color': colour(BrandColors.ink),
        },
      ],
      'info': {'author': 'xcode', 'version': 1},
    }));
}

/// The Android app's images and colours, in `res` (android/app/src/main/res):
/// the launcher icon (the badge for Android 7, and for 8 and later the
/// adaptive icon's foreground, the logo inside the launcher's safe zone, with
/// a monochrome copy for themed icons), the notifications' small icon (a
/// white silhouette, which Android tints), the launch screen's logo, and the
/// colours behind them.
Future<void> _writeAndroid(String res) async {
  const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
  // The logo at `logo` of a `canvas`-sized square, centred as the maskable
  // web icon's is.
  Future<ui.Image> logoIn(int canvas, double logo, Color color) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final s = canvas.toDouble(), side = s * logo;
    c.translate((s - side) / 2, (s - side) / 2 - s * 0.02);
    paintLogo(c, Size(side, side), color);
    return recorder.endRecording().toImage(canvas, canvas);
  }

  for (final MapEntry(key: name, value: scale) in densities.entries) {
    int px(int dp) => (dp * scale).round();
    await _writePng(await _badge(px(48)), '$res/mipmap-$name/ic_launcher.png');
    // 108 dp, of which the launcher shows the middle 72 and keeps a circle
    // of 66 whole: the logo stays inside it.
    await _writePng(await logoIn(px(108), 0.44, BrandColors.copper), '$res/mipmap-$name/ic_launcher_foreground.png');
    await _writePng(await logoIn(px(108), 0.44, Colors.white), '$res/mipmap-$name/ic_launcher_monochrome.png');
    await _writePng(await logoIn(px(24), 0.92, Colors.white), '$res/drawable-$name/ic_stat_murmur.png');
    await _writePng(await logoIn(px(96), 1, BrandColors.copper), '$res/drawable-$name/launch_logo.png');
  }
  String hex(Color c) => '#${[c.r, c.g, c.b].map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
  void colours(String dir, Map<String, Color> colours) => File('$res/$dir/colors.xml')
    ..createSync(recursive: true)
    ..writeAsStringSync([
      '<?xml version="1.0" encoding="utf-8"?>',
      "<!-- Written by tool/render_brand.dart from the brand's colours (lib/ui/brand.dart). -->",
      '<resources>',
      for (final MapEntry(:key, :value) in colours.entries) '    <color name="$key">${hex(value)}</color>',
      '</resources>',
      '',
    ].join('\n'));
  colours('values', {'launch_background': BrandColors.paper, 'ic_launcher_background': BrandColors.ink});
  colours('values-night', {'launch_background': BrandColors.ink});
}

/// The badge at `size`, as an image.
Future<ui.Image> _badge(int size) {
  final recorder = ui.PictureRecorder();
  paintBadge(Canvas(recorder), Size(size.toDouble(), size.toDouble()));
  return recorder.endRecording().toImage(size, size);
}

/// Writes the badge as a Windows icon holding these sizes. The 256-pixel
/// image is stored as PNG and the smaller ones as 32-bit bitmaps, which is
/// what every Windows version and tool reads.
Future<void> _writeIco(String path, List<int> sizes) async {
  final images = <Uint8List>[];
  for (final size in sizes) {
    final image = await _badge(size);
    if (size >= 256) {
      images.add((await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
      continue;
    }
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();
    // A bitmap header, the pixels bottom row first as BGRA, then an empty
    // transparency mask (the alpha channel does that job), its rows padded
    // to 32 bits.
    final maskRow = (size + 31) ~/ 32 * 4;
    final dib = ByteData(40 + size * size * 4 + maskRow * size)
      ..setUint32(0, 40, Endian.little)
      ..setInt32(4, size, Endian.little)
      ..setInt32(8, size * 2, Endian.little)
      ..setUint16(12, 1, Endian.little)
      ..setUint16(14, 32, Endian.little)
      ..setUint32(20, size * size * 4, Endian.little);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final from = (y * size + x) * 4, to = 40 + ((size - 1 - y) * size + x) * 4;
        dib
          ..setUint8(to, rgba[from + 2])
          ..setUint8(to + 1, rgba[from + 1])
          ..setUint8(to + 2, rgba[from])
          ..setUint8(to + 3, rgba[from + 3]);
      }
    }
    images.add(dib.buffer.asUint8List());
  }
  // The file: a 6-byte header, a 16-byte entry per image, then the images.
  final out = BytesBuilder();
  out.add((ByteData(6)
        ..setUint16(2, 1, Endian.little)
        ..setUint16(4, sizes.length, Endian.little))
      .buffer
      .asUint8List());
  var offset = 6 + 16 * sizes.length;
  for (var i = 0; i < sizes.length; i++) {
    out.add((ByteData(16)
          ..setUint8(0, sizes[i] >= 256 ? 0 : sizes[i])
          ..setUint8(1, sizes[i] >= 256 ? 0 : sizes[i])
          ..setUint16(4, 1, Endian.little)
          ..setUint16(6, 32, Endian.little)
          ..setUint32(8, images[i].length, Endian.little)
          ..setUint32(12, offset, Endian.little))
        .buffer
        .asUint8List());
    offset += images[i].length;
  }
  images.forEach(out.add);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(out.takeBytes());
}

void main() {
  testWidgets('render brand icons', (tester) async {
    await tester.runAsync(() async {
      await _renderIcon('web/favicon.png', 64, maskable: false);
      await _renderIcon('web/icons/Icon-192.png', 192, maskable: false);
      await _renderIcon('web/icons/Icon-512.png', 512, maskable: false);
      await _renderIcon('web/icons/Icon-maskable-192.png', 192, maskable: true);
      await _renderIcon('web/icons/Icon-maskable-512.png', 512, maskable: true);
      await _writeIco('windows/runner/resources/app_icon.ico', const [16, 24, 32, 48, 64, 256]);
      await _writePng(await _badge(256), 'linux/runner/resources/app_icon.png');
      await _writeIosIcon('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      await _writeIosLaunch('ios/Runner/Assets.xcassets');
      await _writeAndroid('android/app/src/main/res');
    });
  });

  testWidgets('render glyph preview', (tester) async {
    final key = GlobalKey();
    Widget sheet(ThemeData theme) => Theme(
          data: theme,
          child: Builder(builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return Container(
              color: scheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const MurmurLogo(size: 48),
                  const SizedBox(width: 16),
                  for (final g in [Glyph.thread, Glyph.reply, Glyph.transfer, Glyph.flag])
                    Padding(padding: const EdgeInsets.only(right: 12), child: GlyphAvatar(g)),
                  const GlyphAvatar(Glyph.thread, active: false),
                ]),
                const SizedBox(height: 16),
                for (final size in [24.0, 48.0])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(spacing: size * 0.5, runSpacing: 8, children: [
                      for (final g in Glyph.values) MurmurIcon(g, size: size, color: scheme.onSurface),
                    ]),
                  ),
                Wrap(spacing: 16, children: [
                  for (final g in [Glyph.thread, Glyph.outbox, Glyph.wallet, Glyph.blocks]) ...[
                    MurmurIcon(g, size: 32, color: scheme.onSurfaceVariant),
                    MurmurIcon(g, size: 32, color: scheme.primary, filled: true),
                  ],
                ]),
                const SizedBox(height: 16),
                // Address pictures (ui/people.dart), from sample addresses.
                for (final size in [96.0, 40.0, 22.0])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(spacing: size * 0.35, runSpacing: 8, children: [
                      for (var i = 0; i < 20; i++)
                        CustomPaint(
                          size: Size.square(size),
                          painter: AddressMarkPainter(
                            sha256.convert([i]).bytes,
                            dark: theme.brightness == Brightness.dark,
                            surface: scheme.surface,
                          ),
                        ),
                    ]),
                  ),
              ]),
            );
          }),
        );

    tester.view.physicalSize = const Size(1500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [sheet(darkTheme), sheet(lightTheme)]),
      ),
    ));
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      await _writePng(image, 'build/brand_preview.png');
    });
  });
}
