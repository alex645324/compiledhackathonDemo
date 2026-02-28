import 'dart:math';

class StressEngine {
  ({double originalEffect, double failureRate}) run(
    List<double> control,
    List<double> treatment, {
    int replays = 10000,
  }) {
    final originalEffect = _mean(treatment) - _mean(control);
    int failures = 0;

    final rng = Random();

    for (int i = 0; i < replays; i++) {
      final pressure = i / replays; // 0.0 → 1.0 over the run

      var resampledControl = _resample(control, rng);
      var resampledTreatment = _resample(treatment, rng);

      resampledControl = _increaseVariance(resampledControl, 0.3 * pressure);
      resampledTreatment = _shrinkEffect(
        resampledTreatment,
        resampledControl,
        0.3 * pressure,
      );
      resampledTreatment = _addNoise(resampledTreatment, 0.1 * pressure, rng);

      final effect = _mean(resampledTreatment) - _mean(resampledControl);
      if (effect <= 0) failures++;
    }

    return (
      originalEffect: originalEffect,
      failureRate: failures / replays,
    );
  }

  List<double> _resample(List<double> values, Random rng) {
    return List.generate(
      values.length,
      (_) => values[rng.nextInt(values.length)],
    );
  }

  List<double> _addNoise(List<double> values, double factor, Random rng) {
    if (factor == 0) return values;
    final sd = _stddev(values);
    return [for (final v in values) v + (rng.nextDouble() - 0.5) * 2 * sd * factor];
  }

  List<double> _shrinkEffect(
    List<double> treatment,
    List<double> control,
    double factor,
  ) {
    if (factor == 0) return treatment;
    final controlMean = _mean(control);
    return [for (final v in treatment) v - (v - controlMean) * factor];
  }

  List<double> _increaseVariance(List<double> values, double factor) {
    if (factor == 0) return values;
    final m = _mean(values);
    return [for (final v in values) m + (v - m) * (1 + factor)];
  }

  double _mean(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _stddev(List<double> values) {
    final m = _mean(values);
    final variance = values.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}
