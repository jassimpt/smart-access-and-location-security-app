import 'package:hive_flutter/hive_flutter.dart';

import 'location_snapshot.dart';

class LocationSnapshotAdapter extends TypeAdapter<LocationSnapshot> {
  @override
  final int typeId = 0;

  @override
  LocationSnapshot read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return LocationSnapshot(
      latitude: (fields[0] as num).toDouble(),
      longitude: (fields[1] as num).toDouble(),
      accuracy: (fields[2] as num).toDouble(),
      recordedAt: fields[3] as DateTime,
      isApproximate: fields[4] as bool?,
      address: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationSnapshot value) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(value.latitude)
      ..writeByte(1)
      ..write(value.longitude)
      ..writeByte(2)
      ..write(value.accuracy)
      ..writeByte(3)
      ..write(value.recordedAt)
      ..writeByte(4)
      ..write(value.isApproximate)
      ..writeByte(5)
      ..write(value.address);
  }
}
