/// Renders every exercise pictogram into one review sheet
/// (test/goldens/figure_gallery.png). Regenerate with:
///   flutter test --update-goldens --tags golden test/tools/figure_gallery_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/exercise_library.dart';
import 'package:sweatline/exercise_poses.dart';
import 'package:sweatline/widgets/exercise_figure.dart';

void main() {
  testWidgets('exercise figure gallery sheet', (tester) async {
    const columns = 5;
    const cellWidth = 240.0;
    const cellHeight = 200.0;
    final rows = (exerciseLibrary.length / columns).ceil();
    final size = Size(columns * cellWidth, rows * cellHeight);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF12140D),
          child: GridView.count(
            crossAxisCount: columns,
            childAspectRatio: cellWidth / cellHeight,
            children: [
              for (final exercise in exerciseLibrary)
                Column(
                  children: [
                    ExerciseFigure(
                      illustration: illustrationFor(exercise.id),
                      height: 160,
                      animate: false,
                    ),
                    Text(
                      exercise.id,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(GridView),
      matchesGoldenFile('../goldens/figure_gallery.png'),
    );
  });
}
