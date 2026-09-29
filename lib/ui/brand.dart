// Murmur's look: the copper-on-ink palette of the logo (murmur-logo.svg,
// murmur-logo-badge.svg), the themes built from it, and the logo itself.

import 'package:flutter/material.dart';

class BrandColors {
  /// The logo's copper.
  static const copper = Color(0xFFC1703A);

  /// The badge's background.
  static const ink = Color(0xFF17171A);

  /// Copper deepened enough to read as text on the light background.
  static const copperDeep = Color(0xFFA65A28);

  /// Warm paper, the light theme's background.
  static const paper = Color(0xFFFAF7F3);
}

/// Colors for transaction and connection states, per theme.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.success, required this.pending, required this.danger, required this.idle});

  final Color success;
  final Color pending;
  final Color danger;
  final Color idle;

  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith({Color? success, Color? pending, Color? danger, Color? idle}) => StatusColors(
      success: success ?? this.success,
      pending: pending ?? this.pending,
      danger: danger ?? this.danger,
      idle: idle ?? this.idle);

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          success: Color.lerp(success, other.success, t)!,
          pending: Color.lerp(pending, other.pending, t)!,
          danger: Color.lerp(danger, other.danger, t)!,
          idle: Color.lerp(idle, other.idle, t)!,
        );
}

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: BrandColors.copper,
  onPrimary: BrandColors.ink,
  primaryContainer: Color(0xFF4A2C1A),
  onPrimaryContainer: Color(0xFFF2C8A8),
  secondary: Color(0xFFCBA88C),
  onSecondary: BrandColors.ink,
  secondaryContainer: Color(0xFF2E2622),
  onSecondaryContainer: Color(0xFFEBD3C0),
  tertiary: Color(0xFFA8A09A),
  onTertiary: BrandColors.ink,
  tertiaryContainer: Color(0xFF2A2A30),
  onTertiaryContainer: Color(0xFFD8D2CC),
  error: Color(0xFFE0705F),
  onError: BrandColors.ink,
  errorContainer: Color(0xFF4A1F1A),
  onErrorContainer: Color(0xFFF6C9C2),
  surface: BrandColors.ink,
  onSurface: Color(0xFFEDE7E1),
  onSurfaceVariant: Color(0xFFA8A09A),
  surfaceDim: BrandColors.ink,
  surfaceBright: Color(0xFF37373D),
  surfaceContainerLowest: Color(0xFF121214),
  surfaceContainerLow: Color(0xFF1C1C20),
  surfaceContainer: Color(0xFF212125),
  surfaceContainerHigh: Color(0xFF28282D),
  surfaceContainerHighest: Color(0xFF303036),
  outline: Color(0xFF5A5A62),
  outlineVariant: Color(0xFF34343A),
  inverseSurface: Color(0xFFEDE7E1),
  onInverseSurface: BrandColors.ink,
  inversePrimary: BrandColors.copperDeep,
  surfaceTint: BrandColors.copper,
  shadow: Colors.black,
  scrim: Colors.black,
);

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: BrandColors.copperDeep,
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFF6DCC8),
  onPrimaryContainer: Color(0xFF3D1E0A),
  secondary: Color(0xFF7A5A44),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFF1E4D8),
  onSecondaryContainer: Color(0xFF2E2016),
  tertiary: Color(0xFF6B645E),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFECE6E0),
  onTertiaryContainer: Color(0xFF26221F),
  error: Color(0xFFB3392E),
  onError: Colors.white,
  errorContainer: Color(0xFFFADAD5),
  onErrorContainer: Color(0xFF410E0A),
  surface: BrandColors.paper,
  onSurface: BrandColors.ink,
  onSurfaceVariant: Color(0xFF5E5750),
  surfaceDim: Color(0xFFE2DAD1),
  surfaceBright: BrandColors.paper,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF5F0EA),
  surfaceContainer: Color(0xFFF0EAE3),
  surfaceContainerHigh: Color(0xFFEAE3DB),
  surfaceContainerHighest: Color(0xFFE4DCD3),
  outline: Color(0xFF9C938A),
  outlineVariant: Color(0xFFDDD5CC),
  inverseSurface: BrandColors.ink,
  onInverseSurface: Color(0xFFEDE7E1),
  inversePrimary: BrandColors.copper,
  surfaceTint: BrandColors.copperDeep,
  shadow: Colors.black,
  scrim: Colors.black,
);

ThemeData _theme(ColorScheme scheme, StatusColors status) => ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [status],
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
            )),
      ),
      cardTheme: CardThemeData(color: scheme.surfaceContainerLow, elevation: 0),
      floatingActionButtonTheme:
          FloatingActionButtonThemeData(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
    );

final darkTheme = _theme(
  _darkScheme,
  const StatusColors(
      success: Color(0xFF8DB07F), pending: BrandColors.copper, danger: Color(0xFFE0705F), idle: Color(0xFF6E6E76)),
);

final lightTheme = _theme(
  _lightScheme,
  const StatusColors(
      success: Color(0xFF4E7A42), pending: BrandColors.copperDeep, danger: Color(0xFFB3392E), idle: Color(0xFF9C938A)),
);

// ---- logo -------------------------------------------------------------------

/// Draws murmur-logo.svg (a 100 x 100 design) into `size`.
void paintLogo(Canvas canvas, Size size, Color color) {
  canvas.save();
  canvas.scale(size.width / 100, size.height / 100);
  final line = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(
    Path()
      ..moveTo(15, 80)
      ..lineTo(30, 25)
      ..lineTo(50, 60)
      ..lineTo(70, 25)
      ..lineTo(85, 80),
    line,
  );
  final fill = Paint()..color = color;
  final ring = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  canvas.drawCircle(const Offset(15, 80), 8.5, fill);
  canvas.drawCircle(const Offset(85, 80), 8.5, fill);
  for (final c in const [Offset(30, 25), Offset(50, 60), Offset(70, 25)]) {
    canvas.drawCircle(c, 7.5, ring);
  }
  canvas.restore();
}

/// Draws murmur-logo-badge.svg (196 x 196): the logo on an ink rounded square.
void paintBadge(Canvas canvas, Size size, {bool rounded = true}) {
  final s = size.width / 196;
  final rect = Offset.zero & size;
  final bg = Paint()..color = BrandColors.ink;
  if (rounded) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(45 * s)), bg);
  } else {
    canvas.drawRect(rect, bg);
  }
  canvas.save();
  canvas.translate(25.5 * s, 25.5 * s);
  paintLogo(canvas, Size(145 * s, 145 * s), BrandColors.copper);
  canvas.restore();
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintLogo(canvas, size, color);

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}

/// The Murmur mark, in copper unless told otherwise.
class MurmurLogo extends StatelessWidget {
  const MurmurLogo({super.key, this.size = 28, this.color = BrandColors.copper});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LogoPainter(color));
}
