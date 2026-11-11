import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/app/app.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/core/storage/hive_service.dart';
import 'package:smart_access/core/storage/preferences_service.dart';
import 'package:smart_access/features/authentication/controllers/authentication_controller.dart';
import 'package:smart_access/features/location/models/location_device_status.dart';
import 'package:smart_access/features/location/services/address_service.dart';
import 'package:smart_access/features/location/services/location_service.dart';
import 'package:smart_access/features/location/services/location_storage_service.dart';
import 'package:smart_access/features/location/widgets/map_tile_layer.dart';

import 'helpers/authentication_fakes.dart';
import 'helpers/location_fakes.dart';
import 'widget_test.dart' show MemoryPreferences, TestHiveService;

Future<void> launchLocation(
  WidgetTester tester,
  FakeLocationService service, {
  MemoryLocationStorage? storage,
  FakeAddressService? addresses,
  TileProvider Function()? tiles,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(MemoryPreferences()),
        hiveServiceProvider.overrideWithValue(TestHiveService()),
        authenticationControllerProvider.overrideWith(
          UnlockedAuthenticationController.new,
        ),
        locationServiceProvider.overrideWithValue(service),
        locationStorageServiceProvider.overrideWithValue(
          storage ?? MemoryLocationStorage(),
        ),
        addressServiceProvider.overrideWithValue(
          addresses ?? FakeAddressService(),
        ),
        mapTileProviderFactoryProvider.overrideWithValue(
          tiles ?? OfflineTestTileProvider.new,
        ),
      ],
      child: const SmartAccess(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(TextConstants.location).last);
  await tester.pumpAndSettle();
}

class MissingTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List(0));
}

void main() {
  testWidgets(
    'explains permissions before requesting access and displays a GPS fix',
    (tester) async {
      final service = FakeLocationService()
        ..permission = LocationPermissionStatus.denied;
      addTearDown(service.changes.close);
      await launchLocation(tester, service);
      expect(service.permissionRequests, 0);
      expect(
        find.text(TextConstants.locationPermissionExplanation),
        findsOneWidget,
      );
      await tester.tap(find.text(TextConstants.allowLocation));
      await tester.pumpAndSettle();
      expect(service.permissionRequests, 1);
      expect(find.text('12.971600'), findsOneWidget);
      expect(find.text('77.594600'), findsOneWidget);
      expect(find.text('± 8.5 m'), findsOneWidget);
      expect(find.text(TextConstants.preciseLocation), findsOneWidget);
      expect(find.text('Bengaluru, Karnataka, India'), findsOneWidget);
      expect(find.text(TextConstants.mapAttribution), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offline saved location stays visible with GPS disabled', (
    tester,
  ) async {
    final service = FakeLocationService()..serviceEnabled = false;
    final storage = MemoryLocationStorage()
      ..saved = sampleLocation(address: 'Saved Bengaluru address');
    addTearDown(service.changes.close);
    await launchLocation(tester, service, storage: storage);
    expect(find.text(TextConstants.gpsDisabledTitle), findsOneWidget);
    expect(find.text(TextConstants.lastKnownPosition), findsOneWidget);
    expect(find.text('12.971600'), findsOneWidget);
    expect(find.text('Saved Bengaluru address'), findsOneWidget);
    expect(find.text(TextConstants.openLocationSettings), findsOneWidget);
    expect(service.positionRequests, 0);
  });

  testWidgets(
    'missing map imagery keeps coordinates usable and offers map retry',
    (tester) async {
      final service = FakeLocationService();
      addTearDown(service.changes.close);
      var attempts = 0;
      await launchLocation(
        tester,
        service,
        tiles: () =>
            ++attempts == 1 ? MissingTileProvider() : OfflineTestTileProvider(),
      );
      expect(find.text(TextConstants.mapUnavailable), findsOneWidget);
      expect(find.text('12.971600'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(TextConstants.retryMap));
      await tester.tap(find.text(TextConstants.retryMap));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text(TextConstants.mapUnavailable), findsNothing);
      expect(find.text('12.971600'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('permanent denial presents an app settings action', (
    tester,
  ) async {
    final service = FakeLocationService()
      ..permission = LocationPermissionStatus.permanentlyDenied;
    addTearDown(service.changes.close);
    await launchLocation(tester, service);
    expect(find.text(TextConstants.permissionBlockedTitle), findsOneWidget);
    expect(find.text(TextConstants.openAppSettings), findsOneWidget);
    expect(service.permissionRequests, 0);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets(
      'location layout fits $size with enlarged text and missing address',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final service = FakeLocationService();
        addTearDown(service.changes.close);
        await launchLocation(
          tester,
          service,
          addresses: FakeAddressService()..address = null,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(TextConstants.addressUnavailable));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byTooltip(TextConstants.centerMap));
        await tester.tap(find.byTooltip(TextConstants.centerMap));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
