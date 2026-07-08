import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweatline/main.dart';
import 'package:sweatline/models.dart';
import 'package:sweatline/plan_generator.dart';
import 'package:sweatline/store.dart';

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
  testWidgets('onboarding to finished workout to progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
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
      find.text('First time doing this. Start light and focus on clean form.'),
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
    await scrollAndTap(tester, find.textContaining('Log set'));
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
    await scrollAndTap(tester, find.text('Finish workout'));
    await tester.pumpAndSettle();

    // Summary screen with the session stats, then back home.
    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
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
  });

  testWidgets('an interrupted workout is offered for resume and restores '
      'logged sets', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    await store.setPlan(
      generatePlan(
        goal: Goal.buildMuscle,
        level: Level.beginner,
        daysPerWeek: 3,
      ),
    );
    // Simulate an app kill after one bench set was logged.
    await store.saveDraft(
      WorkoutDraft(
        dayKey: 'push',
        startedAt: DateTime.now(),
        sets: const {
          'benchPress': [SetLog(weightKg: 40, reps: 8)],
        },
      ),
    );

    await tester.pumpWidget(SweatlineApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Resume workout'), findsOneWidget);
    await tester.tap(find.text('Resume workout'));
    await settleWorkout(tester);

    // Back on bench press with the logged set restored.
    expect(find.text('Exercise 1 of 4'), findsOneWidget);
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('40 kg x 8'), findsOneWidget);
  });
}
