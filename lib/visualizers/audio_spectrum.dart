import 'package:flutter/material.dart';

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

class AudioSpectrumValue {
  final List<int> levels;
  final List<int> peakLevels;
  final List<int> meanLevels;

  AudioSpectrumValue({
    required this.levels,
    required this.peakLevels,
    required this.meanLevels,
  });

  AudioSpectrumValue.empty()
      : levels = [],
        peakLevels = [],
        meanLevels = [];
}

class AudioSpectrum extends StatefulWidget {
  const AudioSpectrum({
    super.key,
    required this.fftMagnitudes,
    required this.builder,
    this.samplingRate = 44100,
    this.bandType = BandType.tenBand,
    this.fallSpeed = 0.08,
    this.sensibility = 8.0,
    this.child,
  });

  final List<int> fftMagnitudes;
  final int samplingRate;
  final BandType bandType;
  final double fallSpeed;
  final double sensibility;
  final Widget Function(
      BuildContext context, AudioSpectrumValue value, Widget? child) builder;
  final Widget? child;

  @override
  State<AudioSpectrum> createState() {
    return _AudioSpectrumState();
  }
}

class _AudioSpectrumState extends State<AudioSpectrum> {
  late List<int> levels;
  late List<int> peakLevels;
  late List<int> meanLevels;

  void _init() {
    int bandCount = kMiddleFrequenciesForBands[widget.bandType.index].length;
    levels = List.filled(bandCount, 0);
    peakLevels = List.filled(bandCount, 0);
    meanLevels = List.filled(bandCount, 0);
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(AudioSpectrum oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fftMagnitudes.length != oldWidget.fftMagnitudes.length ||
        widget.bandType != oldWidget.bandType) {
      _init();
    }
    // always update levels
    if (widget.fftMagnitudes.isNotEmpty) {
      _update(widget.fftMagnitudes);
    }
  }

  int _frequencyToSpectrumIndex(double frequency, int numberOfSamples) {
    final resolution = widget.samplingRate / (numberOfSamples * 2);
    int index = (frequency / resolution).floor();
    return index.clamp(0, numberOfSamples - 1);
  }

  void _update(List<int> input) {
    final fallDown = widget.fallSpeed * (1 / 60);
    final filter = math.exp(-widget.sensibility * (1 / 60));
    final middleFrequencies = kMiddleFrequenciesForBands[widget.bandType.index];
    final bandwidth = kBandwidthForBands[widget.bandType.index];
    for (int bi = 0; bi < levels.length; bi++) {
      final freq = middleFrequencies[bi];
      final iMin = _frequencyToSpectrumIndex(freq / bandwidth, input.length);
      final iMax = _frequencyToSpectrumIndex(freq * bandwidth, input.length);
      double bandMax = 0.0;
      for (int fi = iMin; fi <= iMax; fi++) {
        bandMax = math.max(bandMax, input[fi].toDouble());
      }
      levels[bi] = bandMax.round();
      peakLevels[bi] = math.max(peakLevels[bi] - fallDown, bandMax).round();
      meanLevels[bi] = (bandMax - (bandMax - meanLevels[bi]) * filter).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      AudioSpectrumValue(
        levels: levels,
        peakLevels: peakLevels,
        meanLevels: meanLevels,
      ),
      widget.child,
    );
  }
}
