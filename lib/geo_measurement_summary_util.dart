import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'geo_measurement_class.dart';

import 'translation_util/translation_service.dart';

//*** CARD WIDGET TO DISPLAY A SINGLE GeologicalMeasurement ***//

class MeasurementCard extends StatefulWidget {
  final GeologicalMeasurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MeasurementCard({
    super.key,
    required this.measurement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<MeasurementCard> {
  bool _isExpanded = false;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.measurement.name);
    _notesController = TextEditingController(text: widget.measurement.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: () {
          if (!_isEditing) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (always visible)
              Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: UnderlineInputBorder(),
                        ),
                      )
                    ),
                  ] else ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.measurement.name.isNotEmpty) ...[
                            Text(
                              widget.measurement.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'util_unnamed_measure'.tr, // 'Unnamed measure',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                          Text(
                            _formatTimestamp(widget.measurement.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isEditing) ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        _saveEditing();
                        widget.onEdit;
                      },
                      tooltip: 'session_save'.tr, // 'Save',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _cancelEditing,
                      tooltip: 'session_cancel'.tr, // 'Cancel',
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _isExpanded = true;
                        });
                      },
                      tooltip: 'util_edit'.tr, // 'Edit',
                    ),
                  ],

                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),

              // Expanded details
              if (_isExpanded) ...[
                const Divider(height: 16),
                _buildDetailSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveEditing() {
    widget.measurement.name = _nameController.text.trim();
    widget.measurement.notes = _notesController.text.trim();

    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    _nameController.text = widget.measurement.name;
    _notesController.text = widget.measurement.notes ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GPS Data
        _buildSectionTitle('util_gps_loc'.tr), // 'GPS Location'),
        _buildDetailRow(
          'util_latitude'.tr, // 'Latitude',
          '${widget.measurement.latitude != null
            ? widget.measurement.latitude!.toStringAsFixed(6)
            : '--.-'
          }°',
        ),
        _buildDetailRow(
          'util_longitude'.tr, // 'Longitude',
          '${widget.measurement.longitude != null
            ? widget.measurement.longitude!.toStringAsFixed(6)
            : '--.-'
          }°',
        ),
        const SizedBox(height: 12),

        // Compass Data
        _buildSectionTitle('util_comp_bearing'.tr), // 'Compass Bearing'),
        _buildDetailRow(
          'util_bearing'.tr, // 'Bearing',
          '${widget.measurement.bearing != null
            ? _limitTo180Degrees(_radiansToDegrees(widget.measurement.bearing!)).toStringAsFixed(0)
            : '--.-'
          }° (${widget.measurement.bearing != null
            ? widget.measurement.bearing!.toStringAsFixed(3)
            : '--.-'
          } rad)',
        ),
        const SizedBox(height: 12),

        // Tilt/Orientation Data
        _buildSectionTitle('util_orientation'.tr), // 'Orientation'),
        _buildDetailRow(
          'util_pitch'.tr, // 'Pitch (angle to horizontal)',
            '${widget.measurement.pitch != null
                ? _radiansToDegrees(widget.measurement.pitch!).toStringAsFixed(0)
                : '--.-'
            }° (${widget.measurement.pitch != null
                ? widget.measurement.pitch!.toStringAsFixed(3)
                : '--.-'
            } rad)',
        ),
        _buildDetailRow(
          'util_direction'.tr, // 'Direction',
          dipDirectionLabel(widget.measurement.dipDirection),
        ),
        const SizedBox(height: 12),

        // Notes
        _buildSectionTitle('measure_notes'.tr), // 'Notes'),

        _isEditing
          ? TextField(
              controller: _notesController,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'measure_add_notes'.tr, // 'Add notes about this session...',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(8),
              ),
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.measurement.notes?.isEmpty ?? true
                      ? 'measure_no_notes'.tr // 'No notes'
                      : widget.measurement.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.measurement.notes?.isEmpty ?? true
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
            ),

        const SizedBox(height: 12),

        // Delete button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            label: Text('util_delete'.tr, style: TextStyle(color: Colors.red)), // 'Delete'
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String dipDirectionLabel(DipDirection dir) {
    switch (dir) {
      case DipDirection.east:
        return 'util_east_oriented'.tr; // 'East-oriented';
      case DipDirection.west:
        return 'util_west_oriented'.tr; // 'West-oriented';
      case DipDirection.north:
        return 'util_north_oriented'.tr; // 'North-oriented';
      case DipDirection.south:
        return 'util_south_oriented'.tr; // 'South-oriented';
      case DipDirection.blank:
        return '--';
    }
  }

  double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  double _limitTo180Degrees(double degrees) {
    if (degrees > 180) {
      return 360 - degrees;
    }
    return degrees;
  }
}