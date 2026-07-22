import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/main.dart';
import 'package:sweatline/models.dart';
import 'package:sweatline/plan_generator.dart';

import 'test_database.dart';

/// The workout screen has an endlessly repeating pictogram animation, so
/// pumpAndSettle would never settle while it is visible; this pumps just
/// enough for taps and route transitions to complete.
Future<void> settleWorkout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolls the target into view (the workout list is lazy, so widgets far
/// below the fold are not even built until scrolled to), then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  setUpAll(initTestDatabase);

  testWidgets('onboarding to finished workout to progress', (tester) async {
    final store = await openTestStore();
    await tester.pumpWidget(SweatlineApp(store: store));
    await tester.pumpAndSettle();

    // Onboarding with default answers (build muscle, beginner, 3 days).
    expect(find.text('SWEATLINE'), findsOneWidget);
    expect(find.text('Build muscle'), findsOneWidget);
    await tester.tap(find.text('Build my plan'));
    await tester.pumpAndSettle();

    // Home shows today's workout: Push Day of the 3-day split.
    expect(find.text('Push Day'), findsOneWidget);
    await tester.tap(find.text('Start workout'));
    await settleWorkout(tester);

    // Dedicated warm-up step first.
    expect(find.text('Warm-up'), findsWidgets);
    await scrollAndTap(tester, find.text('Start lifting'));
    await settleWorkout(tester);

    // First exercise, first-time trainer tip, log one set.
    expect(find.text('Exercise 1 of 4'), findsOneWidget);
    expect(
      find.text('This is your first time. Start light and focus on good form.'),
      findsOneWidget,
    );
    // The set-logging form sits below the fold; scroll it into build range.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump();
    // First attempt: reps prefilled with the bottom of the range (6 for the
    // 6-8 main lift), weight left empty.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '6',
    );
    await tester.enterText(find.byType(TextFormField).first, '40');
    await tester.enterText(find.byType(TextFormField).last, '10');
    await scrollAndTap(tester, find.textContaining('Save set'));
    await tester.pump();

    // Rest timer runs; skip it.
    expect(find.text('REST'), findsOneWidget);
    await scrollAndTap(tester, find.text('Skip rest'));
    await tester.pump();

    // Move through the remaining exercises and finish.
    for (var i = 0; i < 3; i++) {
      await scrollAndTap(tester, find.text('Next exercise'));
      await settleWorkout(tester);
    }
    expect(find.text('Exercise 4 of 4'), findsOneWidget);

    // Step back to the previous exercise and forward again.
    await scrollAndTap(tester, find.text('Previous'));
    await settleWorkout(tester);
    expect(find.text('Exercise 3 of 4'), findsOneWidget);
    await scrollAndTap(tester, find.text('Next exercise'));
    await settleWorkout(tester);
    expect(find.text('Exercise 4 of 4'), findsOneWidget);

    await scrollAndTap(tester, find.text('Finish workout'));
    await tester.pumpAndSettle();

    // Summary screen with the session stats, then back home.
    expect(find.text('WORKOUT DONE'), findsOneWidget);
    expect(find.text('1 set'), findsOneWidget);
    expect(store.sessions.length, 1);
    expect(store.sessions.first.logs.single.exerciseId, 'benchPress');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Progress tab shows the stats and the logged exercise.
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Total workouts'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('40 kg'), findsOneWidget);

    // Next session cycles to Pull Day.
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Pull Day'), findsOneWidget);

    // Browse the other workouts of the plan from the Today tab.
    await tester.tap(find.byTooltip('Next workout'));
    await tester.pumpAndSettle();
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('IN YOUR PLAN'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous workout'));
    await tester.pumpAndSettle();
    expect(find.text('Pull Day'), findsOneWidget);
    expect(find.text("TODAY'S WORKOUT"), findsOneWidget);
  });

  testWidgets('an interrupted workout is offered for resume and restores '
      'logged sets', (tester) async {
    final store = await openTestStore();
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    // Simulate an app kill while on the third exercise, having logged one
    // bench set on the first exercise earlier.
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'push',
        startedAt: DateTime.now(),
        exerciseIndex: 2,
        sets: const {
          'benchPress': [SetLog(weightKg: 40, reps: 8)],
        },
      ),
    );

    await tester.pumpWidget(SweatlineApp(store: store));
    await tester.pumpAndSettle();

    // The Today tab opens straight on the in-progress workout with a Continue
    // button, skipping the warm-up page on resume.
    expect(find.text('Continue workout'), findsOneWidget);
    await tester.tap(find.text('Continue workout'));
    await settleWorkout(tester);

    // Resumes at the exact saved exercise, not exercise 1.
    expect(find.text('Exercise 3 of 4'), findsOneWidget);

    // Stepping back to exercise 1 shows the previously logged set.
    await scrollAndTap(tester, find.text('Previous'));
    await settleWorkout(tester);
    await scrollAndTap(tester, find.text('Previous'));
    await settleWorkout(tester);
    expect(find.text('Exercise 1 of 4'), findsOneWidget);
    expect(find.text('40 kg x 8'), findsOneWidget);
  });

  testWidgets('a held exercise is logged in seconds, with no weight field', (
    tester,
  ) async {
    final store = await openTestStore();
    // A one-day plan of nothing but the plank, so the workout screen opens
    // straight onto a held exercise.
    await store.setPlan(
      const Plan(
        goal: Goal.getFit,
        level: Level.advanced,
        days: [
          PlanDay(
            key: 'legs',
            exercises: [
              PlannedExercise(
                exerciseId: 'plank',
                sets: 3,
                repsMin: 30,
                repsMax: 45,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(SweatlineApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await settleWorkout(tester);
    await scrollAndTap(tester, find.text('Start lifting'));
    await settleWorkout(tester);

    // The prescription and the input both read in seconds.
    expect(find.textContaining('3 sets x 30 to 45 seconds'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pump();
    expect(find.text('Seconds *'), findsOneWidget);
    expect(find.text('Weight (kg) *'), findsNothing);

    // The goal promised cardio, so the last exercise says what to do.
    expect(
      find.textContaining('Finish with 15 to 20 minutes of cardio'),
      findsOneWidget,
    );

    // A logged hold reads as seconds, not as a weight.
    await tester.enterText(find.byType(TextFormField).first, '40');
    await scrollAndTap(tester, find.textContaining('Save set'));
    await tester.pump();
    expect(find.text('40 s'), findsOneWidget);
  });
}
