import 'exercise_library.dart';
import 'models.dart';

/// Rule-based trainer: turns goal, experience level, and training frequency
/// into a weekly plan the way a coach would program it:
///
/// - Proven splits per frequency: full body (2), push/pull/legs (3),
///   upper/lower (4), PPL + upper + a second leg day (5), PPL twice (6).
/// - Each day lists its exercises in priority order, so a shorter beginner
///   day keeps the movements that matter most instead of three presses in a
///   row; the chosen set is then reordered compound-first for the session.
/// - Compound lifts first while you are fresh; isolation and core last.
/// - The first heavy compound of the day gets 2 warm-up sets, other
///   compounds get 1, isolation gets none.
/// - Rep ranges and rest periods depend on the goal and on whether the
///   exercise is a compound (heavier, longer rest) or isolation (lighter,
///   shorter rest). Meta-analyses favor longer rests on compounds; short
///   rests are fine on single-joint work.
/// - Held exercises like the plank are prescribed in seconds, not reps: a
///   hold of 30 to 45 seconds with good form beats a longer sagging one.
/// - Fat-loss plans keep loads moderately heavy (8-15 reps) to preserve
///   muscle in a deficit; the deficit itself comes from diet plus the
///   prescribed cardio, not from turning lifting into cardio.
/// - Deadlifts are capped at 3 working sets when programmed as the main
///   lift; heavy pulls tax recovery more than anything else in the gym.
/// - Volume scales with experience: 4 exercises per day for beginners,
///   6 for intermediates, 7 for advanced lifters.
/// - Double progression: lower-body barbell/machine compounds jump 5 kg
///   once every set hits the top of the rep range, everything else 2.5 kg.

const Map<int, List<String>> _splits = {
  2: ['fullBodyA', 'fullBodyB'],
  3: ['push', 'pull', 'legs'],
  4: ['upperA', 'lowerA', 'upperB', 'lowerB'],
  // Leg day B instead of lowerA: lowerA would nearly duplicate the PPL leg
  // day (same squat/RDL/leg press block) and stack a third heavy hinge on
  // the week.
  5: ['push', 'pull', 'legs', 'upperA', 'legsB'],
  6: ['push', 'pull', 'legs', 'pushB', 'pullB', 'legsB'],
};

