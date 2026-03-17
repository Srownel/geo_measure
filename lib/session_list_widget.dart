import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'geo_measurement_widget.dart';
import 'geo_measurement_provider.dart';
import 'session_class.dart';
import 'session_widget.dart';
import 'session_database.dart';

import 'settings_widget.dart';

import 'translation_util/translation_service.dart';

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  List<Session> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
    // Listen to language changes
    TranslationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    TranslationService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  void _loadSessions() {
    setState(() {
      _sessions = SessionDatabase.instance.getAllSessions();
      // Sort by most recently modified first
      _sessions.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('session_sessions'.tr), // 'Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'settings_title'.tr, // 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _sessions.length + 1, // +1 for the "new session" card
          itemBuilder: (context, index) {
            if (index == 0) {
              // "Start new session" card at the top
              return _buildNewSessionCard();
            }

            final session = _sessions[index - 1];
            return _buildSessionCard(session);
          },
        ),
      ),
    );
  }

  Widget _buildNewSessionCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: _startNewSession,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'session_new_session'.tr, // 'Start New Session',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'session_new_session_2'.tr, // 'Begin a new measurement session',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNewSession() {
    // Navigate to MeasureTakerFlow without session (will create new one)
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => MeasurementProvider(),
            child: MeasureTakerFlow(),
          )
      ),
    ).then((_) => _loadSessions()); // Refresh when returning
  }

  Widget _buildSessionCard(Session session) {
    final measurementCount = session.measurements.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionScreen(sessionId: session.id),
            ),
          ).then((_) => _loadSessions()); // Refresh when returning
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.name,
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Session metadata
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'session_list_created'.tr} ${_formatTimestamp(session.createdOn)}', // 'Created:'
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'session_list_last_modified'.tr} ${_formatTimestamp(session.lastModified)}', // 'Last modified:'
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 16,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$measurementCount ${measurementCount != 1
                        ? 'session_list_measurements'.tr
                        : 'session_list_measurement'.tr}',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}