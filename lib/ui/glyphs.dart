// The app's icons, drawn in the logo's style: round-capped monoline strokes
// on a 100 x 100 grid, with open rings for nodes and solid dots for
// endpoints. Strokes are a little heavier than the logo's (7.5 vs 6) so they
// stay legible at 16-24 px. A "filled" icon (a selected tab) fills its rings
// and boxes, as the logo fills its two endpoints.

import 'dart:math' as math;

import 'package:flutter/material.dart';

const _stroke = 7.5;
const _ringRadius = 8.0;
const _ringStroke = 6.5;
const _dotRadius = 9.0;

sealed class _Part {
  const _Part();
}

/// A polyline through (x, y) pairs.
class _Line extends _Part {
  const _Line(this.points, {this.closed = false});

  final List<double> points;
  final bool closed;
}

/// A node: an open ring, filled when the icon is.
class _Ring extends _Part {
  const _Ring(this.x, this.y);

  final double x, y;
}

/// An endpoint: always solid.
class _Dot extends _Part {
  const _Dot(this.x, this.y, [this.r = _dotRadius]);

  final double x, y, r;
}

/// A stroked circle (outlines, lenses, coins).
class _Circle extends _Part {
  const _Circle(this.x, this.y, this.r);

  final double x, y, r;
}

/// A stroked rounded box, filled when the icon is (unless `fillable` is off,
/// for boxes with detail inside).
class _Box extends _Part {
  const _Box(this.x, this.y, this.w, this.h, [this.r = 8, this.fillable = true]);

  final double x, y, w, h, r;
  final bool fillable;
}

/// An arc, clockwise from `start` degrees (0 = right), optionally ending in
/// an arrowhead. With `ry`, an arc of an ellipse `r` wide and `ry` tall.
class _Arc extends _Part {
  const _Arc(this.x, this.y, this.r, this.start, this.sweep, {this.arrow = false, this.ry});

  final double x, y, r, start, sweep;
  final bool arrow;
  final double? ry;
}

/// A closed stroked outline of cubic curves: a start point, then (control 1,
/// control 2, end) triples.
class _Curve extends _Part {
  const _Curve(this.points);

  final List<double> points;
}

/// A stroked ellipse.
class _Oval extends _Part {
  const _Oval(this.x, this.y, this.rx, this.ry);

  final double x, y, rx, ry;
}

/// A stroked crescent: circle (x, y, r) with circle (cx, cy, cr) cut away.
class _Crescent extends _Part {
  const _Crescent(this.x, this.y, this.r, this.cx, this.cy, this.cr);

  final double x, y, r, cx, cy, cr;
}

enum Glyph {
  /// A thread: a root with replies branching off it.
  thread([
    _Line([26, 18, 26, 78]),
    _Line([26, 48, 74, 48]),
    _Line([26, 78, 74, 78]),
    _Dot(26, 18),
    _Ring(74, 48),
    _Ring(74, 78),
  ]),

  /// A reply: a line from the parent node down to the new message.
  reply([
    _Line([26, 22, 26, 56, 74, 78]),
    _Ring(26, 22),
    _Dot(74, 78),
  ]),

  /// A transfer: tokens moving from one address to another.
  transfer([
    _Line([16, 50, 84, 50]),
    _Line([64, 30, 84, 50, 64, 70]),
    _Dot(16, 50),
  ]),
  flag([
    _Line([26, 86, 26, 14]),
    _Line([26, 16, 78, 16, 64, 34, 78, 52, 26, 52]),
    _Dot(26, 86, 8),
  ]),

  /// A star: five points around a node, which fills when starred.
  star([
    _Line([50, 10, 60, 38, 88, 40, 66, 58, 74, 86, 50, 70, 26, 86, 34, 58, 12, 40, 40, 38], closed: true),
    _Ring(50, 52),
  ]),

  /// Share: one node passing to two others, like the logo's links.
  share([
    _Line([72, 22, 28, 50, 72, 78]),
    _Ring(72, 22),
    _Ring(28, 50),
    _Ring(72, 78),
  ]),

