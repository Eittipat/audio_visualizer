import 'dart:math';
import 'package:flutter/material.dart';

class RainbowBlockVisualizer extends StatelessWidget {
  final List<int> data;
  final int maxSample;
  final double blockHeight;
  final double blockSpacing;

  const RainbowBlockVisualizer({
    super.key,
    this.data = const [],
    this.maxSample = 32,
    this.blockHeight = 8,
    this.blockSpacing = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AudioBlockPainter(
        data: data,
        blockHeight: blockHeight,
        blockSpacing: blockSpacing,
        maxSample: maxSample,
      ),
      // Set size to match parent
      size: Size.infinite,
    );
  }
}

class AudioBlockPainter extends CustomPainter {
  final List<int> data;
  final double blockHeight;
  final double blockSpacing;
  final int maxSample;

  AudioBlockPainter({
    required this.data,
    required this.blockHeight,
    required this.blockSpacing,
    required this.maxSample,
  });

  int get dataLength => min(maxSample, data.length);

  // Convert audio value (0-255) to number of blocks (1-32)
  int getNumBlocks(int audioValue) {
    return (audioValue / 255 * 32).round().clamp(1, 32);
  }

  Color getBlockColor(int barIndex, int blockIndex, int maxBlocks) {
    final hue = (barIndex / dataLength) * 360;
    const lightnessRange = 0.1;
    final lightness = 0.6 +
        (blockIndex / maxBlocks * lightnessRange).clamp(0.0, lightnessRange);
    return HSLColor.fromAHSL(1, hue, 0.8, lightness).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / dataLength;

    for (int i = 0; i < dataLength; i++) {
      final numBlocks = getNumBlocks(data[i]);
      final barX = i * barWidth;

      for (int j = 0; j < numBlocks; j++) {
        final paint = Paint()..color = getBlockColor(i, j, numBlocks);

        // Calculate block position (from bottom up)
        final blockY = size.height - ((j + 1) * (blockHeight + blockSpacing));

        // Draw main block rectangle
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barX + blockSpacing / 2,
            blockY,
            barWidth - blockSpacing,
            blockHeight,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, paint);

        // Add highlight effect (top-left)
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.top),
          highlightPaint,
        );
        canvas.drawLine(
          Offset(rect.left, rect.top),
          Offset(rect.left, rect.bottom),
          highlightPaint,
        );

        // Add shadow effect (bottom-right)
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(rect.right, rect.top),
          Offset(rect.right, rect.bottom),
          shadowPaint,
        );
        canvas.drawLine(
          Offset(rect.left, rect.bottom),
          Offset(rect.right, rect.bottom),
          shadowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(AudioBlockPainter oldDelegate) {
    return data != oldDelegate.data ||
        blockHeight != oldDelegate.blockHeight ||
        blockSpacing != oldDelegate.blockSpacing;
  }
}
