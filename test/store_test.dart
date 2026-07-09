import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweatline/models.dart';
import 'package:sweatline/plan_generator.dart';
import 'package:sweatline/store.dart';

Future<AppStore> makeStore() async {
  SharedPreferences.setMockInitialValues({});
  return AppStore(await SharedPreferences.getInstance());
}

WorkoutSession sessionFor(String dayKey, List<SetLog> benchSets) =>
    WorkoutSession(
      date: DateTime.now(),
      dayKey: dayKey,
      logs: [ExerciseLog(exerciseId: 'benchPress', sets: benchSets)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('plan and sessions persist across store instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs);
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

    final reloaded = AppStore(prefs);
    expect(reloaded.hasPlan, isTrue);
    expect(reloaded.sessions.length, 1);
    expect(reloaded.sessions.first.dayKey, 'push');
  });

  test('todayPlanDay cycles through the split', () async {
    final store = await makeStore();
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
      final store = await makeStore();
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

  test('corrupt stored data is quarantined instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      'plan': 'this is not json {{{',
      'sessions': '[{"broken": true}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs);

    expect(store.hasPlan, isFalse);
    expect(store.sessions, isEmpty);
    expect(prefs.getString('plan'), isNull);
    expect(
      prefs.getKeys().where((k) => k.startsWith('corrupt.plan.')).length,
      1,
    );
    expect(
      prefs.getKeys().where((k) => k.startsWith('corrupt.sessions.')).length,
      1,
    );
  });

  test('workout draft persists, restores, and clears', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs);
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'push',
        startedAt: DateTime(2026, 7, 8, 18),
        sets: const {
          'benchPress': [SetLog(weightKg: 40, reps: 8)],
        },
      ),
    );

    final reloaded = AppStore(prefs);
    expect(reloaded.draft!.dayKey, 'push');
    expect(reloaded.draft!.sets['benchPress']!.single.weightKg, 40);

    await reloaded.clearDraft();
    expect(AppStore(prefs).draft, isNull);
  });

  test('workout draft round-trips the resume position', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs);
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'legs',
        startedAt: DateTime(2026, 7, 9, 18),
        exerciseIndex: 3,
        sets: const {
          'squat': [SetLog(weightKg: 80, reps: 6)],
        },
      ),
    );

    expect(AppStore(prefs).draft!.exerciseIndex, 3);
  });

  test('settings persist across store instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs);
    await store.setUnit(WeightUnit.lb);
    await store.setThemeMode(ThemeMode.dark);

    final reloaded = AppStore(prefs);
    expect(reloaded.unit, WeightUnit.lb);
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('backup export/import round trip', () async {
    final source = await makeStore();
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

    final target = await makeStore();
    await target.importData(backup);
    expect(target.plan!.goal, Goal.loseWeight);
    expect(target.sessions.single.dayKey, 'upperA');
    expect(target.unit, WeightUnit.lb);
  });

  test('import rejects invalid payloads without touching data', () async {
    final store = await makeStore();
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
