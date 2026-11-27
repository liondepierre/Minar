import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_schedule.dart';
import '../models/weekly_schedule.dart';
import '../ui/theme.dart';
import 'notification_card_renderer.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _nativeChannel =
      MethodChannel('com.minar.app/pinned_notification');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(initSettings);
      tz.initializeTimeZones();
      if (Platform.isAndroid) {
        try {
          final tzName =
              await _nativeChannel.invokeMethod<String>('getLocalTimeZone');
          if (tzName != null && tzName.isNotEmpty) {
            tz.setLocalLocation(tz.getLocation(tzName));
          }
        } catch (_) {}
      }
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.deleteNotificationChannel('minar_pinned_channel');
      _isInitialized = true;
    } catch (e) {
      // Graceful fallback: notifications disabled on unsupported/misconfigured test hosts
      _isInitialized = false;
    }
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static const int _pinnedNotificationId = 888;

  Future<void> updatePinnedNotification(
    PrayerSchedule schedule,
    NextPrayer? nextPrayer, {
    required bool useTurkish,
    String style = 'table',
  }) async {
    try {
      if (!_isInitialized) await init();
      if (!_isInitialized) return;

      // All three styles render styled PNGs and push via the native channel
      // so no Minar icon appears in the status bar or notification header.
      if (Platform.isAndroid) {
        Uint8List? compactBytes;
        Uint8List? expandedBytes;

        if (style == 'minimal') {
          compactBytes = await NotificationCardRenderer.renderMinimalCard(
            schedule: schedule,
            nextPrayer: nextPrayer,
            useTurkish: useTurkish,
          );
        } else {
          compactBytes = await NotificationCardRenderer.renderCompactCard(
            schedule: schedule,
            nextPrayer: nextPrayer,
            useTurkish: useTurkish,
          );
        }

        // Expanded view (shows rich hero card with countdown like e-Diyanet when dropdown chevron is expanded)
        expandedBytes = await NotificationCardRenderer.renderExpandedHeroCard(
          schedule: schedule,
          nextPrayer: nextPrayer,
          useTurkish: useTurkish,
        );

        expandedBytes ??= await NotificationCardRenderer.renderTableCard(
          schedule: schedule,
          nextPrayer: nextPrayer,
          useTurkish: useTurkish,
        );

        if (compactBytes != null || expandedBytes != null) {
          try {
            await _nativeChannel.invokeMethod('showPinnedTable', {
              'bytes': expandedBytes ?? compactBytes,
              'compactBytes': compactBytes ?? expandedBytes,
              'expandedBytes': expandedBytes ?? compactBytes,
            });
            return;
          } catch (_) {}
        }
      }

      // ── iOS / fallback text-only notification ──────────────────────────────
      final nextName =
          nextPrayer?.item.type.displayName(useTurkish: useTurkish);
      final nextTitle = nextPrayer != null
          ? 'Next: $nextName ${nextPrayer.item.time} (${nextPrayer.formattedRemaining})'
          : 'Prayer Times';

      final summary = schedule.items
          .map((i) =>
              '${i.type.displayName(useTurkish: useTurkish)} ${i.time}')
          .join(' • ');

      StyleInformation? styleInfo;
      String contentTitle = nextTitle;
      String contentBody = summary;

      switch (style) {
        case 'minimal':
          contentBody = '${schedule.city} • $nextTitle';
          styleInfo = null;
          break;
        case 'compact':
        case 'table':
        default:
          styleInfo = BigTextStyleInformation(
            summary,
            contentTitle: nextTitle,
            summaryText: '${schedule.city}, ${schedule.country}',
          );
          break;
      }

      final androidDetails = AndroidNotificationDetails(
        'minar_pinned_schedule_v2',
        'Pinned Prayer Schedule',
        channelDescription:
            'Ongoing pinned notification showing current prayer schedule',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        silent: true,
        playSound: false,
        enableVibration: false,
        color: MinarTheme.surfaceSolid,
        styleInformation: styleInfo,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      await _plugin.show(
        _pinnedNotificationId,
        contentTitle,
        contentBody,
        NotificationDetails(android: androidDetails, iOS: darwinDetails),
      );
    } catch (_) {}
  }

  Future<void> cancelPinnedNotification() async {
    try {
      if (Platform.isAndroid) {
        try {
          await _nativeChannel.invokeMethod('cancelPinnedTable');
        } catch (_) {}
      }
      await _plugin.cancel(_pinnedNotificationId);
    } catch (_) {}
  }

  Future<void> sendTestNotification({required bool useTurkish}) async {
    try {
      if (!_isInitialized) await init();
      if (!_isInitialized) return;

      const androidDetails = AndroidNotificationDetails(
        'minar_prayer_channel',
        'Minar Prayer Notifications',
        channelDescription: 'Notifications for daily salah prayer times',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );

      final title =
          useTurkish ? 'Minar Test Bildirimi' : 'Minar Test Notification';
      final body = useTurkish
          ? 'Ezan ve namaz vakti bildirimleri düzgün çalışıyor.'
          : 'Salah prayer notifications are working properly.';

      await _plugin.show(
        999,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      );
    } catch (_) {}
  }

  Future<void> scheduleWeeklyPrayerReminders(
    WeeklySchedule weekly, {
    required bool useTurkish,
  }) async {
    try {
      if (!_isInitialized) await init();
      if (!_isInitialized) return;

      // Cancel previous prayer reminder notifications (IDs 0..70)
      for (int i = 0; i <= 70; i++) {
        await _plugin.cancel(i);
      }

      final now = DateTime.now();

      const androidDetails = AndroidNotificationDetails(
        'minar_prayer_channel',
        'Minar Prayer Notifications',
        channelDescription: 'Notifications for daily salah prayer times',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // Iterate through the week's days and schedule all upcoming prayers
      for (int dayIdx = 0; dayIdx < weekly.days.length; dayIdx++) {
        final daySchedule = weekly.days[dayIdx];
        for (int pIdx = 0; pIdx < daySchedule.items.length; pIdx++) {
          final item = daySchedule.items[pIdx];
          if (item.dateTime.isAfter(now)) {
            final prayerName = item.type.displayName(useTurkish: useTurkish);
            final title = '$prayerName (${item.time})';
            final body = 'Time for $prayerName prayer.';

            final scheduledTz = tz.TZDateTime(
              tz.local,
              item.dateTime.year,
              item.dateTime.month,
              item.dateTime.day,
              item.dateTime.hour,
              item.dateTime.minute,
            );

            final notifId = dayIdx * 10 + pIdx;

            await _plugin.zonedSchedule(
              notifId,
              title,
              body,
              scheduledTz,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> schedulePrayerReminders(
    PrayerSchedule schedule, {
    required bool useTurkish,
  }) async {
    try {
      if (!_isInitialized) await init();
      if (!_isInitialized) return;

      // Cancel previous scheduled reminders (IDs 0..5)
      for (int i = 0; i < 6; i++) {
        await _plugin.cancel(i);
      }

      final now = DateTime.now();

      for (int i = 0; i < schedule.items.length; i++) {
        final item = schedule.items[i];
        if (item.dateTime.isAfter(now)) {
          final prayerName = item.type.displayName(useTurkish: useTurkish);
          final title = '$prayerName (${item.time})';
          final body = 'Time for $prayerName prayer.';

          const androidDetails = AndroidNotificationDetails(
            'minar_prayer_channel',
            'Minar Prayer Notifications',
            channelDescription: 'Notifications for daily salah prayer times',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

          const darwinDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          );

          const notificationDetails = NotificationDetails(
            android: androidDetails,
            iOS: darwinDetails,
            macOS: darwinDetails,
          );

          final scheduledTz = tz.TZDateTime(
            tz.local,
            item.dateTime.year,
            item.dateTime.month,
            item.dateTime.day,
            item.dateTime.hour,
            item.dateTime.minute,
          );

          await _plugin.zonedSchedule(
            i,
            title,
            body,
            scheduledTz,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      // Non-fatal
    }
  }

  String timeFormat(String time) => time;
}
