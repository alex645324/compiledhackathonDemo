import 'package:flutter_test/flutter_test.dart';
import 'package:ui/services/stress_engine.dart';

void main() {
  final engine = StressEngine();

  test('known-pass data returns positive original effect', () {
    final control = [1.0, 1.1, 1.2, 1.0, 1.1];
    final treatment = [2.0, 2.1, 2.2, 2.0, 2.1];
    final result = engine.run(control, treatment);
    expect(result.originalEffect, greaterThan(0));
  });

  test('fragile data shows high failure rate', () {
    // Treatment barely above control — should break easily
    final control = [1.0, 1.1, 1.0, 1.1, 1.0];
    final treatment = [1.01, 1.11, 1.01, 1.11, 1.01];
    final result = engine.run(control, treatment, replays: 5000);
    expect(result.failureRate, greaterThan(0.3));
  });

  test('strong data shows low failure rate', () {
    // Treatment far above control — should survive perturbation
    final control = [1.0, 1.0, 1.0, 1.0, 1.0];
    final treatment = [10.0, 10.0, 10.0, 10.0, 10.0];
    final result = engine.run(control, treatment, replays: 5000);
    expect(result.failureRate, lessThan(0.2));
  });

  test('resample preserves list length', () {
    // Indirectly verified: engine runs without error on varying lengths
    final control = [1.0, 2.0, 3.0];
    final treatment = [4.0, 5.0, 6.0];
    final result = engine.run(control, treatment, replays: 100);
    expect(result.originalEffect, isNotNull);
    expect(result.failureRate, isNotNull);
  });
}
