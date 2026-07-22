import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../exercise_library.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../store.dart';
import '../widgets/stat_tile.dart';
import '../widgets/swipe_delete.dart';
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
        if (store.progressHistory(exercise.id).isNotEmpty) exercise.id,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.statThisWeek,
                  value: '${store.sessionsThisWeek}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: l10n.statTotal,
                  value: '${sessions.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: l10n.statStreak,
                  value: '${store.streakWeeks()}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _WeekDots(),
        const SizedBox(height: 24),
        const _BodyWeightSection(),
        const SizedBox(height: 24),
        Text(l10n.strengthProgressTitle, style: textTheme.titleLarge),
        for (final exerciseId in trainedExerciseIds)
          _StrengthTile(exerciseId: exerciseId),
        const SizedBox(height: 24),
        Text(l10n.historyTitle, style: textTheme.titleLarge),
        for (final session in sessions)
          SwipeToDelete(
            dismissibleKey: ValueKey('session-${session.id}'),
            confirmTitle: l10n.deleteWorkoutTitle,
            confirmBody: l10n.deleteWorkoutBody,
            onDelete: () => store.deleteSession(session),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle, color: colorScheme.primary),
              title: Text(dayLabel(l10n, session.dayKey)),
              subtitle: Text(dateFormat.format(session.date)),
              trailing: Text(l10n.exerciseCount(session.logs.length)),
            ),
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
    final monday = mondayOf(now);

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
                              : colorScheme.surface.withAlpha(0),
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

class _StrengthTile extends StatelessWidget {
  const _StrengthTile({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final timed = exerciseById(exerciseId).isTimed;
    // A held exercise progresses in seconds, so its change reads in seconds.
    final unit = timed ? l10n.unitSeconds : unitLabel(l10n, store.unit);
    final history = store.progressHistory(exerciseId);
    final first = history.first.$2;
    final latest = history.last.$2;
    final delta = timed ? latest - first : kgToUnit(store.unit, latest - first);

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
        progressValueLabel(l10n, store.unit, latest, timed: timed),
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

/// Body-weight tracking: latest weight, change since the start, a small
/// trend line, and the entry history. Down is not colored "good" or "bad":
/// whether losing or gaining is the goal depends on the lifter.
class _BodyWeightSection extends StatelessWidget {
  const _BodyWeightSection();

  Future<void> _addEntry(BuildContext context) async {
    final store = StoreScope.of(context);
    final weightKg = await _showBodyWeightDialog(context);
    if (weightKg == null) return;
    await store.addBodyWeight(weightKg);
  }

  Future<double?> _showBodyWeightDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final unit = unitLabel(l10n, store.unit);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bodyWeightDialogTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.weightFieldLabel(unit),
                  ),
                  validator: (value) {
                    final weight = parseWeightInput(value);
                    return weight == null || weight <= 0
                        ? l10n.weightValidation(unit)
                        : null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(dialogContext).pop(
                      unitToKg(store.unit, parseWeightInput(controller.text)!),
                    );
                  },
                  child: Text(l10n.save),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final entries = store.bodyWeights;
    final unit = unitLabel(l10n, store.unit);
    final dateFormat = DateFormat.MMMEd(
      Localizations.localeOf(context).toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.bodyWeightTitle, style: textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: () => _addEntry(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addWeightButton),
            ),
          ],
        ),
        if (entries.isEmpty)
          Text(l10n.noBodyWeightYet, style: textTheme.bodyMedium)
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.weightWithUnit(
                          formatKgIn(store.unit, entries.first.weightKg),
                          unit,
                        ),
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 10),
                      if (entries.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Builder(
                            builder: (context) {
                              final delta = kgToUnit(
                                store.unit,
                                entries.first.weightKg - entries.last.weightKg,
                              );
                              return Text(
                                l10n.deltaWithUnit(
                                  '${delta > 0 ? '+' : ''}${formatWeight(delta)}',
                                  unit,
                                ),
                                style: textTheme.bodySmall!.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  if (entries.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SparklinePainter(
                          values: [
                            for (final entry in entries.reversed)
                              entry.weightKg,
                          ],
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          for (final entry in entries)
            SwipeToDelete(
              dismissibleKey: ValueKey('bodyweight-${entry.id}'),
              confirmTitle: l10n.deleteWeightTitle,
              confirmBody: l10n.deleteWeightBody,
              onDelete: () => store.deleteBodyWeight(entry),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(dateFormat.format(entry.date)),
                trailing: Text(
                  l10n.weightWithUnit(
                    formatKgIn(store.unit, entry.weightKg),
                    unit,
                  ),
                  style: textTheme.titleLarge,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Minimal line chart of the body-weight trend, oldest to newest.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var min = values.first;
    var max = values.first;
    for (final value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }
    // A flat line still needs a visible vertical position; inset the top
    // and bottom so the stroke and end dot never clip.
    final range = (max - min) == 0 ? 1.0 : max - min;
    const inset = 4.0;
    final drawHeight = size.height - inset * 2;
    Offset pointAt(int i) => Offset(
      size.width * i / (values.length - 1),
      inset + drawHeight * (1 - (values[i] - min) / range),
    );

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    // Soft fill under the line grounds the trend without adding a second
    // color: same accent at low opacity.
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // The newest measurement gets a dot: it is the number shown above.
    canvas.drawCircle(pointAt(values.length - 1), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      color != oldDelegate.color || !listEquals(values, oldDelegate.values);
}
