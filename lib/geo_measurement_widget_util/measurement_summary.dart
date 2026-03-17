import 'package:flutter/material.dart';

import 'package:multi_sensor_app/settings_provider.dart';

import 'package:multi_sensor_app/translation_util/translation_service.dart';

/// Compact card showing the measurement's information.
class MeasurementSummaryCard extends StatelessWidget {
  final double? bearing;
  final double? dipAngle;
  final double? latitude;
  final double? longitude;
  final bool isDark;

  final CoordinatesDisplayFormat coordDisplayFormat;

  const MeasurementSummaryCard({
    super.key,
    this.bearing,
    this.dipAngle,
    this.latitude,
    this.longitude,
    required this.isDark,
    this.coordDisplayFormat = CoordinatesDisplayFormat.DMM,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final labelColor = isDark ? Colors.white38 : Colors.black38;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCell(
              label: 'measureS_BEARING'.tr, // 'BEARING',
              value: (bearing != null) ? '${bearing!.toStringAsFixed(0)}°' : '--',
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            _Divider(isDark: isDark),
            _SummaryCell(
              label: 'measureS_DIP'.tr, // 'DIP',
              value: (dipAngle != null) ? '${dipAngle!.toStringAsFixed(0)}°' : '--',
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            _Divider(isDark: isDark),
            Expanded(
              child: _SummaryCell(
                label: 'measureS_COORD'.tr, // 'COORDINATES',
                value:
                (latitude != null && longitude != null)
                    ? switch (coordDisplayFormat) {
                  CoordinatesDisplayFormat.DD => formatDecimalDegrees(latitude!, longitude!),
                  CoordinatesDisplayFormat.SDD => formatSignedDD(latitude!, longitude!),
                  CoordinatesDisplayFormat.DMM => formatDMM(latitude!, longitude!),
                  CoordinatesDisplayFormat.DMS => formatDMS(latitude!, longitude!),
                }
                    : 'measureS_coord_not_avail'.tr, // 'Coordinates not available',
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDecimalDegrees(double latitude, double longitude,
      {int fractionDigits = 5}) {
    final latHemisphere = latitude >= 0 ? 'N' : 'S';
    final lonHemisphere = longitude >= 0 ? 'E' : 'W';

    final lat = latitude.abs().toStringAsFixed(fractionDigits);
    final lon = longitude.abs().toStringAsFixed(fractionDigits);

    return '$lat° $latHemisphere, $lon° $lonHemisphere';
  }

  String formatSignedDD(double latitude, double longitude,
      {int fractionDigits = 5}) {
    return '${latitude.toStringAsFixed(fractionDigits)}, ${longitude.toStringAsFixed(fractionDigits)}';
  }

  String formatDMM(double latitude, double longitude,
      {int fractionDigits = 4}) {
    final ns = latitude >= 0 ? 'N' : 'S';
    final ew = longitude >= 0 ? 'E' : 'W';

    final latDeg = latitude.abs().floor();
    final latMin = (latitude.abs() - latDeg) * 60;

    final lonDeg = longitude.abs().floor();
    final lonMin = (longitude.abs() - lonDeg) * 60;

    return '$latDeg° ${latMin.toStringAsFixed(fractionDigits)}\' $ns, $lonDeg° ${lonMin.toStringAsFixed(fractionDigits)}\' $ew';
  }

  String formatDMS(double latitude, double longitude) {
    String convert(double value, String positive, String negative, {int fractionDigits = 2}) {
      final hemisphere = value >= 0 ? positive : negative;
      final absValue = value.abs();

      final degrees = absValue.floor();
      final minutesFull = (absValue - degrees) * 60;
      final minutes = minutesFull.floor();
      final seconds = (minutesFull - minutes) * 60;

      return '$degrees° $minutes\' ${seconds.toStringAsFixed(fractionDigits)}" $hemisphere';
    }

    final lat = convert(latitude, 'N', 'S');
    final lon = convert(longitude, 'E', 'W');

    return '$lat, $lon';
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 0.8)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: isDark ? Colors.white12 : Colors.black12,
  );
}