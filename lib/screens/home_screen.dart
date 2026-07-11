import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../exercise_library.dart';
import '../exercise_poses.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../plan_generator.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/exercise_figure.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/page_body.dart';
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
      body: PageBody(
        child: IndexedStack(
          index: _tabIndex,
          children: const [
            _TodayTab(),
            _PlanTab(),
            LibraryTab(),
            ProgressTab(),
          ],
        ),
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

class _TodayTab extends StatefulWidget {
  const _TodayTab();

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  /// Offset from today's plan day; browsing wraps around the split.
  int _dayOffset = 0;
  bool _startedOnDraft = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On launch, open on the in-progress workout's day so its Resume button
    // is the first thing shown.
    if (_startedOnDraft) return;
    _startedOnDraft = true;
    final store = StoreScope.of(context);
    final draft = store.draft;
    if (draft == null) return;
    final plan = store.plan!;
    final draftIndex = plan.days.indexWhere((d) => d.key == draft.dayKey);
    final todayIndex = plan.days.indexWhere(
      (d) => d.key == store.todayPlanDay.key,
    );
    if (draftIndex >= 0 && todayIndex >= 0) {
      _dayOffset = draftIndex - todayIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final plan = store.plan!;
    final dayCount = plan.days.length;
    final todayDay = store.todayPlanDay;
    final todayIndex = plan.days.indexWhere((d) => d.key == todayDay.key);
    final selectedIndex = (todayIndex + _dayOffset) % dayCount;
    final day =
        plan.days[selectedIndex < 0 ? selectedIndex + dayCount : selectedIndex];
    final isToday = _dayOffset % dayCount == 0;
    final sessions = store.sessions;
    final locale = Localizations.localeOf(context).toString();
    final weeklyTarget = dayCount;
    // Capped at the target so overachieving weeks read "2 of 2", not "4 of 2".
    final weeklyDone = store.sessionsThisWeek.clamp(0, weeklyTarget);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          DateFormat.MMMMEEEEd(locale).format(DateTime.now()),
          style: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
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
                (isToday ? l10n.todayWorkoutTitle : l10n.upNextTitle)
                    .toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  letterSpacing: 2.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dayLabel(l10n, day.key),
                      style: textTheme.displaySmall!.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: l10n.previousWorkoutTooltip,
                    onPressed: () => setState(() => _dayOffset--),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: l10n.nextWorkoutTooltip,
                    onPressed: () => setState(() => _dayOffset++),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.exerciseCount(day.exercises.length)} · '
                '${l10n.estimatedMinutes(estimatedSessionMinutes(day))}',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < weeklyTarget; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < weeklyDone
                              ? colorScheme.primary
                              : colorScheme.surface.withAlpha(0),
                          border: Border.all(
                            color: i < weeklyDone
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.weeklyProgress(weeklyDone, weeklyTarget),
                      style: textTheme.bodySmall!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                    DateFormat.MMMEd(locale).format(sessions.first.date),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PlannedExerciseTile extends StatelessWidget {
  const _PlannedExerciseTile({required this.planned, this.onReplace});

  final PlannedExercise planned;

  /// When set, a swap button is shown that replaces this exercise. Omitted on
  /// the read-only Today preview.
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = exerciseById(planned.exerciseId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
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
        '${l10n.setsByReps(planned.sets, planned.repsMin, planned.repsMax)} · '
        '${l10n.restInfo(planned.restSeconds)}',
      ),
      trailing: onReplace == null
          ? const Icon(Icons.chevron_right)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: l10n.swapTooltip,
                  onPressed: onReplace,
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
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
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.newPlanConfirmTitle,
      body: l10n.newPlanConfirmBody,
      primaryLabel: l10n.replace,
      secondaryLabel: l10n.cancel,
    );
    if (confirmed) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _replacePlanExercise(
    BuildContext context,
    String dayKey,
    int index,
    String currentExerciseId,
  ) async {
    final store = StoreScope.of(context);
    final pick = await showExercisePicker(
      context,
      currentExerciseId: currentExerciseId,
    );
    if (pick == null) return;
    await store.replacePlanExercise(dayKey, index, pick.exerciseId);
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
          runSpacing: 8,
          children: [
            Chip(label: Text(goalLabel(l10n, plan.goal))),
            Chip(label: Text(levelLabel(l10n, plan.level))),
            Chip(label: Text(l10n.daysOption(plan.days.length))),
          ],
        ),
        for (final day in plan.days) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayLabel(l10n, day.key),
                          style: textTheme.headlineSmall!.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        l10n.estimatedMinutes(estimatedSessionMinutes(day)),
                        style: textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  for (var i = 0; i < day.exercises.length; i++)
                    _PlannedExerciseTile(
                      planned: day.exercises[i],
                      onReplace: () => _replacePlanExercise(
                        context,
                        day.key,
                        i,
                        day.exercises[i].exerciseId,
                      ),
                    ),
                ],
              ),
            ),
          ),
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