/// Ordered by how much each exercise earns its place on the day, not by the
/// order it is performed in. Beginners take the first 4, intermediates 6,
/// advanced all 7, and [_buildDay] then puts the compounds first.
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
  // Triceps and side delts outrank a third press: without them the beginner
  // version would be bench, overhead press, incline press and one fly.
  'push': [
    'benchPress',
    'overheadPress',
    'tricepPushdown',
    'lateralRaise',
    'inclineDbPress',
    'chestFly',
    'overheadTricepExtension',
  ],
  // Face pull ranks fourth so even the beginner version trains the rear
  // delts and rotator cuff, not just three rows in a row.
  'pull': [
    'deadlift',
    'latPulldown',
    'barbellRow',
    'facePull',
    'seatedRow',
    'barbellCurl',
    'hammerCurl',
  ],
  // Hamstrings and calves outrank the leg press: the squat already covers
  // the quads, and calves would otherwise never be trained.
  'legs': [
    'squat',
    'romanianDeadlift',
    'legCurl',
    'calfRaise',
    'legPress',
    'legExtension',
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
    'legCurl',
    'calfRaise',
    'legPress',
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
  // Close-grip bench rather than front raises: the front delts are already
  // worked by every press on this day, while the triceps carry them.
  'pushB': [
    'dbBenchPress',
    'arnoldPress',
    'closeGripBench',
    'lateralRaise',
    'chestDip',
    'pecDeck',
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
    'legCurl',
    'calfRaise',
    'lunge',
    'hipThrust',
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
///
/// Fat-loss keeps loads moderately heavy: muscle is preserved in a deficit
/// by maintaining intensity, not by chasing 20-rep burnout sets.
const Map<Goal, List<_Rx>> _prescriptions = {
  Goal.buildMuscle: [_Rx(4, 6, 8, 180), _Rx(3, 8, 10, 120), _Rx(3, 10, 15, 90)],
  Goal.loseWeight: [_Rx(3, 8, 10, 120), _Rx(3, 10, 12, 90), _Rx(3, 12, 15, 60)],
  Goal.getFit: [_Rx(3, 8, 10, 120), _Rx(3, 10, 12, 90), _Rx(3, 12, 15, 60)],
};

/// Deadlift as the day's main lift: fewer sets, slightly lower reps.
/// 4x6-8 heavy pulls every week is a recovery bill nobody can pay.
const _deadliftMainRx = _Rx(3, 5, 8, 180);

/// Held exercises are prescribed in seconds. Past roughly a minute a hold
/// trains endurance rather than strength, and form fails long before that,
/// so the range stays short and the set count carries the work.
const _timedRx = _Rx(3, 30, 45, 60);

const Map<Level, int> _exercisesPerDay = {
  Level.beginner: 4,
  Level.intermediate: 6,
  Level.advanced: 7,
};

/// Weight increment suggested once every set of an exercise hits the top of
/// its rep range (double progression).
const double progressionIncrementKg = 2.5;

/// Held exercises progress in seconds instead of kilograms.
const int timedProgressionSeconds = 5;

/// Minutes to allow for the general warm-up the app prescribes before the
/// first lift: easy cardio plus a few dynamic movements.
const int generalWarmupMinutes = 8;

/// Lower-body barbell/machine compounds handle bigger jumps; 2.5 kg on a
/// leg press is stalling on purpose.
const Set<String> _bigIncrementExercises = {
  'squat',
  'frontSquat',
  'legPress',
  'hackSquat',
  'deadlift',
  'romanianDeadlift',
  'hipThrust',
};

/// Weight to add once every set hits the top of the rep range, expressed in
/// the lifter's own unit. Plates come in different sizes per unit, so a
/// pound user steps up by 5 lb and 10 lb rather than by the kilogram
/// equivalents, which land on numbers no gym can load.
double progressionStep(WeightUnit unit, String exerciseId) {
  final big = _bigIncrementExercises.contains(exerciseId);
  return switch (unit) {
    WeightUnit.kg => big ? 5.0 : progressionIncrementKg,
    WeightUnit.lb => big ? 10.0 : 5.0,
  };
}

/// Whether the frequency asks more of the lifter than their experience
/// supports. Beginners recover and adhere better on 3 or 4 days; the app
/// advises rather than blocks, since the choice stays theirs.
bool isDemandingFrequency(Level level, int daysPerWeek) =>
    level == Level.beginner && daysPerWeek >= 5;

/// Rough session length: the general warm-up, then each exercise's warm-up
/// sets, its working sets, and the rest taken between them. No rest is
/// counted after the final set of an exercise, since the next one starts
/// right away.
int estimatedSessionMinutes(PlanDay day) {
  var seconds = generalWarmupMinutes * 60;
  for (final planned in day.exercises) {
    seconds += planned.warmupSets * 60;
    // A held set lasts as long as the hold; a lifted set takes about 45 s.
    final setSeconds = exerciseById(planned.exerciseId).isTimed
        ? planned.repsMax
        : 45;
    seconds += planned.sets * setSeconds;
    seconds += (planned.sets - 1).clamp(0, 99) * planned.restSeconds;
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
  // The day lists rank exercises by importance; the session runs them
  // compound-first. The sort is stable, so the ranking survives within each
  // group and the day's most important compound stays the main lift.
  final ordered = exerciseIds.toList()
    ..sort((a, b) {
      final aCompound = exerciseById(a).isCompound;
      if (aCompound == exerciseById(b).isCompound) return 0;
      return aCompound ? -1 : 1;
    });
  var compoundsSeen = 0;
  return [
    for (final id in ordered)
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
  if (exerciseById(id).isTimed) {
    // A hold needs no ramp-up sets and follows its own seconds prescription.
    rx = _timedRx;
    warmups = 0;
  } else if (compoundIndex == 0) {
    rx = id == 'deadlift' ? _deadliftMainRx : prescriptions[0];
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

/// The prescription to use when [newExerciseId] takes over [slot].
///
/// A swap keeps the slot's sets, reps, rest, and warm-ups, because the slot
/// is what the day was built around. Two movements cannot honor it: a held
/// exercise has to be prescribed in seconds, and the deadlift stays capped
/// at 3 sets of 5 to 8 however heavy the slot it lands in, since the app
/// refuses to program more heavy pulling than a week can absorb.
PlannedExercise prescriptionForSwap(
  PlannedExercise slot,
  String newExerciseId,
) {
  final _Rx? rx = exerciseById(newExerciseId).isTimed
      ? _timedRx
      : newExerciseId == 'deadlift'
      ? _deadliftMainRx
      : null;
  if (rx == null) {
    return PlannedExercise(
      exerciseId: newExerciseId,
      sets: slot.sets,
      repsMin: slot.repsMin,
      repsMax: slot.repsMax,
      restSeconds: slot.restSeconds,
      warmupSets: slot.warmupSets,
    );
  }
  return PlannedExercise(
    exerciseId: newExerciseId,
    sets: rx.sets,
    repsMin: rx.repsMin,
    repsMax: rx.repsMax,
    restSeconds: rx.restSeconds,
    warmupSets: exerciseById(newExerciseId).isTimed ? 0 : slot.warmupSets,
  );
}
