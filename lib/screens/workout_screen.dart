import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../exercise_library.dart';
import '../exercise_poses.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import '../plan_generator.dart';
import '../store.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/exercise_figure.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/note_card.dart';
import '../widgets/page_body.dart';
import '../widgets/record_chip.dart';
import 'exercise_detail_screen.dart';
import 'workout_summary_screen.dart';

/// Standard Olympic bar and plate sizes per display unit, values in that
/// unit: a 20 kg bar with kg plates, a 45 lb bar with lb plates.
const _barWeight = {WeightUnit.kg: 20.0, WeightUnit.lb: 45.0};
const _plateSizes = {
  WeightUnit.kg: [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25],
  WeightUnit.lb: [45.0, 35.0, 25.0, 10.0, 5.0, 2.5],
};

/// Plates for one side of the bar to reach [targetWeight], heaviest first,
/// filled greedily. Comes as close as the plate sizes allow from below.
List<double> platesPerSide(WeightUnit unit, double targetWeight) {
  var remaining = (targetWeight - _barWeight[unit]!) / 2;
  final plates = <double>[];
  for (final plate in _plateSizes[unit]!) {
    while (remaining >= plate - 0.001) {
      plates.add(plate);
      remaining -= plate;
    }
  }
  return plates;
}

/// Guided workout session: walks through the day's exercises one at a time,
/// prescribes warm-ups and a target weight, logs every set, and runs the
/// rest timer in between.
///
/// Production behavior:
/// - The screen stays awake for the whole session.
/// - Progress is auto-saved as a draft after every set and restored if the
///   app is killed mid-workout.
/// - The rest timer is wall-clock based, so backgrounding the app never
///   freezes the countdown; a haptic buzz fires when rest is over.
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, required this.planDay});

  final PlanDay planDay;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  late final List<List<SetLog>> _loggedSets = List.generate(
    widget.planDay.exercises.length,
    (_) => [],
  );

  /// The day's exercises, held mutably so a lifter can swap one for a similar
  /// movement mid-session. Swaps replace an entry in place, so the length never
  /// changes and stays aligned with [_loggedSets] and [_formKeys].
  late final List<PlannedExercise> _exercises = List.of(
    widget.planDay.exercises,
  );

  /// -1 is the warm-up page; 0..n-1 are the exercises.
  int _exerciseIndex = -1;
  DateTime _startedAt = DateTime.now();
  DateTime? _restEndsAt;
  Timer? _restTicker;
  bool _initialized = false;

  // One form key per exercise: during the AnimatedSwitcher transition the
  // outgoing and incoming pages coexist, so a single GlobalKey would be a
  // duplicate-key crash.
  late final List<GlobalKey<FormState>> _formKeys = List.generate(
    widget.planDay.exercises.length,
    (_) => GlobalKey<FormState>(),
  );
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  PlannedExercise get _planned => _exercises[_exerciseIndex];
  List<SetLog> get _currentSets => _loggedSets[_exerciseIndex];

  /// A held exercise is logged in seconds and carries no weight, so its page
  /// swaps the reps field for a seconds field and drops the weight input.
  bool get _isTimed => exerciseById(_planned.exerciseId).isTimed;

  bool get _isLastExercise => _exerciseIndex == _exercises.length - 1;
  bool get _hasAnyLoggedSet => _loggedSets.any((sets) => sets.isNotEmpty);

  int get _restSecondsLeft => _restEndsAt == null
      ? 0
      : ((_restEndsAt!.difference(DateTime.now()).inMilliseconds) / 1000)
            .ceil()
            .clamp(0, 24 * 3600);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setWakelock(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS may kill a backgrounded app without further callbacks, so flush
    // the draft the moment we lose foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _restoreDraft();
      if (_exerciseIndex >= 0) _prefillInputs();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTicker?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    _setWakelock(false);
    super.dispose();
  }

  /// A wakelock failure must never break a workout.
  Future<void> _setWakelock(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (_) {}
  }

  void _restoreDraft() {
    final draft = StoreScope.of(context).draft;
    if (draft == null || draft.dayKey != widget.planDay.key) return;
    _startedAt = draft.startedAt;
    // A mid-session swap that was not written back to the plan lives only in
    // the draft, so its movements win over the plan day's. The length is
    // fixed at construction, so only a draft of the same size can be trusted.
    final savedExercises = draft.exercises;
    if (savedExercises != null && savedExercises.length == _exercises.length) {
      _exercises.setAll(0, savedExercises);
    }
    for (var i = 0; i < _exercises.length; i++) {
      final saved = draft.sets[_exercises[i].exerciseId];
      if (saved != null) _loggedSets[i] = List.of(saved);
    }
    // Prefer the exact saved position; older drafts lack it, so fall back to
    // the first exercise that still has sets to do.
    final lastExercise = _exercises.length - 1;
    if (draft.exerciseIndex != null) {
      _exerciseIndex = draft.exerciseIndex!.clamp(0, lastExercise);
    } else {
      _exerciseIndex = lastExercise;
      for (var i = 0; i < _exercises.length; i++) {
        if (_loggedSets[i].length < _exercises[i].sets) {
          _exerciseIndex = i;
          break;
        }
      }
    }
  }

  /// Persists the in-progress workout. Only once lifting has begun
  /// (`_exerciseIndex >= 0`): a draft always means "resume me", so a session
  /// abandoned on the warm-up page never becomes a phantom resume prompt.
  Future<void> _saveDraft() {
    if (_exerciseIndex < 0) return Future.value();
    return StoreScope.of(context).saveDraft(
      WorkoutDraft(
        dayKey: widget.planDay.key,
        startedAt: _startedAt,
        exerciseIndex: _exerciseIndex,
        exercises: _exercises,
        sets: {
          for (var i = 0; i < _loggedSets.length; i++)
            if (_loggedSets[i].isNotEmpty)
              _exercises[i].exerciseId: _loggedSets[i],
        },
      ),
    );
  }

  void _prefillInputs() {
    final store = StoreScope.of(context);
    final suggestion = store.suggestedWeight(_planned);
    _weightController.text = suggestion == null
        ? ''
        : formatKgIn(store.unit, suggestion);
    _prefillReps();
  }

  void _prefillReps() {
    final store = StoreScope.of(context);
    _repsController.text =
        '${store.suggestedReps(_planned, _currentSets.length)}';
  }

  /// Loading guide under the weight field for barbell lifts: the plates for
  /// one side of the bar, drawn as tiles whose height scales with the plate
  /// size, the way they would hang on the bar.
  Widget _plateHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = _parseNumber(_weightController.text);
    if (target == null || target <= 0) return const SizedBox.shrink();

    final hintStyle = textTheme.bodySmall!.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final plates = platesPerSide(store.unit, target);
    if (plates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          l10n.plateCalcBarOnly,
          textAlign: TextAlign.center,
          style: hintStyle,
        ),
      );
    }

    final maxPlate = _plateSizes[store.unit]!.first;
    final total =
        _barWeight[store.unit]! + 2 * plates.fold(0.0, (sum, p) => sum + p);
    final rounded = (total - target).abs() >= 0.001;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        container: true,
        label:
            '${l10n.plateCalcPerSideLabel}: '
            '${plates.map(formatWeight).join(', ')}',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(
                l10n.plateCalcPerSideLabel.toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  letterSpacing: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final plate in plates)
                    Container(
                      width: 34,
                      height: 22 + 14 * (plate / maxPlate),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Text(
                        formatWeight(plate),
                        style: textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              if (rounded) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.plateCalcTotal(
                    formatWeight(total),
                    unitLabel(l10n, store.unit),
                  ),
                  style: hintStyle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// What the trainer says about the coming sets: how the last session went
  /// and what to beat today. Held exercises talk in seconds, bodyweight
  /// movements in reps, and a lift stuck at the same weight for three
  /// sessions gets told to go lighter rather than grind it again.
  String _trainerTip(AppLocalizations l10n, AppStore store) {
    final last = store.lastLogFor(_planned.exerciseId);
    final unit = unitLabel(l10n, store.unit);
    if (_isTimed) {
      if (last == null) return l10n.trainerTipTimedFirst;
      return l10n.trainerTipTimedRepeat(_bestReps(last));
    }
    if (last == null) return l10n.trainerTipFirstTime;
    final suggestion = store.suggestedWeight(_planned)!;
    if (suggestion > last.bestWeight) {
      return l10n.trainerTipIncrease(formatKgIn(store.unit, suggestion), unit);
    }
    if (suggestion < last.bestWeight) {
      return l10n.trainerTipDeload(formatKgIn(store.unit, suggestion), unit);
    }
    // Bodyweight work logs no load, so there is no weight to quote back.
    if (last.bestWeight == 0) return l10n.trainerTipBodyweight(_bestReps(last));
    return l10n.trainerTipRepeat(formatKgIn(store.unit, last.bestWeight), unit);
  }

  /// The best set of a log, counted in reps or seconds.
  int _bestReps(ExerciseLog log) =>
      log.sets.fold(0, (best, s) => s.reps > best ? s.reps : best);

  bool _isRecordSet(AppStore store, SetLog set) =>
      store.isRecordSet(_planned.exerciseId, set);

  double? _parseNumber(String? value) => parseWeightInput(value);

  int? _parseReps(String? value) => int.tryParse((value ?? '').trim());

  void _logSet() {
    if (!_formKeys[_exerciseIndex].currentState!.validate()) return;
    final unit = StoreScope.of(context).unit;
    HapticFeedback.lightImpact();
    setState(() {
      _currentSets.add(
        SetLog(
          // A hold has no weight field: the seconds are the whole set.
          weightKg: _isTimed
              ? 0
              : unitToKg(unit, _parseNumber(_weightController.text)!),
          reps: _parseReps(_repsController.text)!,
        ),
      );
      _prefillReps();
      if (_currentSets.length < _planned.sets) _startRest();
    });
    _saveDraft();
  }

  /// Adjusts the weight field by [delta] in the display unit.
  void _bumpWeight(double delta) {
    final current = _parseNumber(_weightController.text) ?? 0;
    final next = (current + delta).clamp(0, 999).toDouble();
    setState(() => _weightController.text = formatWeight(next));
  }

  /// Steps the reps field by one, or a held exercise's seconds field by the
  /// same few seconds its progression uses.
  void _bumpReps(int direction) {
    final step = _isTimed ? timedProgressionSeconds : 1;
    final current = _parseReps(_repsController.text) ?? _planned.repsMin;
    final next = (current + direction * step).clamp(1, 999);
    setState(() => _repsController.text = '$next');
  }

  void _startRest() {
    _restTicker?.cancel();
    _restEndsAt = DateTime.now().add(Duration(seconds: _planned.restSeconds));
    _restTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_restSecondsLeft <= 0) {
        HapticFeedback.heavyImpact();
        setState(_stopRest);
      } else {
        setState(() {});
      }
    });
  }

  void _stopRest() {
    _restTicker?.cancel();
    _restTicker = null;
    _restEndsAt = null;
  }

  void _nextExercise() => _goToExercise(_exerciseIndex + 1);

  void _previousExercise() => _goToExercise(_exerciseIndex - 1);

  void _goToExercise(int index) {
    setState(() {
      _stopRest();
      _exerciseIndex = index;
      _weightController.clear();
      _repsController.clear();
      _prefillInputs();
    });
    _saveDraft();
  }

  /// Swaps the current exercise for a similar one. The swap applies to this
  /// session (its logged sets are cleared, since they belong to a different
  /// movement) and, if the lifter opts in, is also written back to the plan.
  Future<void> _replaceCurrentExercise() async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final index = _exerciseIndex;
    final pick = await showExercisePicker(
      context,
      currentExerciseId: _exercises[index].exerciseId,
      offerPlanUpdate: true,
    );
    if (!mounted || pick == null) return;
    if (_loggedSets[index].isNotEmpty) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.replaceExerciseClearTitle,
        body: l10n.replaceExerciseClearBody,
        primaryLabel: l10n.replace,
        secondaryLabel: l10n.cancel,
      );
      if (!mounted || !confirmed) return;
    }
    final old = _exercises[index];
    setState(() {
      _exercises[index] = prescriptionForSwap(old, pick.exerciseId);
      _loggedSets[index] = [];
      _stopRest();
      _weightController.clear();
      _repsController.clear();
      _prefillInputs();
    });
    await _saveDraft();
    if (pick.alsoUpdatePlan) {
      await store.replacePlanExercise(
        widget.planDay.key,
        index,
        pick.exerciseId,
      );
    }
  }

  Future<void> _finishWorkout() async {
    final store = StoreScope.of(context);
    final navigator = Navigator.of(context);
    final session = WorkoutSession(
      date: DateTime.now(),
      dayKey: widget.planDay.key,
      logs: [
        for (var i = 0; i < _loggedSets.length; i++)
          if (_loggedSets[i].isNotEmpty)
            ExerciseLog(
              exerciseId: _exercises[i].exerciseId,
              sets: _loggedSets[i],
            ),
      ],
    );
    await store.addSession(session);
    await store.clearDraft();
    HapticFeedback.mediumImpact();
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          session: session,
          duration: DateTime.now().difference(_startedAt),
        ),
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final navigator = Navigator.of(context);
    if (!_hasAnyLoggedSet) {
      await store.clearDraft();
      navigator.pop();
      return;
    }
    final quit = await showConfirmDialog(
      context,
      title: l10n.exitWorkoutTitle,
      body: l10n.exitWorkoutBody,
      primaryLabel: l10n.quit,
      secondaryLabel: l10n.keepGoing,
      destructive: true,
    );
    if (quit) {
      await store.clearDraft();
      navigator.pop();
    }
  }

  Widget _trainerCard(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dedicated warm-up step shown before the first exercise.
  Widget _warmupPage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      key: const ValueKey(-1),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.warmupTitle,
          style: textTheme.headlineMedium!.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              image: true,
              label: l10n.warmupTitle,
              child: ExerciseFigure(
                illustration: illustrationFor('jumpRope'),
                height: 150,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _trainerCard(context, Icons.directions_run, l10n.warmupCardio),
        const SizedBox(height: 8),
        _trainerCard(context, Icons.accessibility_new, l10n.warmupDynamic),
        const SizedBox(height: 8),
        _trainerCard(context, Icons.local_fire_department, l10n.warmupLifts),
        const SizedBox(height: 8),
        _trainerCard(context, Icons.speed, l10n.effortNote),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _exerciseIndex = 0;
              _prefillInputs();
            });
            _saveDraft();
          },
          icon: const Icon(Icons.bolt),
          label: Text(l10n.startLifting),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onWarmup = _exerciseIndex < 0;
    final total = widget.planDay.exercises.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            onWarmup
                ? l10n.warmupTitle
                : l10n.exerciseProgress(_exerciseIndex + 1, total),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: onWarmup ? 0 : (_exerciseIndex + 1) / total,
            ),
          ),
        ),
        body: PageBody(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: onWarmup ? _warmupPage(context) : _exercisePage(context),
          ),
        ),
      ),
    );
  }

  Widget _exercisePage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final exercise = exerciseById(_planned.exerciseId);
    final unit = unitLabel(l10n, store.unit);
    final allSetsDone = _currentSets.length >= _planned.sets;
    final resting = _restEndsAt != null;
    // The cardio both of these goals promise at sign-up. Shown for the whole
    // last exercise, not only once its sets are done, so nobody who finishes
    // early leaves without it.
    final goal = store.plan?.goal;
    final cardioNote = !_isLastExercise
        ? null
        : switch (goal) {
            Goal.loseWeight => l10n.cardioFinisher,
            Goal.getFit => l10n.cardioFinisherFit,
            _ => null,
          };
    final tip = _trainerTip(l10n, store);

    return ListView(
      key: ValueKey(_exerciseIndex),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineMedium!.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.swap_horiz),
              tooltip: l10n.swapTooltip,
              onPressed: _replaceCurrentExercise,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.info_outline),
              tooltip: l10n.exerciseInfoTooltip,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(exercise: exercise),
                ),
              ),
            ),
          ],
        ),
        Text(
          '${equipmentLabel(l10n, exercise.equipment)} · '
          '${setsAndRepsLabel(l10n, _planned.sets, _planned.repsMin, _planned.repsMax, timed: _isTimed)} · '
          '${l10n.restInfo(_planned.restSeconds)}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < _planned.sets; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _currentSets.length
                        ? colorScheme.primary
                        : colorScheme.surface.withAlpha(0),
                    border: Border.all(
                      color: i < _currentSets.length
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              image: true,
              label: exercise.name,
              child: ExerciseFigure(
                key: ValueKey(_planned.exerciseId),
                illustration: illustrationFor(_planned.exerciseId),
                height: 150,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _trainerCard(context, Icons.tips_and_updates, tip),
        if (store.noteFor(_planned.exerciseId) case final String note) ...[
          const SizedBox(height: 8),
          NoteCard(text: note),
        ],
        if (_planned.warmupSets > 0 && _currentSets.isEmpty) ...[
          const SizedBox(height: 8),
          _trainerCard(
            context,
            Icons.local_fire_department,
            l10n.warmupInfo(_planned.warmupSets),
          ),
        ],
        const SizedBox(height: 8),
        for (var i = 0; i < _currentSets.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle, color: colorScheme.primary),
            title: _isRecordSet(store, _currentSets[i])
                ? Row(
                    children: [
                      Text(l10n.setLabel(i + 1)),
                      const SizedBox(width: 8),
                      const RecordChip(),
                    ],
                  )
                : Text(l10n.setLabel(i + 1)),
            trailing: Text(
              setResultLabel(
                l10n,
                store.unit,
                _currentSets[i],
                timed: _isTimed,
              ),
              style: textTheme.titleLarge,
            ),
          ),
        const SizedBox(height: 8),
        if (resting)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l10n.restTitle.toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(letterSpacing: 2.5),
                  ),
                  Text(
                    '$_restSecondsLeft',
                    style: textTheme.displayLarge!.copyWith(
                      color: colorScheme.primary,
                      fontSize: 96,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_restSecondsLeft / _planned.restSeconds).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () => setState(() {
                          _restEndsAt = _restEndsAt?.add(
                            const Duration(seconds: 30),
                          );
                        }),
                        child: Text(l10n.addRestTime),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => setState(_stopRest),
                        child: Text(l10n.skipRest),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else if (!allSetsDone)
          Form(
            key: _formKeys[_exerciseIndex],
            child: Column(
              children: [
                // A hold carries no load, so it gets no weight field.
                if (!_isTimed) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _bumpWeight(-2.5),
                        icon: const Icon(Icons.remove),
                        padding: const EdgeInsets.all(14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.weightFieldLabel(unit),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final weight = _parseNumber(value);
                            return weight == null || weight < 0
                                ? l10n.weightValidation(unit)
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => _bumpWeight(2.5),
                        icon: const Icon(Icons.add),
                        padding: const EdgeInsets.all(14),
                      ),
                    ],
                  ),
                  if (exercise.equipment == 'barbell') _plateHint(context),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _bumpReps(-1),
                      icon: const Icon(Icons.remove),
                      padding: const EdgeInsets.all(14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _isTimed
                              ? l10n.secondsFieldLabel
                              : l10n.repsFieldLabel,
                        ),
                        validator: (value) {
                          final reps = _parseReps(value);
                          if (reps != null && reps > 0) return null;
                          return _isTimed
                              ? l10n.secondsValidation
                              : l10n.repsValidation;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _bumpReps(1),
                      icon: const Icon(Icons.add),
                      padding: const EdgeInsets.all(14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _logSet,
                  icon: const Icon(Icons.check),
                  label: Text(
                    '${l10n.logSetButton} ${_currentSets.length + 1}/${_planned.sets}',
                  ),
                ),
              ],
            ),
          ),
        if (cardioNote != null) ...[
          const SizedBox(height: 8),
          _trainerCard(context, Icons.directions_run, cardioNote),
        ],
        const SizedBox(height: 24),
        if (_isLastExercise)
          FilledButton.tonalIcon(
            onPressed: _hasAnyLoggedSet ? _finishWorkout : null,
            icon: const Icon(Icons.flag),
            label: Text(l10n.finishWorkout),
          )
        else
          FilledButton.tonalIcon(
            onPressed: _nextExercise,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.nextExercise),
          ),
        if (_exerciseIndex > 0) ...[
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _previousExercise,
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.previousExercise),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
