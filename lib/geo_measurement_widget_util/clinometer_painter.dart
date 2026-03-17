import 'package:flutter/material.dart';
import 'dart:math';

// *** AVIATOR-STYLE PITCH DISPLAY - FOR PHONE FLAT MEASURING MODE *** //

class PitchPainter extends CustomPainter {
  final double pitch; // angle in degrees
  final bool isDark;

  PitchPainter(this.pitch, {this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final fgColor = isDark ? Colors.white : Colors.black;
    final accentColor = Colors.blue.shade400;

    // Pixels per degree of pitch — controls how fast lines scroll
    const double pixelsPerDegree = 8.0;

    // How many degrees to draw above and below center
    const double degreesVisible = 45.0;

    // Fade radius as fraction of half-height
    final double fadeStart = size.height * 0.25;
    final double fadeEnd = size.height * 0.5;

    _drawGraduationLines(
      canvas, size, center, fgColor,
      pixelsPerDegree, degreesVisible, fadeStart, fadeEnd,
    );

    _drawCrosshair(canvas, center, accentColor);
  }

  void _drawGraduationLines(
      Canvas canvas,
      Size size,
      Offset center,
      Color fgColor,
      double pixelsPerDegree,
      double degreesVisible,
      double fadeStart,
      double fadeEnd,
      ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Offset in pixels driven by current pitch
    final double pitchOffset = pitch * pixelsPerDegree;

    // Find the first degree mark above the visible area
    final int firstDegree = (pitch - degreesVisible).floor();
    final int lastDegree = (pitch + degreesVisible).ceil();

    for (int deg = firstDegree; deg <= lastDegree; deg++) {
      final bool isMajor = deg % 10 == 0;
      final bool isMinor = deg % 5 == 0 && !isMajor;

      if (!isMajor && !isMinor) continue;

      // Y position of this graduation line on screen
      final double y = center.dy - (deg * pixelsPerDegree - pitchOffset);

      // Skip if outside canvas
      if (y < 0 || y > size.height) continue;

      // Compute opacity based on distance from center (fade effect)
      final double distFromCenter = (y - center.dy).abs();
      final double opacity;
      if (distFromCenter <= fadeStart) {
        opacity = 1.0;
      } else if (distFromCenter >= fadeEnd) {
        opacity = 0.0;
      } else {
        opacity = 1.0 - (distFromCenter - fadeStart) / (fadeEnd - fadeStart);
      }

      if (opacity <= 0) continue;

      // Line width varies by importance
      final double lineWidth = isMajor ? size.width * 0.5 : size.width * 0.3;
      final double strokeWidth = isMajor ? 2.0 : 1.5;

      final linePaint = Paint()
        ..color = fgColor.withOpacity(isMajor ? opacity * 0.8 : opacity * 0.4)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx - lineWidth / 2, y),
        Offset(center.dx + lineWidth / 2, y),
        linePaint,
      );

      // Draw degree labels on major ticks
      if (isMajor) {
        textPainter.text = TextSpan(
          text: '${deg.abs()}°',
          style: TextStyle(
            color: fgColor.withOpacity(opacity * 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();

        // Label on both sides of the line
        final double labelOffset = lineWidth / 2 + 10;
        final double labelY = y - textPainter.height / 2;

        textPainter.paint(canvas, Offset(center.dx - labelOffset - textPainter.width, labelY));
        textPainter.paint(canvas, Offset(center.dx + labelOffset, labelY));
      }
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center, Color accentColor) {
    const double armLength = 30.0;
    const double gap = 10.0;
    const double strokeWidth = 3.0;

    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Horizontal arms
    canvas.drawLine(Offset(center.dx - armLength - gap, center.dy),
        Offset(center.dx - gap, center.dy), paint);
    canvas.drawLine(Offset(center.dx + gap, center.dy),
        Offset(center.dx + armLength + gap, center.dy), paint);

    // Vertical arms
    canvas.drawLine(Offset(center.dx, center.dy - armLength - gap),
        Offset(center.dx, center.dy - gap), paint);
    canvas.drawLine(Offset(center.dx, center.dy + gap),
        Offset(center.dx, center.dy + armLength + gap), paint);

    // Small center dot
    canvas.drawCircle(center, 4, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(PitchPainter oldDelegate) {
    return oldDelegate.pitch != pitch || oldDelegate.isDark != isDark;
  }
}


// *** CLINOMETER-STYLE ANGLE DISPLAY - FOR PHONE RIDGE MEASURING MODE *** //

class ClinometerPainter extends CustomPainter {
  final double inclination; // Tilt angle in radians
  final bool isDark;

  ClinometerPainter(
      this.inclination,
      {this.isDark = false}
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Color scheme matching the compass
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

    // Draw graduated circle (fixed to screen/phone)
    _drawGraduations(canvas, center, radius - 15, fgColor);

    // Draw horizontal bar (counter-rotates to stay level with real world)
    _drawHorizontalBar(canvas, center, radius - 15);

    // Draw inclination bar
    _drawInclinationBar(canvas, center, radius - 15, accentColor, fgColor);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerDotPaint);

    final centerDotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 6, centerDotBorderPaint);
    
  }

  void _drawGraduations(Canvas canvas, Offset center, double radius, Color fgColor) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw tick marks every 5 degrees, labels every 10
    for (int angle = 0; angle < 360; angle += 5) {
      final isMajor = angle % 10 == 0;
      final angleRadians = angle * pi / 180;

      final tickLength = isMajor ? 15.0 : 8.0;
      final tickWidth = isMajor ? 2.5 : 1.5;

      final outerX = center.dx + radius * cos(angleRadians - pi / 2);
      final outerY = center.dy + radius * sin(angleRadians - pi / 2);
      final innerX = center.dx + (radius - tickLength) * cos(angleRadians - pi / 2);
      final innerY = center.dy + (radius - tickLength) * sin(angleRadians - pi / 2);

      final tickPaint = Paint()
        ..color = fgColor.withOpacity(isMajor ? 0.8 : 0.4)
        ..strokeWidth = tickWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        tickPaint,
      );

      // Draw labels at cardinal points and 45° intervals
      if (angle % 45 == 0) {
        final labelRadius = radius - 35;
        final labelX = center.dx + labelRadius * cos(angleRadians - pi / 2);
        final labelY = center.dy + labelRadius * sin(angleRadians - pi / 2);

        // Calculate the angle to display (0° at top, 90° at sides)
        int displayAngle;
        if (angle <= 90) {
          displayAngle = angle;
        } else if (angle <= 180) {
          displayAngle = 180 - angle;
        } else if (angle <= 270) {
          displayAngle = angle - 180;
        } else {
          displayAngle = 360 - angle;
        }

        textPainter.text = TextSpan(
          text: '$displayAngle°',
          style: TextStyle(
            color: fgColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }
    }
  }
  
  // Bar parallel to the phone
  void _drawInclinationBar(Canvas canvas, Offset center, double radius, Color accentColor, Color fgColor) {
    // Draw the horizontal bar
    final barPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      barPaint,
    );

    // Draw end caps on the bar
    final capPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx, center.dy - radius), 6, capPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + radius), 6, capPaint);

    final capBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(center.dx, center.dy - radius), 6, capBorderPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + radius), 6, capBorderPaint);
  }

  // Bar parallel to the horizontal plane
  void _drawHorizontalBar(Canvas canvas, Offset center, double radius) {
    // Counter-rotate the bar to keep it horizontal in real world
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-inclination);
    canvas.translate(-center.dx, -center.dy);

    // Draw the horizontal bar
    final barPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      barPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(ClinometerPainter oldDelegate) {
    return oldDelegate.inclination != inclination ||
        oldDelegate.isDark != isDark;
  }
}