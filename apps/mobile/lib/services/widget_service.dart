import 'dart:io';
import 'package:flutter/services.dart';
import '../models/prayer_schedule.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.minar.app/widget');

  static Future<void> updateWidgets({
    required PrayerSchedule schedule,
    required NextPrayer? nextPrayer,
    required bool useTurkish,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      final prayersList = schedule.items.map((item) {
        final isNext = nextPrayer?.item.type == item.type;
        return {
          'type': item.type.englishName,
          'name': item.type.displayName(useTurkish: useTurkish),
          'time': item.time,
          'isNext': isNext,
        };
      }).toList();

      final nextName = nextPrayer?.item.type.displayName(useTurkish: useTurkish) ?? '';
      final nextTime = nextPrayer?.item.time ?? '';
      final nextRemaining = nextPrayer?.formattedRemaining ?? '';

      await _channel.invokeMethod('updateWidgets', {
        'city': schedule.city,
        'country': schedule.country,
        'hijriDate': schedule.hijriDate,
        'gregorianDate': schedule.gregorianDate,
        'useTurkish': useTurkish,
        'nextName': nextName,
        'nextTime': nextTime,
        'nextRemaining': nextRemaining,
        'isTomorrowFajr': nextPrayer?.isTomorrowFajr ?? false,
        'prayers': prayersList,
      });
    } catch (_) {
      // Non-fatal if platform channel is unhandled or in tests
    }
  }
}
