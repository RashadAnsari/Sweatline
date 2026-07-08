import 'dart:ui';

/// Pictogram pose data for every exercise in the library.
///
/// Coordinate system: 120 wide x 100 tall, floor at y=92, figure usually
/// side-view facing right. Each illustration has a start and an end pose;
/// the widget tweens between them to show the movement.

class Limb {
  const Limb(this.mid, this.end);

  /// Elbow or knee.
  final Offset mid;

  /// Hand or foot.
  final Offset end;

  static Limb lerp(Limb a, Limb b, double t) =>
      Limb(Offset.lerp(a.mid, b.mid, t)!, Offset.lerp(a.end, b.end, t)!);
}

class Pose {
  const Pose({
    required this.head,
    required this.shoulder,
    required this.hip,
    required this.arms,
    required this.legs,
  });

  final Offset head;
  final Offset shoulder;
  final Offset hip;
  final List<Limb> arms;
  final List<Limb> legs;

  static Pose lerp(Pose a, Pose b, double t) => Pose(
    head: Offset.lerp(a.head, b.head, t)!,
    shoulder: Offset.lerp(a.shoulder, b.shoulder, t)!,
    hip: Offset.lerp(a.hip, b.hip, t)!,
    arms: [
      for (var i = 0; i < a.arms.length; i++)
        Limb.lerp(a.arms[i], b.arms[i], t),
    ],
    legs: [
      for (var i = 0; i < a.legs.length; i++)
        Limb.lerp(a.legs[i], b.legs[i], t),
    ],
  );
}

enum Equipment { none, barbell, dumbbells, cable }

class ExerciseIllustration {
  const ExerciseIllustration({
    required this.start,
    required this.end,
    this.equipment = Equipment.none,
    this.cableAnchor,
    this.beams = const [],
    this.circles = const [],
  });

  final Pose start;
  final Pose end;
  final Equipment equipment;

  /// Pulley position; a line is drawn from here to each hand.
  final Offset? cableAnchor;

  /// Static thick lines: benches, racks, frames, platforms.
  final List<(Offset, Offset)> beams;

  /// Static circles: flywheels, machine wheels.
  final List<(Offset, double)> circles;
}

Limb _l(double mx, double my, double ex, double ey) =>
    Limb(Offset(mx, my), Offset(ex, ey));

Pose _p(
  double headX,
  double headY,
  double shX,
  double shY,
  double hipX,
  double hipY, {
  required List<Limb> arms,
  required List<Limb> legs,
}) => Pose(
  head: Offset(headX, headY),
  shoulder: Offset(shX, shY),
  hip: Offset(hipX, hipY),
  arms: arms,
  legs: legs,
);

List<Limb> _standLegs() => [_l(57, 76, 57, 90), _l(63, 76, 63, 90)];

// Flat bench-press base: lying face up, head to the right, feet on floor.
Pose _lyingPress(List<Limb> arms) =>
    _p(80, 56, 70, 57, 48, 58, arms: arms, legs: [_l(38, 72, 30, 90)]);

const _flatBench = [(Offset(36, 66), Offset(92, 66))];

Pose _hinged(List<Limb> arms) => _p(
  80,
  42,
  72,
  48,
  50,
  62,
  arms: arms,
  legs: [_l(57, 74, 57, 90), _l(60, 75, 60, 90)],
);

Pose _standing(List<Limb> arms) =>
    _p(60, 27, 60, 38, 60, 60, arms: arms, legs: _standLegs());

Pose _hangingFromBar({required bool pulledUp}) => pulledUp
    ? _p(
        64,
        22,
        62,
        32,
        62,
        54,
        arms: [_l(69, 30, 62, 23)],
        legs: [_l(58, 64, 52, 74)],
      )
    : _p(
        62,
        34,
        62,
        44,
        62,
        66,
        arms: [_l(62, 33, 62, 23)],
        legs: [_l(58, 76, 52, 84)],
      );

