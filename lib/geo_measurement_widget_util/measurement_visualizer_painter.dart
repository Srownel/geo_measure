import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:multi_sensor_app/geo_measurement_class.dart';

class MeasurementVisualizerPainter extends CustomPainter {
  final double? bearing;
  final double? dipAngle;
  final DipDirection? dipDirection;
  final Color color;

  MeasurementVisualizerPainter({
    required this.bearing,
    required this.dipAngle,
    required this.dipDirection,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Don't paint if we don't have data
    if (bearing == null || dipAngle == null || dipDirection == null || dipDirection == DipDirection.blank) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Convert bearing to radians (0° = North = up, clockwise)
    // In canvas coordinates: 0° points right, so we need to rotate
    final bearingRadians = (bearing! - 90) * math.pi / 180;
    final dipRadians = dipAngle! * math.pi / 180;

    // Check if dipAngle is nearly vertical (>89.5°)
    final isNearlyVertical = dipAngle! > 89.5;

    if (isNearlyVertical) {
      // Draw bearing line as two segments with gap in center
      final gapSize = 5.0;
      final bearingDir = Offset(math.cos(bearingRadians), math.sin(bearingRadians));

      // First segment (from edge to near center)
      final start1 = center - bearingDir * radius;
      final end1 = center - bearingDir * gapSize;
      canvas.drawLine(start1, end1, paint);

      // Second segment (from near center to other edge)
      final start2 = center + bearingDir * gapSize;
      final end2 = center + bearingDir * radius;
      canvas.drawLine(start2, end2, paint);

      // Draw center point
      canvas.drawCircle(center, 2.5, fillPaint);
    } else {
      // Draw full bearing line through circle
      final bearingDir = Offset(math.cos(bearingRadians), math.sin(bearingRadians));
      final lineStart = center - bearingDir * radius;
      final lineEnd = center + bearingDir * radius;
      canvas.drawLine(lineStart, lineEnd, paint);

      // Calculate dip
      // Length: max (radius) at dipAngle=0, min (0) at dipAngle=90
      final dipLineLength = radius * math.sin(dipRadians + math.pi/2);

      // Determine arrow direction based on dipDirection
      double dipLineAngle;
      switch (dipDirection!) {
        case DipDirection.east:
        // Perpendicular to bearing, to the right
          dipLineAngle = bearingRadians + ((bearing! < 90) ? math.pi / 2 : -math.pi / 2);
          break;
        case DipDirection.west:
        // Perpendicular to bearing, to the left
          dipLineAngle = bearingRadians + ((bearing! > 90) ? math.pi / 2 : -math.pi / 2);
          break;
        case DipDirection.north:
        // Straight up
          dipLineAngle = -math.pi / 2;
          break;
        case DipDirection.south:
        // Straight down
          dipLineAngle = math.pi / 2;
          break;
        case DipDirection.blank:
        // Shouldn't ever happen since we return early for null or blank value
          dipLineAngle = -math.pi / 2;
          break;
      }

      // Draw dip line
      final dipLineDir = Offset(math.cos(dipLineAngle), math.sin(dipLineAngle));
      final dipLineEnd = center + dipLineDir * (dipLineLength + 1);

      canvas.drawLine(center, dipLineEnd, paint..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(MeasurementVisualizerPainter oldDelegate) {
    return oldDelegate.bearing != bearing ||
        oldDelegate.dipAngle != dipAngle ||
        oldDelegate.dipDirection != dipDirection ||
        oldDelegate.color != color;
  }
}