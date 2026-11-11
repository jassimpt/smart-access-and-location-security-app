import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/app/app.dart';
import 'package:smart_access/app/bootstrap.dart';
import 'package:smart_access/app/theme/theme_controller.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/core/storage/hive_service.dart';
import 'package:smart_access/core/storage/preferences_service.dart';

class MemoryPreferences implements PreferencesService {
  ThemeMode savedMode = ThemeMode.system;
  bool failSave = false;

  @override
  Future<ThemeMode> readThemeMode() async => savedMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    if (failSave) throw StateError('Storage unavailable');
    savedMode = mode;
  }
}

class TestHiveService extends HiveService {
  bool failInitialization = false;

  @override
  Future<void> initialize() async {
    if (failInitialization) throw StateError('Storage unavailable');
  }
}

Future<void> launchApp(
  WidgetTester tester, {
  required MemoryPreferences preferences,
  TestHiveService? hive,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
        hiveServiceProvider.overrideWithValue(hive ?? TestHiveService()),
      ],
      child: const SmartAccess(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('appearance survives a fresh app scope and navigation', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    await launchApp(tester, preferences: preferences);
    await tester.ensureVisible(find.text(TextConstants.customizeAppearance));
    await tester.tap(find.text(TextConstants.customizeAppearance));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(TextConstants.darkTheme));
    await tester.tap(find.text(TextConstants.darkTheme));
    await tester.pumpAndSettle();
    expect(preferences.savedMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text(TextConstants.appearance))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text(TextConstants.overview).last);
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.welcomeTitle), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await launchApp(tester, preferences: preferences);
    expect(
      Theme.of(
        tester.element(find.text(TextConstants.welcomeTitle)),
      ).brightness,
      Brightness.dark,
    );
  });

  testWidgets('appearance follows system brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await launchApp(tester, preferences: MemoryPreferences());
    expect(
      Theme.of(
        tester.element(find.text(TextConstants.welcomeTitle)),
      ).brightness,
      Brightness.dark,
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(
      Theme.of(
        tester.element(find.text(TextConstants.welcomeTitle)),
      ).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'failed appearance save retains previous selection and allows retry',
    (tester) async {
      final preferences = MemoryPreferences()..failSave = true;
      await launchApp(tester, preferences: preferences);
      await tester.ensureVisible(find.text(TextConstants.customizeAppearance));
      await tester.tap(find.text(TextConstants.customizeAppearance));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(TextConstants.darkTheme));
      await tester.tap(find.text(TextConstants.darkTheme));
      await tester.pumpAndSettle();
      expect(find.text(TextConstants.themeSaveError), findsOneWidget);
      expect(preferences.savedMode, ThemeMode.system);
      preferences.failSave = false;
      await tester.ensureVisible(find.text(TextConstants.darkTheme));
      await tester.tap(find.text(TextConstants.darkTheme));
      await tester.pumpAndSettle();
      expect(preferences.savedMode, ThemeMode.dark);
      expect(find.text(TextConstants.themeSaveError), findsNothing);
    },
  );

  testWidgets('startup storage failure can be retried', (tester) async {
    final hive = TestHiveService()..failInitialization = true;
    await launchApp(tester, preferences: MemoryPreferences(), hive: hive);
    expect(find.text(TextConstants.startupErrorTitle), findsOneWidget);
    hive.failInitialization = false;
    await tester.tap(find.text(TextConstants.retry));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.welcomeTitle), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('layout fits $size with enlarged text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launchApp(tester, preferences: MemoryPreferences());
      expect(tester.takeException(), isNull);
      expect(
        find.byType(NavigationRail),
        size.width >= 720 ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text(TextConstants.settings).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(TextConstants.darkTheme),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(TextConstants.darkTheme));
      await tester.tap(find.text(TextConstants.darkTheme));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  test('theme controller ignores concurrent saves', () async {
    final preferences = MemoryPreferences();
    final container = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
        hiveServiceProvider.overrideWithValue(TestHiveService()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appInitializationProvider.future);
    final controller = container.read(themeControllerProvider.notifier);
    final firstSave = controller.setThemeMode(ThemeMode.dark);
    await controller.setThemeMode(ThemeMode.light);
    await firstSave;
    expect(container.read(themeControllerProvider).mode, ThemeMode.dark);
    expect(preferences.savedMode, ThemeMode.dark);
  });
}
