import 'dart:math' as math;

class ValueBuffer {
  late final List<double> levels;
  late final List<double> peakLevels;
  late final List<double> meanLevels;
  final double fallSpeed;
  final double sensibility;

  ValueBuffer({
    required int size,
    this.fallSpeed = 0.08,
    this.sensibility = 8.0,
  }) {
    levels = List.filled(size, 0.0);
    peakLevels = List.filled(size, 0.0);
    meanLevels = List.filled(size, 0.0);
  }

  void update(List<double> input) {
    double fallDown = fallSpeed * (1 / 60);
    double filter = math.exp(-sensibility * (1 / 60));
    for (int i = 0; i < input.length; i++) {
      final bandMax = input[i];
      levels[i] = bandMax;
      peakLevels[i] = math.max(peakLevels[i] - fallDown, bandMax);
      meanLevels[i] = bandMax - (bandMax - meanLevels[i]) * filter;
    }
  }

  void flush() {
    for (int i = 0; i < levels.length; i++) {
      levels[i] = 0;
      peakLevels[i] = 0;
      meanLevels[i] = 0;
    }
  }
}

num log10(num x) {
  if (x == 0) return 0;
  return (math.log(x) / math.log(10)).floor();
}

num hypotenuse(num x, num y) {
  return math.sqrt(math.pow(x, 2) + math.pow(y, 2));
}

List<double> getMagnitudes(List<int> fft) {
  if (fft.isEmpty) return [];
  final n = fft.length;
  final magnitudes = List<double>.filled(n ~/ 2 + 1, 0);
  magnitudes[0] = fft[0].abs().toDouble();
  magnitudes[n ~/ 2] = fft[1].abs().toDouble();
  for (int k = 1; k < n ~/ 2; k++) {
    int i = k * 2;
    final real = fft[i];
    final imag = fft[i + 1];
    magnitudes[k] = hypotenuse(real, imag).toDouble();
  }
  return magnitudes;
}
