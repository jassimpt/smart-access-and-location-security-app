enum GeofencePresence { unknown, inside, outside }

enum GeofenceTransition { entered, exited }

class GeofenceEvent {
  const GeofenceEvent({required this.transition, required this.occurredAt});
  final GeofenceTransition transition;
  final DateTime occurredAt;
}
