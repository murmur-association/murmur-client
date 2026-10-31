// How addresses appear: a picture and a name.
// The name is, in order (PROTOCOL.md Section 7.8):
// - the one the user gave it on this device, never sent anywhere;
// - the alias the address published, always with the start of the address,
//   since anyone can publish any alias;
// - its short hex.
// The picture is the one the address published with its name (a profile,
// Section 7.8), or else a mark drawn from the address itself, the same on
// every device. Never both: a published picture replaces the mark.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../protocol/bytes.dart';
import '../protocol/profile.dart';
import '../services/node_client.dart';
import '../services/storage.dart';
import 'common.dart';

/// What to call `address`: the name the user gave it, its published alias
/// with the first 8 hex characters of the address ("bob · 3fa9c21e"), or
/// its short hex.
String nameOf(BuildContext context, String address) {
  final scope = AppScope.of(context);
  return nameFor(scope.prefs, scope.client, address);
}

/// [nameOf], away from the widgets: for a notification.
String nameFor(Preferences prefs, MurmurClient client, String address) {
  final own = prefs.aliases[address];
  if (own != null) return own;
  final published = tryParseHash32(address) == null ? null : client.publishedAlias(address);
  return published == null ? shortHex(address) : publicNameOf(published, address);
}

/// A published alias as it must be shown: never alone (Section 7.8).
String publicNameOf(String alias, String address) => '$alias · ${address.substring(0, 8)}';

/// A picture drawn from the address, in the logo's own language: a zigzag
/// of nodes and lines (like the logo's M, but never mirrored), rings between
/// filled ends, a few stems like replies, in one warm colour of the copper family and one cool complement, on a
/// soft two-tone tile with faint ripples. Easy to tell apart at a glance,
/// and the same wherever it's shown.
class AddressAvatar extends StatelessWidget {
  const AddressAvatar(this.address, {super.key, this.size = 40});

  final String address;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = tryParseHash32(address);
    final scope = AppScope.of(context);
    // A published picture stands in for the mark, never beside it (Section
    // 7.8); a muted author's isn't shown.
    final picture =
        bytes == null || scope.prefs.muted.contains(address) ? null : scope.client.publishedPicture(address);
    return Semantics(
      label: nameOf(context, address),
      image: true,
      child: PicturePreview(address, picture, size: size),
    );
  }
}

/// What `address` shows with `picture` published (null: its mark), whatever
/// it published: a choice seen before it's sent.
class PicturePreview extends StatelessWidget {
  const PicturePreview(this.address, this.picture, {super.key, this.size = 40});

  final String address;
  final ProfilePicture? picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = tryParseHash32(address);
    return SizedBox.square(
      dimension: size,
      child: bytes == null
          ? null
          : CustomPaint(
              painter: picture != null
                  ? ProfilePicturePainter(picture!)
                  : AddressMarkPainter(bytes,
                      dark: Theme.of(context).brightness == Brightness.dark,
                      surface: Theme.of(context).colorScheme.surface)),
    );
  }
}

/// The 32 x 32 images drawn from pictures, kept with the picture (the
/// client keeps one object per Name).
final _pictureImages = Expando<ui.Image>('profile picture');

/// Draws a published picture (PROTOCOL.md Section 7.8) in the address
/// mark's tile shape, scaled to the canvas: sharp pixels when large, smoothed
/// when small, where a pixel is about one of the screen's.
class ProfilePicturePainter extends CustomPainter {
  ProfilePicturePainter(this.picture);

  final ProfilePicture picture;

  ui.Image _image() => _pictureImages[picture] ??= () {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        for (var y = 0; y < profileSide; y++) {
          for (var x = 0; x < profileSide; x++) {
            canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
                Paint()..color = Color(0xFF000000 + picture.rgbAt(x, y)));
          }
        }
        return recorder.endRecording().toImageSync(profileSide, profileSide);
      }();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.22)));
    canvas.drawImageRect(_image(), const Rect.fromLTWH(0, 0, profileSide * 1.0, profileSide * 1.0), rect,
        Paint()..filterQuality = size.width >= 64 ? FilterQuality.none : FilterQuality.medium);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ProfilePicturePainter oldDelegate) => oldDelegate.picture != picture;
}

