import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/exercise_library.dart';

void main() {
  test('similarExercises shares a primary muscle and the compound role', () {
    final source = exerciseById('benchPress');
    final results = similarExercises('benchPress');

    expect(results, isNotEmpty);
    for (final e in results) {
      expect(e.id, isNot('benchPress'));
      expect(
        e.isCompound,
        source.isCompound,
        reason: '${e.id} should match the compound role of benchPress',
      );
      expect(
        e.primaryMuscles.any(source.primaryMuscles.contains),
        isTrue,
        reason: '${e.id} should share a primary muscle with benchPress',
      );
    }
  });

  test('similarExercises excludes the opposite role', () {
    // Bench press is a compound; an isolation chest move must not appear.
    final ids = similarExercises('benchPress').map((e) => e.id).toList();
    for (final id in ids) {
      expect(exerciseById(id).isCompound, isTrue);
    }
    // And an isolation source only offers isolations.
    final curl = exerciseById('bicepCurl');
    for (final e in similarExercises('bicepCurl')) {
      expect(e.isCompound, curl.isCompound);
    }
  });

  test('similarExercises ranks higher primary-muscle overlap first', () {
    final source = exerciseById('benchPress');
    final results = similarExercises('benchPress');
    int overlap(String id) => exerciseById(
      id,
    ).primaryMuscles.where(source.primaryMuscles.toSet().contains).length;
    for (var i = 1; i < results.length; i++) {
      expect(
        overlap(results[i - 1].id),
        greaterThanOrEqualTo(overlap(results[i].id)),
      );
    }
  });
}
