import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/app/app.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/core/storage/hive_service.dart';
import 'package:smart_access/core/storage/preferences_service.dart';
import 'package:smart_access/core/storage/secure_storage_service.dart';
import 'package:smart_access/features/authentication/services/biometric_service.dart';
import 'package:smart_access/features/authentication/services/pin_service.dart';

import 'helpers/authentication_fakes.dart';
import 'widget_test.dart' show MemoryPreferences, TestHiveService;

Future<void> launchAuthentication(
  WidgetTester tester,
  MemorySecureStorage storage,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(MemoryPreferences()),
        hiveServiceProvider.overrideWithValue(TestHiveService()),
        secureStorageServiceProvider.overrideWithValue(storage),
        pinServiceProvider.overrideWithValue(FakePinService()),
        biometricServiceProvider.overrideWithValue(FakeBiometricService()),
      ],
      child: const SmartAccess(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PIN setup gates access, validates confirmation, and unlocks', (
    tester,
  ) async {
    await launchAuthentication(tester, MemorySecureStorage());
    expect(find.text(TextConstants.setupPinTitle), findsOneWidget);
    expect(find.text(TextConstants.welcomeTitle), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, '123456');
    await tester.enterText(find.byType(TextFormField).last, '654321');
    await tester.ensureVisible(find.text(TextConstants.createPin));
    await tester.tap(find.text(TextConstants.createPin));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.pinMismatch), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.ensureVisible(find.text(TextConstants.createPin));
    await tester.tap(find.text(TextConstants.createPin));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.welcomeTitle), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.welcomeTitle), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.unlockTitle), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text(TextConstants.unlock));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.welcomeTitle), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('PIN form fits $size with enlarged text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      await launchAuthentication(tester, MemorySecureStorage());
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '123456');
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.ensureVisible(find.text(TextConstants.createPin));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('secure storage error blocks access and allows retry', (
    tester,
  ) async {
    final storage = MemorySecureStorage()..failRead = true;
    await launchAuthentication(tester, storage);
    expect(find.text(TextConstants.authenticationErrorTitle), findsOneWidget);
    expect(find.text(TextConstants.welcomeTitle), findsNothing);
    storage.failRead = false;
    await tester.tap(find.text(TextConstants.retry));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.setupPinTitle), findsOneWidget);
  });
}
