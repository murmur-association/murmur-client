// A preview of profile pictures (protocol/profile.dart, PROTOCOL.md Section
// 7.8) beside the address marks they replace. Run from the project root:
//
//   flutter test tool/render_profiles.dart
//
// Writes build/profile_preview.png: a light and a dark panel, each with four
// pictures (a landscape, a portrait, the logo, an abstract), drawn at 128
// pixels and saved as PNG, turned into pictures as the app turns a picked
// file (services/picture.dart), then put through the profile message and
// read back. Rows, top to bottom: the picture at 72, 40 and 24 pixels; then,
// at 40, the address mark an address without a picture shows instead (a
// person shows one or the other, never both).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/profile.dart';
import 'package:murmur_client/services/picture.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/people.dart';

const _source = 128;

/// The four scenes, drawn at [_source] pixels.
final _scenes = <void Function(Canvas)>[
  // A landscape at dusk.
  (c) {
    const r = Rect.fromLTWH(0, 0, 128, 128);
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B2D6E), Color(0xFFD9645A), Color(0xFFF2B35E)]).createShader(r));
    c.drawCircle(const Offset(84, 70), 18, Paint()..color = const Color(0xFFFFE3A3));
    c.drawPath(Path()..moveTo(0, 92)..quadraticBezierTo(40, 64, 78, 90)..quadraticBezierTo(104, 104, 128, 84)..lineTo(128, 128)..lineTo(0, 128)..close(), Paint()..color = const Color(0xFF3A2E3F));
    c.drawPath(Path()..moveTo(0, 110)..quadraticBezierTo(60, 92, 128, 112)..lineTo(128, 128)..lineTo(0, 128)..close(), Paint()..color = const Color(0xFF1F1A26));
  },
  // A portrait.
  (c) {
    const r = Rect.fromLTWH(0, 0, 128, 128);
    c.drawRect(r, Paint()..shader = const RadialGradient(center: Alignment(-0.4, -0.5), radius: 1.1, colors: [Color(0xFF9FC7C2), Color(0xFF3F6E73)]).createShader(r));
    c.drawOval(const Rect.fromLTWH(22, 92, 84, 60), Paint()..color = const Color(0xFF8C3B2E));
    c.drawOval(const Rect.fromLTWH(36, 28, 56, 70), Paint()..color = const Color(0xFF3B2618));
    c.drawOval(const Rect.fromLTWH(42, 38, 44, 56), Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.3), colors: [Color(0xFFF1C9A5), Color(0xFFC98F68)]).createShader(const Rect.fromLTWH(42, 38, 44, 56)));
    c.drawArc(const Rect.fromLTWH(38, 26, 52, 36), 3.14, 3.14, true, Paint()..color = const Color(0xFF3B2618));
    final eye = Paint()..color = const Color(0xFF2A1C14);
    c.drawCircle(const Offset(56, 64), 2.6, eye);
    c.drawCircle(const Offset(72, 64), 2.6, eye);
    c.drawArc(const Rect.fromLTWH(56, 72, 16, 10), 0.3, 2.5, false, Paint()..color = const Color(0xFF8A4A3A)..style = PaintingStyle.stroke..strokeWidth = 2.4);
  },
  // The logo.
  (c) {
    c.drawRect(const Rect.fromLTWH(0, 0, 128, 128), Paint()..color = BrandColors.ink);
    c.translate(20, 20);
    paintLogo(c, const Size(88, 88), BrandColors.copper);
  },
  // An abstract.
  (c) {
    c.drawRect(const Rect.fromLTWH(0, 0, 128, 128), Paint()..color = const Color(0xFFF4EDE2));
    for (final (x, y, r, color) in const [
      (40.0, 44.0, 40.0, Color(0xCCE07A3F)),
      (88.0, 52.0, 34.0, Color(0xAA3E7CB1)),
      (64.0, 92.0, 38.0, Color(0xAA6BA368)),
    ]) {
      c.drawCircle(Offset(x, y), r, Paint()..color = color);
    }
  },
];

/// `scene` as a PNG file's bytes, as a user would pick one.
Future<Uint8List> _png(void Function(Canvas) scene) async {
  final recorder = ui.PictureRecorder();
  scene(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_source, _source);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

void main() {
  testWidgets('render profile previews', (tester) async {
    await tester.runAsync(() async {
      final pictures = <ProfilePicture>[];
      for (final scene in _scenes) {
        // As the app makes and sends it, then read back: what others see.
        final message = profileMessage('bob', (await pictureFromImage(await _png(scene)))!);
        pictures.add(profileOf(message)!.picture);
      }
      final addresses = [for (var i = 0; i < _scenes.length; i++) sha256.convert('profile preview $i'.codeUnits).bytes];

      const cell = 100.0, pad = 24.0, scale = 2.0;
      // Each row: its size, and whether it shows the picture or the mark.
      const rows = [(72.0, true), (40.0, true), (24.0, true), (40.0, false)];
      const panelW = pad * 2 + cell * 4, panelH = pad * 2 + cell * 4;
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder)..scale(scale);
      for (final (p, dark, surface) in [(0, false, BrandColors.paper), (1, true, const Color(0xFF1C1B1F))]) {
        c.save();
        c.translate(p * panelW, 0);
        c.drawRect(const Rect.fromLTWH(0, 0, panelW, panelH), Paint()..color = surface);
        for (var col = 0; col < pictures.length; col++) {
          for (var row = 0; row < rows.length; row++) {
            final (size, picture) = rows[row];
            c.save();
            c.translate(pad + col * cell + (cell - size) / 2, pad + row * cell + (cell - size) / 2);
            (picture
                    ? ProfilePicturePainter(pictures[col])
                    : AddressMarkPainter(addresses[col], dark: dark, surface: surface))
                .paint(c, Size(size, size));
            c.restore();
          }
        }
        c.restore();
      }
      final out = await recorder.endRecording().toImage((panelW * 2 * scale).round(), (panelH * scale).round());
      final png = await out.toByteData(format: ui.ImageByteFormat.png);
      File('build/profile_preview.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
