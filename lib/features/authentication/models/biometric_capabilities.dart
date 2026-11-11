import 'package:local_auth/local_auth.dart';

class BiometricCapabilities {
  const BiometricCapabilities({
    this.hasHardware = false,
    this.enrolledTypes = const [],
    this.checkFailed = false,
  });

  final bool hasHardware;
  final List<BiometricType> enrolledTypes;
  final bool checkFailed;
  bool get canAuthenticate =>
      hasHardware && enrolledTypes.isNotEmpty && !checkFailed;
}

enum BiometricResult { success, canceled, failed, lockedOut, unavailable }
