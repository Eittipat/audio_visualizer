// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart';

class CircularBarVisualizer extends CustomPainter {
  final List<double> data;
  Float32List? points;

  final Color color;
  final Paint wavePaint;
  final int gap;
  double radius = -1;

  CircularBarVisualizer({
    required this.data,
    required this.color,
    this.gap = 2,
  }) : wavePaint = Paint()
          ..color = color.withOpacity(1.0)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Calculate the maximum radius that will fit in the canvas
    // considering we need space for the amplitude bars
    if (radius == -1) {
      double minDimension = size.height < size.width ? size.height : size.width;
      // Use 1/3 of the minimum dimension for the base circle radius
      // This leaves room for the amplitude bars to stay within bounds
      radius = minDimension / 6;
      double circumference = 2 * pi * radius;
      wavePaint.strokeWidth = circumference / (data.length * 2);
      wavePaint.style = PaintingStyle.stroke;
    }

    // Center point
    final center = Offset(size.width / 2, size.height / 2);

    // Draw base circle
    canvas.drawCircle(
      center,
      radius.toDouble(),
      wavePaint,
    );

    if (points == null || points!.length < data.length * 4) {
      points = Float32List(data.length * 4);
    }

    // Find the maximum value in the data for scaling
    double maxValue = data.reduce((curr, next) => curr > next ? curr : next);
    if (maxValue == 0) maxValue = 1; // Prevent division by zero

    double angle = 0;
    double angleIncrement = 360 / data.length;

    // Calculate maximum safe amplitude that won't exceed canvas bounds
    // This ensures bars won't extend beyond the smaller dimension of the canvas
    double maxAmplitude = min(
        (size.width / 2 - radius) * 0.8, // 80% of available width space
        (size.height / 2 - radius) * 0.8 // 80% of available height space
        );

    for (int i = 0; i < data.length; i++) {
      // Scale the value relative to the maximum value and the safe amplitude
      double normalizedValue = data[i] / maxValue;
      double barHeight = normalizedValue * maxAmplitude;

      // Calculate points for this bar
      double angleRad = angle * pi / 180.0;
      double cosAngle = cos(angleRad);
      double sinAngle = sin(angleRad);

      // Start point (on the base circle)
      points![i * 4] = center.dx + radius * cosAngle;
      points![i * 4 + 1] = center.dy + radius * sinAngle;

      // End point (extended by bar height)
      points![i * 4 + 2] = center.dx + (radius + barHeight) * cosAngle;
      points![i * 4 + 3] = center.dy + (radius + barHeight) * sinAngle;

      angle += angleIncrement;
    }

    canvas.drawRawPoints(PointMode.lines, points!, wavePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
