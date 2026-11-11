import 'package:hive_flutter/hive_flutter.dart';
import 'geofence.dart';

class GeofenceAdapter extends TypeAdapter<Geofence> {
  @override
  final int typeId = 3;

  @override
  Geofence read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Geofence(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: (fields[2] as num).toDouble(),
      longitude: (fields[3] as num).toDouble(),
      radiusMetres: (fields[4] as num).toDouble(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Geofence fence) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(fence.id)
      ..writeByte(1)
      ..write(fence.name)
      ..writeByte(2)
      ..write(fence.latitude)
      ..writeByte(3)
      ..write(fence.longitude)
      ..writeByte(4)
      ..write(fence.radiusMetres)
      ..writeByte(5)
      ..write(fence.createdAt)
      ..writeByte(6)
      ..write(fence.updatedAt);
  }
}
