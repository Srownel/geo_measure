import 'package:flutter/material.dart';
import 'dart:math';

import 'package:multi_sensor_app/geo_measurement_class.dart';

import 'package:multi_sensor_app/translation_util/translation_service.dart';

// *** PAINTER *** //

/// A stripped-down compass that visualises a slope's bearing on a fixed rose
/// (N always up).  Adds:
///   • hemisphere tint — blue wash on the selected E or W side
///   • slope line     — the strike line through the compass centre
///   • normal arrow   — bold blue arrow toward the confirmed E or W
///
/// Deliberately omits the crosshair and bubble-level indicators present in
/// [CompassPainter]: the phone does not need to be held flat at this step.
class SlopeBearingPainter extends CustomPainter {
  final double? bearing; // in degrees
  final DipDirection selectedDirection;
  final bool isDark;
  final bool isLeftHanded;

  SlopeBearingPainter({
    required this.bearing,
    required this.selectedDirection,
    this.isDark = false,
    this.isLeftHanded = false,
  });

  // ── Colour helpers ── //

  Color get _bgColor => isDark ? Colors.grey.shade900 : Colors.white;
  Color get _fgColor => isDark ? Colors.white : Colors.black;
  Color get _accentColor => Colors.blue.shade400;

  // ── Coordinate helpers ── //

