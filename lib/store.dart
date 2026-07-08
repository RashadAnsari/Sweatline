import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'plan_generator.dart';

/// App state with local JSON persistence via SharedPreferences.
///
/// Robustness rules:
/// - Every stored blob is decoded defensively. A corrupt value is
///   quarantined under `corrupt.<key>.<timestamp>` instead of crashing the
///   app; the user loses that blob, never the whole app.
/// - `schemaVersion` is written on every load so future format changes can
///   migrate old data explicitly.
class AppStore extends ChangeNotifier {
  AppStore(this._prefs) {
    _load();
  }

  static const _planKey = 'plan';
  static const _sessionsKey = 'sessions';
  static const _draftKey = 'draft';
  static const _unitKey = 'unit';
  static const _themeModeKey = 'themeMode';
  static const _schemaVersionKey = 'schemaVersion';

  /// Bump when the persisted format changes; add a migration in [_load].
  static const schemaVersion = 2;

  final SharedPreferences _prefs;

  Plan? _plan;
  List<WorkoutSession> _sessions = [];
  WorkoutDraft? _draft;
  WeightUnit _unit = WeightUnit.kg;
  ThemeMode _themeMode = ThemeMode.system;

  Plan? get plan => _plan;

  /// Newest first.
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  WorkoutDraft? get draft => _draft;
  WeightUnit get unit => _unit;
  ThemeMode get themeMode => _themeMode;

  bool get hasPlan => _plan != null;

  void _load() {
    // Schema v1 lacked warmupSets on planned exercises; fromJson defaults
    // cover it, so no data rewrite is needed yet.
    _prefs.setInt(_schemaVersionKey, schemaVersion);

    _plan = _guarded(_planKey, () {
      final raw = _prefs.getString(_planKey);
      if (raw == null) return null;
      return Plan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });
    _sessions =
        _guarded(_sessionsKey, () {
          final raw = _prefs.getString(_sessionsKey);
          if (raw == null) return null;
          return (jsonDecode(raw) as List)
              .map((s) => WorkoutSession.fromJson(s as Map<String, dynamic>))
              .toList();
        }) ??
        [];
    _draft = _guarded(_draftKey, () {
      final raw = _prefs.getString(_draftKey);
      if (raw == null) return null;
      return WorkoutDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });
    _unit = _enumPref(_unitKey, WeightUnit.values) ?? WeightUnit.kg;
    _themeMode = _enumPref(_themeModeKey, ThemeMode.values) ?? ThemeMode.system;
  }

  /// Decodes one stored blob; on failure quarantines the raw value and
  /// returns null so the rest of the app keeps working.
  T? _guarded<T>(String key, T? Function() decode) {
    try {
      return decode();
    } catch (error) {
      debugPrint('Sweatline: corrupt "$key" quarantined: $error');
      final raw = _prefs.getString(key);
      if (raw != null) {
        _prefs.setString(
          'corrupt.$key.${DateTime.now().millisecondsSinceEpoch}',
          raw,
        );
      }
      _prefs.remove(key);
      return null;
    }
  }

  T? _enumPref<T extends Enum>(String key, List<T> values) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return values.asNameMap()[raw];
  }

  Future<void> setPlan(Plan plan) async {
    _plan = plan;
    await _prefs.setString(_planKey, jsonEncode(plan.toJson()));
    notifyListeners();
  }

  Future<void> addSession(WorkoutSession session) async {
    _sessions.insert(0, session);
    await _persistSessions();
    notifyListeners();
  }

  Future<void> _persistSessions() => _prefs.setString(
    _sessionsKey,
    jsonEncode(_sessions.map((s) => s.toJson()).toList()),
  );

  Future<void> saveDraft(WorkoutDraft draft) async {
    _draft = draft;
    await _prefs.setString(_draftKey, jsonEncode(draft.toJson()));
    notifyListeners();
  }

  Future<void> clearDraft() async {
    _draft = null;
    await _prefs.remove(_draftKey);
    notifyListeners();
  }

  Future<void> setUnit(WeightUnit unit) async {
    _unit = unit;
    await _prefs.setString(_unitKey, unit.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  /// Full backup as a JSON string (plan, history, preferences).
  String exportData() => jsonEncode({
    'app': 'sweatline',
    'schemaVersion': schemaVersion,
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
      await _prefs.remove(_planKey);
    } else {
      await _prefs.setString(_planKey, jsonEncode(plan.toJson()));
    }
    await _persistSessions();
    await _prefs.setString(_unitKey, unit.name);
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
