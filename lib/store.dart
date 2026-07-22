import 'dart:convert';

import 'package:flutter/material.dart';

import 'database.dart';
import 'exercise_library.dart';
import 'labels.dart';
import 'models.dart';
import 'plan_generator.dart';

/// Midnight on the Monday of [date]'s week. Uses calendar arithmetic so a
/// daylight saving change never shifts the boundary to the wrong day.
DateTime mondayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

/// App state backed by SQLite ([AppDatabase]).
///
/// The public API is synchronous: everything is loaded into memory once at
/// [open], and reads (used inside widget builds) serve from that cache.
/// Writes update the cache and persist incrementally to the database, so
/// logging a workout inserts a few rows instead of rewriting all history.
///
/// Meta values (plan, draft) are decoded defensively: a corrupt value is
/// dropped and logged instead of crashing the app.
class AppStore extends ChangeNotifier {
  AppStore._(
    this._db, {
    required Plan? plan,
    required List<WorkoutSession> sessions,
    required WorkoutDraft? draft,
    required WeightUnit unit,
    required ThemeMode themeMode,
    required TimeOfDay? reminderTime,
    required Map<String, String> exerciseNotes,
    required List<BodyWeightEntry> bodyWeights,
  }) : _plan = plan,
       _sessions = sessions,
       _draft = draft,
       _unit = unit,
       _themeMode = themeMode,
       _reminderTime = reminderTime,
       _exerciseNotes = exerciseNotes,
       _bodyWeights = bodyWeights;

  static const _planKey = 'plan';
  static const _draftKey = 'draft';
  static const _unitKey = 'unit';
  static const _themeModeKey = 'themeMode';
  static const _reminderKey = 'reminderMinutes';
  static const _notesKey = 'exerciseNotes';

  final AppDatabase _db;

  Plan? _plan;
  List<WorkoutSession> _sessions;
  WorkoutDraft? _draft;
  WeightUnit _unit;
  ThemeMode _themeMode;
  TimeOfDay? _reminderTime;

  /// The lifter's own sticky note per exercise id ("seat at 4", "narrow
  /// grip"). Lives in meta as one JSON object.
  Map<String, String> _exerciseNotes;

  /// Body-weight measurements, newest first.
  List<BodyWeightEntry> _bodyWeights;

  /// Opens the store, loading everything from [db] into memory.
  static Future<AppStore> open(AppDatabase db) async {
    final plan = await _guarded(db, _planKey, (raw) {
      return Plan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });
    final draft = await _guarded(db, _draftKey, (raw) {
      return WorkoutDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });
    final unit = _enumMeta(await db.getMeta(_unitKey), WeightUnit.values);
    final themeMode = _enumMeta(
      await db.getMeta(_themeModeKey),
      ThemeMode.values,
    );
    // Stored as minutes from midnight; a corrupt value means "off".
    final reminderMinutes = int.tryParse(await db.getMeta(_reminderKey) ?? '');
    final notes = await _guarded(db, _notesKey, (raw) {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (id, note) => MapEntry(id, note as String),
      );
    });

