import 'exercise_library.dart';
import 'models.dart';

/// Rule-based trainer: turns goal, experience level, and training frequency
/// into a weekly plan the way a coach would program it:
///
/// - Proven splits per frequency: full body (2), push/pull/legs (3),
///   upper/lower (4), PPL + upper/lower (5), PPL twice (6).
/// - Compound lifts first while you are fresh; isolation and core last.
/// - The first heavy compound of the day gets 2 warm-up sets, other
///   compounds get 1, isolation gets none.
/// - Rep ranges and rest periods depend on the goal and on whether the
///   exercise is a compound (heavier, longer rest) or isolation (lighter,
///   shorter rest).
/// - Volume scales with experience: 4 exercises per day for beginners,
///   6 for intermediates, 7 for advanced lifters.

const Map<int, List<String>> _splits = {
  2: ['fullBodyA', 'fullBodyB'],
  3: ['push', 'pull', 'legs'],
  4: ['upperA', 'lowerA', 'upperB', 'lowerB'],
  5: ['push', 'pull', 'legs', 'upperA', 'lowerA'],
  6: ['push', 'pull', 'legs', 'pushB', 'pullB', 'legsB'],
};

/// Ordered compound-first. Beginners take the first 4, intermediates 6,
/// advanced all 7.
const Map<String, List<String>> _dayExercises = {
  'fullBodyA': [
    'squat',
    'benchPress',
    'seatedRow',
    'overheadPress',
    'legCurl',
    'bicepCurl',
    'plank',
  ],
  'fullBodyB': [
    'deadlift',
    'inclineDbPress',
    'latPulldown',
    'lunge',
    'lateralRaise',
    'tricepPushdown',
    'cableCrunch',
  ],
  'push': [
    'benchPress',
    'overheadPress',
    'inclineDbPress',
    'chestFly',
    'lateralRaise',
    'tricepPushdown',
    'overheadTricepExtension',
  ],
  'pull': [
    'deadlift',
    'latPulldown',
    'barbellRow',
    'seatedRow',
    'facePull',
    'barbellCurl',
    'hammerCurl',
  ],
  'legs': [
    'squat',
    'romanianDeadlift',
    'legPress',
    'legCurl',
    'legExtension',
    'calfRaise',
    'plank',
  ],
  'upperA': [
    'benchPress',
    'barbellRow',
    'overheadPress',
    'latPulldown',
    'lateralRaise',
    'tricepPushdown',
    'bicepCurl',
  ],
  'lowerA': [
    'squat',
    'romanianDeadlift',
    'legPress',
    'legCurl',
    'calfRaise',
    'cableCrunch',
    'legRaise',
  ],
  'upperB': [
    'inclineBenchPress',
    'pullUp',
    'dbShoulderPress',
    'seatedRow',
    'rearDeltFly',
    'skullCrusher',
    'preacherCurl',
  ],
  'lowerB': [
    'deadlift',
    'bulgarianSplitSquat',
    'legExtension',
    'hipThrust',
    'seatedCalfRaise',
    'abWheelRollout',
    'russianTwist',
  ],
  'pushB': [
    'dbBenchPress',
    'arnoldPress',
    'chestDip',
    'pecDeck',
    'frontRaise',
    'closeGripBench',
    'tricepPushdown',
  ],
  'pullB': [
    'chinUp',
    'tBarRow',
    'dbRow',
    'straightArmPulldown',
    'shrug',
    'cableCurl',
    'concentrationCurl',
  ],
  'legsB': [
    'frontSquat',
    'hackSquat',
    'lunge',
    'legCurl',
    'hipThrust',
    'calfRaise',
    'legRaise',
  ],
};

/// Set/rep/rest prescription for one exercise slot.
class _Rx {
  const _Rx(this.sets, this.repsMin, this.repsMax, this.restSeconds);
  final int sets;
  final int repsMin;
  final int repsMax;
  final int restSeconds;
}

/// Per goal: [main lift, other compounds, isolation].
const Map<Goal, List<_Rx>> _prescriptions = {
  Goal.buildMuscle: [_Rx(4, 6, 8, 180), _Rx(3, 8, 10, 120), _Rx(3, 10, 15, 90)],
  Goal.loseWeight: [_Rx(3, 10, 12, 90), _Rx(3, 12, 15, 75), _Rx(3, 15, 20, 60)],
  Goal.getFit: [_Rx(3, 8, 10, 120), _Rx(3, 10, 12, 90), _Rx(3, 12, 15, 60)],
};

const Map<Level, int> _exercisesPerDay = {
  Level.beginner: 4,
  Level.intermediate: 6,
  Level.advanced: 7,
};

/// Weight increment suggested once every set of an exercise hits the top of
/// its rep range (double progression).
const double progressionIncrementKg = 2.5;

/// Rough session length: warm-ups plus work sets with their rests.
int estimatedSessionMinutes(PlanDay day) {
  var seconds = 0;
  for (final planned in day.exercises) {
    seconds += planned.warmupSets * 60;
    seconds += planned.sets * (45 + planned.restSeconds);
  }
  return (seconds / 60).round();
}

Plan generatePlan({
  required Goal goal,
  required Level level,
  required int daysPerWeek,
}) {
  final split = _splits[daysPerWeek];
  if (split == null) {
    throw ArgumentError.value(
      daysPerWeek,
      'daysPerWeek',
      'supported values: ${_splits.keys.join(', ')}',
    );
  }
  final prescriptions = _prescriptions[goal]!;

  return Plan(
    goal: goal,
    level: level,
    days: [
      for (final dayKey in split)
        PlanDay(
          key: dayKey,
          exercises: _buildDay(
            _dayExercises[dayKey]!.take(_exercisesPerDay[level]!),
            prescriptions,
          ),
        ),
    ],
  );
}

List<PlannedExercise> _buildDay(
  Iterable<String> exerciseIds,
  List<_Rx> prescriptions,
) {
  var compoundsSeen = 0;
  return [
    for (final id in exerciseIds)
      _plan(
        id,
        prescriptions,
        exerciseById(id).isCompound ? compoundsSeen++ : -1,
      ),
  ];
}

PlannedExercise _plan(String id, List<_Rx> prescriptions, int compoundIndex) {
  final _Rx rx;
  final int warmups;
  if (compoundIndex == 0) {
    rx = prescriptions[0];
    warmups = 2;
  } else if (compoundIndex > 0) {
    rx = prescriptions[1];
    warmups = 1;
  } else {
    rx = prescriptions[2];
    warmups = 0;
  }
  return PlannedExercise(
    exerciseId: id,
    sets: rx.sets,
    repsMin: rx.repsMin,
    repsMax: rx.repsMax,
    restSeconds: rx.restSeconds,
    warmupSets: warmups,
  );
}
