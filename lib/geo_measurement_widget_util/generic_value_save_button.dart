import 'package:flutter/material.dart';

import 'package:multi_sensor_app/translation_util/translation_service.dart';

class ValueSaveButton extends StatelessWidget {
  final String value;       // The formatted value to display, e.g. "127.4°"
  final VoidCallback? onSave; // Null to disable the button
  final bool isDark;

  const ValueSaveButton({
    super.key,
    required this.value,
    required this.onSave,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = Colors.blue.shade400;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Value display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: Text(
                value,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: borderColor.withOpacity(0.5),
              indent: 10,
              endIndent: 10,
            ),

            // Save button
            TextButton(
              onPressed: onSave,
              style: TextButton.styleFrom(
                foregroundColor: onSave != null
                    ? Colors.blue.shade400
                    : fgColor.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
              child: Text(
                'saveBtn_save'.tr, //'Save value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}