  /// A token amount: one coin, rim and face.
  coin([
    _Circle(50, 50, 36),
    _Circle(50, 50, 20),
  ]),

  /// A QR code: three corner squares with their centres, and a few modules.
  qr([
    _Box(10, 10, 32, 32, 6, false),
    _Box(58, 10, 32, 32, 6, false),
    _Box(10, 58, 32, 32, 6, false),
    _Dot(26, 26, 6),
    _Dot(74, 26, 6),
    _Dot(26, 74, 6),
    _Dot(64, 64, 5),
    _Dot(84, 64, 5),
    _Dot(74, 76, 5),
    _Dot(64, 88, 5),
    _Dot(88, 88, 5),
  ]),

  /// Seen again: an open eye (unmute an address).
  show([
    _Oval(50, 50, 40, 24),
    _Ring(50, 50),
  ]),

  /// Out of sight: the eye struck through (mute an address).
  hide([
    _Oval(50, 50, 40, 24),
    _Ring(50, 50),
    _Line([18, 84, 82, 16]),
  ]),

  /// Messages this wallet sent.
  outbox([
    _Line([14, 58, 14, 84, 86, 84, 86, 58]),
    _Line([50, 62, 50, 14]),
    _Line([32, 32, 50, 14, 68, 32]),
    _Ring(50, 64),
  ]),
  wallet([
    _Box(12, 24, 76, 56, 12, false),
    _Ring(68, 52),
  ]),

  /// Mining and the chain's technical view: blocks linked in a row.
  blocks([
    _Box(8, 38, 24, 24, 6),
    _Line([32, 50, 38, 50]),
    _Box(38, 38, 24, 24, 6),
    _Line([62, 50, 68, 50]),
    _Box(68, 38, 24, 24, 6),
  ]),

  /// A fee, which goes to the miner: a pickaxe. The head is an arc and the
  /// handle ends in a solid node; drawn upright, then turned 45 degrees about
  /// the centre.
  fee([
    _Arc(40.1, 59.9, 44, 265, 100),
    _Line([71.2, 28.8, 20.3, 79.7]),
    _Dot(20.3, 79.7, 8),
  ]),  send([
    _Line([14, 18, 88, 50, 14, 82, 28, 50], closed: true),
    _Line([28, 50, 56, 50]),
  ]),
  edit([
    _Line([18, 82, 22, 64, 64, 22, 78, 36, 36, 78], closed: true),
    _Line([56, 30, 70, 44]),
  ]),
  key([
    _Circle(32, 50, 16),
    _Line([48, 50, 86, 50]),
    _Line([72, 50, 72, 64]),
    _Line([84, 50, 84, 62]),
  ]),
  keyOff([
    _Circle(32, 50, 16),
    _Line([48, 50, 86, 50]),
    _Line([72, 50, 72, 64]),
    _Line([84, 50, 84, 62]),
    _Line([14, 86, 86, 14]),
  ]),
  logout([
    _Line([46, 16, 18, 16, 18, 84, 46, 84]),
    _Line([38, 50, 84, 50]),
    _Line([66, 32, 84, 50, 66, 68]),
  ]),
  add([
    _Line([50, 18, 50, 82]),
    _Line([18, 50, 82, 50]),
  ]),
  import([
    _Line([50, 14, 50, 64]),
    _Line([30, 44, 50, 64, 70, 44]),
    _Line([18, 84, 82, 84]),
  ]),
  copy([
    _Box(34, 34, 50, 50, 9),
    _Line([60, 16, 16, 16, 16, 60]),
  ]),
  refresh([
    _Arc(50, 52, 30, 330, 300, arrow: true),
  ]),
  search([
    _Circle(42, 42, 26),
    _Line([61, 61, 84, 84]),
  ]),
  arrowForward([
    _Line([16, 50, 84, 50]),
    _Line([60, 26, 84, 50, 60, 74]),
  ]),
  chevronLeft([
    _Line([62, 18, 34, 50, 62, 82]),
  ]),
  chevronRight([
    _Line([38, 18, 66, 50, 38, 82]),
  ]),
  openInNew([
    _Line([42, 18, 18, 18, 18, 82, 82, 82, 82, 58]),
    _Line([48, 52, 82, 18]),
    _Line([58, 18, 82, 18, 82, 42]),
  ]),
  confirmed([
    _Circle(50, 50, 40),
    _Line([32, 52, 45, 65, 70, 38]),
  ]),
  pending([
    _Circle(50, 50, 40),
    _Line([50, 26, 50, 50, 66, 62]),
  ]),
  warning([
    _Line([50, 12, 90, 84, 10, 84], closed: true),
    _Line([50, 38, 50, 60]),
    _Dot(50, 72, 5.5),
  ]),
  error([
    _Circle(50, 50, 40),
    _Line([50, 28, 50, 56]),
    _Dot(50, 71, 5.5),
  ]),
  unknown([
    _Circle(50, 50, 40),
    _Arc(50, 40, 13, 180, 250),
    _Line([54.4, 52.2, 50, 58, 50, 62]),
    _Dot(50, 75, 5.5),
  ]),

