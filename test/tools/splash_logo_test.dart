/// Renders the splash-screen logo: the volt bolt on a transparent
/// background, centered with margin so it survives the Android 12 circle
/// mask.
///
/// Regenerate assets/splash/splash_logo.png with:
///   flutter test --update-goldens --tags golden test/tools/splash_logo_test.dart
///   dart run flutter_native_splash:create
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash logo image', (tester) async {
    tester.view.physicalSize = const Size(1152, 1152);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const RepaintBoundary(
        child: CustomPaint(painter: _SplashPainter(), size: Size(1152, 1152)),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('../../assets/splash/splash_logo.png'),
    );
  });
}

/// Volt bolt centered at ~65% of the frame, transparent elsewhere.
class _SplashPainter extends CustomPainter {
  const _SplashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(0.65);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.scale(size.width / 1024);

    final bolt = Path()
      ..moveTo(600, 96)
      ..lineTo(300, 584)
      ..lineTo(478, 584)
      ..lineTo(424, 928)
      ..lineTo(724, 440)
      ..lineTo(546, 440)
      ..close();
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFC8F135));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
