import 'package:flutter/material.dart';

import '../exercise_library.dart';
import '../exercise_poses.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import 'exercise_figure.dart';

/// The outcome of the exercise picker: which exercise to swap in, and whether
/// the change should also be written back to the saved plan.
class ExerciseReplacement {
  const ExerciseReplacement({
    required this.exerciseId,
    this.alsoUpdatePlan = false,
  });

  final String exerciseId;
  final bool alsoUpdatePlan;
}

/// Shows a bottom sheet of exercises similar to [currentExerciseId] and returns
/// the chosen replacement, or null if dismissed. When [offerPlanUpdate] is true
/// the sheet includes an "also change this in my plan" checkbox, used from a
/// live workout where the swap defaults to this session only.
Future<ExerciseReplacement?> showExercisePicker(
  BuildContext context, {
  required String currentExerciseId,
  bool offerPlanUpdate = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  final current = exerciseById(currentExerciseId);
  final options = similarExercises(currentExerciseId);
  return showModalBottomSheet<ExerciseReplacement>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      var alsoUpdatePlan = false;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final scheme = Theme.of(context).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.replaceExerciseTitle(current.name),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l10n.noSimilarExercises),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, i) {
                          final e = options[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ExerciseFigure(
                                illustration: illustrationFor(e.id),
                                height: 44,
                                animate: false,
                              ),
                            ),
                            title: Text(e.name),
                            subtitle: Text(equipmentLabel(l10n, e.equipment)),
                            onTap: () => Navigator.of(sheetContext).pop(
                              ExerciseReplacement(
                                exerciseId: e.id,
                                alsoUpdatePlan: alsoUpdatePlan,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (offerPlanUpdate && options.isNotEmpty)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: alsoUpdatePlan,
                      onChanged: (value) =>
                          setSheetState(() => alsoUpdatePlan = value ?? false),
                      title: Text(l10n.alsoUpdatePlan),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
