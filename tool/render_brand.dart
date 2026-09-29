// Renders the app icons from the logo (ui/brand.dart), plus a preview sheet
// of every glyph, using Flutter's own renderer. Run from the project root:
//
//   flutter test tool/render_brand.dart
//
// Writes web/favicon.png, web/icons/Icon-{192,512}.png (the rounded badge),
// web/icons/Icon-maskable-{192,512}.png (full bleed, logo inside the maskable
// safe zone) and build/brand_preview.png.

import 'dart:io';
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

void main() {
  testWidgets('render brand icons', (tester) async {
    await tester.runAsync(() async {
      await _renderIcon('web/favicon.png', 64, maskable: false);
      await _renderIcon('web/icons/Icon-192.png', 192, maskable: false);
      await _renderIcon('web/icons/Icon-512.png', 512, maskable: false);
      await _renderIcon('web/icons/Icon-maskable-192.png', 192, maskable: true);
      await _renderIcon('web/icons/Icon-maskable-512.png', 512, maskable: true);
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

    tester.view.physicalSize = const Size(1500, 1200);
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
