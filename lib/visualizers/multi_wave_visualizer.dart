// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'package:flutter/material.dart';
import 'dart:math' as math;

class _MultiWaveVisualizer extends CustomPainter {
  final List<double> data;
  final Color color;
  final Paint wavePaint;

  _MultiWaveVisualizer({
    required this.data,
    required this.color,
  }) : wavePaint = Paint()
          ..color = color.withOpacity(0.75)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _renderWaves(canvas, size);
  }

  void _renderWaves(Canvas canvas, Size size) {
    // Calculate the midpoint of data for splitting into low and high frequencies
    final midPoint = (data.length / 2).floor();

    // Create histograms for low and high frequencies
    // Using dynamic bucket count based on available width
    final bucketCount =
        math.max((size.width / 20).floor(), 5); // Ensure minimum 5 buckets

    final histogramLow = _createHistogram(data, bucketCount, 0, midPoint);
    final histogramHigh =
        _createHistogram(data, bucketCount, midPoint, data.length);

    // Render both histograms
    _renderHistogram(canvas, size, histogramLow);
    _renderHistogram(canvas, size, histogramHigh);
  }

  void _renderHistogram(Canvas canvas, Size size, List<double> histogram) {
    if (histogram.isEmpty) return;

    // Calculate width per point to fit within canvas
    final pointsToGraph = histogram.length;
    final widthPerSample = size.width / (pointsToGraph - 1);

    final points = List<double>.filled(pointsToGraph * 4, 0.0);

    // Create points for the smooth curve
    for (int i = 0; i < histogram.length - 1; ++i) {
      points[i * 4] = (i * widthPerSample).clamp(0.0, size.width);
      points[i * 4 + 1] =
          (size.height * (1 - histogram[i])).clamp(0.0, size.height);
      points[i * 4 + 2] = ((i + 1) * widthPerSample).clamp(0.0, size.width);
      points[i * 4 + 3] =
          (size.height * (1 - histogram[i + 1])).clamp(0.0, size.height);
    }

    // Create and draw the path
    Path path = Path();
    path.moveTo(0.0, size.height);
    path.lineTo(points[0], points[1]);

    // Calculate control point distance based on width
    final controlPointDistance = widthPerSample * 0.5;

    for (int i = 2; i < points.length - 4; i += 2) {
      path.cubicTo(
          points[i - 2] + controlPointDistance,
          points[i - 1],
          points[i] - controlPointDistance,
          points[i + 1],
          points[i],
          points[i + 1]);
    }

    // Complete the path
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  List<double> _createHistogram(
      List<double> samples, int bucketCount, int start, int end) {
    if (start >= end || samples.isEmpty) return const [];

    final sampleCount = end - start;
    final samplesPerBucket = (sampleCount / bucketCount).floor();

    if (samplesPerBucket == 0) return const [];

    List<double> histogram = List<double>.filled(bucketCount, 0.0);
    double maxValue = 0.0;

    // Calculate histogram values and find maximum
    for (int i = 0; i < bucketCount; i++) {
      double sum = 0.0;
      int count = 0;

      for (int j = 0; j < samplesPerBucket; j++) {
        final idx = start + (i * samplesPerBucket) + j;
        if (idx < end) {
          // Convert from [0-255] to [0-1] range
          sum += samples[idx] / 255.0;
          count++;
        }
      }

      if (count > 0) {
        histogram[i] = sum / count;
        maxValue = math.max(maxValue, histogram[i]);
      }
    }

    // Normalize values to [0-1] range based on maximum value
    if (maxValue > 0) {
      for (int i = 0; i < histogram.length; i++) {
        histogram[i] = histogram[i] / maxValue;
      }
    }

    return histogram;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class MultiWaveVisualizer extends StatelessWidget {
  const MultiWaveVisualizer({
    super.key,
    required this.input,
    this.gap = 2,
    this.color = Colors.blue,
    this.backgroundColor = Colors.transparent,
  });

  final Color color;
  final Color backgroundColor;
  final int gap;
  final List<int> input;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: CustomPaint(
        painter: _MultiWaveVisualizer(
          data: input.map((e) => e.toDouble()).toList(),
          color: color,
        ),
      ),
    );
  }
}
