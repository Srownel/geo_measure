import 'package:hive/hive.dart';

part 'geo_measurement_class.g.dart'; // Generated file

@HiveType(typeId: 2)
enum DipDirection {
  @HiveField(0) east,
  @HiveField(1) west,
  @HiveField(2) north,
  @HiveField(3) south,
  @HiveField(4) blank
}

// DATA-STRUCTURE CLASS //  to hold the data related to "one full" measurement.

@HiveType(typeId: 0)
class GeologicalMeasurement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  // User set name
  @HiveField(2)
  String name;

  // GPS data
  @HiveField(3)
  double? latitude;

  @HiveField(4)
  double? longitude;

  // @HiveField(4)
  // double? altitude;

  // @HiveField(5)
  // double? accuracy;

  // Compass data
  @HiveField(5)
  double? bearing; // in radian

  @HiveField(6)
  double? magneticNBearing; // in radian

  // Tilt/orientation data
  @HiveField(7)
  double? pitch; // angle to Z-axis, in radian

  @HiveField(8)
  DipDirection dipDirection; // typically East or West-oriented, barr edge-cases.

  @HiveField(9)
  String? notes;

  GeologicalMeasurement({
    required this.id,
    required this.timestamp,
    required this.name,
    this.latitude,
    this.longitude,
    // this.altitude,
    // this.accuracy,
    this.bearing,
    this.magneticNBearing,
    this.pitch,
    this.dipDirection = DipDirection.blank,
    this.notes,
  });
}