    return AppStore._(
      db,
      plan: plan,
      sessions: await db.loadSessions(),
      draft: draft,
      unit: unit ?? WeightUnit.kg,
      themeMode: themeMode ?? ThemeMode.system,
      reminderTime: reminderMinutes == null || reminderMinutes < 0
          ? null
          : TimeOfDay(
              hour: (reminderMinutes ~/ 60) % 24,
              minute: reminderMinutes % 60,
            ),
      exerciseNotes: notes ?? {},
      bodyWeights: await db.loadBodyWeights(),
    );
  }

  /// Decodes a meta value; on failure drops the bad row and returns null so
  /// the rest of the app keeps working.
  static Future<T?> _guarded<T>(
    AppDatabase db,
    String key,
    T Function(String raw) decode,
  ) async {
    final raw = await db.getMeta(key);
    if (raw == null) return null;
    try {
      return decode(raw);
    } catch (error) {
      debugPrint('Sweatline: corrupt "$key" dropped: $error');
      await db.deleteMeta(key);
      return null;
    }
  }

  static T? _enumMeta<T extends Enum>(String? raw, List<T> values) =>
      raw == null ? null : values.asNameMap()[raw];

  Plan? get plan => _plan;

  /// Newest first.
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  WorkoutDraft? get draft => _draft;
  WeightUnit get unit => _unit;
  ThemeMode get themeMode => _themeMode;

  bool get hasPlan => _plan != null;

  Future<void> setPlan(Plan plan) async {
    _plan = plan;
    await _db.setMeta(_planKey, jsonEncode(plan.toJson()));
    // A new plan invalidates any in-progress draft: its saved sets are keyed
    // to the old plan's exercises, so restoring it would map onto the wrong
    // day or orphan the draft when no day shares its key.
    if (_draft != null) {
      _draft = null;
      await _db.deleteMeta(_draftKey);
    }
    notifyListeners();
  }

  /// Applies [mutate] to a copy of the [dayKey] day's exercise list and, when
  /// it reports a change, persists the rewritten plan. Returns whether the
  /// plan changed. Callers stay responsible for [notifyListeners].
  Future<bool> _mutatePlanDay(
    String dayKey,
    bool Function(List<PlannedExercise> exercises) mutate,
  ) async {
    final plan = _plan;
    if (plan == null) return false;
    final dayIndex = plan.days.indexWhere((d) => d.key == dayKey);
    if (dayIndex < 0) return false;
    final exercises = List<PlannedExercise>.of(plan.days[dayIndex].exercises);
    if (!mutate(exercises)) return false;
    final days = List<PlanDay>.of(plan.days)
      ..[dayIndex] = PlanDay(key: dayKey, exercises: exercises);
    _plan = Plan(goal: plan.goal, level: plan.level, days: days);
    await _db.setMeta(_planKey, jsonEncode(_plan!.toJson()));
    return true;
  }

  /// Replaces the exercise at [index] of the [dayKey] day with [newExerciseId],
  /// keeping the slot's sets, reps, rest, and warm-up so the day keeps its
  /// shape; [prescriptionForSwap] adjusts the few movements that cannot honor
  /// the slot as written. Persists the plan and, unlike [setPlan], keeps any
  /// in-progress draft, pruning only the swapped-out exercise from it so its
  /// saved sets do not resurface under a movement the plan no longer contains.
  /// A no-op when there is no plan, the day is unknown, or the index is out of
  /// range.
  Future<void> replacePlanExercise(
    String dayKey,
    int index,
    String newExerciseId,
  ) async {
    String? oldExerciseId;
    final changed = await _mutatePlanDay(dayKey, (exercises) {
      if (index < 0 || index >= exercises.length) return false;
      final old = exercises[index];
      oldExerciseId = old.exerciseId;
      exercises[index] = prescriptionForSwap(old, newExerciseId);
      return true;
    });
    if (!changed) return;

    final draft = _draft;
    if (draft != null &&
        draft.dayKey == dayKey &&
        draft.sets.containsKey(oldExerciseId)) {
      final sets = Map<String, List<SetLog>>.of(draft.sets)
        ..remove(oldExerciseId);
      _draft = WorkoutDraft(
        dayKey: draft.dayKey,
        startedAt: draft.startedAt,
        exerciseIndex: draft.exerciseIndex,
        // The running session keeps the movements it is actually doing,
        // which the workout screen saved just before asking for this.
        exercises: draft.exercises,
        sets: sets,
      );
      await _db.setMeta(_draftKey, jsonEncode(_draft!.toJson()));
    }
    notifyListeners();
  }

  /// Rewrites the prescription of the slot at [index] of the [dayKey] day.
  /// The movement and its warm-up stay, so any draft remains valid.
  Future<void> updatePlanPrescription(
    String dayKey,
    int index, {
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
  }) async {
    final changed = await _mutatePlanDay(dayKey, (exercises) {
      if (index < 0 || index >= exercises.length) return false;
      final old = exercises[index];
      exercises[index] = PlannedExercise(
        exerciseId: old.exerciseId,
        sets: sets,
        repsMin: repsMin,
        repsMax: repsMax,
        restSeconds: restSeconds,
        warmupSets: old.warmupSets,
      );
      return true;
    });
    if (changed) notifyListeners();
  }

  /// Moves the exercise at [from] to position [to] within the [dayKey] day.
  /// Draft sets are keyed by exercise id, so an open draft stays valid.
  Future<void> movePlanExercise(String dayKey, int from, int to) async {
    final changed = await _mutatePlanDay(dayKey, (exercises) {
      if (from < 0 ||
          from >= exercises.length ||
          to < 0 ||
          to >= exercises.length ||
          from == to) {
        return false;
      }
      exercises.insert(to, exercises.removeAt(from));
      return true;
    });
    if (changed) notifyListeners();
  }

  Future<void> addSession(WorkoutSession session) async {
    final id = await _db.insertSession(session);
    _sessions.insert(
      0,
      WorkoutSession(
        id: id,
        date: session.date,
        dayKey: session.dayKey,
        logs: session.logs,
      ),
    );
    notifyListeners();
  }

  /// Removes a session from history. A no-op for unsaved sessions.
  /// Notifies before the database write so a swiped-away row leaves the
  /// widget tree in the same frame.
  Future<void> deleteSession(WorkoutSession session) async {
    final id = session.id;
    if (id == null) return;
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
    await _db.deleteSession(id);
  }

  Future<void> saveDraft(WorkoutDraft draft) async {
    _draft = draft;
    await _db.setMeta(_draftKey, jsonEncode(draft.toJson()));
    notifyListeners();
  }

  Future<void> clearDraft() async {
    _draft = null;
    await _db.deleteMeta(_draftKey);
    notifyListeners();
  }

  Future<void> setUnit(WeightUnit unit) async {
    _unit = unit;
    await _db.setMeta(_unitKey, unit.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _db.setMeta(_themeModeKey, mode.name);
    notifyListeners();
  }

  /// Daily reminder time; null means the reminder is off. Scheduling the
  /// actual OS notification is the caller's job ([ReminderService]).
  TimeOfDay? get reminderTime => _reminderTime;

  Future<void> setReminderTime(TimeOfDay? time) async {
    _reminderTime = time;
    if (time == null) {
      await _db.deleteMeta(_reminderKey);
    } else {
      await _db.setMeta(_reminderKey, '${time.hour * 60 + time.minute}');
    }
    notifyListeners();
  }

  /// The lifter's note for an exercise, or null when there is none.
  String? noteFor(String exerciseId) => _exerciseNotes[exerciseId];

  /// Saves the note for an exercise; a blank note removes it.
  Future<void> setExerciseNote(String exerciseId, String note) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      _exerciseNotes.remove(exerciseId);
    } else {
      _exerciseNotes[exerciseId] = trimmed;
    }
    await _db.setMeta(_notesKey, jsonEncode(_exerciseNotes));
    notifyListeners();
  }

  /// Body-weight entries, newest first.
  List<BodyWeightEntry> get bodyWeights => List.unmodifiable(_bodyWeights);

  Future<void> addBodyWeight(double weightKg, {DateTime? date}) async {
    final entry = BodyWeightEntry(
      date: date ?? DateTime.now(),
      weightKg: weightKg,
    );
    final id = await _db.insertBodyWeight(entry);
    _bodyWeights
      ..add(BodyWeightEntry(id: id, date: entry.date, weightKg: entry.weightKg))
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// Removes a body-weight entry. A no-op for unsaved entries.
  /// Notifies before the database write so a swiped-away row leaves the
  /// widget tree in the same frame.
  Future<void> deleteBodyWeight(BodyWeightEntry entry) async {
    final id = entry.id;
    if (id == null) return;
    _bodyWeights.removeWhere((e) => e.id == id);
    notifyListeners();
    await _db.deleteBodyWeight(id);
  }

  /// Full backup as a JSON string (plan, history, preferences, notes,
  /// body weight).
  String exportData() => jsonEncode({
    'app': 'sweatline',
    'plan': _plan?.toJson(),
    'sessions': _sessions.map((s) => s.toJson()).toList(),
    'unit': _unit.name,
    'exerciseNotes': _exerciseNotes,
    'bodyWeights': _bodyWeights.map((e) => e.toJson()).toList(),
  });

  /// Restores a backup produced by [exportData]. Throws [FormatException]
  /// if the payload is not a Sweatline backup; existing data is untouched
  /// in that case.
  Future<void> importData(String raw) async {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('not JSON');
    }
    if (json['app'] != 'sweatline') {
      throw const FormatException('not a Sweatline backup');
    }
    // Parse everything before mutating state so a bad backup cannot leave
    // half-restored data behind.
    final plan = json['plan'] == null
        ? null
        : Plan.fromJson(json['plan'] as Map<String, dynamic>);
    final sessions = ((json['sessions'] as List?) ?? [])
        .map((s) => WorkoutSession.fromJson(s as Map<String, dynamic>))
        .toList();
    final unit =
        WeightUnit.values.asNameMap()[json['unit'] as String? ?? ''] ??
        WeightUnit.kg;
    // Backups from before notes and body weight existed simply have none.
    final notes = ((json['exerciseNotes'] as Map<String, dynamic>?) ?? {}).map(
      (id, note) => MapEntry(id, note as String),
    );
    final bodyWeights = ((json['bodyWeights'] as List?) ?? [])
        .map((e) => BodyWeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    _plan = plan;
    _unit = unit;
    _exerciseNotes = notes;
    await _db.setMeta(_notesKey, jsonEncode(notes));
    await _db.replaceAllBodyWeights(bodyWeights);
    _bodyWeights = await _db.loadBodyWeights();
    if (plan == null) {
      await _db.deleteMeta(_planKey);
    } else {
      await _db.setMeta(_planKey, jsonEncode(plan.toJson()));
    }
    await _db.replaceAllSessions(sessions);
    // Reload so the cached sessions carry their freshly assigned row ids.
    _sessions = await _db.loadSessions();
    await _db.setMeta(_unitKey, unit.name);
    await clearDraft();
  }

  /// The plan day to train next: cycles through the split in order,
  /// continuing from the most recently completed day.
  PlanDay get todayPlanDay {
    final plan = _plan!;
    if (_sessions.isEmpty) return plan.days.first;
    final lastKey = _sessions.first.dayKey;
    final lastIndex = plan.days.indexWhere((d) => d.key == lastKey);
    return plan.days[(lastIndex + 1) % plan.days.length];
  }

  /// Most recent log for an exercise, or null if never trained.
  ExerciseLog? lastLogFor(String exerciseId) {
    for (final session in _sessions) {
      for (final log in session.logs) {
        if (log.exerciseId == exerciseId && log.sets.isNotEmpty) return log;
      }
    }
    return null;
  }

  /// The most recent logs for an exercise, newest first, at most [limit].
  List<ExerciseLog> recentLogsFor(String exerciseId, int limit) {
    final logs = <ExerciseLog>[];
    for (final session in _sessions) {
      for (final log in session.logs) {
        if (log.exerciseId == exerciseId && log.sets.isNotEmpty) {
          logs.add(log);
          if (logs.length == limit) return logs;
        }
      }
    }
    return logs;
  }

  /// Whether every prescribed set was completed at the top of the rep range,
  /// which is what earns the next jump in weight (double progression).
  bool _metTarget(ExerciseLog log, PlannedExercise planned) =>
      log.sets.length >= planned.sets &&
      log.sets.every((s) => s.reps >= planned.repsMax);

  /// Sessions at the same weight, none of them completed, before the trainer
  /// calls a stall and takes weight off the bar.
  static const _stallSessions = 3;

  /// Trainer suggestion for the next working weight, or null when there is
  /// nothing to suggest: a held exercise carries no weight, and a movement
  /// never trained before has no history to build on.
  ///
  /// Repeat the last weight, step up once every set hit the top of the rep
  /// range, or back off to about 90% after three sessions stuck at the same
  /// weight. Grinding the same failed weight forever is the most common way
  /// a self-guided lifter stops making progress.
  double? suggestedWeight(PlannedExercise planned) {
    if (exerciseById(planned.exerciseId).isTimed) return null;
    final recent = recentLogsFor(planned.exerciseId, _stallSessions);
    if (recent.isEmpty) return null;
    final last = recent.first;
    if (_metTarget(last, planned)) {
      final step = progressionStep(_unit, planned.exerciseId);
      return unitToKg(_unit, kgToUnit(_unit, last.bestWeight) + step);
    }
    if (isStalled(planned)) {
      final deload = _deloadWeight(last.bestWeight, planned.exerciseId);
      if (deload != null) return deload;
    }
    return last.bestWeight;
  }

  /// Whether the last [_stallSessions] sessions all sat at the same weight
  /// without ever completing the prescription.
  bool isStalled(PlannedExercise planned) {
    if (exerciseById(planned.exerciseId).isTimed) return false;
    final recent = recentLogsFor(planned.exerciseId, _stallSessions);
    if (recent.length < _stallSessions) return false;
    final weight = recent.first.bestWeight;
    return recent.every((log) => log.bestWeight == weight) &&
        !recent.any((log) => _metTarget(log, planned));
  }

  /// About 90% of [currentKg], rounded down to a weight the gym can actually
  /// load in the lifter's unit. Null when that lands at or below zero, or
  /// would not lighten the bar at all, in which case there is nothing to
  /// deload from.
  double? _deloadWeight(double currentKg, String exerciseId) {
    final step = progressionStep(_unit, exerciseId);
    final current = kgToUnit(_unit, currentKg);
    final target = (current * 0.9 / step).floorToDouble() * step;
    if (target <= 0 || target >= current) return null;
    return unitToKg(_unit, target);
  }

  /// Target reps for the set at [setIndex], or seconds for a held exercise.
  ///
  /// Add one rep (or a few seconds) to what was done last time, up to the top
  /// of the range: repeating last session's reps exactly is what leaves a
  /// lifter stuck at the same numbers forever. Start at the bottom of the
  /// range on a first attempt and whenever the weight has just gone up.
  int suggestedReps(PlannedExercise planned, int setIndex) {
    final last = lastLogFor(planned.exerciseId);
    if (last == null || setIndex >= last.sets.length) return planned.repsMin;
    final suggestion = suggestedWeight(planned);
    if (suggestion != null && suggestion != last.bestWeight) {
      return planned.repsMin;
    }
    final step = exerciseById(planned.exerciseId).isTimed
        ? timedProgressionSeconds
        : 1;
    return (last.sets[setIndex].reps + step).clamp(
      planned.repsMin,
      planned.repsMax,
    );
  }

  int get sessionsThisWeek {
    final monday = mondayOf(DateTime.now());
    return _sessions.where((s) => !s.date.isBefore(monday)).length;
  }

  /// Consecutive weeks in which the lifter did at least as many workouts as
  /// the plan has days. The current week counts once its target is met, but
  /// never breaks the streak while it is still in progress. [now] is
  /// injectable for tests.
  int streakWeeks([DateTime? now]) {
    final plan = _plan;
    if (plan == null) return 0;
    final target = plan.days.length;
    int inWeek(DateTime monday) {
      final next = DateTime(monday.year, monday.month, monday.day + 7);
      return _sessions
          .where((s) => !s.date.isBefore(monday) && s.date.isBefore(next))
          .length;
    }

    var monday = mondayOf(now ?? DateTime.now());
    var streak = inWeek(monday) >= target ? 1 : 0;
    monday = DateTime(monday.year, monday.month, monday.day - 7);
    while (inWeek(monday) >= target) {
      streak++;
      monday = DateTime(monday.year, monday.month, monday.day - 7);
    }
    return streak;
  }

  /// Whether [set] beats every set of this exercise logged before it, either
  /// by weight or by reps at the same weight: 60 kg for 10 is a record over
  /// 60 kg for 8, which comparing weights alone would miss. For a held
  /// exercise, whose sets carry no weight, this is the longest hold so far.
  /// With [before], only sessions strictly earlier than that date count, so a
  /// just-saved session can be judged against everything before it.
  /// First-ever attempts are not records: there is nothing to beat.
  bool isRecordSet(String exerciseId, SetLog set, {DateTime? before}) {
    var trainedBefore = false;
    for (final session in _sessions) {
      if (before != null && !session.date.isBefore(before)) continue;
      for (final log in session.logs) {
        if (log.exerciseId != exerciseId) continue;
        for (final earlier in log.sets) {
          trainedBefore = true;
          if (earlier.weightKg > set.weightKg) return false;
          if (earlier.weightKg == set.weightKg && earlier.reps >= set.reps) {
            return false;
          }
        }
      }
    }
    return trainedBefore;
  }

  /// Heaviest weight ever logged for an exercise, or null if never trained.
  /// With [before], only sessions strictly earlier than that date count, so
  /// a just-saved session can be compared against everything before it.
  double? bestWeightFor(String exerciseId, {DateTime? before}) {
    double? best;
    for (final session in _sessions) {
      if (before != null && !session.date.isBefore(before)) continue;
      for (final log in session.logs) {
        if (log.exerciseId != exerciseId || log.sets.isEmpty) continue;
        if (best == null || log.bestWeight > best) best = log.bestWeight;
      }
    }
    return best;
  }

  /// What the lifter is beating over time, per session, oldest first: the
  /// best weight, or the longest hold in seconds for a held exercise, whose
  /// weight is always zero and would otherwise draw a flat line.
  List<(DateTime, double)> progressHistory(String exerciseId) {
    final timed = exerciseById(exerciseId).isTimed;
    final points = <(DateTime, double)>[];
    for (final session in _sessions.reversed) {
      for (final log in session.logs) {
        if (log.exerciseId == exerciseId && log.sets.isNotEmpty) {
          points.add((
            session.date,
            timed ? log.bestReps.toDouble() : log.bestWeight,
          ));
        }
      }
    }
    return points;
  }
}
