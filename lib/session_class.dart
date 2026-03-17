import 'package:hive/hive.dart';
import 'geo_measurement_class.dart';

part 'session_class.g.dart'; // Generated file

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdOn;

  @HiveField(3)
  DateTime lastModified;

  @HiveField(4)
  List<GeologicalMeasurement> measurements;

  @HiveField(5)
  String? notes;

  Session({
    required this.id,
    required this.name,
    required this.createdOn,
    required this.lastModified,
    List<GeologicalMeasurement>? measurements,
  }) : measurements = measurements ?? [];

  // Helper to get default name
  static String defaultName(int id) => 'Session $id';
}