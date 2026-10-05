// Renders the app icons from the logo (ui/brand.dart), plus a preview sheet
// of every glyph, using Flutter's own renderer. Run from the project root:
//
//   flutter test tool/render_brand.dart
//
// Writes web/favicon.png, web/icons/Icon-{192,512}.png (the rounded badge),
// web/icons/Icon-maskable-{192,512}.png (full bleed, logo inside the maskable
// safe zone), windows/runner/resources/app_icon.ico and
// linux/runner/resources/app_icon.png (the badge, for the desktop apps) and
// build/brand_preview.png.

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
