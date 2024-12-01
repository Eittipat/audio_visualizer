// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'package:flutter/material.dart';
import 'dart:math' as math;

class _LineBarVisualizer extends CustomPainter {
  final List<int> data;
  final Color color;
  final Paint wavePaint;
  final int gap;

  _LineBarVisualizer({
    required this.data,
    required this.color,
    this.gap = 2,
  }) : wavePaint = Paint()
          ..color = color.withOpacity(1.0)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Calculate the maximum number of bars that can fit in the width
    final maxBars = (size.width / (gap + 1)).floor();
    final density = math.min(data.length, maxBars);

    // Calculate bar width ensuring we don't exceed the canvas width
    final barWidth = size.width / density;

    // Calculate sampling interval for data
    final samplingInterval = data.length / density;

    // Set wave paint stroke width
    wavePaint.strokeWidth = math.max(1, barWidth - gap);

    // Find maximum amplitude for scaling
    final maxAmplitude = math.max(1, data.reduce(math.max));

    // Calculate half height for center line
    final centerY = size.height / 2;

    // Calculate maximum possible amplitude in pixels (half of available height)
    final maxPixelAmplitude = centerY;

    for (int i = 0; i < density; i++) {
      // Calculate the data index, ensuring we don't exceed array bounds
      final dataIndex =
          (i * samplingInterval).floor().clamp(0, data.length - 1);

      // Scale the amplitude to [0-maxPixelAmplitude]
      final scaledAmplitude =
          (data[dataIndex] / maxAmplitude) * maxPixelAmplitude;

      // Calculate bar position
      final barX = (i * barWidth) + (barWidth / 2);

      // Calculate top and bottom points, ensuring they stay within bounds
      final top = (centerY - scaledAmplitude).clamp(0.0, size.height);
      final bottom = (centerY + scaledAmplitude).clamp(0.0, size.height);

      // Draw only if the bar would be visible
      if (barX >= 0 && barX <= size.width) {
        canvas.drawLine(Offset(barX, centerY), Offset(barX, top), wavePaint);
        canvas.drawLine(Offset(barX, centerY), Offset(barX, bottom), wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class LineBarVisualizer extends StatelessWidget {
  const LineBarVisualizer({
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
        painter: _LineBarVisualizer(
          data: input,
          gap: gap,
          color: color,
        ),
      ),
    );
  }
}
