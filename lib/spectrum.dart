/*
Copyright (C) 2013 Keijiro Takahashi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//  Original source code from
//  - https://github.com/keijiro/unity-audio-spectrum

import 'dart:math' as math;

enum BandType {
  fourBand,
  fourBandVisual,
  eightBand,
  tenBand,
  twentySixBand,
  thirtyOneBand,
}

const List<List<double>> kMiddleFrequenciesForBands = [
  [125.0, 500, 1000, 2000],
  [250.0, 400, 600, 800],
  [63.0, 125, 500, 1000, 2000, 4000, 6000, 8000],
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
  ]
];

const List<double> kBandwidthForBands = [
  1.414,
  1.260,
  1.414,
  1.414,
  1.122,
  1.122
];

class AudioSpectrum {
  BandType bandType;
  double fallSpeed;
  double sensibility;
  int samplingRate;

  late List<double> rawSpectrum;
  late List<double> levels;
  late List<double> peakLevels;
  late List<double> meanLevels;

  AudioSpectrum({
    this.samplingRate = 44100,
    this.bandType = BandType.tenBand,
    this.fallSpeed = 0.08,
    this.sensibility = 8.0,
  }) {
    rawSpectrum = List.filled(0, 0.0);
    int bandCount = kMiddleFrequenciesForBands[bandType.index].length;
    levels = List.filled(bandCount, 0.0);
    peakLevels = List.filled(bandCount, 0.0);
    meanLevels = List.filled(bandCount, 0.0);
  }

  void update(List<double> fft) {
    rawSpectrum = fft;
    if (rawSpectrum.isNotEmpty) {
      _updateSpectrum();
    }
  }

  void flush() {
    for (int i = 0; i < levels.length; i++) {
      levels[i] = 0;
      peakLevels[i] = 0;
      meanLevels[i] = 0;
    }
  }

  int get numberOfSamples => rawSpectrum.length;

  int _frequencyToSpectrumIndex(double frequency) {
    final resolution = samplingRate / (numberOfSamples * 2);
    int index = (frequency / resolution).floor();
    return index.clamp(0, rawSpectrum.length - 1);
  }

  void _updateSpectrum() {
    final fallDown = fallSpeed * (1 / 60);
    final filter = math.exp(-sensibility * (1 / 60));
    final middleFrequencies = kMiddleFrequenciesForBands[bandType.index];
    final bandwidth = kBandwidthForBands[bandType.index];
    for (int bi = 0; bi < levels.length; bi++) {
      final freq = middleFrequencies[bi];
      final iMin = _frequencyToSpectrumIndex(freq / bandwidth);
      final iMax = _frequencyToSpectrumIndex(freq * bandwidth);
      double bandMax = 0.0;
      for (int fi = iMin; fi <= iMax; fi++) {
        bandMax = math.max(bandMax, rawSpectrum[fi]);
      }
      levels[bi] = bandMax;
      peakLevels[bi] = math.max(peakLevels[bi] - fallDown, bandMax);
      meanLevels[bi] = bandMax - (bandMax - meanLevels[bi]) * filter;
    }
  }
}
