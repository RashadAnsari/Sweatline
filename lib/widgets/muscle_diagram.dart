import 'package:flutter/material.dart';

/// Geometric muscle map: stylized front and back body figures with the
/// target muscles highlighted. Primary muscles get the accent color,
/// secondary muscles a faded version, everything else stays neutral.
class MuscleDiagram extends StatelessWidget {
  const MuscleDiagram({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.height = 190,
  });

  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BodyPainter(
          primary: primaryMuscles,
          secondary: secondaryMuscles,
          primaryColor: colorScheme.primary,
          secondaryColor: colorScheme.primary.withValues(alpha: 0.35),
          idleColor: colorScheme.surfaceContainerHighest,
          baseColor: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.primary,
    required this.secondary,
    required this.primaryColor,
    required this.secondaryColor,
    required this.idleColor,
    required this.baseColor,
  });

  final Set<String> primary;
  final Set<String> secondary;
  final Color primaryColor;
  final Color secondaryColor;
  final Color idleColor;
  final Color baseColor;

  static const _figureWidth = 100.0;
  static const _figureHeight = 175.0;

  Paint _paintFor(String muscle) => Paint()
    ..color = primary.contains(muscle)
        ? primaryColor
        : secondary.contains(muscle)
        ? secondaryColor
        : idleColor;

  Paint get _neutral => Paint()..color = baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _figureHeight;
    final figureGap = 24.0 * scale;
    final totalWidth = (2 * _figureWidth * scale) + figureGap;
    final left = (size.width - totalWidth) / 2;

    canvas.save();
    canvas.translate(left, 0);
    canvas.scale(scale);
    _drawFront(canvas);
    canvas.restore();

    canvas.save();
    canvas.translate(left + _figureWidth * scale + figureGap, 0);
    canvas.scale(scale);
    _drawBack(canvas);
    canvas.restore();
  }

  void _capsule(
    Canvas canvas,
    Paint paint,
    double l,
    double t,
    double r,
    double b,
    double radius,
  ) {
    canvas.drawRRect(
      RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)),
      paint,
    );
  }

  void _drawHeadAndNeck(Canvas canvas) {
    canvas.drawCircle(const Offset(50, 13), 9.5, _neutral);
    _capsule(canvas, _neutral, 45, 21, 55, 30, 3);
  }

  void _drawFront(Canvas canvas) {
    _drawHeadAndNeck(canvas);
    // Traps (front slope beside the neck).
    _capsule(canvas, _paintFor('traps'), 34, 26, 45, 32, 3);
    _capsule(canvas, _paintFor('traps'), 55, 26, 66, 32, 3);
    // Shoulders.
    canvas.drawCircle(const Offset(30, 37), 8.5, _paintFor('shoulders'));
    canvas.drawCircle(const Offset(70, 37), 8.5, _paintFor('shoulders'));
    // Chest.
    _capsule(canvas, _paintFor('chest'), 36, 33, 49.5, 51, 6);
    _capsule(canvas, _paintFor('chest'), 50.5, 33, 64, 51, 6);
    // Arms.
    _capsule(canvas, _paintFor('biceps'), 21, 47, 31, 64, 5);
    _capsule(canvas, _paintFor('biceps'), 69, 47, 79, 64, 5);
    _capsule(canvas, _paintFor('forearms'), 17, 66, 26, 84, 4.5);
    _capsule(canvas, _paintFor('forearms'), 74, 66, 83, 84, 4.5);
    canvas.drawCircle(const Offset(21, 89), 3.5, _neutral);
    canvas.drawCircle(const Offset(79, 89), 3.5, _neutral);
    // Trunk.
    _capsule(canvas, _paintFor('abs'), 41, 53, 59, 80, 6);
    _capsule(canvas, _paintFor('obliques'), 35, 55, 40, 77, 2.5);
    _capsule(canvas, _paintFor('obliques'), 60, 55, 65, 77, 2.5);
    // Pelvis.
    _capsule(canvas, _neutral, 38, 82, 62, 92, 5);
    // Quads.
    _capsule(canvas, _paintFor('quads'), 36, 94, 48, 130, 6);
    _capsule(canvas, _paintFor('quads'), 52, 94, 64, 130, 6);
    // Shins (neutral on the front view).
    _capsule(canvas, _neutral, 38, 134, 47, 164, 4.5);
    _capsule(canvas, _neutral, 53, 134, 62, 164, 4.5);
    // Feet.
    _capsule(canvas, _neutral, 36, 166, 48, 172, 3);
    _capsule(canvas, _neutral, 52, 166, 64, 172, 3);
  }

  void _drawBack(Canvas canvas) {
    _drawHeadAndNeck(canvas);
    // Traps (diamond down the upper spine).
    final traps = Path()
      ..moveTo(50, 24)
      ..lineTo(33, 35)
      ..lineTo(50, 46)
      ..lineTo(67, 35)
      ..close();
    canvas.drawPath(traps, _paintFor('traps'));
    // Rear shoulders.
    canvas.drawCircle(const Offset(29, 38), 8, _paintFor('shoulders'));
    canvas.drawCircle(const Offset(71, 38), 8, _paintFor('shoulders'));
    // Upper back between the shoulder blades.
    _capsule(canvas, _paintFor('upperBack'), 36, 44, 64, 55, 4);
    // Lats (tapering wings).
    final leftLat = Path()
      ..moveTo(36, 50)
      ..lineTo(30, 55)
      ..lineTo(41, 80)
      ..lineTo(47, 72)
      ..close();
    final rightLat = Path()
      ..moveTo(64, 50)
      ..lineTo(70, 55)
      ..lineTo(59, 80)
      ..lineTo(53, 72)
      ..close();
    canvas.drawPath(leftLat, _paintFor('lats'));
    canvas.drawPath(rightLat, _paintFor('lats'));
    // Lower back.
    _capsule(canvas, _paintFor('lowerBack'), 43, 62, 57, 80, 4);
    // Arms.
    _capsule(canvas, _paintFor('triceps'), 21, 47, 31, 64, 5);
    _capsule(canvas, _paintFor('triceps'), 69, 47, 79, 64, 5);
    _capsule(canvas, _paintFor('forearms'), 17, 66, 26, 84, 4.5);
    _capsule(canvas, _paintFor('forearms'), 74, 66, 83, 84, 4.5);
    canvas.drawCircle(const Offset(21, 89), 3.5, _neutral);
    canvas.drawCircle(const Offset(79, 89), 3.5, _neutral);
    // Glutes.
    _capsule(canvas, _paintFor('glutes'), 37, 82, 49.5, 99, 7);
    _capsule(canvas, _paintFor('glutes'), 50.5, 82, 63, 99, 7);
    // Hamstrings.
    _capsule(canvas, _paintFor('hamstrings'), 36, 101, 48, 133, 6);
    _capsule(canvas, _paintFor('hamstrings'), 52, 101, 64, 133, 6);
    // Calves.
    _capsule(canvas, _paintFor('calves'), 38, 136, 47, 164, 4.5);
    _capsule(canvas, _paintFor('calves'), 53, 136, 62, 164, 4.5);
    // Feet.
    _capsule(canvas, _neutral, 36, 166, 48, 172, 3);
    _capsule(canvas, _neutral, 52, 166, 64, 172, 3);
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.primaryColor != primaryColor;
}
