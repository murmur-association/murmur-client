// QR codes for invitation cards: drawn on screen, and as SVG for printing.
// Encoded on the device by package:qr (pure Dart); nothing is fetched.

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

QrImage _image(String text) => QrImage(QrCode(payload: QrPayload.fromString(text)));

/// A QR code for `text`, dark on white (scanners need the contrast) with
/// the four-module quiet zone around it.
class QrView extends StatelessWidget {
  const QrView(this.text, {super.key, this.size = 160});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _QrPainter(_image(text))),
      );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount + 8;
    final cell = size.width / n;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final dark = Paint()..color = Colors.black;
    for (var r = 0; r < image.moduleCount; r++) {
      for (var c = 0; c < image.moduleCount; c++) {
        if (image.isDark(r, c)) {
          canvas.drawRect(Rect.fromLTWH((c + 4) * cell, (r + 4) * cell, cell + 0.3, cell + 0.3), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}

/// The same QR code as an SVG element, for the printable sheet.
String qrSvg(String text, {String size = '30mm'}) {
  final image = _image(text);
  final n = image.moduleCount + 8;
  final path = StringBuffer();
  for (var r = 0; r < image.moduleCount; r++) {
    for (var c = 0; c < image.moduleCount; c++) {
      if (image.isDark(r, c)) path.write('M${c + 4} ${r + 4}h1v1h-1z');
    }
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $n $n" width="$size" height="$size" '
      'shape-rendering="crispEdges"><rect width="$n" height="$n" fill="#fff"/><path d="$path" fill="#000"/></svg>';
}
