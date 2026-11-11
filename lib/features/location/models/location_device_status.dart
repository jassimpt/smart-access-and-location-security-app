enum LocationPermissionStatus { denied, permanentlyDenied, granted }

class LocationDeviceStatus {
  const LocationDeviceStatus({
    required this.serviceEnabled,
    required this.permission,
  });

  final bool serviceEnabled;
  final LocationPermissionStatus permission;
  bool get canLocate =>
      serviceEnabled && permission == LocationPermissionStatus.granted;
}
