import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../exercise_library.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import 'exercise_detail_screen.dart';
import 'workout_screen.dart';

/// Progress overview: workout stats, per-exercise strength trend, and history.
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final sessions = store.sessions;

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, size: 56, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                l10n.noProgressYet,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutScreen(planDay: store.todayPlanDay),
                  ),
                ),
                icon: const Icon(Icons.bolt),
                label: Text(l10n.startWorkout),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat.MMMEd(
      Localizations.localeOf(context).toString(),
    );
    final trainedExerciseIds = [
      for (final exercise in exerciseLibrary)
        if (store.weightHistory(exercise.id).isNotEmpty) exercise.id,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.statThisWeek,
                value: '${store.sessionsThisWeek}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.statTotal,
                value: '${sessions.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _WeekDots(),
        const SizedBox(height: 24),
        Text(l10n.strengthProgressTitle, style: textTheme.titleLarge),
        for (final exerciseId in trainedExerciseIds)
          _StrengthTile(exerciseId: exerciseId),
        const SizedBox(height: 24),
        Text(l10n.historyTitle, style: textTheme.titleLarge),
        for (final session in sessions)
          ListTile(
            leading: Icon(Icons.check_circle, color: colorScheme.primary),
            title: Text(dayLabel(l10n, session.dayKey)),
            subtitle: Text(dateFormat.format(session.date)),
            trailing: Text(l10n.exerciseCount(session.logs.length)),
          ),
      ],
    );
  }
}

/// Mon..Sun row showing which days had a workout this week.
class _WeekDots extends StatelessWidget {
  const _WeekDots();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < 7; i++)
              Builder(
                builder: (context) {
                  final date = monday.add(Duration(days: i));
                  final trained = store.sessions.any(
                    (s) =>
                        s.date.year == date.year &&
                        s.date.month == date.month &&
                        s.date.day == date.day,
                  );
                  final isToday = i == now.weekday - 1;
                  return Column(
                    children: [
                      Text(
                        DateFormat.E(locale).format(date).substring(0, 1),
                        style: textTheme.labelSmall!.copyWith(
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: trained
                              ? colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: trained
                                ? colorScheme.primary
                                : isToday
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: textTheme.headlineMedium),
            Text(label, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StrengthTile extends StatelessWidget {
  const _StrengthTile({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final unit = unitLabel(l10n, store.unit);
    final history = store.weightHistory(exerciseId);
    final first = history.first.$2;
    final latest = history.last.$2;
    final delta = kgToUnit(store.unit, latest - first);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(exerciseById(exerciseId).name),
      subtitle: delta == 0
          ? null
          : Text(
              l10n.deltaWithUnit(
                '${delta > 0 ? '+' : ''}${formatWeight(delta)}',
                unit,
              ),
              style: TextStyle(
                color: delta > 0 ? colorScheme.primary : colorScheme.error,
              ),
            ),
      trailing: Text(
        l10n.weightWithUnit(formatKgIn(store.unit, latest), unit),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ExerciseDetailScreen(exercise: exerciseById(exerciseId)),
        ),
      ),
    );
  }
}
