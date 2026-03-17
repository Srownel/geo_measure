import 'package:hive_flutter/hive_flutter.dart';
import 'session_class.dart';
import 'geo_measurement_class.dart';

class SessionDatabase {
  static final SessionDatabase instance = SessionDatabase._();
  SessionDatabase._();

  static const String sessionsBoxName = 'sessions';
  static const String metadataBoxName = 'metadata';
  static const String sessionCounterKey = 'sessionCounter';

  Box<Session>? sessionsBox;
  Box? metadataBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GeologicalMeasurementAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DipDirectionAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionAdapter());
    }

    // Open boxes
    sessionsBox = await Hive.openBox<Session>(sessionsBoxName);
    metadataBox = await Hive.openBox(metadataBoxName);
  }

  Box<Session> get _sessions {
    if (sessionsBox == null || !sessionsBox!.isOpen) {
      throw Exception('SessionDatabase not initialized. Call init() first.');
    }
    return sessionsBox!;
  }

  Box get _metadata {
    if (metadataBox == null || !metadataBox!.isOpen) {
      throw Exception('SessionDatabase not initialized. Call init() first.');
    }
    return metadataBox!;
  }

  // Get next auto-increment ID
  int _getNextSessionId() {
    int currentCounter = _metadata.get(sessionCounterKey, defaultValue: 0);
    int nextId = currentCounter + 1;
    _metadata.put(sessionCounterKey, nextId);
    return nextId;
  }

  // ===== SESSION OPERATIONS =====

  /// Create a new session
  Future<Session> createSession({String? name, GeologicalMeasurement? firstMeasurement}) async {
    final id = _getNextSessionId();
    final now = DateTime.now();

    final session = Session(
      id: id,
      name: name ?? Session.defaultName(id),
      createdOn: now,
      lastModified: now,
      measurements: [if (firstMeasurement != null) firstMeasurement],
    );

    await _sessions.put(id, session);
    return session;
  }

  /// Get all sessions
  List<Session> getAllSessions() {
    return _sessions.values.toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified)); // Most recent first
  }

  /// Get a specific session by ID
  Session? getSession(int id) {
    return _sessions.get(id);
  }

  /// Update a session (mainly for renaming)
  Future<void> updateSession(Session session) async {
    session.lastModified = DateTime.now();
    await session.save(); // HiveObject method
  }

  /// Delete a session
  Future<void> deleteSession(int id) async {
    await _sessions.delete(id);
  }

  // ===== MEASUREMENT OPERATIONS =====

  /// Add a measurement to a session
  Future<void> addMeasurement(int sessionId, GeologicalMeasurement measurement) async {
    final session = getSession(sessionId);
    if (session == null) {
      throw Exception('Session $sessionId not found');
    }

    session.measurements.add(measurement);
    session.lastModified = DateTime.now();
    await session.save();
  }

  /// Get a specific measurement from a session
  GeologicalMeasurement? getMeasurement(int sessionId, int measurementIndex) {
    final session = getSession(sessionId);
    if (session == null || measurementIndex >= session.measurements.length) {
      return null;
    }
    return session.measurements[measurementIndex];
  }

  /// Get the last (most recent) measurement from a session
  GeologicalMeasurement? getLastMeasurement(int sessionId) {
    final session = getSession(sessionId);
    if (session == null || session.measurements.isEmpty) {
      return null;
    }
    return session.measurements.last;
  }

  /// Update a measurement at a specific index
  Future<void> updateMeasurement(
      int sessionId,
      int measurementIndex,
      GeologicalMeasurement updatedMeasurement
      ) async {
    final session = getSession(sessionId);
    if (session == null) {
      throw Exception('Session $sessionId not found');
    }
    if (measurementIndex >= session.measurements.length) {
      throw Exception('Measurement index $measurementIndex out of bounds');
    }

    session.measurements[measurementIndex] = updatedMeasurement;
    session.lastModified = DateTime.now();
    await session.save();
  }

  /// Delete a measurement from a session
  Future<void> deleteMeasurement(int sessionId, int measurementIndex) async {
    final session = getSession(sessionId);
    if (session == null) {
      throw Exception('Session $sessionId not found');
    }
    if (measurementIndex >= session.measurements.length) {
      throw Exception('Measurement index $measurementIndex out of bounds');
    }

    session.measurements.removeAt(measurementIndex);
    session.lastModified = DateTime.now();
    await session.save();
  }

  /// Reorder measurements within a session
  Future<void> reorderMeasurements(
      int sessionId,
      int oldIndex,
      int newIndex
      ) async {
    final session = getSession(sessionId);
    if (session == null) {
      throw Exception('Session $sessionId not found');
    }

    if (oldIndex >= session.measurements.length ||
        newIndex >= session.measurements.length) {
      throw Exception('Invalid indices for reordering');
    }

    final measurement = session.measurements.removeAt(oldIndex);
    session.measurements.insert(newIndex, measurement);
    session.lastModified = DateTime.now();
    await session.save();
  }

  // ===== UTILITY METHODS =====

  /// Get total number of sessions
  int getSessionCount() {
    return _sessions.length;
  }

  /// Get total measurements across all sessions
  int getTotalMeasurementCount() {
    return _sessions.values.fold(0, (sum, session) => sum + session.measurements.length);
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    await _sessions.clear();
    await _metadata.clear();
  }
}