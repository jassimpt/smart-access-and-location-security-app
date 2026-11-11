import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_access/core/storage/hive_service.dart';
import 'package:smart_access/features/location/models/location_snapshot.dart';
import 'package:smart_access/features/location/services/address_service.dart';
import 'package:smart_access/features/location/services/location_storage_service.dart';

import 'helpers/location_fakes.dart';

void main() {
  test(
    'typed Hive model persists coordinates and matching address across reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'smart-access-location-test-',
      );
      try {
        Hive.init(directory.path);
        final storage = LocationStorageService(HiveService());
        final original = sampleLocation(address: 'Bengaluru, India');
        await storage.saveLatest(original);
        await Hive.close();
        final restored = await LocationStorageService(
          HiveService(),
        ).loadLatest();
        expect(restored!.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
        expect(restored.accuracy, original.accuracy);
        expect(restored.address, original.address);
        expect(restored.recordedAt, original.recordedAt);
        expect(restored.isApproximate, original.isApproximate);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('rejects invalid or non-finite coordinates', () {
    expect(
      () => LocationSnapshot(
        latitude: 91,
        longitude: 77,
        accuracy: 1,
        recordedAt: DateTime.now(),
      ),
      throwsFormatException,
    );
    expect(
      () => LocationSnapshot(
        latitude: 12,
        longitude: double.nan,
        accuracy: 1,
        recordedAt: DateTime.now(),
      ),
      throwsFormatException,
    );
  });

  test('address formatting omits empty and repeated components', () {
    final service = AddressService();
    expect(
      service.formatPlacemark(
        const Placemark(
          street: ' Main Road ',
          subLocality: 'main road',
          locality: 'Bengaluru',
          country: 'India',
        ),
      ),
      'Main Road, Bengaluru, India',
    );
    expect(service.formatPlacemark(const Placemark()), isNull);
  });
}
