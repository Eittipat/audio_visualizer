import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BarVisualizer extends CustomPainter {
  final List<double> waveData;
  final Color color;
  final Paint wavePaint;
  final int density;
  final int gap;

  BarVisualizer({required this.waveData, required this.color, this.density = 100, this.gap = 2})
      : wavePaint = new Paint()
          ..color = color.withOpacity(1.0)
          ..style = PaintingStyle.fill,
        assert(waveData != null),
        assert(color != null);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    if (waveData != null) {
      double barWidth = width / density;
      double div = waveData.length / density;
      wavePaint.strokeWidth = barWidth - gap;
      for (int i = 0; i < density; i++) {
        int bytePosition = (i * div).ceil();
        double barX = (i * barWidth) + (barWidth / 2);
        final dy = height * waveData[bytePosition];
        canvas.drawLine(Offset(barX, height), Offset(barX, height - dy), wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
