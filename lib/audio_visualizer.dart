/*

Original code from https://github.com/keijiro/unity-audio-spectrum

Copyright (C) 2013 Keijiro Takahashi
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import 'dart:math' as math;

import 'fft.dart';

enum BandType {
  FourBand,
  FourBandVisual,
  EightBand,
  TenBand,
  TwentySixBand,
  ThirtyOneBand
}

class AudioVisualizer {
  // https://github.com/keijiro/unity-audio-spectrum/blob/master/AudioSpectrum.cs
  final BandType bandType;
  final int sampleRate;
  final double zeroHzScale;
  final double fallSpeed;
  final double sensibility;
  int windowSize;

  static List<List<double>> middleFrequenciesForBands = [
    [125.0, 500, 1000, 2000],
    [250.0, 400, 600, 800],
    [63.0, 125, 500, 1000, 2000, 4000, 6000, 8000], // 8 bin
    [31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
    [
      25.0,
      31.5,
      40,
      50,
      63,
      80,
      100,
      125,
      160,
      200,
      250,
      315,
      400,
      500,
      630,
      800,
      1000,
      1250,
      1600,
      2000,
      2500,
      3150,
      4000,
      5000,
      6300,
      8000
    ],
    [
      20.0,
      25,
      31.5,
      40,
      50,
      63,
      80,
      100,
      125,
      160,
      200,
      250,
      315,
      400,
      500,
      630,
      800,
      1000,
      1250,
      1600,
      2000,
      2500,
      3150,
      4000,
      5000,
      6300,
      8000,
      10000,
      12500,
      16000,
      20000
    ],
  ];
  static List<double> bandwidthForBands = [
    1.414, // 2^(1/2)
    1.260, // 2^(1/3)
    1.414, // 2^(1/2)
    1.414, // 2^(1/2)
    1.122, // 2^(1/6)
    1.122 // 2^(1/6)
  ];

  List<double> levels;
  List<double> peakLevels;
  List<double> meanLevels;

  AudioVisualizer({
    this.windowSize = 2048,
    this.bandType = BandType.EightBand,
    this.sampleRate = 44100,
    this.zeroHzScale = 0.05,
    this.fallSpeed = 0.08,
    this.sensibility = 8.0,
  }) {
    reset();
  }

  void reset() {
    final band = middleFrequenciesForBands[bandType.index];
    int bandSize = band.length;
    levels = List<double>.filled(bandSize, 0.0, growable: false);
    peakLevels = List<double>.filled(bandSize, 0.0, growable: false);
    meanLevels = List<double>.filled(bandSize, 0.0, growable: false);
  }

  int freqToSpectrumIndex(double freq, int N) {
    // freq = index * (Fs / N)
    int i = (freq / (sampleRate / N)).floor();
    return i.clamp(0, N - 1);
  }

  DateTime lastDateTime;
  double maxScale = 0.0;

  List<double> transform(List<int> audio,
      {int minRange = 0, int maxRange = 255}) {
    final frequencies = middleFrequenciesForBands[bandType.index];
    final bandwidth = bandwidthForBands[bandType.index];

    // convert to complex number with power of two
    final input =
        FFT.from(audio.map((e) => e.toDouble()).toList(), padding: true);
    final N = input.length;
    final coeffs = FFT.transform(input, inverse: false);
    // scale magnitude to amplitude
    var samples = FFT.magnitudeToAmplitude(
        coeffs, false, minRange.toDouble(), maxRange.toDouble(), N);
    // scale 0 Hz coefficient
    samples[0] = samples[0] * zeroHzScale;
    // take half
    samples = samples.take(N ~/ 2).toList();

    // compute visualizer
    if (lastDateTime == null) lastDateTime = DateTime.now();
    final now = DateTime.now();
    double delta = (now.difference(lastDateTime).inMilliseconds / 1000.0);
    lastDateTime = now;

    final falldown = fallSpeed * delta;
    final filter = math.exp(-sensibility * delta);
    for (var bi = 0; bi < levels.length; bi++) {
      int imin = freqToSpectrumIndex(frequencies[bi] / bandwidth, N ~/ 2);
      int imax = freqToSpectrumIndex(frequencies[bi] * bandwidth, N ~/ 2);

      var bandMax = 0.0;
      for (var fi = imin; fi <= imax; fi++) {
        bandMax = math.max(bandMax, samples[fi]);
      }

      levels[bi] = bandMax;
      peakLevels[bi] = math.max(peakLevels[bi] - falldown, bandMax);
      meanLevels[bi] = bandMax - (bandMax - meanLevels[bi]) * filter;
    }

    // convert to dB
    var wave = List<double>.filled(meanLevels.length, 0, growable: false);
    double min = double.infinity;
    double max = double.negativeInfinity;
    for (int i = 0; i < meanLevels.length; i++) {
      var value = meanLevels[i];
      value = value != 0 ? FFT.logScale(value) : 0;
      assert(value.isFinite);
      wave[i] = value;

      if (value < min) min = value;
      if (value > max) max = value;
    }
    double coeff = (min.abs() + max.abs());
    wave = wave
        .map((e) => ((coeff + e) / 100.0).clamp(0.0, 1.0).toDouble())
        .toList();
    return List.unmodifiable(wave);
  }
}
