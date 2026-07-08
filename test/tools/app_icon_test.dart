/// Renders the launcher icon source image.
///
/// Regenerate assets/icon/app_icon.png with:
///   flutter test --update-goldens --tags golden test/tools/app_icon_test.dart
///   dart run flutter_launcher_icons
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app icon source image', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const RepaintBoundary(
        child: CustomPaint(painter: _IconPainter(), size: Size(1024, 1024)),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('../../assets/icon/app_icon.png'),
    );
  });
}

/// Volt lightning bolt on charcoal, matching the app theme.
class _IconPainter extends CustomPainter {
  const _IconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF12140D),
    );

    // Subtle darker plate behind the bolt for depth.
    canvas.drawCircle(
      size.center(Offset.zero),
      440,
      Paint()..color = const Color(0xFF1B1F13),
    );

    final bolt = Path()
      ..moveTo(600, 96)
      ..lineTo(300, 584)
      ..lineTo(478, 584)
      ..lineTo(424, 928)
      ..lineTo(724, 440)
      ..lineTo(546, 440)
      ..close();
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFC8F135));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
