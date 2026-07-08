import 'package:flutter/material.dart';

import '../exercise_library.dart';
import '../exercise_poses.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../widgets/exercise_figure.dart';
import 'exercise_detail_screen.dart';

/// Browsable exercise encyclopedia with search and muscle-group filters.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _query = '';
  String? _group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final results = exerciseLibrary.where((exercise) {
      final matchesGroup = _group == null || exercise.group == _group;
      final matchesQuery =
          _query.isEmpty ||
          exercise.name.toLowerCase().contains(_query.toLowerCase());
      return matchesGroup && matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.librarySearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (final group in exerciseGroups)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(muscleLabel(l10n, group)),
                    selected: _group == group,
                    onSelected: (selected) =>
                        setState(() => _group = selected ? group : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(l10n.libraryEmpty, style: textTheme.bodyLarge),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final exercise = results[index];
                    return ListTile(
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ExerciseFigure(
                          illustration: illustrationFor(exercise.id),
                          height: 48,
                          animate: false,
                        ),
                      ),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${equipmentLabel(l10n, exercise.equipment)} · '
                        '${exercise.primaryMuscles.map((m) => muscleLabel(l10n, m)).join(', ')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(exercise: exercise),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
