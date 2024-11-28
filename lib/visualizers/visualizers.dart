import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:audio_visualizer/spectrum.dart';
import 'package:audio_visualizer/visualizers/utils.dart';
import 'package:flutter/material.dart';

export 'bar_visualizer.dart';
export 'line_bar_visualizer.dart';
export 'circular_bar_visualizer.dart';
export 'multi_wave_visualizer.dart';

class VisualizerValue {
  final List<double> amplitudes;
  final List<double> magnitudes;
  final List<double> levels;
  final List<double> peakLevels;
  final List<double> meanLevels;

  const VisualizerValue({
    this.amplitudes = const [],
    this.magnitudes = const [],
    this.levels = const [],
    this.peakLevels = const [],
    this.meanLevels = const [],
  });
}

class VisualizerBuilder extends StatefulWidget {
  const VisualizerBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.child,
    this.bandType,
    this.fallSpeed = 0.08,
    this.sensitivity = 8.0,
    this.samplingRate = 44100,
  });

  final AudioVisualizer controller;
  final BandType? bandType;
  final Widget Function(
    BuildContext context,
    VisualizerValue value,
    Widget? child,
  ) builder;
  final Widget? child;
  final int samplingRate;
  final double fallSpeed;
  final double sensitivity;

  @override
  State<VisualizerBuilder> createState() {
    return _VisualizerBuilderState();
  }
}

class _VisualizerBuilderState extends State<VisualizerBuilder> {
  AudioSpectrum? spectrum;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onValueChanged);
  }

  @override
  void didUpdateWidget(VisualizerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.bandType != widget.bandType ||
        oldWidget.samplingRate != widget.samplingRate ||
        oldWidget.fallSpeed != widget.fallSpeed ||
        oldWidget.sensitivity != widget.sensitivity ||
        oldWidget.builder != widget.builder ||
        oldWidget.child != widget.child) {
      spectrum = null;
      oldWidget.controller.removeListener(onValueChanged);
      widget.controller.addListener(onValueChanged);
    }
  }

  void onValueChanged() {
    spectrum ??= AudioSpectrum(
      samplingRate: widget.samplingRate,
      bandType: widget.bandType ?? BandType.tenBand,
      fallSpeed: widget.fallSpeed,
      sensibility: widget.sensitivity,
    );
    final value = getMagnitudes(widget.controller.value.fft);
    spectrum!.update(value);
    setState(() {
      // trigger rebuild
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(onValueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveform = widget.controller.value.waveform;
    final amplitudes = waveform.map((e) => e.toDouble()).toList();
    return widget.builder(
      context,
      VisualizerValue(
        amplitudes: amplitudes,
        magnitudes: spectrum?.rawSpectrum ?? [],
        levels: spectrum?.levels ?? [],
        peakLevels: spectrum?.peakLevels ?? [],
        meanLevels: spectrum?.meanLevels ?? [],
      ),
      widget.child,
    );
  }
}
