import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/exercise_library.dart';
import 'package:sweatline/models.dart';
import 'package:sweatline/plan_generator.dart';

void main() {
  test('generates one plan day per training day for 2 to 6 days', () {
    for (var days = 2; days <= 6; days++) {
      final plan = generatePlan(
        goal: Goal.buildMuscle,
        level: Level.advanced,
        daysPerWeek: days,
      );
      expect(plan.days.length, days);
      expect(
        plan.days.map((d) => d.key).toSet().length,
        days,
        reason: 'day keys must be unique so the split can cycle',
      );
    }
  });

  test('rejects unsupported training frequency', () {
    expect(
      () => generatePlan(
        goal: Goal.getFit,
        level: Level.beginner,
        daysPerWeek: 7,
      ),
      throwsArgumentError,
    );
  });

  test('volume scales with experience level', () {
    expect(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ).days.every((d) => d.exercises.length == 4),
      isTrue,
    );
    expect(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.intermediate,
        daysPerWeek: 3,
      ).days.every((d) => d.exercises.length == 6),
      isTrue,
    );
    expect(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.advanced,
        daysPerWeek: 3,
      ).days.every((d) => d.exercises.length == 7),
      isTrue,
    );
  });

  test('main lift, secondary compounds, and isolation get distinct rx', () {
    final plan = generatePlan(
      goal: Goal.buildMuscle,
      level: Level.beginner,
      daysPerWeek: 3,
    );
    // Push day: benchPress (main), overheadPress (compound),
    // inclineDbPress (compound), chestFly (isolation).
    final push = plan.days.first.exercises;
    final main = push[0];
    expect(main.exerciseId, 'benchPress');
    expect(main.sets, 4);
    expect(main.repsMax, 8);
    expect(main.restSeconds, 180);
    expect(main.warmupSets, 2);

    final secondary = push[1];
    expect(exerciseById(secondary.exerciseId).isCompound, isTrue);
    expect(secondary.repsMax, 10);
    expect(secondary.restSeconds, 120);
    expect(secondary.warmupSets, 1);

    final isolation = push.firstWhere(
      (e) => !exerciseById(e.exerciseId).isCompound,
    );
    expect(isolation.repsMax, 15);
    expect(isolation.restSeconds, 90);
    expect(isolation.warmupSets, 0);
  });

  test('goal shifts rep ranges and rest periods', () {
    // Fat loss keeps loads moderately heavy to preserve muscle in a
    // deficit; only build-muscle goes heavier still on the main lift.
    final loseWeight = generatePlan(
      goal: Goal.loseWeight,
      level: Level.beginner,
      daysPerWeek: 3,
    ).days.first.exercises.first;
    expect(loseWeight.repsMin, 8);
    expect(loseWeight.repsMax, 10);
    expect(loseWeight.restSeconds, 120);
  });

  test('deadlift as main lift is capped at 3 sets of 5-8', () {
    final pull = generatePlan(
      goal: Goal.buildMuscle,
      level: Level.intermediate,
      daysPerWeek: 3,
    ).days[1];
    final deadlift = pull.exercises.first;
    expect(deadlift.exerciseId, 'deadlift');
    expect(deadlift.sets, 3);
    expect(deadlift.repsMin, 5);
    expect(deadlift.repsMax, 8);
    expect(deadlift.warmupSets, 2);
  });

  test('beginner pull day includes rear-delt work', () {
    final pull = generatePlan(
      goal: Goal.getFit,
      level: Level.beginner,
      daysPerWeek: 3,
    ).days[1];
    expect(pull.exercises.map((e) => e.exerciseId), contains('facePull'));
  });

  test('5-day split has two distinct leg days, no duplicate day content', () {
    final plan = generatePlan(
      goal: Goal.buildMuscle,
      level: Level.intermediate,
      daysPerWeek: 5,
    );
    expect(plan.days.map((d) => d.key), containsAll(['legs', 'legsB']));
    final legs = plan.days.firstWhere((d) => d.key == 'legs');
    final legsB = plan.days.firstWhere((d) => d.key == 'legsB');
    expect(
      legs.exercises.first.exerciseId,
      isNot(legsB.exercises.first.exerciseId),
    );
  });

  test('lower-body compounds progress in bigger jumps', () {
    expect(incrementFor('squat'), 5.0);
    expect(incrementFor('deadlift'), 5.0);
    expect(incrementFor('legPress'), 5.0);
    expect(incrementFor('benchPress'), progressionIncrementKg);
    expect(incrementFor('bicepCurl'), progressionIncrementKg);
  });

  test('every planned exercise exists in the library and none is cardio', () {
    for (var days = 2; days <= 6; days++) {
      final plan = generatePlan(
        goal: Goal.getFit,
        level: Level.advanced,
        daysPerWeek: days,
      );
      for (final day in plan.days) {
        for (final planned in day.exercises) {
          final exercise = exerciseById(planned.exerciseId);
          expect(exercise.group, isNot('cardio'));
        }
      }
    }
  });

  test('plan survives a JSON round trip including warm-up sets', () {
    final plan = generatePlan(
      goal: Goal.loseWeight,
      level: Level.intermediate,
      daysPerWeek: 4,
    );
    final restored = Plan.fromJson(plan.toJson());
    expect(restored.goal, plan.goal);
    expect(restored.level, plan.level);
    expect(restored.days.length, plan.days.length);
    expect(
      restored.days.first.exercises.first.warmupSets,
      plan.days.first.exercises.first.warmupSets,
    );
  });

  test('library data is complete for every exercise', () {
    for (final exercise in exerciseLibrary) {
      expect(exercise.steps, isNotEmpty, reason: exercise.id);
      expect(exercise.tips, isNotEmpty, reason: exercise.id);
      expect(exercise.primaryMuscles, isNotEmpty, reason: exercise.id);
      expect(exerciseGroups, contains(exercise.group), reason: exercise.id);
    }
  });
}
