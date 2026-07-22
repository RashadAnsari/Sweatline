import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../exercise_poses.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/exercise_figure.dart';
import '../widgets/muscle_diagram.dart';
import '../widgets/note_card.dart';
import '../widgets/note_dialog.dart';
import '../widgets/page_body.dart';

/// Full exercise card: muscle map, equipment, how-to steps, trainer form
/// tips, the user's own note, and their history for the lift.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  Future<void> _editNote(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final text = await showNoteDialog(
      context,
      title: l10n.myNoteTitle,
      initialText: store.noteFor(exercise.id) ?? '',
      hint: l10n.noteHint,
      saveLabel: l10n.save,
      cancelLabel: l10n.cancel,
    );
    if (text == null) return;
    await store.setExerciseNote(exercise.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final history = store.weightHistory(exercise.id);
    final dateFormat = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Semantics(
                  image: true,
                  label: exercise.name,
                  child: ExerciseFigure(
                    illustration: illustrationFor(exercise.id),
                    height: 170,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Semantics(
                      image: true,
                      label:
                          '${l10n.primaryMusclesLabel}: '
                          '${exercise.primaryMuscles.map((m) => muscleLabel(l10n, m)).join(', ')}. '
                          '${l10n.secondaryMusclesLabel}: '
                          '${exercise.secondaryMuscles.map((m) => muscleLabel(l10n, m)).join(', ')}',
                      child: MuscleDiagram(
                        primaryMuscles: exercise.primaryMuscles.toSet(),
                        secondaryMuscles: exercise.secondaryMuscles.toSet(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            l10n.diagramFront,
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall,
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            l10n.diagramBack,
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                  label: Text(equipmentLabel(l10n, exercise.equipment)),
                ),
                for (final muscle in exercise.primaryMuscles)
                  Chip(
                    label: Text(muscleLabel(l10n, muscle)),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
                    side: BorderSide.none,
                  ),
                for (final muscle in exercise.secondaryMuscles)
                  Chip(label: Text(muscleLabel(l10n, muscle))),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.howToTitle, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            for (var i = 0; i < exercise.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        style: textTheme.headlineSmall!.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        exercise.steps[i],
                        style: textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(l10n.trainerTipsTitle, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tip in exercise.tips)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates,
                              size: 18,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tip,
                                style: textTheme.bodyMedium!.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.myNoteTitle, style: textTheme.titleLarge),
                ),
                TextButton.icon(
                  onPressed: () => _editNote(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    store.noteFor(exercise.id) == null
                        ? l10n.addNoteButton
                        : l10n.editNoteButton,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (store.noteFor(exercise.id) case final String note)
              NoteCard(text: note)
            else
              Text(l10n.noNoteYet, style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text(l10n.yourHistoryTitle, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Text(l10n.noHistoryYet, style: textTheme.bodyMedium)
            else ...[
              Card(
                child: ListTile(
                  leading: Icon(Icons.emoji_events, color: colorScheme.primary),
                  title: Text(l10n.allTimeBest),
                  trailing: Text(
                    l10n.weightWithUnit(
                      formatKgIn(
                        store.unit,
                        history
                            .map((entry) => entry.$2)
                            .reduce((a, b) => a > b ? a : b),
                      ),
                      unitLabel(l10n, store.unit),
                    ),
                    style: textTheme.titleLarge!.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              for (final (date, weight) in history.reversed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(dateFormat.format(date)),
                  trailing: Text(
                    l10n.weightWithUnit(
                      formatKgIn(store.unit, weight),
                      unitLabel(l10n, store.unit),
                    ),
                    style: textTheme.titleLarge,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
