import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../plan_generator.dart';

/// Three-question quiz the trainer uses to build the weekly plan.
/// Shown at first launch and when the user asks for a new plan.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Goal _goal = Goal.buildMuscle;
  Level _level = Level.beginner;
  int _daysPerWeek = 3;

  Future<void> _buildPlan() async {
    final store = StoreScope.of(context);
    final navigator = Navigator.of(context);
    await store.setPlan(
      generatePlan(goal: _goal, level: _level, daysPerWeek: _daysPerWeek),
    );
    // When opened from the Plan tab this screen is pushed; at first launch it
    // is the root and the app root swaps to HomeScreen on its own.
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.onboardingIntro, style: textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text(l10n.goalQuestion, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Goal>(
            segments: [
              for (final goal in Goal.values)
                ButtonSegment(value: goal, label: Text(goalLabel(l10n, goal))),
            ],
            selected: {_goal},
            onSelectionChanged: (selection) =>
                setState(() => _goal = selection.first),
          ),
          const SizedBox(height: 24),
          Text(l10n.levelQuestion, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Level>(
            segments: [
              for (final level in Level.values)
                ButtonSegment(
                  value: level,
                  label: Text(levelLabel(l10n, level)),
                ),
            ],
            selected: {_level},
            onSelectionChanged: (selection) =>
                setState(() => _level = selection.first),
          ),
          const SizedBox(height: 24),
          Text(l10n.daysQuestion, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (var days = 2; days <= 6; days++)
                ButtonSegment(value: days, label: Text('$days')),
            ],
            selected: {_daysPerWeek},
            onSelectionChanged: (selection) =>
                setState(() => _daysPerWeek = selection.first),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _buildPlan,
            child: Text(l10n.createPlanButton),
          ),
        ],
      ),
    );
  }
}
