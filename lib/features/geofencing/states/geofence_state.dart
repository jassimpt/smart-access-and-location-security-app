import '../../location/models/location_snapshot.dart';
import '../models/geofence.dart';
import '../models/geofence_event.dart';

class GeofenceState {
  GeofenceState({
    List<Geofence> fences = const [],
    Map<String, GeofencePresence> presences = const {},
    Map<String, GeofenceEvent> events = const {},
    this.initialized = false,
    this.isBusy = false,
    this.loadFailed = false,
    this.isMonitoring = false,
    this.message,
    this.notificationWarning,
    this.lastPosition,
  }) : fences = List.unmodifiable(fences),
       presences = Map.unmodifiable(presences),
       events = Map.unmodifiable(events);

  final List<Geofence> fences;
  final Map<String, GeofencePresence> presences;
  final Map<String, GeofenceEvent> events;
  final bool initialized;
  final bool isBusy;
  final bool loadFailed;
  final bool isMonitoring;
  final String? message;
  final String? notificationWarning;
  final LocationSnapshot? lastPosition;

  /// Publishes immutable geofence and foreground monitoring state.
  GeofenceState copyWith({
    List<Geofence>? fences,
    Map<String, GeofencePresence>? presences,
    Map<String, GeofenceEvent>? events,
    bool? initialized,
    bool? isBusy,
    bool? loadFailed,
    bool? isMonitoring,
    String? message,
    bool clearMessage = false,
    String? notificationWarning,
    bool clearNotificationWarning = false,
    LocationSnapshot? lastPosition,
    bool clearPosition = false,
  }) => GeofenceState(
    fences: fences ?? this.fences,
    presences: presences ?? this.presences,
    events: events ?? this.events,
    initialized: initialized ?? this.initialized,
    isBusy: isBusy ?? this.isBusy,
    loadFailed: loadFailed ?? this.loadFailed,
    isMonitoring: isMonitoring ?? this.isMonitoring,
    message: clearMessage ? null : message ?? this.message,
    notificationWarning: clearNotificationWarning
        ? null
        : notificationWarning ?? this.notificationWarning,
    lastPosition: clearPosition ? null : lastPosition ?? this.lastPosition,
  );
}
