//
//
//
// library audio_visualizer;
//
// import 'package:audio_visualizer/fft.dart';
// import 'dart:math' as math;
//
// import 'package:complex/complex.dart';
//
// enum BandType { FourBand, FourBandVisual, EightBand, TenBand, TwentySixBand, ThirtyOneBand }
//
// class AudioVisualizer {
//   // https://github.com/keijiro/unity-audio-spectrum/blob/master/AudioSpectrum.cs
//   List<double> _samples;
//   final BandType bandType;
//   final int sampleRate;
//
//   int windowSize;
//
//   static List<List<double>> middleFrequenciesForBands = [
//     [125.0, 500, 1000, 2000],
//     [250.0, 400, 600, 800],
//     [63.0, 125, 500, 1000, 2000, 4000, 6000, 8000], // 8 bin
//     [31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
//     [25.0, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000],
//     [20.0, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000],
//   ];
//   static List<double> bandwidthForBands = [
//     1.414, // 2^(1/2)
//     1.260, // 2^(1/3)
//     1.414, // 2^(1/2)
//     1.414, // 2^(1/2)
//     1.122, // 2^(1/6)
//     1.122 // 2^(1/6)
//   ];
//
//   List<double> levels;
//   List<double> peakLevels;
//   List<double> meanLevels;
//
//   AudioVisualizer({this.windowSize = 512, this.bandType = BandType.EightBand, this.sampleRate = 44100});
//
//   void reset() {
//     int bandSize = middleFrequenciesForBands[bandType.index].length;
//     _samples = List<double>.filled(windowSize, 0.0, growable: false);
//     final bandCount = middleFrequenciesForBands[2].length;
//     assert(bandCount == 8);
//     levels = List<double>.filled(bandSize, 0.0, growable: false);
//     peakLevels = List<double>.filled(bandSize, 0.0, growable: false);
//     meanLevels = List<double>.filled(bandSize, 0.0, growable: false);
//   }
//
//   int freqToSpectrumIndex(double freq) {
//     // freq = index * (Fs / N)
//     int n = windowSize;
//     int i = (freq / sampleRate * n).floor();
//     return i.clamp(0, n - 1);
//   }
//
//   DateTime lastDateTime;
//   double maxScale = 0.0;
//
//   List<double> transform(List<double> audio) {
//     // calculate fft
//     final actualLength = audio.length;
//     final temp = FFT.transform(FFT.from(audio, padding: true), inverse: false);
//     windowSize = temp.length;
//     _samples = toAmplitudeScale(temp, actualLength);
//     _samples[0] = _samples[0] * 0.0; // discard 0 hz
//     assert(_samples.length == windowSize ~/ 2);
//
//     if (lastDateTime == null) lastDateTime = DateTime.now();
//     final now = DateTime.now();
//     double fallSpeed = 0.08;
//     double sensibility = 8.0;
//     double delta = (now.difference(lastDateTime).inMilliseconds / 1000.0);
//     lastDateTime = now;
//
//     final middlefrequencies = middleFrequenciesForBands[bandType.index];
//     var bandwidth = bandwidthForBands[bandType.index];
//
//     var falldown = fallSpeed * delta;
//     var filter = math.exp(-sensibility * delta);
//
//     for (var bi = 0; bi < levels.length; bi++) {
//       int imin = freqToSpectrumIndex(middlefrequencies[bi] / bandwidth);
//       int imax = freqToSpectrumIndex(middlefrequencies[bi] * bandwidth);
//
//       var bandMax = 0.0;
//       for (var fi = imin; fi <= imax; fi++) {
//         bandMax = math.max(bandMax, _samples[fi]);
//       }
//
//       levels[bi] = bandMax;
//       peakLevels[bi] = math.max(peakLevels[bi] - falldown, bandMax);
//       meanLevels[bi] = bandMax - (bandMax - meanLevels[bi]) * filter;
//     }
//
//     return meanLevels;
//   }
//
//   List<double> toAmplitudeScale(List<Complex> input, int size) {
//     final double factor = (1.0 / size);
//     final List<double> buffer = input
//         .map((e) {
//           double amp = factor * e.abs();
//           double value = amp.roundToDouble().clamp(0.0, 255.0);
//           return scale(value, 0.0, 255, 0.0, 1.0);
//         })
//         .skip(0)
//         .take(input.length ~/ 2)
//         .toList();
//
//     return buffer;
//   }
//
//   double scale(double k, double minX, double maxX, double a, double b) {
//     return a + ((k - minX) * (b - a) / (maxX - minX));
//   }
//
//   double logScale(double k) {
//     return 10 * math.log(k) / math.ln10;
//   }
// }
