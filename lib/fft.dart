library audio_visualizer;

import 'dart:math' as math;
import 'package:complex/complex.dart';

class FFT {
  static List<Complex> transform(List<Complex> input, {bool inverse = false}) {
    if (input.length == 1) {
      return <Complex>[input[0]];
    }

    final int length = input.length;
    assert(_isPowerOfTwo(length), 'length must be power of 2');
    final int half = length ~/ 2;
    final double sign = inverse == true ? -1.0 : 1.0;
    final result = List<Complex>(length);
    final factorExp = (-2.0 * math.pi / length) * sign;

    final evens = List<Complex>(half);
    final odds = List<Complex>(half);
    for (int i = 0; i < half; i++) {
      evens[i] = input[2 * i];
      odds[i] = input[2 * i + 1];
    }

    final evenResult = transform(evens, inverse: inverse);
    final oddResult = transform(odds, inverse: inverse);

    for (int k = 0; k < half; k++) {
      final factorK = factorExp * k;
      final oddComponent = oddResult[k] * Complex(math.cos(factorK), math.sin(factorK));
      result[k] = evenResult[k] + oddComponent;
      result[k + half] = evenResult[k] - oddComponent;
    }
    return result;
  }

  static List<Complex> from(List<double> input, {bool padding = true, int size}) {
    if (size != null) assert(size >= input.length && _isPowerOfTwo(size), 'size must larger than input and must be power of two');
    final int length = padding ? (size == null ? math.pow(2, (math.log(input.length) / math.log(2)).ceil()) : size) : input.length;
    final output = List<Complex>(length);
    for (int i = 0; i < length; i++) {
      final double value = i >= input.length ? 0.0 : input[i];
      output[i] = Complex(value, 0.0);
    }
    return output;
  }

  static bool _isPowerOfTwo(int input) {
    return input != 0 && (input & (input - 1)) == 0;
  }

  static List<int> fromDoubleToInt(List<double> input) {
    return input.map((e) => scale(e,0.0,1.0,0,255).round()).toList();
  }

  static List<double> scaleAmplitude(List<Complex> input, int size) {
    final double factor = (1.0 / size);
    final List<double> buffer = input
        .map((e) {
      double amp = factor * e.abs();
      //assert(amp <= 255.0);
      double value = amp.roundToDouble().clamp(0.0, 255.0);
      return scale(value, 0.0, 255, 0.0, 1.0);
    })
        .skip(0)
        .take(input.length ~/ 2)
        .toList();

    return buffer;
  }

  static double scale(double k, double minX, double maxX, double a, double b) {
    return a + ((k - minX) * (b - a) / (maxX - minX));
  }

  static double logScale(double k) {
    return 10 * math.log(k) / math.ln10;
  }
}