  /// Converts a geological bearing (0 = N, clockwise) to a Flutter canvas
  /// angle (0 = East / rightward, counter-clockwise in maths space but
  /// Flutter's Y-axis is flipped so effectively clockwise visually).
  ///
  ///   canvas_angle = (bearing − 90°) × π/180
  double _bearingToCanvas(double deg) => (deg - 90) * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    _drawBackground(canvas, center, radius);
    _drawHemisphereTint(canvas, center, radius);
    _drawOuterRing(canvas, center, radius);
    _drawInnerRing(canvas, center, radius);
    _drawTickMarks(canvas, center, radius);
    _drawCardinalLabels(canvas, center, radius);
    _drawSlopeLine(canvas, center, radius);
    _drawNormalArrow(canvas, center, radius);
    _drawCenterDot(canvas, center);
  }

  // ── Background ── //

  void _drawBackground(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = _bgColor
        ..style = PaintingStyle.fill,
    );
  }

  // ── Hemisphere tint ── //

  /// Fills the East, West, North or South semicircle with a translucent blue wash.
  void _drawHemisphereTint(Canvas canvas, Offset center, double radius) {
    if (bearing == null || selectedDirection == DipDirection.blank) return;

    final tintPaint = Paint()
      ..color = _accentColor.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCircle(center: center, radius: radius - 11);

    // East  → right half: arc from −π/2 (N) sweeping π clockwise to π/2 (S)
    // West  → left half:  arc from  π/2 (S) sweeping π clockwise to −π/2 (N)
    final double startAngle =
      switch (selectedDirection) {
        DipDirection.east => -pi / 2,
        DipDirection.west => pi / 2,
        DipDirection.north => -pi,
        DipDirection.south => 0,
        DipDirection.blank => 0, // Doesn't matter, unreachable
      };

    canvas.drawArc(rect, startAngle, pi, true, tintPaint);

    // Subtle dividing line (N–S axis) to visually anchor the two sides
    final dividerPaint = Paint()
      ..color = _accentColor.withOpacity(0.25)
      ..strokeWidth = 1.5;
    if (selectedDirection == DipDirection.south || selectedDirection == DipDirection.north) {
      canvas.drawLine(
        Offset(center.dx - radius + 12, center.dy),
        Offset(center.dx + radius - 12, center.dy),
        dividerPaint,
      );
    } else {
      canvas.drawLine(
        Offset(center.dx, center.dy - radius + 12),
        Offset(center.dx, center.dy + radius - 12),
        dividerPaint,
      );
    }
  }

  // ── Rings ── //

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..color = _accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }

  void _drawInnerRing(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius - 30,
      Paint()
        ..color = _fgColor.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Tick marks ── //

  /// Draws major ticks every 30° and minor ticks every 10°.
  /// N is always at the top (no rotation).
  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (int deg = 0; deg < 360; deg += 10) {
      final isMain = deg % 30 == 0;
      paint
        ..color = _fgColor.withOpacity(isMain ? 0.8 : 0.4)
        ..strokeWidth = isMain ? 3 : 1.5;

      final angle = _bearingToCanvas(deg.toDouble());
      final outerR = radius - 25;
      final innerR = radius - (isMain ? 40 : 35);

      canvas.drawLine(
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        paint,
      );
    }
  }

  // ── Cardinal labels ── //

  void _drawCardinalLabels(Canvas canvas, Offset center, double radius) {
    const dirs = ['N', 'E', 'S', 'W'];
    const bearings = [0.0, 90.0, 180.0, 270.0];

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < dirs.length; i++) {
      final angle = _bearingToCanvas(bearings[i]);
      final labelR = radius - 60;
      final x = center.dx + labelR * cos(angle);
      final y = center.dy + labelR * sin(angle);

      painter.text = TextSpan(
        text: dirs[i],
        style: TextStyle(
          color: dirs[i] == 'N' ? Colors.red : _fgColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(x - painter.width / 2, y - painter.height / 2),
      );
    }
  }

  // ── Slope line (strike) ── //

  /// The slope's strike runs towards the bearing.
  void _drawSlopeLine(Canvas canvas, Offset center, double radius) {
    if (bearing == null) return;

    final strikeAngle = _bearingToCanvas(bearing!); // canvas radians for strike
    final lineR = radius - 19;

    final dx = cos(strikeAngle);
    final dy = sin(strikeAngle);

    final p1 = Offset(center.dx + lineR * dx, center.dy + lineR * dy);
    final p2 = Offset(center.dx - lineR * dx, center.dy - lineR * dy);

    // Main strike line
    final linePaint = Paint()
      ..color = _fgColor.withOpacity(0.75)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, linePaint);

    // Small perpendicular end-caps (geological convention)
    final capLen = 8.0;
    final perpDx = -dy; // perpendicular direction
    final perpDy = dx;
    final capPaint = Paint()
      ..color = _fgColor.withOpacity(0.55)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (final endPoint in [p1, p2]) {
      canvas.drawLine(
        Offset(endPoint.dx - capLen * perpDx, endPoint.dy - capLen * perpDy),
        Offset(endPoint.dx + capLen * perpDx, endPoint.dy + capLen * perpDy),
        capPaint,
      );
    }
  }

  // ── Normal arrow ── //

  /// Draws a solid blue arrow representing the dip, perpendicular to the bearing.
  /// By default and without user input, perpendicular is assumed to mean 90° clockwise.
  void _drawNormalArrow(Canvas canvas, Offset center, double radius) {
    if (bearing == null) return;
    bool forceEastWest = selectedDirection == DipDirection.east || selectedDirection == DipDirection.west;
    final arrowAngle = // canvas radians, perpendicular to the bearing
      ( selectedDirection == getOppositeDirection(suggestedDirection(bearing, forceEastWest, isLeftHanded)) ) // Check if the user swapped the normal direction manually.
          ? (isLeftHanded) ? _bearingToCanvas(bearing!) + pi/2 : _bearingToCanvas(bearing!) - pi/2
          : (isLeftHanded) ? _bearingToCanvas(bearing!) - pi/2 : _bearingToCanvas(bearing!) + pi/2;

    final arrowLength = (radius - 35) * 0.62;

    final tipX = center.dx + arrowLength * cos(arrowAngle);
    final tipY = center.dy + arrowLength * sin(arrowAngle);
    final tip = Offset(tipX, tipY);

    // Shaft
    final shaftPaint = Paint()
      ..color = _accentColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, shaftPaint);

    // Arrowhead
    const headLen = 14.0;
    const headWidth = 8.0;
    final perpAngle = arrowAngle + pi / 2;

    final head = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(
        tipX - headLen * cos(arrowAngle) + headWidth * cos(perpAngle),
        tipY - headLen * sin(arrowAngle) + headWidth * sin(perpAngle),
      )
      ..lineTo(
        tipX - headLen * cos(arrowAngle) - headWidth * cos(perpAngle),
        tipY - headLen * sin(arrowAngle) - headWidth * sin(perpAngle),
      )
      ..close();

    canvas.drawPath(
      head,
      Paint()
        ..color = _accentColor
        ..style = PaintingStyle.fill,
    );
  }

  // ── Centre dot ── //

  void _drawCenterDot(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 6, Paint()..color = Colors.red);
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(SlopeBearingPainter old) =>
      old.bearing != bearing ||
          old.selectedDirection != selectedDirection ||
          old.isDark != isDark;
}


