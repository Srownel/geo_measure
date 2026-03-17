import 'package:flutter/material.dart';
import 'package:multi_sensor_app/session_class.dart';
import 'package:multi_sensor_app/session_database.dart';

import 'geo_measurement_class.dart';

import 'translation_util/translation_service.dart';

// PROVIDER CLASS //  holds the current measurement
class MeasurementProvider extends ChangeNotifier {
  int? currentSessionId;

  // Init a new measurement
  GeologicalMeasurement? _currentMeasurement;

  // Init a new measurement on first access
  GeologicalMeasurement get currentMeasurement {
    if (_currentMeasurement == null) {
      String newMeasurementName = '';
      if (currentSessionId != null) {
        Session? currentSession = SessionDatabase.instance.getSession(currentSessionId!);
        if (currentSession != null) {
          newMeasurementName = '${'measureP_point'.tr} ${currentSession.measurements.length + 1}';
        } else {
          newMeasurementName = '${'measureP_point'.tr} X'; // This only happens if database fetch failed. In which case we'll have bigger fish to fry than what to name a ghost measurement belonging to no Session.
        }
      } else {
        newMeasurementName = "${'measureP_point'.tr} 1";
      }

      _currentMeasurement = GeologicalMeasurement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        name: newMeasurementName,
      );
    }

    return _currentMeasurement!;
  }

  // -- Helper functions to update the measurement data -- //

  void updateGPS(double lat, double lon) { // , double alt, double acc
    currentMeasurement.latitude = lat;
    currentMeasurement.longitude = lon;
    // currentMeasurement.altitude = alt;
    // currentMeasurement.accuracy = acc;
    notifyListeners();
  }

  void updateBearing(double bearing) {
    currentMeasurement.bearing = bearing;
    notifyListeners();
  }

  void updateInclination(double angle) {
    currentMeasurement.pitch = angle;
    notifyListeners();
  }

  void updateEastWestOrientation(DipDirection orientation) {
    currentMeasurement.dipDirection = orientation;
    notifyListeners();
  }


  // -- "Database" interaction functions -- //
  // TODO check if I'm really supposed to "await" saves and loads in "database".

  Future<void> saveMeasurement() async {
    currentMeasurement.timestamp = DateTime.now();

    SessionDatabase sessionDatabase = SessionDatabase.instance;
    if (currentSessionId == null) {
      Session newSession = await sessionDatabase.createSession(firstMeasurement: currentMeasurement);
      currentSessionId = newSession.id;
    } else {
      await sessionDatabase.addMeasurement(currentSessionId!, currentMeasurement);
    }
  }

  GeologicalMeasurement loadMeasurement(int sessionId, int measurementIndex) {
    GeologicalMeasurement? measurement = SessionDatabase.instance.getMeasurement(sessionId, measurementIndex);
    if (measurement != null) {
      _currentMeasurement = measurement;
    } else {
      _currentMeasurement = GeologicalMeasurement(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        timestamp: DateTime.now(),
        name: (currentSessionId != null) ? '${'measureP_measure'.tr} ${SessionDatabase.instance.getSession(currentSessionId!)?.measurements.length ?? 'X'}' : '${'measureP_measure'.tr} 1'
      );
    }
    return currentMeasurement;
  }
}