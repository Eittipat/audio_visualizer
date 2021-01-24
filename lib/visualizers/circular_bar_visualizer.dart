// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui';
//
// import 'package:flutter/rendering.dart';
// import 'package:meta/meta.dart';
// import 'package:vector_math/vector_math_64.dart';
//
// class CircularBarVisualizer extends CustomPainter {
//   final List<int> waveData;
//   Float32List points;
//   final Color color;
//   final Paint wavePaint;
//   final int density;
//
//   final int gap;
//
//   double radius = -1;
//
//   CircularBarVisualizer({@required this.waveData, @required this.color, this.density = 100, this.gap = 2})
//       : wavePaint = new Paint()
//           ..color = color.withOpacity(1.0)
//           ..style = PaintingStyle.fill,
//         assert(waveData != null),
//         assert(color != null);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final width = size.width;
//     final height = size.height;
//
//     if (radius == -1) {
//       radius = height < width ? height : width;
//       radius = (radius / 4);
//       double circumference = 2 * pi * radius;
//       wavePaint.strokeWidth = circumference / density;
//       wavePaint.style = PaintingStyle.stroke;
//     }
//     canvas.drawCircle(new Offset(width / 2, height / 2), radius.toDouble(), wavePaint);
//     if (waveData != null) {
//       if (points == null || points.length < waveData.length * 4) {
//         points = new Float32List(waveData.length * 4);
//       }
//       double angle = 0;
//
//       for (int i = 0; i < density; i++, angle += 360 / density) {
//         int x = (i * waveData.length / density).ceil();
//         int t = ((((-(waveData[x]).abs() + 128)) * (height / 4) ~/ 128).abs()*0.5).round();
//
//         points[i * 4] = width / 2 + radius * cos(radians(angle));
//         points[i * 4 + 1] = height / 2 + radius * sin(radians(angle));
//         points[i * 4 + 2] = width / 2 + (radius + t) * cos(radians(angle));
//         points[i * 4 + 3] = height / 2 + (radius + t) * sin(radians(angle));
//       }
//
//       canvas.drawRawPoints(PointMode.lines, points, wavePaint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }
