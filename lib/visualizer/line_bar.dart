library audio_visualizer;

import 'package:flutter/material.dart';

class LineBarVisualizer extends CustomPainter {
  final List<double> waveData;
  final double height;
  final double width;
  final Color color;
  final Paint wavePaint;
  final int density;
  final int gap;

  List<double> points;

  LineBarVisualizer({@required this.waveData, @required this.height, @required this.width, @required this.color, this.density = 100, this.gap = 2})
      : wavePaint = new Paint()
          ..color = color.withOpacity(1.0)
          ..style = PaintingStyle.fill,
        assert(waveData != null),
        assert(height != null),
        assert(width != null),
        assert(color != null);

  @override
  void paint(Canvas canvas, Size size) {
    if (waveData != null) {
      double barWidth = width / density;
      double div = waveData.length / density;
      wavePaint.strokeWidth = barWidth - gap;
      for (int i = 0; i < density; i++) {
        int bytePosition = (i * div).ceil();
        double value = waveData[bytePosition];
        if (value.isNaN) value = 0.0;
        if (value > 1.0) value = 1.0;
        if (value < 0.0) value = 0.0;

        final h2 = height / 2.0;
        double barX = (i * barWidth) + (barWidth / 2);
        //canvas.drawLine(Offset(barX, h2), Offset(barX, h2 - h2 * value), wavePaint);
        //canvas.drawLine(Offset(barX, h2), Offset(barX, height - (h2 - h2 * value)), wavePaint);
        canvas.drawLine(Offset(barX, height), Offset(barX, height - (height * value)), wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
