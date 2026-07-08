import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../exercise_library.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import 'exercise_detail_screen.dart';
import 'library_tab.dart';
import 'onboarding_screen.dart';
import 'progress_tab.dart';
import 'settings_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_tabIndex) {
          0 => l10n.appTitle,
          1 => l10n.tabPlan,
          2 => l10n.tabLibrary,
          _ => l10n.tabProgress,
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [_TodayTab(), _PlanTab(), LibraryTab(), ProgressTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.bolt),
            label: l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note),
            label: l10n.tabPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book),
            label: l10n.tabLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up),
            label: l10n.tabProgress,
          ),
        ],
      ),
    );
  }
}

/// Rough session length: warm-ups plus work sets with their rests.
int estimatedMinutes(PlanDay day) {
  var seconds = 0;
  for (final planned in day.exercises) {
    seconds += planned.warmupSets * 60;
    seconds += planned.sets * (45 + planned.restSeconds);
  }
  return (seconds / 60).round();
}

class _TodayTab extends StatelessWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final day = store.todayPlanDay;
    final sessions = store.sessions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.primary, width: 1.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.todayWorkoutTitle.toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  letterSpacing: 2.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabel(l10n, day.key),
                style: textTheme.displaySmall!.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.exerciseCount(day.exercises.length)} · '
                '${l10n.estimatedMinutes(estimatedMinutes(day))}',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutScreen(planDay: day),
                  ),
                ),
                icon: const Icon(Icons.bolt),
                label: Text(
                  store.draft?.dayKey == day.key
                      ? l10n.resumeWorkout
                      : l10n.startWorkout,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final planned in day.exercises)
          _PlannedExerciseTile(planned: planned),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.calendar_today, color: colorScheme.primary),
          title: Text(l10n.workoutsThisWeek(store.sessionsThisWeek)),
          subtitle: Text(
            sessions.isEmpty
                ? l10n.noWorkoutsYet
                : l10n.lastWorkoutOn(
                    DateFormat.MMMEd(
                      Localizations.localeOf(context).toString(),
                    ).format(sessions.first.date),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PlannedExerciseTile extends StatelessWidget {
  const _PlannedExerciseTile({required this.planned});

  final PlannedExercise planned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = exerciseById(planned.exerciseId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(exercise.name),
      subtitle: Text(
        '${l10n.setsByReps(planned.sets, planned.repsMin, planned.repsMax)} · '
        '${l10n.restInfo(planned.restSeconds)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        ),
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab();

  Future<void> _confirmNewPlan(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.newPlanConfirmTitle),
        content: Text(l10n.newPlanConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.replace),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final plan = store.plan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(goalLabel(l10n, plan.goal))),
            Chip(label: Text(levelLabel(l10n, plan.level))),
            Chip(label: Text(l10n.daysOption(plan.days.length))),
          ],
        ),
        for (final day in plan.days) ...[
          const SizedBox(height: 20),
          Text(
            dayLabel(l10n, day.key),
            style: textTheme.headlineSmall!.copyWith(
              color: colorScheme.primary,
            ),
          ),
          for (final planned in day.exercises)
            _PlannedExerciseTile(planned: planned),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _confirmNewPlan(context),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.newPlanButton),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
