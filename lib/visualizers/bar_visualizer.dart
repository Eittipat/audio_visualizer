// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'package:flutter/material.dart';
import 'dart:math' as math;

class _BarVisualizerPainter extends CustomPainter {
  final List<int> data;
  final Color color;
  final Paint wavePaint;
  final int gap;

  _BarVisualizerPainter({
    required this.data,
    required this.color,
    this.gap = 2,
  }) : wavePaint = Paint()
          ..color = color.withOpacity(1.0)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final density = data.length;
    int maxValue = data.reduce(math.max);
    double barWidth = size.width / density;
    double div = data.length / density;
    wavePaint.strokeWidth = barWidth - gap;
    for (int i = 0; i < density; i++) {
      int bytePosition = (i * div).ceil();
      double ratio = maxValue > 0 ? data[bytePosition] / maxValue : 0.0;
      double top = ratio * size.height;
      double barX = (i * barWidth) + (barWidth / 2);
      canvas.drawLine(
        Offset(barX, size.height),
        Offset(barX, size.height - top),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarVisualizerPainter oldDelegate) {
    return true;
  }
}

class BarVisualizer extends StatelessWidget {
  const BarVisualizer({
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
        painter: _BarVisualizerPainter(
          data: input,
          gap: gap,
          color: color,
        ),
      ),
    );
  }
}
