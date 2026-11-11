import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/features/authentication/controllers/authentication_controller.dart';
import 'package:smart_access/features/location/controllers/location_controller.dart';
import 'package:smart_access/features/location/models/location_device_status.dart';
import 'package:smart_access/features/location/models/location_snapshot.dart';
import 'package:smart_access/features/location/services/address_service.dart';
import 'package:smart_access/features/location/services/location_service.dart';
import 'package:smart_access/features/location/services/location_storage_service.dart';
import 'package:smart_access/features/location/states/location_state.dart';

import 'helpers/authentication_fakes.dart';
import 'helpers/location_fakes.dart';

void main() {
  late FakeLocationService service;
  late FakeAddressService addresses;
  late MemoryLocationStorage storage;
  late ProviderContainer container;

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      authenticationControllerProvider.overrideWith(
        UnlockedAuthenticationController.new,
      ),
      locationServiceProvider.overrideWithValue(service),
      addressServiceProvider.overrideWithValue(addresses),
      locationStorageServiceProvider.overrideWithValue(storage),
    ],
  );

  Future<LocationController> initialize() async {
    await container.read(authenticationControllerProvider.future);
    final controller = container.read(locationControllerProvider.notifier);
    await controller.initialize();
    return controller;
  }

  LocationState current() => container.read(locationControllerProvider);

  setUp(() {
    service = FakeLocationService();
    addresses = FakeAddressService();
    storage = MemoryLocationStorage();
    container = createContainer();
  });
  tearDown(() async {
    container.dispose();
    await service.changes.close();
  });

  test(
    'does not prompt or request a position before contextual consent',
    () async {
      service.permission = LocationPermissionStatus.denied;
      final controller = await initialize();
      expect(current().status, LocationStatus.permissionRequired);
      expect(service.permissionRequests, 0);
      expect(service.positionRequests, 0);
      await controller.requestAccess();
      expect(service.permissionRequests, 1);
      expect(current().snapshot!.address, addresses.address);
      expect(current().isCached, isFalse);
      expect(storage.saved!.address, addresses.address);
    },
  );

  test(
    'handles denied and permanently denied responses without GPS access',
    () async {
      service.permission = LocationPermissionStatus.denied;
      service.requestOutcome = LocationPermissionStatus.denied;
      final controller = await initialize();
      await controller.requestAccess();
      expect(current().status, LocationStatus.permissionRequired);
      service.requestOutcome = LocationPermissionStatus.permanentlyDenied;
      await controller.requestAccess();
      expect(current().status, LocationStatus.permanentlyDenied);
      expect(service.positionRequests, 0);
      service.permission = LocationPermissionStatus.denied;
      await controller.refresh();
      expect(current().status, LocationStatus.permanentlyDenied);
      service.permission = LocationPermissionStatus.granted;
      await controller.refresh();
      expect(current().status, LocationStatus.ready);
    },
  );

  test(
    'disabled GPS retains saved coordinates without requesting a fix',
    () async {
      storage.saved = sampleLocation(address: 'Saved Bengaluru address');
      service.serviceEnabled = false;
      await initialize();
      expect(current().status, LocationStatus.gpsDisabled);
      expect(current().snapshot!.address, 'Saved Bengaluru address');
      expect(current().isCached, isTrue);
      expect(service.positionRequests, 0);
    },
  );

  test(
    'address lookup failure leaves GPS and local persistence functional',
    () async {
      addresses.address = null;
      await initialize();
      expect(current().status, LocationStatus.ready);
      expect(current().snapshot!.latitude, 12.9716);
      expect(current().snapshot!.address, isNull);
      expect(storage.saved, isNotNull);
      expect(current().isBusy, isFalse);
    },
  );

  test(
    'reuses a saved nearby address but never assigns it to another city',
    () async {
      storage.saved = sampleLocation(address: 'Saved Bengaluru address');
      addresses.address = null;
      final controller = await initialize();
      expect(current().snapshot!.address, 'Saved Bengaluru address');
      expect(current().isAddressCached, isTrue);
      expect(addresses.calls, 0);
      service.position = sampleLocation(latitude: 28.6139, longitude: 77.2090);
      await controller.refresh();
      expect(current().snapshot!.address, isNull);
      expect(current().isAddressCached, isFalse);
      expect(addresses.calls, 1);
    },
  );

  test(
    'restores last known coordinates after restart without internet or a GPS fix',
    () async {
      await initialize();
      container.dispose();
      container = createContainer();
      service.positionError = TimeoutException('No fix');
      await initialize();
      expect(current().snapshot!.latitude, 12.9716);
      expect(current().snapshot!.address, 'Bengaluru, Karnataka, India');
      expect(current().isCached, isTrue);
      expect(current().status, LocationStatus.unavailable);
    },
  );

  test('cache failures do not hide a usable live GPS result', () async {
    storage.failRead = true;
    storage.failWrite = true;
    final controller = await initialize();
    expect(current().snapshot, isNotNull);
    expect(current().storageWarning, TextConstants.locationSaveFailed);
    storage.failWrite = false;
    await controller.refresh();
    expect(current().storageWarning, isNull);
  });

  test(
    'repeated refreshes keep exactly one service-status subscription',
    () async {
      final controller = await initialize();
      await controller.refresh();
      await controller.refresh();
      expect(service.activeListeners, 1);
      expect(service.totalListeners, 1);
      controller.handleLifecycle(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(service.activeListeners, 0);
      controller.handleLifecycle(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(service.activeListeners, 1);
    },
  );

  test('late GPS readings are discarded after the app backgrounds', () async {
    final controller = await initialize();
    service.pending = Completer<LocationSnapshot>();
    final pending = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    controller.handleLifecycle(AppLifecycleState.paused);
    service.pending!.complete(sampleLocation(latitude: 28.6139));
    await pending;
    expect(current().snapshot!.latitude, 12.9716);
    expect(current().isBusy, isFalse);
  });

  test('concurrent refresh actions do not duplicate GPS requests', () async {
    final controller = await initialize();
    service.pending = Completer<LocationSnapshot>();
    final first = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    final requests = service.positionRequests;
    await controller.refresh();
    expect(service.positionRequests, requests);
    service.pending!.complete(sampleLocation());
    await first;
  });

  test(
    'GPS disabled event immediately marks the displayed reading as last known',
    () async {
      await initialize();
      service.serviceEnabled = false;
      service.changes.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(current().status, LocationStatus.gpsDisabled);
      expect(current().isCached, isTrue);
      expect(current().snapshot, isNotNull);
    },
  );

  test('locking the app stops GPS status monitoring', () async {
    final controller = await initialize();
    final requests = service.positionRequests;
    container.read(authenticationControllerProvider.notifier).lock();
    await Future<void>.delayed(Duration.zero);
    expect(service.activeListeners, 0);
    await controller.refresh();
    expect(service.positionRequests, requests);
  });

  test('settings launch failures show a recovery message', () async {
    final controller = await initialize();
    service.settingsOpen = false;
    await controller.openLocationSettings();
    expect(current().message, TextConstants.locationSettingsUnavailable);
  });
}
