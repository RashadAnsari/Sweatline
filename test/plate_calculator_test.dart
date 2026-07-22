import 'package:flutter_test/flutter_test.dart';
import 'package:sweatline/models.dart';
import 'package:sweatline/screens/workout_screen.dart';

void main() {
  test('platesPerSide fills greedily from the heaviest kg plate', () {
    expect(platesPerSide(WeightUnit.kg, 60), [20.0]);
    expect(platesPerSide(WeightUnit.kg, 100), [25.0, 15.0]);
    expect(platesPerSide(WeightUnit.kg, 47.5), [10.0, 2.5, 1.25]);
  });

  test('platesPerSide returns no plates at or below the bar weight', () {
    expect(platesPerSide(WeightUnit.kg, 20), isEmpty);
    expect(platesPerSide(WeightUnit.kg, 15), isEmpty);
    expect(platesPerSide(WeightUnit.lb, 45), isEmpty);
  });

  test('platesPerSide rounds down when the weight is not reachable', () {
    // 41 kg needs 10.5 per side; the closest from below is a single 10.
    expect(platesPerSide(WeightUnit.kg, 41), [10.0]);
  });

  test('platesPerSide uses lb plates and the 45 lb bar for lb', () {
    expect(platesPerSide(WeightUnit.lb, 135), [45.0]);
    expect(platesPerSide(WeightUnit.lb, 225), [45.0, 45.0]);
  });
}
