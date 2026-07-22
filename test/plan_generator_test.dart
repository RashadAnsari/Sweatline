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
    // Push day: benchPress (main), overheadPress (compound), then the
    // isolation work.
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
    expect(progressionStep(WeightUnit.kg, 'squat'), 5.0);
    expect(progressionStep(WeightUnit.kg, 'deadlift'), 5.0);
    expect(progressionStep(WeightUnit.kg, 'legPress'), 5.0);
    expect(
      progressionStep(WeightUnit.kg, 'benchPress'),
      progressionIncrementKg,
    );
    expect(progressionStep(WeightUnit.kg, 'bicepCurl'), progressionIncrementKg);
  });

  test('pound users step up in plate sizes their gym stocks', () {
    // 2.5 kg is 5.5 lb: a jump no gym can load. Pounds step in 5 and 10.
    expect(progressionStep(WeightUnit.lb, 'benchPress'), 5.0);
    expect(progressionStep(WeightUnit.lb, 'squat'), 10.0);
  });

  test('held exercises are prescribed in seconds, not reps', () {
    // The plank is the last slot of the advanced leg day.
    final legs = generatePlan(
      goal: Goal.buildMuscle,
      level: Level.advanced,
      daysPerWeek: 3,
    ).days.firstWhere((d) => d.key == 'legs');
    final plank = legs.exercises.firstWhere((e) => e.exerciseId == 'plank');
    expect(exerciseById('plank').isTimed, isTrue);
    expect(plank.repsMin, 30);
    expect(plank.repsMax, 45);
    expect(plank.warmupSets, 0);
  });

  test('a swapped-in deadlift keeps its recovery cap', () {
    final push = generatePlan(
      goal: Goal.buildMuscle,
      level: Level.beginner,
      daysPerWeek: 3,
    ).days.first.exercises.first;
    expect(push.sets, 4);

    final swapped = prescriptionForSwap(push, 'deadlift');
    expect(swapped.exerciseId, 'deadlift');
    expect(swapped.sets, 3);
    expect(swapped.repsMin, 5);
    expect(swapped.repsMax, 8);

    // Everything else inherits the slot untouched.
    final ordinary = prescriptionForSwap(push, 'dbBenchPress');
    expect(ordinary.sets, push.sets);
    expect(ordinary.repsMax, push.repsMax);
    expect(ordinary.restSeconds, push.restSeconds);
    expect(ordinary.warmupSets, push.warmupSets);
  });

  test('beginner days cover the whole body, not three presses in a row', () {
    final plan = generatePlan(
      goal: Goal.buildMuscle,
      level: Level.beginner,
      daysPerWeek: 3,
    );
    final push = plan.days.firstWhere((d) => d.key == 'push');
    expect(
      push.exercises.map((e) => e.exerciseId),
      containsAll(['tricepPushdown', 'lateralRaise']),
    );
    final legs = plan.days.firstWhere((d) => d.key == 'legs');
    expect(legs.exercises.map((e) => e.exerciseId), contains('calfRaise'));

    // Compounds still come first in every day, whatever the priority order.
    for (final day in plan.days) {
      var seenIsolation = false;
      for (final planned in day.exercises) {
        final compound = exerciseById(planned.exerciseId).isCompound;
        expect(
          compound && seenIsolation,
          isFalse,
          reason: '${day.key} runs ${planned.exerciseId} after an isolation',
        );
        seenIsolation |= !compound;
      }
    }
  });

  test('beginners are warned off the highest frequencies', () {
    expect(isDemandingFrequency(Level.beginner, 3), isFalse);
    expect(isDemandingFrequency(Level.beginner, 4), isFalse);
    expect(isDemandingFrequency(Level.beginner, 5), isTrue);
    expect(isDemandingFrequency(Level.advanced, 6), isFalse);
  });

  test('session estimate covers the warm-up and skips the trailing rest', () {
    // One exercise: 2 warm-up sets, then 4 working sets of about 45 s with
    // 3 rests of 180 s between them, plus the general warm-up.
    final day = PlanDay(
      key: 'push',
      exercises: const [
        PlannedExercise(
          exerciseId: 'benchPress',
          sets: 4,
          repsMin: 6,
          repsMax: 8,
          restSeconds: 180,
          warmupSets: 2,
        ),
      ],
    );
    final seconds = generalWarmupMinutes * 60 + 2 * 60 + 4 * 45 + 3 * 180;
    expect(estimatedSessionMinutes(day), (seconds / 60).round());
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
