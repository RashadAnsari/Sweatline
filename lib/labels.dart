import 'l10n/app_localizations.dart';
import 'models.dart';

/// Maps stable stored keys to localized display labels.

String dayLabel(AppLocalizations l10n, String key) => switch (key) {
  'push' => l10n.dayPush,
  'pull' => l10n.dayPull,
  'legs' => l10n.dayLegs,
  'pushB' => l10n.dayPushB,
  'pullB' => l10n.dayPullB,
  'legsB' => l10n.dayLegsB,
  'upperA' => l10n.dayUpperA,
  'lowerA' => l10n.dayLowerA,
  'upperB' => l10n.dayUpperB,
  'lowerB' => l10n.dayLowerB,
  'fullBodyA' => l10n.dayFullBodyA,
  'fullBodyB' => l10n.dayFullBodyB,
  _ => key,
};

/// Covers both filter groups (chest, back, ..., cardio) and granular
/// diagram muscles (lats, quads, ...).
String muscleLabel(AppLocalizations l10n, String key) => switch (key) {
  'chest' => l10n.muscleChest,
  'back' => l10n.muscleBack,
  'shoulders' => l10n.muscleShoulders,
  'arms' => l10n.muscleArms,
  'legs' => l10n.muscleLegs,
  'core' => l10n.muscleCore,
  'cardio' => l10n.muscleCardio,
  'traps' => l10n.muscleTraps,
  'lats' => l10n.muscleLats,
  'upperBack' => l10n.muscleUpperBack,
  'lowerBack' => l10n.muscleLowerBack,
  'biceps' => l10n.muscleBiceps,
  'triceps' => l10n.muscleTriceps,
  'forearms' => l10n.muscleForearms,
  'abs' => l10n.muscleAbs,
  'obliques' => l10n.muscleObliques,
  'quads' => l10n.muscleQuads,
  'hamstrings' => l10n.muscleHamstrings,
  'glutes' => l10n.muscleGlutes,
  'calves' => l10n.muscleCalves,
  _ => key,
};

String equipmentLabel(AppLocalizations l10n, String key) => switch (key) {
  'barbell' => l10n.equipmentBarbell,
  'dumbbell' => l10n.equipmentDumbbell,
  'cable' => l10n.equipmentCable,
  'machine' => l10n.equipmentMachine,
  'bodyweight' => l10n.equipmentBodyweight,
  _ => key,
};

String goalLabel(AppLocalizations l10n, Goal goal) => switch (goal) {
  Goal.buildMuscle => l10n.goalBuildMuscle,
  Goal.loseWeight => l10n.goalLoseWeight,
  Goal.getFit => l10n.goalGetFit,
};

String levelLabel(AppLocalizations l10n, Level level) => switch (level) {
  Level.beginner => l10n.levelBeginner,
  Level.intermediate => l10n.levelIntermediate,
  Level.advanced => l10n.levelAdvanced,
};

/// Weights render without a trailing .0 (20, 22.5).
String formatWeight(double weight) => weight == weight.roundToDouble()
    ? weight.toStringAsFixed(0)
    : weight.toStringAsFixed(1);

const _kgPerLb = 0.45359237;

/// Storage is always kg; these convert at the display/input boundary.
double kgToUnit(WeightUnit unit, double kg) =>
    unit == WeightUnit.kg ? kg : kg / _kgPerLb;

double unitToKg(WeightUnit unit, double value) =>
    unit == WeightUnit.kg ? value : value * _kgPerLb;

String unitLabel(AppLocalizations l10n, WeightUnit unit) => switch (unit) {
  WeightUnit.kg => l10n.unitKg,
  WeightUnit.lb => l10n.unitLb,
};

/// Convenience: kg value formatted in the display unit, e.g. "22.5".
String formatKgIn(WeightUnit unit, double kg) =>
    formatWeight(kgToUnit(unit, kg));
