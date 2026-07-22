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

  test('similarExercises never offers cardio in place of a lift', () {
    // Calf raises share the calves with jump rope, leg extensions share the
    // quads with the bike: conditioning work must not inherit a lifting slot.
    for (final id in ['calfRaise', 'legExtension', 'rearDeltFly', 'squat']) {
      for (final e in similarExercises(id)) {
        expect(e.group, isNot('cardio'), reason: 'offered ${e.id} for $id');
      }
    }
  });

  test('similarExercises keeps held and counted work apart', () {
    // A plank prescribed in seconds must never be swapped for a rep-based
    // movement, or the other way round.
    for (final e in similarExercises('plank')) {
      expect(e.isTimed, isTrue);
    }
    for (final e in similarExercises('cableCrunch')) {
      expect(e.isTimed, isFalse, reason: '${e.id} is held, not counted');
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