  /// Light mode (shown while dark, as the mode to switch to).
  sun([
    _Circle(50, 50, 16),
    _Line([79, 50, 90, 50]),
    _Line([21, 50, 10, 50]),
    _Line([50, 79, 50, 90]),
    _Line([50, 21, 50, 10]),
    _Line([70.5, 70.5, 78.3, 78.3]),
    _Line([29.5, 70.5, 21.7, 78.3]),
    _Line([29.5, 29.5, 21.7, 21.7]),
    _Line([70.5, 29.5, 78.3, 21.7]),
  ]),

  /// Dark mode: a crescent with a star as a solid node.
  moon([
    _Crescent(46, 54, 32, 68, 34, 26),
    _Dot(82, 18, 6),
  ]),

  /// Burned tokens: a flame with a second tongue, around a solid core.
  burn([
    _Curve([
      54, 8, //
      58, 28, 80, 38, 78, 62,
      76, 80, 64, 90, 50, 90,
      34, 90, 22, 78, 22, 62,
      22, 50, 28, 42, 34, 34,
      38, 44, 42, 46, 44, 38,
      46, 26, 48, 16, 54, 8,
    ]),
    _Dot(50, 70, 8),
  ]),

  /// A total cost: a receipt.
  receipt([
    _Line([22, 12, 78, 12, 78, 88, 69, 80, 60, 88, 50, 80, 40, 88, 31, 80, 22, 88], closed: true),
    _Line([36, 34, 64, 34]),
    _Line([36, 52, 64, 52]),
  ]),

  /// What stays in the wallet: a stack of coins, seen from the side.
  coins([
    _Oval(32, 32, 20, 8),
    _Line([12, 32, 12, 72]),
    _Line([52, 32, 52, 72]),
    _Arc(32, 45, 20, 0, 180, ry: 8),
    _Arc(32, 58, 20, 0, 180, ry: 8),
    _Arc(32, 72, 20, 0, 180, ry: 8),
    _Circle(72, 64, 16),
    _Dot(72, 64, 6),
  ]),

  /// Language: a globe.
  language([
    _Circle(50, 50, 38),
    _Oval(50, 50, 16, 38),
    _Line([12, 50, 88, 50]),
  ]),

  /// Filters: a funnel.
  filter([
    _Line([14, 18, 86, 18, 58, 50, 58, 80, 42, 88, 42, 50], closed: true),
  ]),

  /// A status light: one solid node.
  node([
    _Dot(50, 50, 30),
  ]);

  const Glyph(this._parts);

  final List<_Part> _parts;

  /// Glyphs that point along the reading direction, mirrored in
  /// right-to-left languages (as Material mirrors its directional icons).
  static const _directional = {thread, reply, transfer, send, arrowForward, chevronLeft, chevronRight, logout};

