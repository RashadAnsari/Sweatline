import 'package:flutter/material.dart';

import '../exercise_poses.dart';

/// Animated exercise pictogram: a stick figure tweens between the start
/// and end position of the lift so you can see what the movement looks
/// like. Equipment (bar, dumbbells, cable, benches) is drawn with it.
///
/// Pose data lives in `exercise_poses.dart` on a 120x100 canvas with the
/// floor at y=92.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({
    super.key,
    required this.illustration,
    this.height = 140,
    this.animate = true,
  });

  final ExerciseIllustration illustration;
  final double height;
  final bool animate;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _FigurePainter(
            illustration: widget.illustration,
            t: widget.animate ? _t.value : 0,
            figureColor: colorScheme.primary,
            propColor: colorScheme.outline,
            floorColor: colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.illustration,
    required this.t,
    required this.figureColor,
    required this.propColor,
    required this.floorColor,
  });

  final ExerciseIllustration illustration;
  final double t;
  final Color figureColor;
  final Color propColor;
  final Color floorColor;

  static const _canvas = Size(120, 100);

  Pose get _pose => Pose.lerp(illustration.start, illustration.end, t);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _canvas.width < size.height / _canvas.height)
        ? size.width / _canvas.width
        : size.height / _canvas.height;
    canvas.save();
    canvas.translate(
      (size.width - _canvas.width * scale) / 2,
      (size.height - _canvas.height * scale) / 2,
    );
    canvas.scale(scale);

    final pose = _pose;
    final figure = Paint()
      ..color = figureColor
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final prop = Paint()
      ..color = propColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final floor = Paint()
      ..color = floorColor
      ..strokeWidth = 2;

    // Floor.
    canvas.drawLine(const Offset(6, 92), const Offset(114, 92), floor);

    // Static props: beams (benches, racks, frames) and circles (wheels).
    for (final beam in illustration.beams) {
      canvas.drawLine(beam.$1, beam.$2, prop..strokeWidth = 5);
    }
    prop.strokeWidth = 3.2;
    for (final circle in illustration.circles) {
      canvas.drawCircle(circle.$1, circle.$2, prop);
    }

    // Cable from its anchor to each hand.
    if (illustration.equipment == Equipment.cable &&
        illustration.cableAnchor != null) {
      final cable = Paint()
        ..color = propColor
        ..strokeWidth = 1.8;
      canvas.drawCircle(illustration.cableAnchor!, 2.5, prop);
      for (final arm in pose.arms) {
        canvas.drawLine(illustration.cableAnchor!, arm.end, cable);
      }
    }

    // Figure: torso, neck, head, limbs.
    canvas.drawLine(pose.hip, pose.shoulder, figure);
    canvas.drawLine(pose.shoulder, pose.head, figure);
    canvas.drawCircle(pose.head, 5.2, Paint()..color = figureColor);
    for (final leg in pose.legs) {
      canvas.drawLine(pose.hip, leg.mid, figure);
      canvas.drawLine(leg.mid, leg.end, figure);
    }
    for (final arm in pose.arms) {
      canvas.drawLine(pose.shoulder, arm.mid, figure);
      canvas.drawLine(arm.mid, arm.end, figure);
    }

    // Hand-held equipment follows the hands.
    final held = Paint()
      ..color = propColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    switch (illustration.equipment) {
      case Equipment.barbell:
        for (final arm in pose.arms) {
          canvas.drawCircle(arm.end, 6, held);
          canvas.drawLine(
            arm.end.translate(-9, 0),
            arm.end.translate(9, 0),
            held,
          );
        }
      case Equipment.dumbbells:
        for (final arm in pose.arms) {
          canvas.drawCircle(arm.end, 3.4, held);
        }
      case Equipment.cable:
      case Equipment.none:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.illustration != illustration ||
      oldDelegate.figureColor != figureColor;
}
