import 'package:flutter/material.dart';

import '../exercise_library.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/page_body.dart';

/// Post-workout celebration: duration, total volume, sets, and the best
/// set per exercise. Replaces the workout screen when a session is saved.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.duration,
  });

  final WorkoutSession session;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final unit = unitLabel(l10n, store.unit);

    final setCount = session.logs.fold(0, (sum, log) => sum + log.sets.length);
    final volumeKg = session.logs.fold(
      0.0,
      (sum, log) =>
          sum + log.sets.fold(0.0, (s, set) => s + set.weightKg * set.reps),
    );
    final minutes = duration.inMinutes.clamp(1, 24 * 60);

    return Scaffold(
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.workoutCompleteTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall!.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabel(l10n, session.dayKey),
                      style: textTheme.titleMedium!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: l10n.statDuration,
                    value: l10n.minutesValue(minutes),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: l10n.statVolume,
                    value: l10n.weightWithUnit(
                      formatKgIn(store.unit, volumeKg),
                      unit,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: l10n.statSetsLogged,
                    value: '$setCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final log in session.logs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle, color: colorScheme.primary),
                title: Text(exerciseById(log.exerciseId).name),
                subtitle: Text(l10n.setsCount(log.sets.length)),
                trailing: Text(
                  l10n.setResult(
                    formatKgIn(store.unit, log.bestWeight),
                    unit,
                    log.sets
                        .reduce((a, b) => a.weightKg >= b.weightKg ? a : b)
                        .reps,
                  ),
                  style: textTheme.titleLarge,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PageBody(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check),
              label: Text(l10n.doneButton),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: textTheme.headlineMedium),
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
