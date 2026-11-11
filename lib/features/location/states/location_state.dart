import '../models/location_device_status.dart';
import '../models/location_snapshot.dart';

enum LocationStatus {
  initial,
  permissionRequired,
  permanentlyDenied,
  gpsDisabled,
  ready,
  unavailable,
}

class LocationState {
  const LocationState({
    this.status = LocationStatus.initial,
    this.device,
    this.snapshot,
    this.isBusy = false,
    this.isCached = false,
    this.isAddressCached = false,
    this.isResolvingAddress = false,
    this.message,
    this.storageWarning,
  });

  final LocationStatus status;
  final LocationDeviceStatus? device;
  final LocationSnapshot? snapshot;
  final bool isBusy;
  final bool isCached;
  final bool isAddressCached;
  final bool isResolvingAddress;
  final String? message;
  final String? storageWarning;

  /// Updates location state while retaining the last valid position.
  LocationState copyWith({
    LocationStatus? status,
    LocationDeviceStatus? device,
    LocationSnapshot? snapshot,
    bool? isBusy,
    bool? isCached,
    bool? isAddressCached,
    bool? isResolvingAddress,
    String? message,
    bool clearMessage = false,
    String? storageWarning,
    bool clearStorageWarning = false,
  }) => LocationState(
    status: status ?? this.status,
    device: device ?? this.device,
    snapshot: snapshot ?? this.snapshot,
    isBusy: isBusy ?? this.isBusy,
    isCached: isCached ?? this.isCached,
    isAddressCached: isAddressCached ?? this.isAddressCached,
    isResolvingAddress: isResolvingAddress ?? this.isResolvingAddress,
    message: clearMessage ? null : message ?? this.message,
    storageWarning: clearStorageWarning
        ? null
        : storageWarning ?? this.storageWarning,
  );
}
