// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_measurement_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeologicalMeasurementAdapter extends TypeAdapter<GeologicalMeasurement> {
  @override
  final int typeId = 0;

  @override
  GeologicalMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeologicalMeasurement(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      name: fields[2] as String,
      latitude: fields[3] as double?,
      longitude: fields[4] as double?,
      bearing: fields[5] as double?,
      magneticNBearing: fields[6] as double?,
      pitch: fields[7] as double?,
      dipDirection: fields[8] as DipDirection,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GeologicalMeasurement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.bearing)
      ..writeByte(6)
      ..write(obj.magneticNBearing)
      ..writeByte(7)
      ..write(obj.pitch)
      ..writeByte(8)
      ..write(obj.dipDirection)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeologicalMeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DipDirectionAdapter extends TypeAdapter<DipDirection> {
  @override
  final int typeId = 2;

  @override
  DipDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DipDirection.east;
      case 1:
        return DipDirection.west;
      case 2:
        return DipDirection.north;
      case 3:
        return DipDirection.south;
      case 4:
        return DipDirection.blank;
      default:
        return DipDirection.east;
    }
  }

  @override
  void write(BinaryWriter writer, DipDirection obj) {
    switch (obj) {
      case DipDirection.east:
        writer.writeByte(0);
        break;
      case DipDirection.west:
        writer.writeByte(1);
        break;
      case DipDirection.north:
        writer.writeByte(2);
        break;
      case DipDirection.south:
        writer.writeByte(3);
        break;
      case DipDirection.blank:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DipDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
