# Smart Access & Location Security

A Flutter app for secure device access, live location, journey tracking, and geofencing on Android and iOS. User data stays on the device; the app does not require a backend, account registration, or a custom REST API.

## App downloads

[Download Android APK](https://drive.google.com/file/d/1JNG8lRk6Ue8RfxLzwlMwyVgQU0kvYvsw/view?usp=sharing)

[Download iOS IPA](https://drive.google.com/file/d/1CERtbJ9x6QOnirkRNLT-iVWq1hPkOIwF/view?usp=sharing)

> **iOS installation:** This IPA is unsigned. Use [iLoader](https://github.com/nab138/iloader) on a Mac to sign and install it on your iPhone through **Import IPA**.

## Features

- **Secure access:** Six-digit PIN setup and unlock, optional fingerprint/Face ID, biometric capability checks, failed-attempt lockout, and configurable automatic locking.
- **Overview:** Device security, biometric availability, location permission, GPS status, latest known position, tracking activity, saved area count, and last successful authentication.
- **Location:** Contextual permission requests, interactive map, coordinates, accuracy and precision status, refresh/recenter controls, reverse-geocoded address, and saved location fallback.
- **Tracking:** Start, pause, resume, and stop journeys; display route, distance, current speed, and duration; save completed sessions and browse their details.
- **Geofencing:** Select map coordinates or enter them manually, configure a radius, manage multiple areas, and detect entry/exit events with local notifications.
- **Local history:** Persist completed journeys across restarts and clear history with confirmation while preserving an unfinished session.
- **Export:** Export completed tracking history as CSV or JSON through the native share sheet.
- **Appearance:** System, light, and dark themes, with responsive layouts for phones, tablets, landscape, and enlarged text.

## Requirements

| Component | Project configuration |
| --- | --- |
| Flutter | Developed and built with Flutter 3.35.4 |
| Dart | 3.9.2; SDK constraint `^3.9.2` |
| Android | Android Studio/SDK, JDK 17, SDK platform 36 |
| Android build tools | Gradle 8.12, Android Gradle Plugin 8.9.1, Kotlin 2.1.0 |
| iOS | macOS, Xcode, CocoaPods; deployment target iOS 15.0 |
| Devices | Android emulator/device or iOS simulator/device; physical devices recommended for GPS and biometric checks |

Internet access is needed to install SDK components and dependencies. No API keys or environment secrets are required to run the default configuration.

## Setup

Clone the repository and install dependencies:

```bash
git clone https://github.com/jassimpt/smart-access-and-location-security-app.git
cd smart-access-and-location-security-app
flutter doctor -v
flutter pub get
```

### Android

Install Android SDK platform 36 and configure JDK 17 in Android Studio. Accept SDK licences if prompted:

```bash
flutter doctor --android-licenses
flutter devices
flutter run -d <device-id>
```

The SDK and NDK versions are selected through the Flutter Android configuration. Flutter/Gradle may install missing components during the first build.

### iOS

Install dependencies from macOS:

```bash
cd ios
pod install
cd ..
flutter devices
flutter run -d <device-id>
```

For a physical iPhone, open `ios/Runner.xcworkspace` in Xcode, select the **Runner** target, and configure **Signing & Capabilities** with your development team and an available bundle identifier. The simulator does not require device provisioning.

The Podfile also raises older pod deployment targets to iOS 15.0. Location access is configured for foreground use; background location permissions are not requested.

The iOS host uses a native `SceneDelegate` and one explicitly managed `FlutterEngine` to support the scene lifecycle required by Xcode 27 without upgrading Flutter 3.35.4. Scene transitions are bridged to the legacy lifecycle notifications used by the engine and plugins. This preserves automatic locking, foreground tracking suspension, and native authentication handling.

## Build

### Android release APK

```bash
flutter pub get
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To rebuild from a clean workspace:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

Cleaning removes all generated builds, including any locally packaged IPA. For Play Store or production distribution, configure a release keystore instead of the current debug signing configuration.

### Signed iOS archive / IPA

Configure the appropriate development team, certificates, provisioning, and export method in Xcode, then run:

```bash
flutter build ipa --release
```

The archive is generated under `build/ios/archive/`. A successful signed export is written under `build/ios/ipa/`.

### Unsigned IPA for a sideloading tool

Build for a physical device without signing, then package the app bundle:

```bash
flutter build ios --release --no-codesign
mkdir -p build/ios/ipa
rm -rf build/ios/ipa/Payload build/ios/ipa/SmartAccess-unsigned.ipa
mkdir -p build/ios/ipa/Payload
ditto build/ios/iphoneos/Runner.app build/ios/ipa/Payload/Runner.app
cd build/ios/ipa
zip -qry SmartAccess-unsigned.ipa Payload
cd ../../..
```

Output: `build/ios/ipa/SmartAccess-unsigned.ipa`. This is an unsigned device build, not a simulator build. A sideloading tool must sign and provision it before installation.

## Architecture

The code uses feature-based architecture with Riverpod state management and GoRouter navigation.

```text
lib/
  main.dart
  app/
    bootstrap.dart       # Hive and saved appearance initialization
    router/              # Routes and retained navigation branches
    theme/               # Theme definitions, controller, and state
    widgets/             # App shell, startup, and lifecycle handling
  core/
    constants/           # Centralized UI text
    helpers/             # Shared color constants
    services/            # Foreground position access and local notifications
    storage/             # Hive, secure storage, and preferences services
    widgets/             # Reusable layout and presentation components
  features/
    authentication/
    dashboard/
    location/
    tracking/
    geofencing/
    settings/
```

Features use separate `models`, `services`, `controllers`, `states`, `screens`, and `widgets` directories where needed. Feature-specific helpers and constants remain within the feature.

| Layer | Responsibility |
| --- | --- |
| Screens and widgets | Render state and forward user actions; reusable widgets live in separate files |
| Controllers | Coordinate permissions, services, lifecycle events, and immutable UI state |
| Services | Encapsulate native plugins, storage, calculations, serialization, and file sharing |
| Models and adapters | Represent authentication data, positions, route samples, sessions, and geofences |
| States | Represent loading, active, empty, error, cached, and paused states |

### Application flow

1. Initialize Hive and restore the saved theme.
2. Load authentication preferences from secure storage and show PIN setup or unlock.
3. After unlocking, restore dashboard summaries and saved feature data.
4. Navigate between Overview, Location, Tracking, Areas, and Settings using retained GoRouter branches.
5. Coordinate foreground/background transitions centrally through `AppLifecycleHandler`.

Tracking and geofencing use the shared foreground position service. Controllers own and cancel their subscriptions, preventing duplicate listeners across navigation and lifecycle changes. Hive adapters are handwritten; no code generation or `build_runner` step is required.

## Storage and security

| Storage | Data |
| --- | --- |
| Hive | Latest saved location/address, tracking checkpoints, completed journey history, and geofences |
| Flutter Secure Storage | Salted PIN verifier, biometric preference, auto-lock policy, failed attempts/lockout expiry, and last successful authentication |
| SharedPreferences | Selected appearance mode |
| Temporary app storage | Generated CSV/JSON exports; old export files are eligible for cleanup after one day |

The PIN is stored as a salted PBKDF2-HMAC-SHA256 verifier using 600,000 iterations. Derivation runs outside the UI isolate. Raw PINs and biometric data are not persisted. Biometric verification is performed by the operating system.

Five incorrect PIN attempts trigger a persisted 30-second lockout. Automatic lock options are **Immediately**, **30 seconds**, **1 minute**, and **5 minutes**. Positive durations apply to foreground inactivity and elapsed background time; **Immediately** locks when the app leaves the foreground. Inactive and locked app content is hidden by the authentication gate.

Location and journey data use local Hive storage without additional Hive database encryption. PIN recovery/reset and screenshot blocking are not implemented. PIN verification can take longer on debug builds or emulators because of the hashing work.

## Offline and lifecycle behavior

| Function | Offline behavior |
| --- | --- |
| PIN, authentication preferences, and appearance | Stored locally |
| GPS coordinates and accuracy | Available when the device can obtain a location fix |
| Tracking distance, speed, and duration | Calculated locally |
| Journey history and geofence management | Persisted locally across restarts |
| Geofence boundary evaluation and local notifications | Work without a backend while foreground monitoring is active |
| CSV/JSON generation | Works offline; the selected sharing destination may need internet |
| Map imagery | Previously viewed tiles may be available from cache; uncached areas require internet |
| Address lookup | Uses the device geocoder, which may require internet; matching saved addresses remain available |

The app is backend-free, but map imagery and fresh reverse-geocoding results are **not guaranteed to work fully offline**. The map cache is configured for 100 MB and may expire or be evicted. No offline map regions or address dataset are bundled.

Tracking pauses when the app is backgrounded, locked, or loses required GPS access. Geofence monitoring stops in those cases. Resume tracking or restart monitoring explicitly after returning. Background tracking is not implemented.

An unfinished tracking session is checkpointed locally and restored as paused after an interrupted run. Paused time is excluded from active duration, and separate route segments prevent lines being drawn across pauses. Geofence presence is established from the first reliable fix; notifications wait for a confirmed boundary crossing. Recent crossing events are held in memory, while the saved boundaries persist.

## Tracking history export

Open **Tracking → View history → Export history** and choose a format:

- **CSV:** One row per GPS sample, with session summary fields repeated. Sessions without GPS samples still receive a summary row. UTF-8 encoding, a BOM, and quoted fields support spreadsheet applications.
- **JSON:** A versioned document containing completed sessions and their nested route samples.

Exports use UTC timestamps, metres for distance/accuracy, metres per second for speed, and milliseconds for duration. Route segment identifiers preserve pause boundaries. Active or paused unfinished journeys are excluded, and exporting does not modify the saved history. The native share sheet determines which save/share destinations are available on the device.

## Permissions

| Permission or capability | Purpose |
| --- | --- |
| Foreground location | Current position, active tracking, and geofence monitoring |
| Notifications | Tracking status changes and geofence entry/exit alerts |
| Biometrics / Face ID | Optional device authentication, with PIN fallback |
| Internet | Map tile loading and platform address lookups when required |

Location permission is requested after a contextual explanation. Notification permission is requested when starting tracking or geofence monitoring. Denying notifications does not prevent local tracking or boundary detection. Exports use app-private temporary files and native sharing; broad external-storage permission is not requested.

## Dependencies

Versions below are the direct constraints in `pubspec.yaml`; `pubspec.lock` records the resolved versions.

| Package | Version | Purpose |
| --- | --- | --- |
| `flutter_riverpod` | `^3.3.2` | State management and dependency injection |
| `go_router` | `^17.2.3` | Navigation and retained tab branches |
| `hive_flutter` | `^1.1.0` | Local typed storage |
| `flutter_secure_storage` | `^10.3.4` | Sensitive authentication preferences |
| `shared_preferences` | `^2.5.5` | Theme preference |
| `local_auth` | `^3.0.1` | Fingerprint / Face ID authentication |
| `cryptography` | `^2.9.0` | Salted PIN derivation and verification |
| `geolocator` | `^14.0.2` | Location permissions, GPS, and local distance calculations |
| `geocoding` | `^5.0.1` | Native reverse geocoding |
| `flutter_map` | `^8.3.2` | Interactive maps, routes, circles, and tile caching |
| `latlong2` | `^0.10.1` | Geographic coordinates and boundary calculations |
| `url_launcher` | `^6.3.2` | Map attribution links |
| `flutter_local_notifications` | `^20.1.0` | Tracking and geofence alerts |
| `share_plus` | `^11.1.0` | Native CSV/JSON file sharing |
| `path_provider` | `^2.1.5` | Temporary export directory |
| `flutter_lints` | `^5.0.0` | Development lint rules |

Permission handling uses the location and notification plugins' native permission APIs; a separate permission-handler package is not required.

## Map configuration

The default tile source is OpenStreetMap, with visible contributor attribution. There is no Google Maps API key requirement. To use a compatible tile endpoint:

```bash
flutter run --dart-define=MAP_TILE_URL='https://your-tile-host/{z}/{x}/{y}.png'
```

The endpoint's attribution, access requirements, caching rules, and usage policy must match the selected provider. The default configuration uses the OpenStreetMap attribution link.

## Code checks

```bash
dart format --output=none --set-exit-if-changed lib
flutter analyze
```

Automated test files are not included in this repository. Verify GPS movement, biometric enrollment, native permission prompts, notifications, file sharing, and lifecycle behavior on Android and iOS devices before distributing a build.
