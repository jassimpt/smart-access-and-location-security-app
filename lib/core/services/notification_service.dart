import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/text_constants.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

enum TrackingNotification { started, paused, resumed, stopped }

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  /// Initializes local notifications without showing a permission prompt.
  Future<void> _initialize() => _initialization ??= _initializePlugin();

  /// Configures the Android icon and iOS foreground notification presentation.
  Future<void> _initializePlugin() async {
    try {
      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_tracking'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      if (initialized != true) throw StateError('Notifications unavailable');
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  /// Requests notification permission only after the tracking explanation.
  Future<bool> requestPermission() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    try {
      await _initialize();
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: false, sound: true) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Posts the latest tracking status locally using one replaceable notification.
  Future<void> showTrackingUpdate(TrackingNotification status) async {
    await _initialize();
    final (title, body) = switch (status) {
      TrackingNotification.started => (
        TextConstants.trackingStartedNotification,
        TextConstants.trackingStartedBody,
      ),
      TrackingNotification.paused => (
        TextConstants.trackingPausedNotification,
        TextConstants.trackingPausedBody,
      ),
      TrackingNotification.resumed => (
        TextConstants.trackingResumedNotification,
        TextConstants.trackingResumedBody,
      ),
      TrackingNotification.stopped => (
        TextConstants.trackingStoppedNotification,
        TextConstants.trackingStoppedBody,
      ),
    };
    await _plugin.show(
      id: 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tracking_updates',
          TextConstants.trackingChannelName,
          channelDescription: TextConstants.trackingChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
    );
  }
}
