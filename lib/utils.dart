import 'dart:math' as math;

/// Calculates the hypotenuse of a right-angled triangle given the lengths of the other two sides.
///
/// This function uses the Pythagorean theorem to compute the hypotenuse.
///
/// param [x] The length of one side of the triangle.
/// param [y] The length of the other side of the triangle.
/// returns The length of the hypotenuse.
num hypotenuse(num x, num y) {
  return math.sqrt(math.pow(x, 2) + math.pow(y, 2));
}

/// Computes the magnitudes from the FFT (Fast Fourier Transform) data.
///
/// This function processes the FFT data to calculate the magnitudes of the frequency components.
/// It scales the magnitudes to the range [0, 255].
///
/// param [fft] A list of integers representing the FFT data.
/// returns A list of integers representing the magnitudes of the frequency components.
List<int> getMagnitudes(List<int> fft) {
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
    magnitudes[k] = scale(magnitudes[k].floor(), 0, 180, 0, 255);
  }
  return magnitudes.map((e) => e.toInt()).toList();
}

/// Converts a value to a 32-bit signed integer.
///
/// This function takes an integer value, masks it to 32 bits, and then
/// shifts it to ensure it is treated as a signed 32-bit integer.
///
/// param [value] The integer value to be converted.
/// returns The 32-bit signed integer representation of the input value.
int int32(int value) {
  return (value & 0xFFFFFFFF) << 32 >> 32;
}

/// Converts a value to a 16-bit signed integer.
///
/// This function takes an integer value, masks it to 16 bits, and then
/// shifts it to ensure it is treated as a signed 16-bit integer.
///
/// param [value] The integer value to be converted.
/// returns The 16-bit signed integer representation of the input value.
int int16(int value) {
  return (value & 0xFFFF) << 48 >> 48;
}

/// Converts a value to an 8-bit signed integer.
///
/// This function takes an integer value, masks it to 8 bits, and then
/// shifts it to ensure it is treated as a signed 8-bit integer.
///
/// param [value] The integer value to be converted.
/// returns The 8-bit signed integer representation of the input value.
int int8(int value) {
  return (value & 0xFF) << 56 >> 56;
}

/// Converts a value to an 8-bit unsigned integer.
///
/// This function takes an integer value and masks it to 8 bits to ensure
/// it is treated as an unsigned 8-bit integer.
///
/// param [value] The integer value to be converted.
/// returns The 8-bit unsigned integer representation of the input value.
int uint8(int value) {
  return value & 0xFF;
}

/// Scales a value from one range to another.
///
/// This function takes a value within a specified range and scales it to a new range.
///
/// param [value] The value to be scaled.
/// param [min] The minimum value of the original range.
/// param [max] The maximum value of the original range.
/// param [newMin] The minimum value of the new range.
/// param [newMax] The maximum value of the new range.
/// returns The scaled value within the new range.
double scale(num value, num min, num max, num newMin, num newMax) {
  return (value - min) * (newMax - newMin) / (max - min) + newMin;
}
