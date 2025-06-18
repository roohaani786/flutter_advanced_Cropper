// Enhanced custom painter for crop overlay

import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final bool isDragging;

  CropOverlayPainter({required this.cropRect, this.isDragging = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw overlay outside crop area
    final overlayOpacity = isDragging ? 0.7 : 0.5;
    final paint =
        Paint()
          ..color = Colors.black.withAlpha((overlayOpacity * 255).round())
          ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()..addRect(cropRect),
      ),
      paint,
    );

    // Draw crop border
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = isDragging ? 3.0 : 2.0;

    canvas.drawRect(cropRect, borderPaint);

    // Draw grid lines (more subtle when dragging)
    final gridOpacity = isDragging ? 0.3 : 0.5;
    final gridPaint =
        Paint()
          ..color = Colors.white.withAlpha((gridOpacity * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Rule of thirds grid
    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdWidth * i, cropRect.top),
        Offset(cropRect.left + thirdWidth * i, cropRect.bottom),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdHeight * i),
        Offset(cropRect.right, cropRect.top + thirdHeight * i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
