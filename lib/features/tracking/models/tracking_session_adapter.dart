import 'package:hive_flutter/hive_flutter.dart';
import 'track_point.dart';
import 'tracking_session.dart';

class TrackingSessionAdapter extends TypeAdapter<TrackingSession> {
  @override
  final int typeId = 2;

  @override
  TrackingSession read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return TrackingSession(
      id: fields[0] as String,
      startedAt: fields[1] as DateTime,
      status: TrackingSessionStatus.values.byName(fields[2] as String),
      endedAt: fields[3] as DateTime?,
      elapsedMilliseconds: fields[4] as int,
      distanceMetres: (fields[5] as num).toDouble(),
      segment: fields[6] as int,
      points: (fields[7] as List).cast<TrackPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrackingSession session) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(session.id)
      ..writeByte(1)
      ..write(session.startedAt)
      ..writeByte(2)
      ..write(session.status.name)
      ..writeByte(3)
      ..write(session.endedAt)
      ..writeByte(4)
      ..write(session.elapsedMilliseconds)
      ..writeByte(5)
      ..write(session.distanceMetres)
      ..writeByte(6)
      ..write(session.segment)
      ..writeByte(7)
      ..write(session.points);
  }
}