  bool get directional => _directional.contains(this);
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color, this.filled);

  final Glyph glyph;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke;
    final fill = Paint()..color = color;

    for (final part in glyph._parts) {
      switch (part) {
        case _Line(:final points, :final closed):
          final path = Path()..moveTo(points[0], points[1]);
          for (var i = 2; i < points.length; i += 2) {
            path.lineTo(points[i], points[i + 1]);
          }
          if (closed) path.close();
          canvas.drawPath(path, stroke);
        case _Ring(:final x, :final y):
          canvas.drawCircle(
              Offset(x, y), filled ? _ringRadius + _ringStroke / 2 : _ringRadius, filled ? fill : ring);
        case _Dot(:final x, :final y, :final r):
          canvas.drawCircle(Offset(x, y), r, fill);
        case _Circle(:final x, :final y, :final r):
          canvas.drawCircle(Offset(x, y), r, stroke);
        case _Box(:final x, :final y, :final w, :final h, :final r, :final fillable):
          final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
          if (filled && fillable) canvas.drawRRect(rrect, fill);
          canvas.drawRRect(rrect, stroke);
        case _Arc(:final x, :final y, :final r, :final start, :final sweep, :final arrow, :final ry):
          final a0 = start * math.pi / 180;
          final a1 = (start + sweep) * math.pi / 180;
          final bounds = Rect.fromCenter(center: Offset(x, y), width: r * 2, height: (ry ?? r) * 2);
          canvas.drawArc(bounds, a0, a1 - a0, false, stroke);
          if (arrow) {
            final end = Offset(x + r * math.cos(a1), y + r * math.sin(a1));
            // Clockwise tangent at the end, and its normal.
            final dir = Offset(-math.sin(a1), math.cos(a1));
            final normal = Offset(-dir.dy, dir.dx);
            canvas.drawPath(
              Path()
                ..moveTo((end - dir * 14 + normal * 12).dx, (end - dir * 14 + normal * 12).dy)
                ..lineTo(end.dx, end.dy)
                ..lineTo((end - dir * 14 - normal * 12).dx, (end - dir * 14 - normal * 12).dy),
              stroke,
            );
          }
        case _Curve(:final points):
          final path = Path()..moveTo(points[0], points[1]);
          for (var i = 2; i + 5 < points.length; i += 6) {
            path.cubicTo(points[i], points[i + 1], points[i + 2], points[i + 3], points[i + 4], points[i + 5]);
          }
          path.close();
          canvas.drawPath(path, stroke);
        case _Oval(:final x, :final y, :final rx, :final ry):
          canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2), stroke);
        case _Crescent(:final x, :final y, :final r, :final cx, :final cy, :final cr):
          final crescent = Path.combine(
            PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)),
            Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: cr)),
          );
          if (filled) canvas.drawPath(crescent, fill);
          canvas.drawPath(crescent, stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color || old.filled != filled;
}

/// A glyph, sized and colored by the surrounding IconTheme unless given, so it
/// drops in wherever an Icon went (buttons, navigation bars, list tiles).
class MurmurIcon extends StatelessWidget {
  const MurmurIcon(this.glyph, {super.key, this.size, this.color, this.filled = false, this.semanticLabel});

  final Glyph glyph;
  final double? size;
  final Color? color;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    final color = this.color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    Widget paint = CustomPaint(size: Size.square(size), painter: _GlyphPainter(glyph, color, filled));
    if (glyph.directional && Directionality.maybeOf(context) == TextDirection.rtl) {
      paint = Transform.flip(flipX: true, child: paint);
    }
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(child: paint),
    );
  }
}

/// A glyph in a ringed circle, the list-row counterpart of the logo's
/// nodes: copper and solid-edged once confirmed, muted while pending.
class GlyphAvatar extends StatelessWidget {
  const GlyphAvatar(this.glyph, {super.key, this.active = true, this.size = 40});

  final Glyph glyph;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? scheme.primaryContainer.withValues(alpha: 0.35) : scheme.surfaceContainerHigh,
        border: Border.all(color: color.withValues(alpha: active ? 0.9 : 0.5), width: 1.5),
      ),
      child: MurmurIcon(glyph, size: size * 0.5, color: color),
    );
  }
}