/// Hue and saturation of the warm colours (the copper family) and the cool
/// ones that complement them. Lightness follows the theme.
const _warm = [(24.0, 0.58), (40.0, 0.60), (8.0, 0.50), (340.0, 0.36), (54.0, 0.50)];
const _cool = [(200.0, 0.42), (178.0, 0.36), (228.0, 0.34), (96.0, 0.30), (262.0, 0.30)];

/// Draws an address's mark (see [AddressAvatar]) in a 100 x 100 design,
/// scaled to the canvas.
class AddressMarkPainter extends CustomPainter {
  AddressMarkPainter(this.bytes, {required this.dark, required this.surface});

  final List<int> bytes;
  final bool dark;

  /// The page behind it: the rings' inside, so the line doesn't show through.
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    var bit = 0;
    // The next `n` bits of the address, in order.
    int take(int n) {
      var v = 0;
      for (var i = 0; i < n; i++, bit++) {
        v = v * 2 + ((bytes[bit ~/ 8] >> (bit % 8)) & 1);
      }
      return v;
    }

    // Two different colours from a family.
    ((double, double), (double, double)) pair(List<(double, double)> family) {
      final a = take(3) % family.length;
      return (family[a], family[(a + 1 + take(2)) % family.length]);
    }

    Color tone((double, double) hs, double light) => HSLColor.fromAHSL(1, hs.$1, hs.$2, light).toColor();
    final warm = pair(_warm);
    final cool = pair(_cool);
    final swap = take(1) == 1;
    // Four colours: the line shades from one to another of one family; its
    // rings and the accents take two of the other.
    final (lineFrom, lineTo) = swap ? cool : warm;
    final (nodeHs, accentHs) = swap ? warm : cool;
    final lineA = tone(lineFrom, dark ? 0.62 : 0.44);
    final lineB = tone(lineTo, dark ? 0.62 : 0.44);
    final node = tone(nodeHs, dark ? 0.68 : 0.40);
    final accent = tone(accentHs, dark ? 0.70 : 0.46);
    final detailed = size.width >= 32;

    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final tile = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 100, 100), const Radius.circular(22));
    canvas.clipRRect(tile);
    // The tile: the colours faintly, corner to corner.
    final corner = take(2);
    final from = [Alignment.topLeft, Alignment.topRight, Alignment.bottomRight, Alignment.bottomLeft][corner];
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = LinearGradient(
          begin: from,
          end: -from,
          colors: [
            lineA.withValues(alpha: dark ? 0.26 : 0.20),
            node.withValues(alpha: dark ? 0.14 : 0.10),
            accent.withValues(alpha: dark ? 0.12 : 0.09),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    // Ripples from that corner: a murmur spreading. Too fine to see small.
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final centre = Offset((from.x + 1) * 50, (from.y + 1) * 50);
    final radii = [34.0 + take(2) * 4, 56.0 + take(2) * 4];
    if (detailed) {
      canvas.drawCircle(centre, radii[0], ripple..color = node.withValues(alpha: dark ? 0.22 : 0.18));
      canvas.drawCircle(centre, radii[1], ripple..color = accent.withValues(alpha: dark ? 0.20 : 0.16));
    }

    // The path: five to seven nodes across, evenly spaced, each one drawn
    // from the address (no mirroring, so the whole mark is unique). It
    // zigzags like the logo: each node two or three levels up or down from
    // the one before, turning at every node.
    const levels = [24.0, 37.0, 50.0, 63.0, 76.0];
    final count = 5 + [0, 1, 1, 2][take(2)];
    final gap = 72 / (count - 1);
    var level = take(3) % 5;
    var up = level >= 2;
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      if (i > 0) {
        var next = (level + (up ? -1 : 1) * (2 + take(1))).clamp(0, 4);
        if (next == level) next = level + (up ? 1 : -1);
        // Turn: the next step goes the other way from this one.
        up = next > level;
        level = next;
      }
      // Ends stay put; the nodes between shift a little sideways.
      final shift = i == 0 || i == count - 1 ? 0.0 : (take(2) - 1.5) * gap * 0.12;
      points.add(Offset(14 + i * gap + shift, levels[level]));
    }
    final path = Path()..addPolygon(points, false);

    // A faint echo of the path beneath it, as a murmur repeats.
    if (detailed) {
      canvas.drawPath(
        path.shift(Offset(0, take(1) == 0 ? 7 : -7)),
        Paint()
          ..color = accent.withValues(alpha: dark ? 0.30 : 0.26)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // The line, shading from one end's colour to the other's.
    final stroke = Paint()
      ..shader = LinearGradient(colors: [lineA, lineB]).createShader(const Rect.fromLTRB(14, 0, 86, 100))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    // Beads on some of the lines between nodes.
    final bead = Paint()..color = accent;
    for (var i = 0; i + 1 < points.length; i++) {
      if (take(1) == 1) canvas.drawCircle(Offset.lerp(points[i], points[i + 1], 0.5)!, 2.8, bead);
    }

    // Up to two stems off nodes between the ends, like a thread's replies,
    // each toward the side with more room, ending in a dot or a diamond.
    final stemCount = [0, 1, 1, 2][take(2)];
    final stems = <int>{for (var s = 0; s < stemCount; s++) 1 + take(3) % (count - 2)};
    final tips = <(Offset, bool)>[];
    stroke.strokeWidth = 5;
    for (final i in stems) {
      final p = points[i];
      final end = Offset(p.dx, p.dy <= 50 ? p.dy + 18 : p.dy - 18);
      canvas.drawLine(p, end, stroke);
      tips.add((end, take(1) == 1));
    }

    // Filled ends in the line's colours, some with an eye; rings in the
    // other family around a tinted disc, some with a seed of the accent.
    // One ring is the mark's heart: larger and doubled.
    final hole = Paint()..color = Color.alphaBlend(node.withValues(alpha: 0.18), surface);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    final heart = 1 + take(3) % (count - 2);
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == 0 || i == points.length - 1) {
        canvas.drawCircle(p, 8, Paint()..color = i == 0 ? lineA : lineB);
        if (take(1) == 1) canvas.drawCircle(p, 2.8, Paint()..color = surface);
      } else if (i == heart) {
        canvas.drawCircle(p, 9, hole);
        canvas.drawCircle(
            p,
            9,
            ring
              ..color = accent
              ..strokeWidth = 3.2);
        canvas.drawCircle(p, 4.2, Paint()..color = node);
      } else {
        canvas.drawCircle(p, 5.8, hole);
        canvas.drawCircle(
            p,
            5.8,
            ring
              ..color = node
              ..strokeWidth = 4.5);
        if (take(1) == 1) canvas.drawCircle(p, 1.8, Paint()..color = accent);
      }
    }
    for (final (end, diamond) in tips) {
      final paint = Paint()..color = accent;
      if (diamond) {
        canvas.drawPath(
          Path()
            ..moveTo(end.dx, end.dy - 6)
            ..lineTo(end.dx + 5, end.dy)
            ..lineTo(end.dx, end.dy + 6)
            ..lineTo(end.dx - 5, end.dy)
            ..close(),
          paint,
        );
      } else {
        canvas.drawCircle(end, 5, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AddressMarkPainter old) => old.dark != dark || old.surface != surface || old.bytes != bytes;
}

/// Asks for a name for `address`, kept on this device only.
Future<void> editAlias(BuildContext context, String address) async {
  final l = context.l10n;
  final prefs = AppScope.of(context).prefs;
  final name = await showAppDialog<String>(
    context: context,
    builder: (context) => WithTextController(
        text: prefs.aliases[address] ?? '',
        builder: (context, controller) => AlertDialog(
      scrollable: true,
      title: Text(l.aliasTitle),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.aliasHelp),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLength: 32,
          decoration: InputDecoration(labelText: l.nameAddress, border: const OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l.save)),
      ],
    )),
  );
  if (name != null) await prefs.setAlias(address, name);
}
