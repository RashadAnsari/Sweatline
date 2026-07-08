import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/exercise_library.dart';
import 'package:sweatline/exercise_poses.dart';

void main() {
  test('every library exercise has a hand-authored illustration', () {
    for (final exercise in exerciseLibrary) {
      expect(
        illustratedExerciseIds,
        contains(exercise.id),
        reason: '${exercise.id} falls back to the generic figure',
      );
    }
  });

  test('no orphan illustrations for removed exercises', () {
    final libraryIds = exerciseLibrary.map((e) => e.id).toSet();
    for (final id in illustratedExerciseIds) {
      expect(libraryIds, contains(id), reason: '$id has no library entry');
    }
  });

  test('poses are lerp-safe and stay on the canvas', () {
    void checkPoint(String id, Offset point) {
      expect(point.dx, inInclusiveRange(0, 120), reason: id);
      expect(point.dy, inInclusiveRange(0, 100), reason: id);
    }

    for (final exercise in exerciseLibrary) {
      final illustration = illustrationFor(exercise.id);
      // Matching limb counts, otherwise Pose.lerp throws mid-animation.
      expect(
        illustration.start.arms.length,
        illustration.end.arms.length,
        reason: exercise.id,
      );
      expect(
        illustration.start.legs.length,
        illustration.end.legs.length,
        reason: exercise.id,
      );
      for (final pose in [illustration.start, illustration.end]) {
        checkPoint(exercise.id, pose.head);
        checkPoint(exercise.id, pose.shoulder);
        checkPoint(exercise.id, pose.hip);
        for (final limb in [...pose.arms, ...pose.legs]) {
          checkPoint(exercise.id, limb.mid);
          checkPoint(exercise.id, limb.end);
        }
      }
    }
  });
}
