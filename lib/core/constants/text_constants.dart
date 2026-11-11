abstract final class TextConstants {
  static const appName = 'Smart Access';
  static const overview = 'Overview';
  static const settings = 'Settings';
  static const welcomeTitle = 'Your security, at a glance.';
  static const welcomeDescription =
      'A personal space for device access, location, and activity.';
  static const privacyTitle = 'Personal by design';
  static const privacyDescription =
      'Your preferences stay on this device. Choose an appearance that feels right for you.';
  static const customizeAppearance = 'Customize appearance';
  static const deviceAccess = 'Device access';
  static const deviceAccessDescription =
      'Biometric authentication and a personal PIN for app access.';
  static const locationAwareness = 'Location awareness';
  static const locationDescription =
      'Your current position and the places that matter to you.';
  static const activityHistory = 'Activity history';
  static const activityDescription =
      'Your journeys, routes, and movement in one place.';
  static const notConfigured = 'Not configured';
  static const appearance = 'Appearance';
  static const appearanceDescription =
      'Choose how Smart Access looks on your device.';
  static const systemTheme = 'System';
  static const systemThemeDescription = 'Follow your device appearance';
  static const lightTheme = 'Light';
  static const lightThemeDescription = 'A bright, clear workspace';
  static const darkTheme = 'Dark';
  static const darkThemeDescription = 'A softer view in low light';
  static const themeSaveError =
      'Could not save your appearance. Please try again.';
  static const startingApp = 'Getting things ready';
  static const startupErrorTitle = 'Unable to open Smart Access';
  static const startupErrorDescription =
      'Your local preferences could not be loaded. Please try again.';
  static const retry = 'Try again';
  static const pageNotFound = 'This page is unavailable';
  static const backToOverview = 'Back to overview';
  static const security = 'Security';
  static const securityDescription = 'Manage app access and automatic locking.';
  static const setupPinTitle = 'A little more protection.';
  static const setupPinDescription =
      'Create a six-digit PIN to keep access to Smart Access private.';
  static const pinLabel = 'Six-digit PIN';
  static const confirmPinLabel = 'Confirm PIN';
  static const createPin = 'Create PIN';
  static const pinHint = 'Remember your PIN. It cannot be recovered.';
  static const invalidPin = 'Enter a six-digit PIN.';
  static const pinMismatch = 'The PINs do not match.';
  static const unlockTitle = 'Welcome back.';
  static const unlockDescription = 'Enter your PIN to open Smart Access.';
  static const unlock = 'Unlock';
  static const incorrectPin = 'Incorrect PIN. Please try again.';
  static const pinLockout =
      'Too many incorrect attempts. Your PIN is temporarily locked. Please wait before trying again.';
  static const pinProtected = 'PIN protection active';
  static const biometricUnlock = 'Biometric unlock';
  static const biometricReason = 'Verify your identity to access Smart Access.';
  static const useBiometrics = 'Use biometrics';
  static const cancelBiometrics = 'Cancel biometric check';
  static const biometricCanceled =
      'Biometric authentication was canceled. You can use your PIN.';
  static const biometricFailed =
      'Biometric authentication failed. Try again or use your PIN.';
  static const biometricLockedOut =
      'Biometrics are locked. Use your PIN or unlock your device to try again.';
  static const biometricUnavailable =
      'Biometrics are unavailable. You can use your PIN.';
  static const biometricsNotEnrolled =
      'No biometrics enrolled. Add biometrics in your device settings, then return here.';
  static const biometricsNotSupported =
      'Biometric hardware is not available on this device.';
  static const biometricCheckFailed =
      'Biometric status could not be checked. Your PIN is still available.';
  static const fingerprintAvailable = 'Fingerprint';
  static const faceAvailable = 'Face recognition';
  static const irisAvailable = 'Iris recognition';
  static const deviceBiometrics = 'Device biometrics';
  static const biometricEnabled = 'Biometric unlock enabled';
  static const biometricDisabled =
      'Use your PIN, or enable biometric unlock below.';
  static const refreshSecurity = 'Refresh biometric status';
  static const autoLock = 'Auto-lock';
  static const autoLockDescription =
      'Lock after inactivity or time away. Immediately locks when you leave the app.';
  static const lockImmediately = 'Immediately';
  static const lockAfterThirtySeconds = '30 seconds';
  static const lockAfterOneMinute = '1 minute';
  static const lockAfterFiveMinutes = '5 minutes';
  static const lockNow = 'Lock now';
  static const authenticationStorageError =
      'Security changes could not be saved. Please try again.';
  static const authenticationLoadError =
      'Your security settings could not be loaded. Retry to continue safely.';
  static const authenticationLoading = 'Checking app security';
  static const authenticationErrorTitle = 'Unable to load app security';
  static const lastAuthentication = 'Last successful unlock';
  static const noAuthentication = 'No successful unlock yet';
  static const showPin = 'Show PIN';
  static const hidePin = 'Hide PIN';

  /// Formats the last authentication date and time for display.
  static String authenticationTime(String date, String time) =>
      '$date at $time';
}
