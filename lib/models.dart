/// Domain models. All enum-like values are stored as stable string keys;
/// display labels come from the l10n layer.
library;

enum Goal { buildMuscle, loseWeight, getFit }

enum Level { beginner, intermediate, advanced }

/// Display unit for weights. Storage is always kilograms.
enum WeightUnit { kg, lb }

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.equipment,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.steps,
    required this.tips,
    this.isCompound = false,
    this.isTimed = false,
  });

  final String id;

  /// Names, steps, and tips are seed data (like database content), not UI
  /// chrome, so they are stored here instead of the ARB files.
  final String name;

  /// Stable filter-group key: chest, back, shoulders, arms, legs, core,
  /// cardio.
  final String group;

  /// Stable equipment key: barbell, dumbbell, cable, machine, bodyweight.
  final String equipment;

  /// Granular muscle keys for the muscle diagram: chest, lats, upperBack,
  /// lowerBack, traps, shoulders, biceps, triceps, forearms, abs, obliques,
  /// quads, hamstrings, glutes, calves.
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  /// How-to, one step per entry, in order.
  final List<String> steps;

  /// Form cues a trainer would call out.
  final List<String> tips;

  /// Multi-joint lift: programmed first, heavier, longer rests, warm-ups.
  final bool isCompound;

  /// Held or repeated for time instead of counted in reps (planks, cardio).
  /// The prescription and the log then read as seconds, and the lift carries
  /// no weight, so these can never fill a rep-based slot.
  final bool isTimed;
}

class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.restSeconds,
    this.warmupSets = 0,
  });

  final String exerciseId;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int restSeconds;

  /// Lighter preparation sets a trainer prescribes before the working sets.
  final int warmupSets;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'restSeconds': restSeconds,
    'warmupSets': warmupSets,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) =>
      PlannedExercise(
        exerciseId: json['exerciseId'] as String,
        sets: json['sets'] as int,
        repsMin: json['repsMin'] as int,
        repsMax: json['repsMax'] as int,
        restSeconds: json['restSeconds'] as int,
        warmupSets: json['warmupSets'] as int? ?? 0,
      );
}

class PlanDay {
  const PlanDay({required this.key, required this.exercises});

  /// Stable day key (e.g. push, pull, legs, fullBodyA); localized for display.
  final String key;
  final List<PlannedExercise> exercises;

  Map<String, dynamic> toJson() => {
    'key': key,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
    key: json['key'] as String,
    exercises: (json['exercises'] as List)
        .map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Plan {
  const Plan({required this.goal, required this.level, required this.days});

  final Goal goal;
  final Level level;
  final List<PlanDay> days;

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'level': level.name,
    'days': days.map((d) => d.toJson()).toList(),
  };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    goal: Goal.values.byName(json['goal'] as String),
    level: Level.values.byName(json['level'] as String),
    days: (json['days'] as List)
        .map((d) => PlanDay.fromJson(d as Map<String, dynamic>))
        .toList(),
  );
}

class SetLog {
  const SetLog({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;

  Map<String, dynamic> toJson() => {'weightKg': weightKg, 'reps': reps};

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
    weightKg: (json['weightKg'] as num).toDouble(),
    reps: json['reps'] as int,
  );
}

class ExerciseLog {
  const ExerciseLog({required this.exerciseId, required this.sets});

  final String exerciseId;
  final List<SetLog> sets;

  double get bestWeight =>
      sets.fold(0, (max, s) => s.weightKg > max ? s.weightKg : max);

  /// The best set counted in reps, or in seconds for a held exercise. This
  /// is what progresses when there is no weight on the movement.
  int get bestReps => sets.fold(0, (max, s) => s.reps > max ? s.reps : max);

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    exerciseId: json['exerciseId'] as String,
    sets: (json['sets'] as List)
        .map((s) => SetLog.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

/// In-progress workout, auto-saved continuously so closing or killing the
/// app mid-session resumes exactly where the lifter left off.
class WorkoutDraft {
  const WorkoutDraft({
    required this.dayKey,
    required this.startedAt,
    required this.sets,
    this.exerciseIndex,
    this.exercises,
  });

  final String dayKey;
  final DateTime startedAt;

  /// Logged sets per exercise id.
  final Map<String, List<SetLog>> sets;

  /// The exercise the lifter was on when last saved. Null in drafts from
  /// before this field existed; the workout screen then infers the position
  /// from which sets are still incomplete.
  final int? exerciseIndex;

  /// The exercises actually being trained, which differ from the plan day
  /// once the lifter swaps one mid-session without changing the plan. Null in
  /// drafts from before this field existed; the workout screen then falls back
  /// to the plan day.
  final List<PlannedExercise>? exercises;

  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'startedAt': startedAt.toIso8601String(),
    'exerciseIndex': exerciseIndex,
    'exercises': exercises?.map((e) => e.toJson()).toList(),
    'sets': sets.map(
      (id, logs) => MapEntry(id, logs.map((s) => s.toJson()).toList()),
    ),
  };

  factory WorkoutDraft.fromJson(Map<String, dynamic> json) => WorkoutDraft(
    dayKey: json['dayKey'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    exerciseIndex: json['exerciseIndex'] as int?,
    exercises: (json['exercises'] as List?)
        ?.map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
    sets: (json['sets'] as Map<String, dynamic>).map(
      (id, logs) => MapEntry(
        id,
        (logs as List)
            .map((s) => SetLog.fromJson(s as Map<String, dynamic>))
            .toList(),
      ),
    ),
  );
}

/// One body-weight measurement. Weight is stored in kilograms like every
/// other weight in the app.
class BodyWeightEntry {
  const BodyWeightEntry({this.id, required this.date, required this.weightKg});

  /// Database row id; null until saved. Not part of the JSON backup format.
  final int? id;

  final DateTime date;
  final double weightKg;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weightKg': weightKg,
  };

  factory BodyWeightEntry.fromJson(Map<String, dynamic> json) =>
      BodyWeightEntry(
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weightKg'] as num).toDouble(),
      );
}

class WorkoutSession {
  const WorkoutSession({
    this.id,
    required this.date,
    required this.dayKey,
    required this.logs,
  });

  /// Database row id; null until the session has been saved. Not part of
  /// the JSON backup format: ids are reassigned on restore.
  final int? id;

  final DateTime date;
  final String dayKey;
  final List<ExerciseLog> logs;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dayKey': dayKey,
    'logs': logs.map((l) => l.toJson()).toList(),
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    date: DateTime.parse(json['date'] as String),
    dayKey: json['dayKey'] as String,
    logs: (json['logs'] as List)
        .map((l) => ExerciseLog.fromJson(l as Map<String, dynamic>))
        .toList(),
  );
}
