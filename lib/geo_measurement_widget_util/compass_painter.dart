import 'package:flutter/material.dart';
import 'dart:math';

import 'package:multi_sensor_app/settings_provider.dart';

class CompassPainter extends CustomPainter {
  final double heading;
  final double pitch;  // Tilt forward/backward in radians
  final double roll;   // Tilt left/right in radians
  final bool isDark;
  final LevelIndicatorStyle levelIndicatorStyle; // bubble level or crosshair

  CompassPainter(
      this.heading,
      this.pitch,
      this.roll,
      {this.isDark = false,
      this.levelIndicatorStyle = LevelIndicatorStyle.BUBBLE}
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Color scheme based on theme
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;
    final accentColor = Colors.blue.shade400;

    // Draw background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 5, bgPaint);

    // Draw outer ring
    final outerRingPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius - 10, outerRingPaint);

    // Draw inner circle border
    final innerRingPaint = Paint()
      ..color = fgColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 30, innerRingPaint);

    // Save canvas state before rotation
    canvas.save();

    // Rotate canvas based on heading
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * pi / 180);
    canvas.translate(-center.dx, -center.dy);

    // Draw tick marks
    _drawTickMarks(canvas, center, radius, fgColor);

    // Draw cardinal directions
    _drawCardinalMarkers(canvas, center, radius, fgColor);

    // Restore canvas
    canvas.restore();

    // Draw north indicator (fixed, doesn't rotate)
    _drawNorthIndicator(canvas, center, radius);

    if (levelIndicatorStyle == LevelIndicatorStyle.CROSSHAIR) {
      // Draw center dot
      final centerDotPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 6, centerDotPaint);
    }

    // Draw white border around center dot
    final centerDotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 6, centerDotBorderPaint);

    // Draw level indicator (bubble level, or crosshair style)
    if (levelIndicatorStyle == LevelIndicatorStyle.BUBBLE) {
      _drawBubbleLevelIndicator(canvas, center, radius, Colors.lime);
    } else if (levelIndicatorStyle == LevelIndicatorStyle.CROSSHAIR) {
      _drawCrosshairIndicator(canvas, center, radius, fgColor);
    }

  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius,
      Color color) {
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 10) {
      final angle = i * pi / 180;
      final isMainTick = i % 30 == 0;
      final tickLength = isMainTick ? 15.0 : 10.0;
      final tickWidth = isMainTick ? 3.0 : 1.5;

      tickPaint.strokeWidth = tickWidth;
      tickPaint.color = color.withOpacity(isMainTick ? 0.8 : 0.4);

      final startX = center.dx + (radius - 25) * sin(angle);
      final startY = center.dy - (radius - 25) * cos(angle);
      final endX = center.dx + (radius - 25 - tickLength) * sin(angle);
      final endY = center.dy - (radius - 25 - tickLength) * cos(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }
  }

  void _drawCardinalMarkers(Canvas canvas, Offset center, double radius,
      Color color) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * pi / 180;
      final x = center.dx + (radius - 60) * sin(angle);
      final y = center.dy - (radius - 60) * cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directions[i] == 'N' ? Colors.red : color,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawNorthIndicator(Canvas canvas, Offset center, double radius) {
    // Draw red arrow pointing to current heading direction
    final needlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.moveTo(center.dx, center.dy - radius + 35); // Tip
    path.lineTo(center.dx - 12, center.dy - radius + 65); // Left
    path.lineTo(center.dx, center.dy - radius + 60); // Center notch
    path.lineTo(center.dx + 12, center.dy - radius + 65); // Right
    path.close();

    // Draw shadow
    canvas.drawPath(path, shadowPaint);

    // Draw arrow
    canvas.drawPath(path, needlePaint);

    // Draw white border on arrow
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

// *** PITCH AND ROLL INDICATORS *** //

  //* BUBBLE LEVEL-STYLE VISUALIZATION FOR PITCH AND ROLL *//

  void _drawBubbleLevelIndicator(Canvas canvas, Offset center, double radius, Color fgColor) {
    final containerRadius = 35.0;
    final containerThickness = 3.0;

    final bubbleRadius = 10.0;
    final bubbleThickness = 1.0;

    final maxOffsetRadians = 0.785; // 45 degrees, in radians

    // DRAW CONTAINER

    // Draw container background
    final rect = Rect.fromCircle(
      center: Offset(center.dx - containerRadius/2, center.dy - containerRadius),
      radius: containerRadius * 2,
    );

    final containerBackgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFBFFF66).withOpacity(0.7), // lighter version
          const Color(0xFF7CFC00).withOpacity(0.6), // middle
          const Color(0xFF4CAF00).withOpacity(0.8), // darker edge
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);

    canvas.drawCircle(
      center,
      containerRadius,
      containerBackgroundPaint,
    );

    // Draw container outer ring
    final containerPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = containerThickness;

    canvas.drawCircle(
      center,
      containerRadius,
      containerPaint,
    );

    // Draw container inner indicators

    final innerIndicatorPaint = Paint()
    ..color = Colors.black.withOpacity(0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = bubbleThickness;

    canvas.drawLine(
      Offset(center.dx - containerRadius, center.dy),
      Offset(center.dx + containerRadius, center.dy),
      innerIndicatorPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - containerRadius),
      Offset(center.dx, center.dy + containerRadius),
      innerIndicatorPaint,
    );
    canvas.drawCircle(
      center,
      bubbleRadius + 1,
      innerIndicatorPaint,
    );

    // DRAW BUBBLE

    // Calculate moving bubble position based on pitch and roll
    final maxOffset = containerRadius - bubbleRadius;

    final offset = Offset(
      (roll / maxOffsetRadians) * maxOffset,
      (pitch / maxOffsetRadians) * maxOffset,
    );

    final distance = offset.distance;

    final clampedOffset = distance > maxOffset
        ? offset / distance * maxOffset
        : offset;

    final movingCenter = center + clampedOffset;

    // Draw moving bubble
    final bubbleinsidePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      movingCenter,
      bubbleRadius,
      bubbleinsidePaint,
    );

    final bubbleOutlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bubbleThickness;

    canvas.drawCircle(
      movingCenter,
      bubbleRadius,
      bubbleOutlinePaint,
    );
  }

  //* CROSSHAIR-STYLE VISUALIZATION FOR PITCH AND ROLL *//

  void _drawCrosshairIndicator(Canvas canvas, Offset center, double radius, Color fgColor) {
    final crosshairSize = 40.0;
    final crosshairThickness = 3.0;

    final maxOffsetRadians = 0.785; // 45 degrees, in radians

    // Draw fixed reference crosshair (green)
    final fixedPaint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = crosshairThickness
      ..strokeCap = StrokeCap.round;

    // Horizontal line of fixed crosshair
    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx - 10, center.dy),
      fixedPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 10, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      fixedPaint,
    );

    // Vertical line of fixed crosshair
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy - 10),
      fixedPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 10),
      Offset(center.dx, center.dy + crosshairSize),
      fixedPaint,
    );

    // Calculate moving crosshair position based on pitch and roll
    final maxOffset = radius * 0.4; // Maximum displacement
    final rollOffset = min((roll / maxOffsetRadians), 1) * maxOffset;
    final pitchOffset = min((pitch / maxOffsetRadians), 1) * maxOffset;

    final movingCenter = Offset(
      center.dx + rollOffset,
      center.dy + pitchOffset,
    );

    // Draw moving crosshair (orange/amber)
    final movingPaint = Paint()
      ..color = Colors.orange.withOpacity(0.9)
      ..strokeWidth = crosshairThickness
      ..strokeCap = StrokeCap.round;

    // Horizontal line of moving crosshair
    canvas.drawLine(
      Offset(movingCenter.dx - crosshairSize, movingCenter.dy),
      Offset(movingCenter.dx - 10, movingCenter.dy),
      movingPaint,
    );
    canvas.drawLine(
      Offset(movingCenter.dx + 10, movingCenter.dy),
      Offset(movingCenter.dx + crosshairSize, movingCenter.dy),
      movingPaint,
    );

    // Vertical line of moving crosshair
    canvas.drawLine(
      Offset(movingCenter.dx, movingCenter.dy - crosshairSize),
      Offset(movingCenter.dx, movingCenter.dy - 10),
      movingPaint,
    );
    canvas.drawLine(
      Offset(movingCenter.dx, movingCenter.dy + 10),
      Offset(movingCenter.dx, movingCenter.dy + crosshairSize),
      movingPaint,
    );

    // Draw small circle at moving crosshair center
    canvas.drawCircle(
      movingCenter,
      4,
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }



  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.pitch != pitch ||
        oldDelegate.roll != roll ||
        oldDelegate.isDark != isDark;
  }
}