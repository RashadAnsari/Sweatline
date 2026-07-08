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

/// In-progress workout, auto-saved after every set so a phone call or an
/// app kill mid-session never loses logged work.
class WorkoutDraft {
  const WorkoutDraft({
    required this.dayKey,
    required this.startedAt,
    required this.sets,
  });

  final String dayKey;
  final DateTime startedAt;

  /// Logged sets per exercise id.
  final Map<String, List<SetLog>> sets;

  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'startedAt': startedAt.toIso8601String(),
    'sets': sets.map(
      (id, logs) => MapEntry(id, logs.map((s) => s.toJson()).toList()),
    ),
  };

  factory WorkoutDraft.fromJson(Map<String, dynamic> json) => WorkoutDraft(
    dayKey: json['dayKey'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
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

class WorkoutSession {
  const WorkoutSession({
    required this.date,
    required this.dayKey,
    required this.logs,
  });

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
