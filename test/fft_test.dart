import 'package:audio_visualizer/fft.dart';
import 'package:audio_visualizer/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('int32', () {
    test('int to int32', () {
      expect(int32(0), 0);
      expect(int32(1), 1);
      expect(int32(-1), -1);
      expect(int32(2147483647), 2147483647);
      expect(int32(-2147483648), -2147483648);
    });

    test('int to int32 (underflow)', () {
      expect(int32(-2147483649), 2147483647);
      expect(int32(-2147483650), 2147483646);
      expect(int32(-2147483651), 2147483645);
    });

    test('int to int32 (overflow)', () {
      expect(int32(2147483648), -2147483648);
      expect(int32(2147483649), -2147483647);
      expect(int32(2147483650), -2147483646);
    });
  });

  group('int16', () {
    test('int to int16', () {
      expect(int16(0), 0);
      expect(int16(1), 1);
      expect(int16(-1), -1);
      expect(int16(32767), 32767);
      expect(int16(-32768), -32768);
    });
    test('int to int16 (underflow)', () {
      expect(int16(-32769), 32767);
      expect(int16(-32770), 32766);
      expect(int16(-32771), 32765);
    });
    test('int to int16 (overflow)', () {
      expect(int16(32768), -32768);
      expect(int16(32769), -32767);
      expect(int16(32770), -32766);
    });
  });

  group('int8', () {
    test('int to int8', () {
      expect(int8(0), 0);
      expect(int8(1), 1);
      expect(int8(-1), -1);
      expect(int8(127), 127);
      expect(int8(-128), -128);
    });
    test('int to int8 (underflow)', () {
      expect(int8(-129), 127);
      expect(int8(-130), 126);
      expect(int8(-131), 125);
    });
    test('int to int8 (overflow)', () {
      expect(int8(128), -128);
      expect(int8(129), -127);
      expect(int8(130), -126);
    });
  });

  group('uint8', () {
    test('int to uint8', () {
      expect(uint8(0), 0);
      expect(uint8(1), 1);
      expect(uint8(-1), 255);
      expect(uint8(255), 255);
    });

    test('int to uint8 (underflow)', () {
      expect(uint8(-1), 255);
      expect(uint8(-2), 254);
      expect(uint8(-3), 253);
    });

    test('int to uint8 (overflow)', () {
      expect(uint8(256), 0);
      expect(uint8(257), 1);
      expect(uint8(258), 2);
    });
  });

  group('doFft', () {
    test('0s sequence', () {
      final input = List<int>.filled(8, 0);
      final output = List<int>.filled(8, 0);
      doFft(output, input);
      expect(output, [128, 0, 0, 255, 0, 0, 0, 0]);
    });

    test('0-to-7 sequence', () {
      final input = [0, 1, 2, 3, 4, 5, 6, 7];
      final output = List<int>.filled(8, 0);
      doFft(output, input);
      expect(output, [131, 252, 251, 9, 251, 252, 251, 1]);
    });

    test('symmetric sequence', () {
      final input = [7, 6, 5, 4, 4, 5, 6, 7];
      final output = List<int>.filled(8, 0);
      doFft(output, input);
      expect(output, [133, 0, 5, 2, 0, 0, 0, 0]);
    });
  });

  group('scale', () {
    test('scales value within the range correctly', () {
      expect(scale(5, 0, 10, 0, 100), equals(50));
    });

    test('scales value at the minimum of the range correctly', () {
      expect(scale(0, 0, 10, 0, 100), equals(0));
    });

    test('scales value at the maximum of the range correctly', () {
      expect(scale(10, 0, 10, 0, 100), equals(100));
    });

    test('scales value below the original range correctly', () {
      expect(scale(-5, 0, 10, 0, 100), equals(-50));
    });

    test('scales value above the original range correctly', () {
      expect(scale(15, 0, 10, 0, 100), equals(150));
    });

    test('scales value with negative original range correctly', () {
      expect(scale(-5, -10, 0, 0, 100), equals(50));
    });

    test('scales value with negative new range correctly', () {
      expect(scale(5, 0, 10, -100, 0), equals(-50));
    });
  });
}
