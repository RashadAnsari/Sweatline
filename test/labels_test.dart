import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/labels.dart';
import 'package:sweatline/models.dart';

void main() {
  test('kg is the identity unit', () {
    expect(kgToUnit(WeightUnit.kg, 42.5), 42.5);
    expect(unitToKg(WeightUnit.kg, 42.5), 42.5);
  });

  test('kg/lb conversion round trips', () {
    const kg = 100.0;
    final lb = kgToUnit(WeightUnit.lb, kg);
    expect(lb, closeTo(220.46, 0.01));
    expect(unitToKg(WeightUnit.lb, lb), closeTo(kg, 1e-9));
  });

  test('weights format without trailing .0 and with one decimal', () {
    expect(formatWeight(20), '20');
    expect(formatWeight(22.5), '22.5');
    expect(formatWeight(88.1849), '88.2');
    expect(formatKgIn(WeightUnit.lb, 40), '88.2');
  });
}
