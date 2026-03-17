import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'geo_measurement_class.dart';
import 'geo_measurement_widget.dart';
import 'geo_measurement_provider.dart';
import 'geo_measurement_summary_util.dart';
import 'session_class.dart';
import 'session_database.dart';

import 'settings_widget.dart';

import 'translation_util/translation_service.dart';

class SessionScreen extends StatefulWidget {
  final int sessionId;

  const SessionScreen({super.key, required this.sessionId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late SessionDatabase sessionDatabase;

  @override
  void initState() {
    super.initState();

    sessionDatabase = SessionDatabase.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('session_details'.tr), // 'Session Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ValueListenableBuilder( // TODO wouldn't it just make more sense to load the session as an object once on init()? Note: that implies reloading it explicitely when coming back to this screen in _addNewMeasurement (and similar?)
          valueListenable: sessionDatabase.sessionsBox!.listenable(keys: [widget.sessionId]),
          builder: (context, Box<Session> box, _) {
            final session = sessionDatabase.getSession(widget.sessionId);

            if (session == null) {
              return Center(
                child: Text('session_not_found'.tr), // 'Session not found.'),
              );
            }

            return CustomScrollView(
              slivers: [

                //* Session Info Header *//

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SessionInfoCard(
                      session: session,
                      onSave: (updatedSession) => _saveSessionInfo(updatedSession),
                    ),
                  ),
                ),

                //* Measurements Header *//

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'session_measurements'.tr} (${session.measurements.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _addNewMeasurement(session),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text('session_add'.tr), // 'Add'),
                        ),
                      ],
                    ),
                  ),
                ),

                //* Measurements List *//

                session.measurements.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'session_no_measure'.tr, // 'No measurements yet.\nTap "Add" to create one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      int reverseIndex = session.measurements.length - 1 - index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: MeasurementCard(
                          key: ValueKey(session.measurements[reverseIndex].id),
                          measurement: session.measurements[reverseIndex],
                          onEdit: () => _editMeasurement(reverseIndex, session.measurements[reverseIndex]),
                          onDelete: () => _deleteMeasurement(session, session.measurements[reverseIndex]),
                        ),
                      );
                    },
                    childCount: session.measurements.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _saveSessionInfo(Session updatedSession) {
    updatedSession.lastModified = DateTime.now();
    sessionDatabase.updateSession(updatedSession);
  }

  void _addNewMeasurement(Session session) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => MeasurementProvider(),
            child: MeasureTakerFlow(sessionId: session.id),
          )
      ),
    ); // .then((_) => _loadSession()); // Refresh when returning
  }

  void _editMeasurement(int measurementIdx, GeologicalMeasurement measurement) {
    sessionDatabase.updateMeasurement(widget.sessionId, measurementIdx, measurement);
  }

  void _deleteMeasurement(Session session, GeologicalMeasurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('session_delete_Measurement'.tr), // 'Delete Measurement'),
        content: Text('${'session_delete_measurement'.tr} ${measurement.id}?'), // 'Delete measurement'
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('session_cancel'.tr), // 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              session.measurements.remove(measurement);
              session.lastModified = DateTime.now();
              sessionDatabase.updateSession(session);
              Navigator.pop(context);
            },
            child: Text('session_delete'.tr, style: TextStyle(color: Colors.red)), // 'Delete'
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}

//*** CARD WIDGET TO DISPLAY A INFO RELATED TO THE SESSION ***//

class SessionInfoCard extends StatefulWidget {
  final Session session;
  final Function(Session) onSave;

  const SessionInfoCard({
    super.key,
    required this.session,
    required this.onSave,
  });

  @override
  State<SessionInfoCard> createState() => _SessionInfoCardState();
}

class _SessionInfoCardState extends State<SessionInfoCard> {
  bool _isExpanded = true;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _notesController = TextEditingController(text: widget.session.notes ?? '');
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
      elevation: 4,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: _isEditing
                      ? TextField(
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
                      : Text(
                    widget.session.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _saveChanges,
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
                    tooltip: 'session_edit'.tr, // 'Edit',
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    if (!_isEditing) {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    }
                  },
                ),
              ],
            ),

            // Expanded Details
            if (_isExpanded) ...[
              const Divider(height: 16),
              _buildDetailRow('session_sessionId'.tr, '#${widget.session.id}'), // 'Session ID'
              _buildDetailRow(
                'session_created'.tr, // 'Created',
                _formatDateTime(widget.session.createdOn),
              ),
              _buildDetailRow(
                'session_last_modif'.tr, // 'Last Modified',
                _formatDateTime(widget.session.lastModified),
              ),
              const SizedBox(height: 8),

              // Notes Section
              Text(
                'session_notes'.tr, // 'Notes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 4),
              _isEditing
                  ? TextField(
                controller: _notesController,
                maxLines: null,
                minLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'session_add_notes'.tr, // 'Add notes about this session...',
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
                        widget.session.notes?.isEmpty ?? true
                            ? 'session_no_notes'.tr // 'No notes'
                            : widget.session.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.session.notes?.isEmpty ?? true
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    widget.session.name = _nameController.text.trim();
    widget.session.notes = _notesController.text.trim();
    widget.onSave(widget.session);

    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    _nameController.text = widget.session.name;
    _notesController.text = widget.session.notes ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}