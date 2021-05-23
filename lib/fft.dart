library audio_visualizer;

import 'dart:math' as math;
import 'package:complex/complex.dart';

class FFT {
  static List<Complex?> transform(List<Complex?> input,
      {bool inverse = false}) {
    if (input.length == 1) {
      return <Complex?>[input[0]];
    }

    final int length = input.length;
    assert(isPowerOfTwo(length), 'length must be power of 2');
    final int half = length ~/ 2;
    final double sign = inverse == true ? -1.0 : 1.0;
    final result = List<Complex?>.filled(length, Complex(0, 0));
    final factorExp = (-2.0 * math.pi / length) * sign;

    final evens = List<Complex?>.filled(half, Complex(0, 0));
    final odds = List<Complex?>.filled(half, Complex(0, 0));
    for (int i = 0; i < half; i++) {
      evens[i] = input[2 * i];
      odds[i] = input[2 * i + 1];
    }

    final evenResult = transform(evens, inverse: inverse);
    final oddResult = transform(odds, inverse: inverse);

    for (int k = 0; k < half; k++) {
      final factorK = factorExp * k;
      final oddComponent =
          oddResult[k]! * Complex(math.cos(factorK), math.sin(factorK));
      result[k] = evenResult[k]! + oddComponent;
      result[k + half] = evenResult[k]! - oddComponent;
    }
    return result;
  }

  static List<Complex?> from(List<double> input,
      {bool padding = true, int? size}) {
    if (size != null)
      assert(size >= input.length && isPowerOfTwo(size),
          'size must larger than input and must be power of two');
    final int length = padding
        ? (size == null ? roundToPowerOfTwo(input.length) : size)
        : input.length;
    final output = List<Complex?>.filled(length, Complex(0, 0));
    for (int i = 0; i < length; i++) {
      final double value = i >= input.length ? 0.0 : input[i];
      output[i] = Complex(value, 0.0);
    }
    return output;
  }

  static List<double?> padToSize(List<double> input, int size) {
    final output = List<double?>.filled(size, 0);
    for (int i = 0; i < size; i++) {
      final double value = i >= input.length ? 0.0 : input[i];
      output[i] = value;
    }
    return output;
  }

  static bool isPowerOfTwo(int input) {
    return input != 0 && (input & (input - 1)) == 0;
  }

  static int roundToPowerOfTwo(int input) {
    return math.pow(2, (math.log(input) / math.log(2)).ceil()) as int;
  }

  static List<double> magnitudeToAmplitude(
    List<Complex?> input,
    bool normalize,
    double min,
    double max,
    int size,
  ) {
    final double factor = (1.0 / size);
    final List<double> buffer = input.map((e) {
      double amp = factor * e!.abs();
      assert(amp <= max);
      double value = amp.roundToDouble().clamp(min, max);
      return normalize ? scale(value, min, max, 0.0, 1.0) : value;
    }).toList();

    return buffer;
  }

  static double scale(double k, double minX, double maxX, double a, double b) {
    return a + ((k - minX) * (b - a) / (maxX - minX));
  }

  static double logScale(double k) {
    return 20 * math.log(k) / math.ln10;
  }
}
