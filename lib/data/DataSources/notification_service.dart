// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final bool forceTestMode = false;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        if (kDebugMode) {
          print('Notification tapped: ${notificationResponse.payload}');
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleSimpleExpirationNotification({
    required int id,
    required String itemName,
    required DateTime expirationDate,
    bool forceShortDelayForTestButton = false,
  }) async {
    tz.TZDateTime scheduledTZDateTime;
    String notificationMessageSuffix;
    int effectiveDaysToNotifyBefore = 3;

    if (forceShortDelayForTestButton) {
      scheduledTZDateTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 15));
      notificationMessageSuffix = " (BUTTON TEST)";
      print('SETTINGS BUTTON TEST: Scheduling notification to appear in 15 seconds for "$itemName"');
    } else if (forceTestMode) {
      scheduledTZDateTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 15));
      notificationMessageSuffix = " (FORCED GLOBAL TEST)";
      print('FORCED GLOBAL TEST MODE: Scheduling notification to appear in 15 seconds for "$itemName"');
    } else {
      DateTime notificationTime = expirationDate.subtract(Duration(days: effectiveDaysToNotifyBefore));
      scheduledTZDateTime = tz.TZDateTime.from(notificationTime, tz.local);
      notificationMessageSuffix = " (in $effectiveDaysToNotifyBefore days)";

      if (!notificationTime.isAfter(DateTime.now()) || !expirationDate.isAfter(DateTime.now())) {
        if (kDebugMode) {
          if (!expirationDate.isAfter(DateTime.now())) {
            print('NORMAL LOGIC: Item "$itemName" (ID: $id) has already expired. Notification not scheduled.');
          } else {
            print(
              'NORMAL LOGIC: Notification for "$itemName" (ID: $id) not scheduled. The $effectiveDaysToNotifyBefore-day prior mark is not in the future.',
            );
          }
        }
        return;
      }
      if (kDebugMode) {
        print(
          'NORMAL LOGIC: Scheduling notification for "$itemName" (ID: $id) for $effectiveDaysToNotifyBefore days prior.',
        );
      }
    }

    if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledTZDateTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'item_expiration_channel_simple',
      'Item Expiration Alerts',
      channelDescription: 'Notifies before an item expires.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Item Expiring Soon!',
        '$itemName will expire on ${DateFormat.yMd().format(expirationDate)}$notificationMessageSuffix.',
        scheduledTZDateTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.dateAndTime,
        payload: 'item_id=$id',
      );
      print('NOTIFICATION SCHEDULED: "$itemName" (ID: $id) will fire at ${scheduledTZDateTime.toLocal()}');
    } catch (e) {
      print('NOTIFICATION ERROR: Failed to schedule for "$itemName" (ID: $id): $e');
    }
  }

  Future<void> triggerTestNotification() async {
    const int testNotificationId = 99999;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_notification_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        testNotificationId,
        'Test Notification',
        'This is a test notification to verify the notification system is working correctly.',
        platformDetails,
      );

      print('TEST NOTIFICATION: Triggered immediate test notification with ID: $testNotificationId');
    } catch (e) {
      print('TEST NOTIFICATION ERROR: Failed to show test notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Cancelled notification with ID: $id');
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('CANCELLED ALL NOTIFICATIONS');
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notification tapped in background: ${notificationResponse.payload}');
}
