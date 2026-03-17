import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'geo_measurement_class.dart';
import 'geo_measurement_provider.dart';
import 'geo_measurement_widget.dart';
import 'session_class.dart';
import 'session_list_widget.dart';
import 'session_database.dart';
import 'settings_widget.dart';
import 'action_card.dart';

import 'translation_util/translation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Session? _lastSession;
  GeologicalMeasurement? _lastMeasurement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLastSession();
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

  Future<void> _loadLastSession() async {
    setState(() => _isLoading = true);

    SessionDatabase sessionDatabase = SessionDatabase.instance;
    List<Session> sessions = sessionDatabase.getAllSessions();
    if (sessions.isNotEmpty) {
      _lastSession = sessions[0];
      _lastMeasurement = sessionDatabase.getLastMeasurement(sessions[0].id);
      _isLoading = false;
    } else {
      setState(() {
        _lastSession = null;
        _lastMeasurement = null;
        _isLoading = false;
      });
    }
  }

  void _continueLastSession() {
    if (_lastSession == null) return;

    // Navigate to MeasureTakerFlow with existing session
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MeasurementProvider(),
          child: MeasureTakerFlow(sessionId: _lastSession?.id),
        )
      ),
    ).then((_) => _loadLastSession()); // Refresh when returning
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
    ).then((_) => _loadLastSession()); // Refresh when returning
  }

  void _viewSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionsListScreen(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('home_app_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'settings_title'.tr,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome section
              Padding(
                padding: EdgeInsets.only(left: 16),
                child:
                  Text(
                    'home_welcome'.tr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child:
                  Text(
                    'home_welcome_2'.tr, // 'What would you like to do?'
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ),
              const SizedBox(height: 32),

              // Continue last session (if available and recent)
              if (_lastSession != null)
                _ContinueSessionCard(
                  session: _lastSession!,
                  measurement: _lastMeasurement,
                  onTap: _continueLastSession,
                ),

              if (_lastSession != null)
                const SizedBox(height: 16),

              // Start new session
              ActionCard(
                icon: Icons.add_circle_outline,
                title: 'home_start'.tr, // 'Start New Session'
                subtitle: 'home_start_2'.tr, // 'Begin a new measurement session'
                color: colorScheme.primaryContainer,
                onTap: _startNewSession,
              ),
              const SizedBox(height: 16),

              // View past sessions
              ActionCard(
                icon: Icons.history,
                title: 'home_view_session'.tr, // 'View Past Sessions'
                subtitle: 'home_view_session_2'.tr, // 'Browse and review your measurements'
                color: colorScheme.secondaryContainer,
                onTap: _viewSessions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card for continuing the last session
class _ContinueSessionCard extends StatelessWidget {
  final Session session;
  final GeologicalMeasurement? measurement;
  final VoidCallback onTap;

  const _ContinueSessionCard({
    required this.session,
    required this.measurement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.tertiaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 32,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_continue_session'.tr, // 'Continue Last Session',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'home_continue_session_2'.tr, // 'Pick up where you left off',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onTertiaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home_last_session'.tr + session.name, // 'Last session: '
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home_last_session_date'.tr + _formatTimestamp(session.lastModified), // 'Date: '
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home_last_session_measurements'.tr + session.measurements.length.toString(), // 'Measurements: '
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