const _pullupFrame = [(Offset(34, 20), Offset(90, 20))];

Pose _squatTop(List<Limb> arms) => _standing(arms);

Pose _squatBottom(List<Limb> arms) => _p(
  60,
  40,
  56,
  48,
  48,
  68,
  arms: arms,
  legs: [_l(63, 74, 58, 90), _l(66, 76, 61, 90)],
);

final Map<String, ExerciseIllustration> _illustrations = {
  // ----- Chest -----
  'benchPress': ExerciseIllustration(
    start: _lyingPress([_l(60, 64, 70, 46)]),
    end: _lyingPress([_l(68, 44, 70, 30)]),
    equipment: Equipment.barbell,
    beams: _flatBench,
  ),
  'inclineBenchPress': ExerciseIllustration(
    start: _p(
      72,
      42,
      64,
      48,
      46,
      64,
      arms: [_l(60, 58, 70, 44)],
      legs: [_l(42, 76, 36, 90)],
    ),
    end: _p(
      72,
      42,
      64,
      48,
      46,
      64,
      arms: [_l(68, 38, 72, 24)],
      legs: [_l(42, 76, 36, 90)],
    ),
    equipment: Equipment.barbell,
    beams: [(Offset(40, 70), Offset(58, 70)), (Offset(42, 72), Offset(70, 44))],
  ),
  'dbBenchPress': ExerciseIllustration(
    start: _lyingPress([_l(60, 64, 70, 46)]),
    end: _lyingPress([_l(68, 44, 70, 30)]),
    equipment: Equipment.dumbbells,
    beams: _flatBench,
  ),
  'inclineDbPress': ExerciseIllustration(
    start: _p(
      72,
      42,
      64,
      48,
      46,
      64,
      arms: [_l(60, 58, 70, 44)],
      legs: [_l(42, 76, 36, 90)],
    ),
    end: _p(
      72,
      42,
      64,
      48,
      46,
      64,
      arms: [_l(68, 38, 72, 24)],
      legs: [_l(42, 76, 36, 90)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(40, 70), Offset(58, 70)), (Offset(42, 72), Offset(70, 44))],
  ),
  'chestFly': ExerciseIllustration(
    start: _standing([_l(50, 44, 40, 40)]),
    end: _standing([_l(70, 48, 82, 50)]),
    equipment: Equipment.cable,
    cableAnchor: const Offset(14, 44),
  ),
  'pecDeck': ExerciseIllustration(
    start: _p(
      52,
      29,
      52,
      40,
      52,
      62,
      arms: [_l(64, 38, 76, 40)],
      legs: [_l(66, 72, 66, 90)],
    ),
    end: _p(
      52,
      29,
      52,
      40,
      52,
      62,
      arms: [_l(62, 44, 74, 50)],
      legs: [_l(66, 72, 66, 90)],
    ),
    beams: [(Offset(46, 38), Offset(46, 66)), (Offset(46, 66), Offset(62, 66))],
  ),
  'pushUp': ExerciseIllustration(
    start: _p(
      88,
      56,
      78,
      60,
      56,
      68,
      arms: [_l(78, 74, 78, 90)],
      legs: [_l(42, 76, 28, 86)],
    ),
    end: _p(
      88,
      66,
      78,
      70,
      56,
      74,
      arms: [_l(70, 82, 78, 90)],
      legs: [_l(42, 80, 28, 88)],
    ),
  ),
  'chestDip': ExerciseIllustration(
    start: _p(
      60,
      28,
      60,
      42,
      60,
      66,
      arms: [_l(64, 50, 68, 56)],
      legs: [_l(54, 76, 46, 82)],
    ),
    end: _p(
      62,
      38,
      60,
      52,
      58,
      74,
      arms: [_l(70, 52, 68, 56)],
      legs: [_l(52, 82, 44, 86)],
    ),
    beams: [(Offset(44, 56), Offset(80, 56))],
  ),

  // ----- Back -----
  'deadlift': ExerciseIllustration(
    start: _hinged([_l(72, 62, 72, 78)]),
    end: _standing([_l(62, 50, 64, 64)]),
    equipment: Equipment.barbell,
  ),
  'pullUp': ExerciseIllustration(
    start: _hangingFromBar(pulledUp: false),
    end: _hangingFromBar(pulledUp: true),
    beams: _pullupFrame,
  ),
  'chinUp': ExerciseIllustration(
    start: _hangingFromBar(pulledUp: false),
    end: _hangingFromBar(pulledUp: true),
    beams: _pullupFrame,
  ),
  'latPulldown': ExerciseIllustration(
    start: _p(
      58,
      29,
      58,
      40,
      56,
      62,
      arms: [_l(68, 26, 74, 14)],
      legs: [_l(68, 72, 68, 90)],
    ),
    end: _p(
      58,
      29,
      58,
      40,
      56,
      62,
      arms: [_l(68, 44, 72, 38)],
      legs: [_l(68, 72, 68, 90)],
    ),
    equipment: Equipment.cable,
    cableAnchor: const Offset(76, 8),
    beams: [(Offset(48, 68), Offset(70, 68))],
  ),
  'barbellRow': ExerciseIllustration(
    start: _hinged([_l(72, 60, 72, 74)]),
    end: _hinged([_l(66, 58, 70, 62)]),
    equipment: Equipment.barbell,
  ),
  'dbRow': ExerciseIllustration(
    start: _p(
      86,
      48,
      76,
      50,
      52,
      54,
      arms: [_l(70, 62, 68, 74)],
      legs: [_l(48, 72, 44, 90)],
    ),
    end: _p(
      86,
      48,
      76,
      50,
      52,
      54,
      arms: [_l(66, 56, 68, 62)],
      legs: [_l(48, 72, 44, 90)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(58, 64), Offset(94, 64))],
  ),
  'seatedRow': ExerciseIllustration(
    start: _p(
      52,
      29,
      52,
      40,
      52,
      62,
      arms: [_l(64, 50, 78, 54)],
      legs: [_l(66, 68, 80, 72)],
    ),
    end: _p(
      52,
      29,
      52,
      40,
      52,
      62,
      arms: [_l(58, 52, 64, 54)],
      legs: [_l(66, 68, 80, 72)],
    ),
    equipment: Equipment.cable,
    cableAnchor: const Offset(104, 56),
    beams: [(Offset(44, 68), Offset(58, 68))],
  ),
  'tBarRow': ExerciseIllustration(
    start: _hinged([_l(72, 60, 72, 74)]),
    end: _hinged([_l(66, 58, 70, 62)]),
    equipment: Equipment.barbell,
  ),
  'straightArmPulldown': ExerciseIllustration(
    start: _p(
      64,
      27,
      62,
      38,
      56,
      60,
      arms: [_l(74, 30, 84, 22)],
      legs: _standLegs(),
    ),
    end: _p(
      64,
      27,
      62,
      38,
      56,
      60,
      arms: [_l(70, 52, 78, 62)],
      legs: _standLegs(),
    ),
    equipment: Equipment.cable,
    cableAnchor: const Offset(92, 10),
  ),
  'backExtension': ExerciseIllustration(
    start: _p(
      80,
      78,
      74,
      72,
      62,
      60,
      arms: [_l(74, 78, 72, 82)],
      legs: [_l(50, 72, 38, 82)],
    ),
    end: _p(
      92,
      52,
      84,
      54,
      62,
      60,
      arms: [_l(84, 60, 82, 64)],
      legs: [_l(50, 72, 38, 82)],
    ),
    beams: [(Offset(44, 80), Offset(64, 62)), (Offset(36, 84), Offset(52, 84))],
  ),
  'shrug': ExerciseIllustration(
    start: _p(
      60,
      27,
      60,
      40,
      60,
      60,
      arms: [_l(64, 50, 64, 64)],
      legs: _standLegs(),
    ),
    end: _p(
      60,
      24,
      60,
      36,
      60,
      60,
      arms: [_l(64, 46, 64, 60)],
      legs: _standLegs(),
    ),
    equipment: Equipment.dumbbells,
  ),

  // ----- Shoulders -----
  'overheadPress': ExerciseIllustration(
    start: _standing([_l(66, 46, 66, 34)]),
    end: _standing([_l(63, 24, 62, 12)]),
    equipment: Equipment.barbell,
  ),
  'dbShoulderPress': ExerciseIllustration(
    start: _p(
      56,
      28,
      56,
      40,
      56,
      62,
      arms: [_l(62, 44, 64, 34)],
      legs: [_l(68, 72, 68, 90)],
    ),
    end: _p(
      56,
      28,
      56,
      40,
      56,
      62,
      arms: [_l(59, 24, 58, 12)],
      legs: [_l(68, 72, 68, 90)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(50, 38), Offset(50, 66)), (Offset(50, 66), Offset(66, 66))],
  ),
  'arnoldPress': ExerciseIllustration(
    start: _p(
      56,
      28,
      56,
      40,
      56,
      62,
      arms: [_l(62, 44, 62, 36)],
      legs: [_l(68, 72, 68, 90)],
    ),
    end: _p(
      56,
      28,
      56,
      40,
      56,
      62,
      arms: [_l(59, 24, 58, 12)],
      legs: [_l(68, 72, 68, 90)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(50, 38), Offset(50, 66)), (Offset(50, 66), Offset(66, 66))],
  ),
  'lateralRaise': ExerciseIllustration(
    // Front view.
    start: _p(
      60,
      28,
      60,
      40,
      60,
      62,
      arms: [_l(52, 50, 50, 62), _l(68, 50, 70, 62)],
      legs: [_l(55, 76, 53, 90), _l(65, 76, 67, 90)],
    ),
    end: _p(
      60,
      28,
      60,
      40,
      60,
      62,
      arms: [_l(48, 42, 38, 40), _l(72, 42, 82, 40)],
      legs: [_l(55, 76, 53, 90), _l(65, 76, 67, 90)],
    ),
    equipment: Equipment.dumbbells,
  ),
  'frontRaise': ExerciseIllustration(
    start: _standing([_l(64, 52, 66, 64)]),
    end: _standing([_l(72, 42, 84, 38)]),
    equipment: Equipment.dumbbells,
  ),
  'rearDeltFly': ExerciseIllustration(
    start: _hinged([_l(70, 60, 68, 70)]),
    end: _hinged([_l(62, 50, 52, 44)]),
    equipment: Equipment.dumbbells,
  ),
  'facePull': ExerciseIllustration(
    start: _standing([_l(74, 36, 86, 30)]),
    end: _standing([_l(72, 30, 64, 30)]),
    equipment: Equipment.cable,
    cableAnchor: const Offset(102, 28),
  ),
  'uprightRow': ExerciseIllustration(
    start: _standing([_l(64, 52, 66, 64)]),
    end: _standing([_l(68, 40, 64, 44)]),
    equipment: Equipment.cable,
    cableAnchor: const Offset(72, 90),
  ),

  // ----- Arms -----
  'bicepCurl': ExerciseIllustration(
    start: _standing([_l(62, 52, 64, 66)]),
    end: _standing([_l(62, 52, 72, 40)]),
    equipment: Equipment.dumbbells,
  ),
  'barbellCurl': ExerciseIllustration(
    start: _standing([_l(62, 52, 64, 66)]),
    end: _standing([_l(62, 52, 72, 40)]),
    equipment: Equipment.barbell,
  ),
  'hammerCurl': ExerciseIllustration(
    start: _standing([_l(62, 52, 64, 66)]),
    end: _standing([_l(62, 52, 72, 40)]),
    equipment: Equipment.dumbbells,
  ),
  'preacherCurl': ExerciseIllustration(
    start: _p(
      54,
      30,
      54,
      42,
      50,
      62,
      arms: [_l(64, 54, 76, 62)],
      legs: [_l(62, 72, 62, 90)],
    ),
    end: _p(
      54,
      30,
      54,
      42,
      50,
      62,
      arms: [_l(64, 54, 64, 42)],
      legs: [_l(62, 72, 62, 90)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(58, 52), Offset(74, 62)), (Offset(46, 66), Offset(60, 66))],
  ),
  'concentrationCurl': ExerciseIllustration(
    start: _p(
      64,
      32,
      62,
      44,
      54,
      62,
      arms: [_l(68, 54, 70, 68)],
      legs: [_l(68, 70, 70, 90)],
    ),
    end: _p(
      64,
      32,
      62,
      44,
      54,
      62,
      arms: [_l(68, 54, 76, 44)],
      legs: [_l(68, 70, 70, 90)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(44, 66), Offset(60, 66))],
  ),
  'cableCurl': ExerciseIllustration(
    start: _standing([_l(62, 52, 64, 66)]),
    end: _standing([_l(62, 52, 72, 40)]),
    equipment: Equipment.cable,
    cableAnchor: const Offset(86, 90),
  ),
  'tricepPushdown': ExerciseIllustration(
    start: _standing([_l(64, 50, 70, 40)]),
    end: _standing([_l(64, 50, 72, 64)]),
    equipment: Equipment.cable,
    cableAnchor: const Offset(76, 12),
  ),
  'skullCrusher': ExerciseIllustration(
    start: _lyingPress([_l(66, 44, 78, 48)]),
    end: _lyingPress([_l(66, 42, 68, 28)]),
    equipment: Equipment.barbell,
    beams: _flatBench,
  ),
  'overheadTricepExtension': ExerciseIllustration(
    start: _standing([_l(64, 24, 52, 32)]),
    end: _standing([_l(62, 22, 60, 10)]),
    equipment: Equipment.dumbbells,
  ),
  'closeGripBench': ExerciseIllustration(
    start: _lyingPress([_l(60, 64, 70, 46)]),
    end: _lyingPress([_l(68, 44, 70, 30)]),
    equipment: Equipment.barbell,
    beams: _flatBench,
  ),

  // ----- Legs -----
  'squat': ExerciseIllustration(
    start: _squatTop([_l(66, 42, 66, 36)]),
    end: _squatBottom([_l(62, 52, 64, 46)]),
    equipment: Equipment.barbell,
  ),
  'frontSquat': ExerciseIllustration(
    start: _squatTop([_l(68, 44, 68, 38)]),
    end: _squatBottom([_l(64, 54, 66, 48)]),
    equipment: Equipment.barbell,
  ),
  'gobletSquat': ExerciseIllustration(
    start: _squatTop([_l(66, 46, 64, 40)]),
    end: _squatBottom([_l(60, 56, 58, 50)]),
    equipment: Equipment.dumbbells,
  ),
  'legPress': ExerciseIllustration(
    start: _p(
      30,
      42,
      34,
      50,
      46,
      68,
      arms: [_l(46, 62, 50, 68)],
      legs: [_l(58, 54, 74, 46)],
    ),
    end: _p(
      30,
      42,
      34,
      50,
      46,
      68,
      arms: [_l(46, 62, 50, 68)],
      legs: [_l(66, 44, 84, 40)],
    ),
    beams: [(Offset(28, 42), Offset(46, 74)), (Offset(80, 34), Offset(94, 50))],
  ),
  'hackSquat': ExerciseIllustration(
    start: _p(
      64,
      26,
      62,
      38,
      58,
      60,
      arms: [_l(68, 42, 68, 36)],
      legs: _standLegs(),
    ),
    end: _p(
      62,
      40,
      58,
      48,
      50,
      68,
      arms: [_l(64, 52, 66, 46)],
      legs: [_l(63, 74, 58, 90), _l(66, 76, 61, 90)],
    ),
    beams: [(Offset(70, 26), Offset(80, 70))],
  ),
  'romanianDeadlift': ExerciseIllustration(
    start: _standing([_l(62, 50, 64, 64)]),
    end: _p(
      82,
      46,
      74,
      50,
      50,
      58,
      arms: [_l(74, 62, 74, 74)],
      legs: [_l(56, 74, 58, 90), _l(59, 75, 61, 90)],
    ),
    equipment: Equipment.barbell,
  ),
  'legCurl': ExerciseIllustration(
    start: _p(
      88,
      55,
      78,
      57,
      56,
      58,
      arms: [_l(78, 62, 74, 64)],
      legs: [_l(42, 60, 26, 66)],
    ),
    end: _p(
      88,
      55,
      78,
      57,
      56,
      58,
      arms: [_l(78, 62, 74, 64)],
      legs: [_l(42, 60, 34, 44)],
    ),
    beams: [(Offset(36, 62), Offset(88, 62))],
  ),
  'legExtension': ExerciseIllustration(
    start: _p(
      54,
      28,
      54,
      40,
      54,
      62,
      arms: [_l(60, 52, 62, 60)],
      legs: [_l(66, 68, 64, 84)],
    ),
    end: _p(
      54,
      28,
      54,
      40,
      54,
      62,
      arms: [_l(60, 52, 62, 60)],
      legs: [_l(66, 68, 84, 64)],
    ),
    beams: [(Offset(48, 38), Offset(48, 66)), (Offset(48, 66), Offset(64, 66))],
  ),
  'lunge': ExerciseIllustration(
    start: _standing([_l(64, 52, 64, 66)]),
    end: _p(
      58,
      32,
      58,
      44,
      58,
      66,
      arms: [_l(62, 56, 62, 70)],
      legs: [_l(72, 76, 72, 90), _l(48, 80, 38, 90)],
    ),
    equipment: Equipment.dumbbells,
  ),
  'bulgarianSplitSquat': ExerciseIllustration(
    start: _p(
      58,
      26,
      58,
      38,
      58,
      58,
      arms: [_l(62, 50, 62, 62)],
      legs: [_l(66, 72, 66, 90), _l(48, 74, 36, 64)],
    ),
    end: _p(
      56,
      34,
      56,
      46,
      56,
      68,
      arms: [_l(60, 58, 60, 70)],
      legs: [_l(70, 78, 68, 90), _l(46, 80, 36, 64)],
    ),
    equipment: Equipment.dumbbells,
    beams: [(Offset(26, 64), Offset(44, 64)), (Offset(30, 64), Offset(30, 90))],
  ),
  'hipThrust': ExerciseIllustration(
    start: _p(
      38,
      50,
      46,
      54,
      62,
      72,
      arms: [_l(56, 62, 62, 70)],
      legs: [_l(74, 68, 74, 90)],
    ),
    end: _p(
      38,
      50,
      46,
      54,
      64,
      56,
      arms: [_l(56, 56, 64, 54)],
      legs: [_l(76, 64, 76, 90)],
    ),
    equipment: Equipment.barbell,
    beams: [(Offset(28, 58), Offset(50, 58)), (Offset(32, 58), Offset(32, 90))],
  ),
  'calfRaise': ExerciseIllustration(
    start: _p(
      60,
      25,
      60,
      36,
      60,
      58,
      arms: [_l(64, 48, 64, 58)],
      legs: [_l(59, 72, 59, 84), _l(62, 73, 62, 84)],
    ),
    end: _p(
      60,
      20,
      60,
      31,
      60,
      53,
      arms: [_l(64, 43, 64, 53)],
      legs: [_l(59, 67, 59, 80), _l(62, 68, 62, 80)],
    ),
    beams: [(Offset(46, 86), Offset(76, 86))],
  ),
  'seatedCalfRaise': ExerciseIllustration(
    start: _p(
      54,
      32,
      54,
      44,
      54,
      64,
      arms: [_l(60, 54, 64, 60)],
      legs: [_l(66, 72, 64, 90)],
    ),
    end: _p(
      54,
      30,
      54,
      42,
      54,
      62,
      arms: [_l(60, 52, 64, 58)],
      legs: [_l(66, 66, 64, 86)],
    ),
    beams: [(Offset(44, 68), Offset(58, 68)), (Offset(58, 64), Offset(74, 64))],
  ),

  // ----- Core -----
  'plank': ExerciseIllustration(
    start: _p(
      86,
      58,
      76,
      62,
      54,
      68,
      arms: [_l(74, 88, 84, 88)],
      legs: [_l(40, 76, 26, 86)],
    ),
    end: _p(
      86,
      58,
      76,
      62,
      54,
      68,
      arms: [_l(74, 88, 84, 88)],
      legs: [_l(40, 76, 26, 86)],
    ),
  ),
  'sidePlank': ExerciseIllustration(
    start: _p(
      82,
      46,
      74,
      54,
      58,
      72,
      arms: [_l(74, 88, 84, 88), _l(80, 46, 86, 36)],
      legs: [_l(48, 80, 40, 88)],
    ),
    end: _p(
      84,
      42,
      76,
      50,
      60,
      68,
      arms: [_l(74, 88, 84, 88), _l(82, 42, 88, 32)],
      legs: [_l(48, 78, 40, 88)],
    ),
  ),
  'crunch': ExerciseIllustration(
    start: _p(
      24,
      74,
      34,
      76,
      52,
      74,
      arms: [_l(30, 70, 26, 72)],
      legs: [_l(66, 62, 70, 88)],
    ),
    end: _p(
      32,
      60,
      40,
      66,
      52,
      74,
      arms: [_l(34, 62, 28, 64)],
      legs: [_l(66, 62, 70, 88)],
    ),
  ),
  'cableCrunch': ExerciseIllustration(
    start: _p(
      66,
      34,
      64,
      46,
      58,
      68,
      arms: [_l(70, 38, 70, 30)],
      legs: [_l(58, 80, 46, 84)],
    ),
    end: _p(
      76,
      48,
      70,
      56,
      58,
      68,
      arms: [_l(74, 50, 76, 42)],
      legs: [_l(58, 80, 46, 84)],
    ),
    equipment: Equipment.cable,
    cableAnchor: const Offset(84, 10),
  ),
  'legRaise': ExerciseIllustration(
    start: _p(
      62,
      29,
      62,
      40,
      62,
      62,
      arms: [_l(62, 30, 62, 22)],
      legs: [_l(62, 76, 62, 88)],
    ),
    end: _p(
      62,
      29,
      62,
      40,
      62,
      62,
      arms: [_l(62, 30, 62, 22)],
      legs: [_l(74, 64, 86, 62)],
    ),
    beams: _pullupFrame,
  ),
  'russianTwist': ExerciseIllustration(
    start: _p(
      40,
      44,
      44,
      54,
      56,
      72,
      arms: [_l(56, 52, 66, 48)],
      legs: [_l(70, 62, 80, 68)],
    ),
    end: _p(
      40,
      44,
      44,
      54,
      56,
      72,
      arms: [_l(52, 58, 60, 62)],
      legs: [_l(70, 62, 80, 68)],
    ),
  ),
  'abWheelRollout': ExerciseIllustration(
    start: _p(
      68,
      40,
      62,
      50,
      52,
      64,
      arms: [_l(68, 64, 72, 76)],
      legs: [_l(50, 80, 38, 86)],
    ),
    end: _p(
      82,
      54,
      74,
      60,
      56,
      70,
      arms: [_l(84, 72, 94, 80)],
      legs: [_l(50, 80, 38, 86)],
    ),
    equipment: Equipment.dumbbells,
  ),
  'deadBug': ExerciseIllustration(
    start: _p(
      30,
      80,
      40,
      82,
      56,
      82,
      arms: [_l(40, 72, 40, 62)],
      legs: [_l(64, 68, 72, 74)],
    ),
    end: _p(
      30,
      80,
      40,
      82,
      56,
      82,
      arms: [_l(32, 74, 22, 70)],
      legs: [_l(68, 72, 82, 78)],
    ),
  ),

  // ----- Cardio -----
  'treadmillRun': ExerciseIllustration(
    start: _p(
      70,
      25,
      68,
      36,
      64,
      56,
      arms: [_l(60, 44, 54, 50), _l(76, 44, 82, 50)],
      legs: [_l(74, 68, 80, 86), _l(54, 66, 48, 80)],
    ),
    end: _p(
      70,
      25,
      68,
      36,
      64,
      56,
      arms: [_l(76, 44, 82, 52), _l(60, 44, 54, 52)],
      legs: [_l(56, 68, 50, 86), _l(72, 66, 78, 78)],
    ),
    beams: [(Offset(36, 88), Offset(96, 88)), (Offset(38, 88), Offset(32, 56))],
  ),
  'rowingMachine': ExerciseIllustration(
    start: _p(
      74,
      46,
      70,
      56,
      58,
      74,
      arms: [_l(78, 62, 88, 66)],
      legs: [_l(74, 64, 86, 76)],
    ),
    end: _p(
      34,
      44,
      38,
      54,
      48,
      74,
      arms: [_l(48, 60, 44, 62)],
      legs: [_l(66, 68, 86, 76)],
    ),
    beams: [(Offset(28, 80), Offset(96, 80))],
    circles: [(Offset(94, 70), 8)],
  ),
  'stationaryBike': ExerciseIllustration(
    start: _p(
      66,
      26,
      62,
      36,
      52,
      54,
      arms: [_l(70, 44, 76, 48)],
      legs: [_l(62, 68, 66, 80)],
    ),
    end: _p(
      66,
      26,
      62,
      36,
      52,
      54,
      arms: [_l(70, 44, 76, 48)],
      legs: [_l(58, 64, 54, 72)],
    ),
    beams: [(Offset(52, 58), Offset(54, 76)), (Offset(74, 50), Offset(78, 74))],
    circles: [(Offset(78, 80), 9)],
  ),
  'jumpRope': ExerciseIllustration(
    // Front view, small hop.
    start: _p(
      60,
      28,
      60,
      40,
      60,
      62,
      arms: [_l(50, 52, 46, 60), _l(70, 52, 74, 60)],
      legs: [_l(56, 76, 55, 90), _l(64, 76, 65, 90)],
    ),
    end: _p(
      60,
      22,
      60,
      34,
      60,
      56,
      arms: [_l(50, 48, 44, 54), _l(70, 48, 76, 54)],
      legs: [_l(56, 70, 55, 82), _l(64, 70, 65, 82)],
    ),
  ),
  'burpee': ExerciseIllustration(
    start: _p(
      60,
      18,
      60,
      32,
      60,
      56,
      arms: [_l(54, 22, 52, 12), _l(66, 22, 68, 12)],
      legs: [_l(57, 72, 57, 88), _l(63, 72, 63, 88)],
    ),
    end: _p(
      88,
      66,
      78,
      70,
      56,
      74,
      arms: [_l(70, 82, 78, 90), _l(72, 80, 80, 90)],
      legs: [_l(42, 80, 28, 88), _l(44, 82, 30, 90)],
    ),
  ),
};

/// Illustration for an exercise id. Every library exercise has one; a
/// neutral standing figure is the defensive fallback.
ExerciseIllustration illustrationFor(String exerciseId) =>
    _illustrations[exerciseId] ??
    ExerciseIllustration(
      start: _standing([_l(64, 52, 64, 66)]),
      end: _standing([_l(64, 52, 64, 66)]),
    );

/// Exposed for the completeness test.
Set<String> get illustratedExerciseIds => _illustrations.keys.toSet();
