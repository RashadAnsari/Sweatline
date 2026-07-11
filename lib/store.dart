import 'dart:convert';

import 'package:flutter/material.dart';

import 'database.dart';
import 'models.dart';
import 'plan_generator.dart';

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
  }) : _plan = plan,
       _sessions = sessions,
       _draft = draft,
       _unit = unit,
       _themeMode = themeMode;

  static const _planKey = 'plan';
  static const _draftKey = 'draft';
  static const _unitKey = 'unit';
  static const _themeModeKey = 'themeMode';

  final AppDatabase _db;

  Plan? _plan;
  List<WorkoutSession> _sessions;
  WorkoutDraft? _draft;
  WeightUnit _unit;
  ThemeMode _themeMode;

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

    return AppStore._(
      db,
      plan: plan,
      sessions: await db.loadSessions(),
      draft: draft,
      unit: unit ?? WeightUnit.kg,
      themeMode: themeMode ?? ThemeMode.system,
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

  Future<void> addSession(WorkoutSession session) async {
    _sessions.insert(0, session);
    await _db.insertSession(session);
    notifyListeners();
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

  /// Full backup as a JSON string (plan, history, preferences).
  String exportData() => jsonEncode({
    'app': 'sweatline',
    'plan': _plan?.toJson(),
    'sessions': _sessions.map((s) => s.toJson()).toList(),
    'unit': _unit.name,
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

    _plan = plan;
    _sessions = sessions;
    _unit = unit;
    if (plan == null) {
      await _db.deleteMeta(_planKey);
    } else {
      await _db.setMeta(_planKey, jsonEncode(plan.toJson()));
    }
    await _db.replaceAllSessions(sessions);
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

  /// Trainer suggestion: repeat last weight, or add the exercise's
  /// progression increment once every set hit the top of the rep range.
  double? suggestedWeight(PlannedExercise planned) {
    final last = lastLogFor(planned.exerciseId);
    if (last == null) return null;
    final allSetsAtTop =
        last.sets.length >= planned.sets &&
        last.sets.every((s) => s.reps >= planned.repsMax);
    return allSetsAtTop
        ? last.bestWeight + incrementFor(planned.exerciseId)
        : last.bestWeight;
  }

  int get sessionsThisWeek {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _sessions.where((s) => !s.date.isBefore(monday)).length;
  }

  /// Best weight per session for an exercise, oldest first, for trend display.
  List<(DateTime, double)> weightHistory(String exerciseId) {
    final points = <(DateTime, double)>[];
    for (final session in _sessions.reversed) {
      for (final log in session.logs) {
        if (log.exerciseId == exerciseId && log.sets.isNotEmpty) {
          points.add((session.date, log.bestWeight));
        }
      }
    }
    return points;
  }
}
