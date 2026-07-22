import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/labels.dart';
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

  test('a stalled lift is deloaded instead of ground out forever', () async {
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

    // Same weight, never completing the 4x8 target.
    for (var i = 0; i < 2; i++) {
      await store.addSession(
        sessionFor('push', const [
          SetLog(weightKg: 60, reps: 8),
          SetLog(weightKg: 60, reps: 7),
          SetLog(weightKg: 60, reps: 6),
          SetLog(weightKg: 60, reps: 5),
        ]),
      );
      expect(store.isStalled(planned), isFalse, reason: 'only ${i + 1} tries');
      expect(store.suggestedWeight(planned), 60);
    }

    // The third failed session at the same weight is a stall: back off to
    // about 90%, rounded to a weight the gym can load.
    await store.addSession(
      sessionFor('push', const [
        SetLog(weightKg: 60, reps: 8),
        SetLog(weightKg: 60, reps: 7),
        SetLog(weightKg: 60, reps: 6),
        SetLog(weightKg: 60, reps: 5),
      ]),
    );
    expect(store.isStalled(planned), isTrue);
    expect(store.suggestedWeight(planned), 52.5);
  });

  test('suggestedReps asks for one more rep than last time', () async {
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

    // Nothing logged yet: start at the bottom of the range.
    expect(store.suggestedReps(planned, 0), planned.repsMin);

    await store.addSession(
      sessionFor('push', const [
        SetLog(weightKg: 40, reps: 6),
        SetLog(weightKg: 40, reps: 8),
      ]),
    );
    // One more rep than last time, never past the top of the range.
    expect(store.suggestedReps(planned, 0), 7);
    expect(store.suggestedReps(planned, 1), planned.repsMax);
    // Sets beyond last session's start at the bottom of the range.
    expect(store.suggestedReps(planned, 2), planned.repsMin);
  });

  test('a held exercise progresses in seconds and carries no weight', () async {
    final store = await openTestStore();
    const plank = PlannedExercise(
      exerciseId: 'plank',
      sets: 3,
      repsMin: 30,
      repsMax: 45,
      restSeconds: 60,
    );
    await store.addSession(
      WorkoutSession(
        date: DateTime.now(),
        dayKey: 'legs',
        logs: const [
          ExerciseLog(
            exerciseId: 'plank',
            sets: [SetLog(weightKg: 0, reps: 30)],
          ),
        ],
      ),
    );

    expect(store.suggestedWeight(plank), isNull);
    expect(store.isStalled(plank), isFalse);
    expect(store.suggestedReps(plank, 0), 30 + timedProgressionSeconds);
    // The trend follows the hold, not the weight, which is always zero.
    expect(store.progressHistory('plank').single.$2, 30);
  });

  test('pound users are suggested weights their gym can load', () async {
    final store = await openTestStore();
    await store.setUnit(WeightUnit.lb);
    const planned = PlannedExercise(
      exerciseId: 'benchPress',
      sets: 1,
      repsMin: 6,
      repsMax: 8,
      restSeconds: 180,
    );
    // 100 lb completed at the top of the range steps to 105 lb, not to the
    // 102.5 lb that a 2.5 kg jump would land on.
    await store.addSession(
      sessionFor('push', [
        SetLog(weightKg: unitToKg(WeightUnit.lb, 100), reps: 8),
      ]),
    );
    expect(
      kgToUnit(WeightUnit.lb, store.suggestedWeight(planned)!),
      closeTo(105, 0.001),
    );
  });

  test('more reps at the same weight counts as a record', () async {
    final store = await openTestStore();
    // Nothing logged yet, so a first attempt is not a record.
    expect(
      store.isRecordSet('benchPress', const SetLog(weightKg: 60, reps: 8)),
      isFalse,
    );

    await store.addSession(
      sessionFor('push', const [SetLog(weightKg: 60, reps: 8)]),
    );

    expect(
      store.isRecordSet('benchPress', const SetLog(weightKg: 60, reps: 9)),
      isTrue,
      reason: 'same weight for one more rep beats it',
    );
    expect(
      store.isRecordSet('benchPress', const SetLog(weightKg: 62.5, reps: 6)),
      isTrue,
      reason: 'heavier is a record even for fewer reps',
    );
    expect(
      store.isRecordSet('benchPress', const SetLog(weightKg: 60, reps: 8)),
      isFalse,
      reason: 'matching a set does not beat it',
    );
    // A held exercise carries no weight, so the longest hold is the record.
    await store.addSession(
      WorkoutSession(
        date: DateTime.now(),
        dayKey: 'legs',
        logs: const [
          ExerciseLog(
            exerciseId: 'plank',
            sets: [SetLog(weightKg: 0, reps: 30)],
          ),
        ],
      ),
    );
    expect(
      store.isRecordSet('plank', const SetLog(weightKg: 0, reps: 35)),
      isTrue,
    );
  });

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

  test('a draft remembers a mid-session swap the plan never saw', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    // The lifter swapped the bench for dumbbells for this session only.
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'push',
        startedAt: DateTime(2026, 7, 22, 18),
        exerciseIndex: 0,
        exercises: const [
          PlannedExercise(
            exerciseId: 'dbBenchPress',
            sets: 4,
            repsMin: 6,
            repsMax: 8,
            restSeconds: 180,
            warmupSets: 2,
          ),
        ],
        sets: const {
          'dbBenchPress': [SetLog(weightKg: 30, reps: 8)],
        },
      ),
    );

    final reloaded = await AppStore.open(db);
    expect(reloaded.draft!.exercises!.single.exerciseId, 'dbBenchPress');
    expect(reloaded.draft!.sets['dbBenchPress']!.single.reps, 8);
    // The plan itself is untouched by a session-only swap.
    expect(reloaded.plan!.days.first.exercises.first.exerciseId, 'benchPress');
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

  test('updatePlanPrescription rewrites sets, reps, and rest only', () async {
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

    await store.updatePlanPrescription(
      'push',
      0,
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      restSeconds: 180,
    );

    final updated = store.plan!.days[pushIndex].exercises.first;
    expect(updated.exerciseId, original.exerciseId);
    expect(updated.warmupSets, original.warmupSets);
    expect(updated.sets, 5);
    expect(updated.repsMin, 5);
    expect(updated.repsMax, 5);
    expect(updated.restSeconds, 180);

    final reloaded = await AppStore.open(db);
    expect(reloaded.plan!.days[pushIndex].exercises.first.sets, 5);
  });

  test('movePlanExercise reorders within a day and persists', () async {
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
    final ids = [
      for (final e in store.plan!.days[pushIndex].exercises) e.exerciseId,
    ];

    await store.movePlanExercise('push', 0, 2);

    final moved = [
      for (final e in store.plan!.days[pushIndex].exercises) e.exerciseId,
    ];
    expect(moved, [ids[1], ids[2], ids[0], ...ids.sublist(3)]);

    // Out-of-range moves are no-ops.
    await store.movePlanExercise('push', 0, 99);
    expect([
      for (final e in store.plan!.days[pushIndex].exercises) e.exerciseId,
    ], moved);

    final reloaded = await AppStore.open(db);
    expect([
      for (final e in reloaded.plan!.days[pushIndex].exercises) e.exerciseId,
    ], moved);
  });

  test('settings persist across store instances', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.setUnit(WeightUnit.lb);
    await store.setThemeMode(ThemeMode.dark);

    final reloaded = await AppStore.open(db);
    expect(reloaded.unit, WeightUnit.lb);
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('bestWeightFor finds the all-time best and respects a cutoff', () async {
    final store = await openTestStore();
    expect(store.bestWeightFor('benchPress'), isNull);

    await store.addSession(
      WorkoutSession(
        date: DateTime(2026, 7, 1),
        dayKey: 'push',
        logs: const [
          ExerciseLog(
            exerciseId: 'benchPress',
            sets: [SetLog(weightKg: 40, reps: 8)],
          ),
        ],
      ),
    );
    await store.addSession(
      WorkoutSession(
        date: DateTime(2026, 7, 8),
        dayKey: 'push',
        logs: const [
          ExerciseLog(
            exerciseId: 'benchPress',
            sets: [SetLog(weightKg: 45, reps: 6)],
          ),
        ],
      ),
    );

    expect(store.bestWeightFor('benchPress'), 45);
    // The cutoff excludes the session on that exact date.
    expect(store.bestWeightFor('benchPress', before: DateTime(2026, 7, 8)), 40);
    expect(store.bestWeightFor('squat'), isNull);
  });

  test('streakWeeks counts full weeks and tolerates the current one', () async {
    final store = await openTestStore();
    expect(store.streakWeeks(DateTime(2026, 7, 22)), 0);

    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    // July 22, 2026 is a Wednesday; its week starts Monday July 20.
    Future<void> trainOn(DateTime date) => store.addSession(
      WorkoutSession(date: date, dayKey: 'push', logs: const []),
    );

    // Two full weeks before the current one.
    for (final day in [6, 8, 10, 13, 15, 17]) {
      await trainOn(DateTime(2026, 7, day));
    }
    // The current week is in progress: it neither counts nor breaks.
    await trainOn(DateTime(2026, 7, 20));
    expect(store.streakWeeks(DateTime(2026, 7, 22)), 2);

    // Meeting the target this week extends the streak to three.
    await trainOn(DateTime(2026, 7, 21));
    await trainOn(DateTime(2026, 7, 22, 9));
    expect(store.streakWeeks(DateTime(2026, 7, 22, 18)), 3);
  });

  test('streakWeeks is broken by an empty week', () async {
    final store = await openTestStore();
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    // A full week two weeks back, nothing last week.
    for (final day in [6, 8, 10]) {
      await store.addSession(
        WorkoutSession(
          date: DateTime(2026, 7, day),
          dayKey: 'push',
          logs: const [],
        ),
      );
    }
    expect(store.streakWeeks(DateTime(2026, 7, 22)), 0);
  });

  test('deleteSession removes the session and persists', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    await store.addSession(
      sessionFor('push', const [SetLog(weightKg: 40, reps: 8)]),
    );
    await store.addSession(
      sessionFor('pull', const [SetLog(weightKg: 30, reps: 10)]),
    );
    expect(store.sessions.length, 2);
    expect(store.sessions.first.id, isNotNull);

    await store.deleteSession(
      store.sessions.firstWhere((s) => s.dayKey == 'push'),
    );

    expect(store.sessions.single.dayKey, 'pull');
    // Derived stats no longer see the deleted session's sets.
    expect(store.bestWeightFor('benchPress'), 30);

    final reloaded = await AppStore.open(db);
    expect(reloaded.sessions.single.dayKey, 'pull');
  });

  test('exercise notes save, clear, and persist', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    expect(store.noteFor('benchPress'), isNull);

    await store.setExerciseNote('benchPress', '  narrow grip  ');
    expect(store.noteFor('benchPress'), 'narrow grip');

    final reloaded = await AppStore.open(db);
    expect(reloaded.noteFor('benchPress'), 'narrow grip');

    // A blank note removes the entry.
    await reloaded.setExerciseNote('benchPress', '   ');
    expect(reloaded.noteFor('benchPress'), isNull);
    expect((await AppStore.open(db)).noteFor('benchPress'), isNull);
  });

  test('body weight entries add, sort, delete, and persist', () async {
    final db = await openTestDatabase();
    final store = await AppStore.open(db);
    expect(store.bodyWeights, isEmpty);

    await store.addBodyWeight(82.5, date: DateTime(2026, 7, 20));
    await store.addBodyWeight(83.1, date: DateTime(2026, 7, 6));
    await store.addBodyWeight(82.0, date: DateTime(2026, 7, 22));

    // Newest first, regardless of insertion order.
    expect(store.bodyWeights.map((e) => e.weightKg), [82.0, 82.5, 83.1]);

    final reloaded = await AppStore.open(db);
    expect(reloaded.bodyWeights.map((e) => e.weightKg), [82.0, 82.5, 83.1]);

    await reloaded.deleteBodyWeight(reloaded.bodyWeights.first);
    expect(reloaded.bodyWeights.map((e) => e.weightKg), [82.5, 83.1]);
    expect((await AppStore.open(db)).bodyWeights.length, 2);
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
    await source.setExerciseNote('benchPress', 'narrow grip');
    await source.addBodyWeight(82.5, date: DateTime(2026, 7, 20));
    final backup = source.exportData();

    final target = await openTestStore();
    await target.setExerciseNote('squat', 'old note that must not survive');
    await target.addBodyWeight(90, date: DateTime(2026, 7, 1));
    await target.importData(backup);
    expect(target.plan!.goal, Goal.loseWeight);
    expect(target.sessions.single.dayKey, 'upperA');
    expect(target.sessions.single.logs.single.sets.single.weightKg, 60);
    expect(target.unit, WeightUnit.lb);
    expect(target.noteFor('benchPress'), 'narrow grip');
    expect(target.noteFor('squat'), isNull);
    expect(target.bodyWeights.single.weightKg, 82.5);
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
