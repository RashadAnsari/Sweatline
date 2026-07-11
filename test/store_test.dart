import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/models.dart';
import 'package:sweatline/plan_generator.dart';
import 'package:sweatline/store.dart';

import 'test_database.dart';

WorkoutSession sessionFor(String dayKey, List<SetLog> benchSets) =>
    WorkoutSession(
      date: DateTime.now(),
      dayKey: dayKey,
      logs: [ExerciseLog(exerciseId: 'benchPress', sets: benchSets)],
    );

void main() {
  setUpAll(initTestDatabase);

  test('plan and sessions persist across store instances', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    await store.addSession(
      sessionFor('push', const [SetLog(weightKg: 40, reps: 10)]),
    );

    final reloaded = await AppStore.open(db);
    expect(reloaded.hasPlan, isTrue);
    expect(reloaded.sessions.length, 1);
    expect(reloaded.sessions.first.dayKey, 'push');
    expect(reloaded.sessions.first.logs.single.sets.single.weightKg, 40);
  });

  test('todayPlanDay cycles through the split', () async {
    final store = await openTestStore();
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    expect(store.todayPlanDay.key, 'push');
    await store.addSession(sessionFor('push', const []));
    expect(store.todayPlanDay.key, 'pull');
    await store.addSession(sessionFor('pull', const []));
    await store.addSession(sessionFor('legs', const []));
    expect(store.todayPlanDay.key, 'push');
  });

  test(
    'suggestedWeight repeats last weight until all sets hit top reps',
    () async {
      final store = await openTestStore();
      await store.setPlan(
        generatePlan(
          goal: Goal.buildMuscle,
          level: Level.beginner,
          daysPerWeek: 3,
        ),
      );
      final planned = store.plan!.days.first.exercises.firstWhere(
        (e) => e.exerciseId == 'benchPress',
      );

      expect(store.suggestedWeight(planned), isNull);

      // Bench press is the main lift: 4 sets of 6-8. Not every set at the
      // top of the range yet, so the trainer repeats the weight.
      await store.addSession(
        sessionFor('push', const [
          SetLog(weightKg: 40, reps: 8),
          SetLog(weightKg: 40, reps: 8),
          SetLog(weightKg: 40, reps: 7),
          SetLog(weightKg: 40, reps: 6),
        ]),
      );
      expect(store.suggestedWeight(planned), 40);

      await store.addSession(
        sessionFor('push', const [
          SetLog(weightKg: 40, reps: 8),
          SetLog(weightKg: 40, reps: 8),
          SetLog(weightKg: 40, reps: 8),
          SetLog(weightKg: 40, reps: 8),
        ]),
      );
      expect(store.suggestedWeight(planned), 40 + progressionIncrementKg);
    },
  );

  test('corrupt meta value is dropped instead of crashing', () async {
    final db = await openTestDatabase();
    await db.setMeta('plan', 'this is not json {{{');
    final store = await AppStore.open(db);

    expect(store.hasPlan, isFalse);
    // The bad row was removed, so a reopen is also clean.
    expect((await AppStore.open(db)).hasPlan, isFalse);
  });

  test('workout draft persists, restores, and clears', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'push',
        startedAt: DateTime(2026, 7, 8, 18),
        exerciseIndex: 1,
        sets: const {
          'benchPress': [SetLog(weightKg: 40, reps: 8)],
        },
      ),
    );

    final reloaded = await AppStore.open(db);
    expect(reloaded.draft!.dayKey, 'push');
    expect(reloaded.draft!.exerciseIndex, 1);
    expect(reloaded.draft!.sets['benchPress']!.single.weightKg, 40);

    await reloaded.clearDraft();
    expect((await AppStore.open(db)).draft, isNull);
  });

  test('replacing the plan clears an in-progress draft', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'push',
        startedAt: DateTime(2026, 7, 8, 18),
        exerciseIndex: 1,
        sets: const {
          'benchPress': [SetLog(weightKg: 40, reps: 8)],
        },
      ),
    );

    await store.setPlan(
      generatePlan(
        goal: Goal.loseWeight,
        level: Level.beginner,
        daysPerWeek: 4,
      ),
    );

    expect(store.draft, isNull);
    expect((await AppStore.open(db)).draft, isNull);
  });

  test(
    'replacePlanExercise swaps the movement but keeps the prescription',
    () async {
      final db = await openTestDatabase();
      final store = await AppStore.open(db);
      await store.setPlan(
        generatePlan(
          goal: Goal.buildMuscle,
          level: Level.beginner,
          daysPerWeek: 3,
        ),
      );
      final pushIndex = store.plan!.days.indexWhere((d) => d.key == 'push');
      final original = store.plan!.days[pushIndex].exercises.first;

      await store.replacePlanExercise('push', 0, 'dbBenchPress');

      final swapped = store.plan!.days[pushIndex].exercises.first;
      expect(swapped.exerciseId, 'dbBenchPress');
      expect(swapped.sets, original.sets);
      expect(swapped.repsMin, original.repsMin);
      expect(swapped.repsMax, original.repsMax);
      expect(swapped.restSeconds, original.restSeconds);
      expect(swapped.warmupSets, original.warmupSets);

      // The change is persisted, not just in memory.
      final reloaded = await AppStore.open(db);
      expect(
        reloaded.plan!.days[pushIndex].exercises.first.exerciseId,
        'dbBenchPress',
      );
    },
  );

  test(
    'replacePlanExercise keeps the draft but drops the swapped-out sets',
    () async {
      final db = await openTestDatabase();
      final store = await AppStore.open(db);
      await store.setPlan(
        generatePlan(
          goal: Goal.buildMuscle,
          level: Level.beginner,
          daysPerWeek: 3,
        ),
      );
      final oldId = store.plan!.days
          .firstWhere((d) => d.key == 'push')
          .exercises
          .first
          .exerciseId;
      await store.saveDraft(
        WorkoutDraft(
          dayKey: 'push',
          startedAt: DateTime(2026, 7, 8, 18),
          exerciseIndex: 0,
          sets: {
            oldId: const [SetLog(weightKg: 40, reps: 8)],
          },
        ),
      );

      await store.replacePlanExercise('push', 0, 'dbBenchPress');

      // The draft survives (unlike setPlan) but the old exercise's sets are gone.
      expect(store.draft, isNotNull);
      expect(store.draft!.sets.containsKey(oldId), isFalse);
    },
  );

  test('settings persist across store instances', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.setUnit(WeightUnit.lb);
    await store.setThemeMode(ThemeMode.dark);

    final reloaded = await AppStore.open(db);
    expect(reloaded.unit, WeightUnit.lb);
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('backup export/import round trip', () async {
    final source = await openTestStore();
    await source.setPlan(
      generatePlan(
        goal: Goal.loseWeight,
        level: Level.intermediate,
        daysPerWeek: 4,
      ),
    );
    await source.addSession(
      sessionFor('upperA', const [SetLog(weightKg: 60, reps: 12)]),
    );
    await source.setUnit(WeightUnit.lb);
    final backup = source.exportData();

    final target = await openTestStore();
    await target.importData(backup);
    expect(target.plan!.goal, Goal.loseWeight);
    expect(target.sessions.single.dayKey, 'upperA');
    expect(target.sessions.single.logs.single.sets.single.weightKg, 60);
    expect(target.unit, WeightUnit.lb);
  });

  test('import rejects invalid payloads without touching data', () async {
    final store = await openTestStore();
    await store.setPlan(
      generatePlan(goal: Goal.getFit, level: Level.beginner, daysPerWeek: 2),
    );
    await expectLater(store.importData('not json'), throwsFormatException);
    await expectLater(
      store.importData('{"app": "other"}'),
      throwsFormatException,
    );
    expect(store.hasPlan, isTrue);
  });
}
