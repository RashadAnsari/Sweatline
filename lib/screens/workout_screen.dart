import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../exercise_library.dart';
import '../l10n/app_localizations.dart';
import '../labels.dart';
import '../main.dart';
import '../models.dart';
import 'exercise_detail_screen.dart';

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

class _WorkoutScreenState extends State<WorkoutScreen> {
  late final List<List<SetLog>> _loggedSets = List.generate(
    widget.planDay.exercises.length,
    (_) => [],
  );

  int _exerciseIndex = 0;
  DateTime _startedAt = DateTime.now();
  DateTime? _restEndsAt;
  Timer? _restTicker;
  bool _initialized = false;

  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  PlannedExercise get _planned => widget.planDay.exercises[_exerciseIndex];
  List<SetLog> get _currentSets => _loggedSets[_exerciseIndex];
  bool get _isLastExercise =>
      _exerciseIndex == widget.planDay.exercises.length - 1;
  bool get _hasAnyLoggedSet => _loggedSets.any((sets) => sets.isNotEmpty);

  int get _restSecondsLeft => _restEndsAt == null
      ? 0
      : ((_restEndsAt!.difference(DateTime.now()).inMilliseconds) / 1000)
            .ceil()
            .clamp(0, 24 * 3600);

  @override
  void initState() {
    super.initState();
    _setWakelock(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _restoreDraft();
      _prefillWeight();
    }
  }

  @override
  void dispose() {
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
    for (var i = 0; i < widget.planDay.exercises.length; i++) {
      final saved = draft.sets[widget.planDay.exercises[i].exerciseId];
      if (saved != null) _loggedSets[i] = List.of(saved);
    }
    // Resume at the first exercise that still has sets to do.
    var resumeIndex = widget.planDay.exercises.length - 1;
    for (var i = 0; i < widget.planDay.exercises.length; i++) {
      if (_loggedSets[i].length < widget.planDay.exercises[i].sets) {
        resumeIndex = i;
        break;
      }
    }
    _exerciseIndex = resumeIndex;
  }

  Future<void> _saveDraft() {
    return StoreScope.of(context).saveDraft(
      WorkoutDraft(
        dayKey: widget.planDay.key,
        startedAt: _startedAt,
        sets: {
          for (var i = 0; i < _loggedSets.length; i++)
            if (_loggedSets[i].isNotEmpty)
              widget.planDay.exercises[i].exerciseId: _loggedSets[i],
        },
      ),
    );
  }

  void _prefillWeight() {
    final store = StoreScope.of(context);
    final suggestion = store.suggestedWeight(_planned);
    _weightController.text = suggestion == null
        ? ''
        : formatKgIn(store.unit, suggestion);
  }

  double? _parseNumber(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  int? _parseReps(String? value) => int.tryParse((value ?? '').trim());

  void _logSet() {
    if (!_formKey.currentState!.validate()) return;
    final unit = StoreScope.of(context).unit;
    setState(() {
      _currentSets.add(
        SetLog(
          weightKg: unitToKg(unit, _parseNumber(_weightController.text)!),
          reps: _parseReps(_repsController.text)!,
        ),
      );
      _repsController.clear();
      if (_currentSets.length < _planned.sets) _startRest();
    });
    _saveDraft();
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

  void _nextExercise() {
    setState(() {
      _stopRest();
      _exerciseIndex++;
      _weightController.clear();
      _repsController.clear();
      _prefillWeight();
    });
  }

  Future<void> _finishWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await store.addSession(
      WorkoutSession(
        date: DateTime.now(),
        dayKey: widget.planDay.key,
        logs: [
          for (var i = 0; i < _loggedSets.length; i++)
            if (_loggedSets[i].isNotEmpty)
              ExerciseLog(
                exerciseId: widget.planDay.exercises[i].exerciseId,
                sets: _loggedSets[i],
              ),
        ],
      ),
    );
    await store.clearDraft();
    messenger.showSnackBar(SnackBar(content: Text(l10n.workoutSavedMessage)));
    navigator.pop();
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
    final quit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitWorkoutTitle),
        content: Text(l10n.exitWorkoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.quit),
          ),
        ],
      ),
    );
    if (quit == true) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = StoreScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final exercise = exerciseById(_planned.exerciseId);
    final unit = unitLabel(l10n, store.unit);
    final total = widget.planDay.exercises.length;
    final allSetsDone = _currentSets.length >= _planned.sets;
    final resting = _restEndsAt != null;
    final sessionStart = _exerciseIndex == 0 && _currentSets.isEmpty;
    final showCardioFinisher =
        _isLastExercise && allSetsDone && store.plan?.goal == Goal.loseWeight;

    final suggestion = store.suggestedWeight(_planned);
    final lastLog = store.lastLogFor(_planned.exerciseId);
    final String tip;
    if (lastLog == null) {
      tip = l10n.trainerTipFirstTime;
    } else if (suggestion != null && suggestion > lastLog.bestWeight) {
      tip = l10n.trainerTipIncrease(formatKgIn(store.unit, suggestion), unit);
    } else {
      tip = l10n.trainerTipRepeat(
        formatKgIn(store.unit, lastLog.bestWeight),
        unit,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.exerciseProgress(_exerciseIndex + 1, total)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_exerciseIndex + 1) / total),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (sessionStart) ...[
              _trainerCard(context, Icons.directions_run, l10n.sessionWarmup),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: textTheme.headlineMedium!.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
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
              '${l10n.setsByReps(_planned.sets, _planned.repsMin, _planned.repsMax)} · '
              '${l10n.restInfo(_planned.restSeconds)}',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _trainerCard(context, Icons.tips_and_updates, tip),
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
                title: Text(l10n.setLabel(i + 1)),
                trailing: Text(
                  l10n.setResult(
                    formatKgIn(store.unit, _currentSets[i].weightKg),
                    unit,
                    _currentSets[i].reps,
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
                        style: textTheme.labelSmall!.copyWith(
                          letterSpacing: 2.5,
                        ),
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
                        value: _restSecondsLeft / _planned.restSeconds,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(_stopRest),
                        child: Text(l10n.skipRest),
                      ),
                    ],
                  ),
                ),
              )
            else if (!allSetsDone)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.weightFieldLabel(unit),
                            ),
                            validator: (value) {
                              final weight = _parseNumber(value);
                              return weight == null || weight < 0
                                  ? l10n.weightValidation(unit)
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _repsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.repsFieldLabel,
                            ),
                            validator: (value) {
                              final reps = _parseReps(value);
                              return reps == null || reps <= 0
                                  ? l10n.repsValidation
                                  : null;
                            },
                          ),
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
            if (showCardioFinisher) ...[
              const SizedBox(height: 8),
              _trainerCard(context, Icons.directions_run, l10n.cardioFinisher),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
