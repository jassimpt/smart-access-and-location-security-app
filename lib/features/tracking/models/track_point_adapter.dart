import 'package:hive_flutter/hive_flutter.dart';
import 'track_point.dart';

class TrackPointAdapter extends TypeAdapter<TrackPoint> {
  @override
  final int typeId = 1;

  @override
  TrackPoint read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return TrackPoint(
      latitude: (fields[0] as num).toDouble(),
      longitude: (fields[1] as num).toDouble(),
      accuracy: (fields[2] as num).toDouble(),
      recordedAt: fields[3] as DateTime,
      speed: (fields[4] as num).toDouble(),
      segment: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TrackPoint point) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(point.latitude)
      ..writeByte(1)
      ..write(point.longitude)
      ..writeByte(2)
      ..write(point.accuracy)
      ..writeByte(3)
      ..write(point.recordedAt)
      ..writeByte(4)
      ..write(point.speed)
      ..writeByte(5)
      ..write(point.segment);
  }
}