class DipDirectionSelector extends StatelessWidget {
  // True if we need to display additional options for North-South orientations, in the case of an East-West bearing strike.
  final bool is_E_W_EdgeCase;
  final DipDirection currentSelection;

  final Color accent;
  final bool isDark;
  final void Function(DipDirection) onSelect; // Function to call when selecting a direction.
  final void Function(bool) onForceE_W; // Function to call when swapping between a North/South selection and a East/West selection.

  const DipDirectionSelector({
    super.key,
    required this.currentSelection,
    required this.accent,
    required this.isDark,
    required this.is_E_W_EdgeCase,
    required this.onSelect,
    required this.onForceE_W,
  });

  @override
  Widget build(BuildContext context) {
    // Only meaningful if is_E_W_EdgeCase = true. isSwappingNorthSouth = true if we are swapping between north and south orientation, false if swapping between east and west.
    bool isSwappingNorthSouth = (currentSelection == DipDirection.north || currentSelection == DipDirection.south);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (is_E_W_EdgeCase) ...[
          Text(
            'painter_strike_warning'.tr, // 'Strike is roughly E–W. Select the dip side:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
        ],

        Row(
          children: [
            Expanded(
              child: _DirectionSwapButton(
                label: isSwappingNorthSouth ? 'painter_SOUTH'.tr : 'painter_WEST'.tr, // 'SOUTH' : 'WEST',
                icon: isSwappingNorthSouth ? Icons.arrow_downward : Icons.arrow_back,
                accent: accent,
                isDark: isDark,
                onTap: () => isSwappingNorthSouth ? onSelect(DipDirection.south) : onSelect(DipDirection.west),
              ),
            ),
            const SizedBox(width: 12),

            if (is_E_W_EdgeCase) ...[
              Expanded(
                child: _DirectionSwapButton(
                  label: isSwappingNorthSouth ? 'painter_EAST_WEST'.tr : 'painter_NORTH_SOUTH'.tr, // 'EAST/WEST' : 'NORTH/SOUTH',
                  icon: Icons.swap_vert_circle,
                  accent: accent,
                  isDark: isDark,
                  onTap: () {
                    onForceE_W(isSwappingNorthSouth);
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],

            Expanded(
              child: _DirectionSwapButton(
                label: isSwappingNorthSouth ? 'painter_NORTH'.tr : 'painter_EAST'.tr, // 'NORTH' : 'EAST',
                icon: isSwappingNorthSouth ? Icons.arrow_upward : Icons.arrow_forward,
                accent: accent,
                isDark: isDark,
                onTap: () => isSwappingNorthSouth ? onSelect(DipDirection.north) : onSelect(DipDirection.east),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DirectionSwapButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _DirectionSwapButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: accent),
      label: Text(label,
          style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: accent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: accent.withOpacity(0.06),
      ),
    );
  }
}

// *** DATA & UTILS *** //

/// Computes the suggested dip direction from a bearing (0–360°).
/// Default suggested direction is counterclockwise from bearing, clockwise if left handed.
DipDirection suggestedDirection(double? bearing, bool forceEastWest, bool isLeftHanded) {
  if (bearing == null) return DipDirection.blank;

  final b = (isLeftHanded) ? (bearing - 90) % 360 : (bearing + 90) % 360;

  if (!forceEastWest) {
    if (b < 1 || b > 359) return DipDirection.north;
    if (b > 179 && b < 181) return DipDirection.south;
  }
  return (b > 0 && b <= 180) ? DipDirection.east : DipDirection.west;
}

DipDirection getOppositeDirection(DipDirection dir) {
  switch (dir) {
    case DipDirection.east:
      return DipDirection.west;
    case DipDirection.west:
      return DipDirection.east;
    case DipDirection.north:
      return DipDirection.south;
    case DipDirection.south:
      return DipDirection.north;
    case DipDirection.blank:
      return DipDirection.blank;
  }
}