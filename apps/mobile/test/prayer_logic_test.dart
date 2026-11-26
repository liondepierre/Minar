import 'package:flutter_test/flutter_test.dart';
import 'package:minar_mobile/models/calculation_method.dart';
import 'package:minar_mobile/models/prayer_schedule.dart';
import 'package:minar_mobile/models/prayer_type.dart';
import 'package:minar_mobile/models/weekly_schedule.dart';
import 'package:minar_mobile/services/geocoding_service.dart';
import 'package:minar_mobile/services/notification_card_renderer.dart';

void main() {
  group('Minar Core Prayer Logic Tests', () {
    test('Default calculation method is Diyanet (13)', () {
      expect(CalculationMethod.diyanet.id, 13);
      expect(CalculationMethod.fromId(null), CalculationMethod.diyanet);
      expect(CalculationMethod.fromId(13), CalculationMethod.diyanet);
      expect(CalculationMethod.fromId(3), CalculationMethod.mwl);
    });

    test('PrayerType supports Turkish and English names', () {
      expect(PrayerType.fajr.displayName(useTurkish: true), 'İmsak');
      expect(PrayerType.fajr.displayName(useTurkish: false), 'Fajr');
      expect(PrayerType.isha.displayName(useTurkish: true), 'Yatsı');
      expect(PrayerType.isha.displayName(useTurkish: false), 'Isha');
    });

    test('Next prayer calculates correctly mid-day', () {
      final baseDate = DateTime(2026, 10, 25, 12, 0); // 12:00 PM

      final items = [
        PrayerItem(
          type: PrayerType.fajr,
          time: '05:10',
          dateTime: DateTime(2026, 10, 25, 5, 10),
        ),
        PrayerItem(
          type: PrayerType.sunrise,
          time: '07:08',
          dateTime: DateTime(2026, 10, 25, 7, 8),
        ),
        PrayerItem(
          type: PrayerType.dhuhr,
          time: '12:12',
          dateTime: DateTime(2026, 10, 25, 12, 12),
        ),
        PrayerItem(
          type: PrayerType.asr,
          time: '14:30',
          dateTime: DateTime(2026, 10, 25, 14, 30),
        ),
        PrayerItem(
          type: PrayerType.maghrib,
          time: '17:07',
          dateTime: DateTime(2026, 10, 25, 17, 7),
        ),
        PrayerItem(
          type: PrayerType.isha,
          time: '18:51',
          dateTime: DateTime(2026, 10, 25, 18, 51),
        ),
      ];

      final schedule = PrayerSchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        hijriDate: '14 Cemaziyelevvel 1448 AH',
        gregorianDate: '25.10.2026',
        items: items,
      );

      // At 12:00, next should be Dhuhr at 12:12 (12m remaining)
      final next1 = schedule.nextPrayer(baseDate);
      expect(next1, isNotNull);
      expect(next1!.item.type, PrayerType.dhuhr);
      expect(next1.remaining.inMinutes, 12);
      expect(next1.isTomorrowFajr, false);

      // At 15:00, next should be Maghrib at 17:07
      final next2 = schedule.nextPrayer(DateTime(2026, 10, 25, 15, 0));
      expect(next2, isNotNull);
      expect(next2!.item.type, PrayerType.maghrib);
      expect(next2.remaining.inMinutes, 127);
    });

    test('After Isha, next prayer correctly transitions to Tomorrow Fajr', () {
      final afterIsha = DateTime(2026, 10, 25, 22, 0); // 10:00 PM

      final items = [
        PrayerItem(
          type: PrayerType.fajr,
          time: '05:10',
          dateTime: DateTime(2026, 10, 25, 5, 10),
        ),
        PrayerItem(
          type: PrayerType.sunrise,
          time: '07:08',
          dateTime: DateTime(2026, 10, 25, 7, 8),
        ),
        PrayerItem(
          type: PrayerType.dhuhr,
          time: '12:12',
          dateTime: DateTime(2026, 10, 25, 12, 12),
        ),
        PrayerItem(
          type: PrayerType.asr,
          time: '14:30',
          dateTime: DateTime(2026, 10, 25, 14, 30),
        ),
        PrayerItem(
          type: PrayerType.maghrib,
          time: '17:07',
          dateTime: DateTime(2026, 10, 25, 17, 7),
        ),
        PrayerItem(
          type: PrayerType.isha,
          time: '18:51',
          dateTime: DateTime(2026, 10, 25, 18, 51),
        ),
      ];

      final schedule = PrayerSchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        hijriDate: '14 Cemaziyelevvel 1448 AH',
        gregorianDate: '25.10.2026',
        items: items,
      );

      final next = schedule.nextPrayer(afterIsha);
      expect(next, isNotNull);
      expect(next!.item.type, PrayerType.fajr);
      expect(next.isTomorrowFajr, true);
      // From 22:00 to 05:10 tomorrow = 7 hours 10 mins = 430 mins
      expect(next.remaining.inMinutes, 430);
    });

    test('Schedule JSON serialization/deserialization roundtrip', () {
      final items = [
        PrayerItem(
          type: PrayerType.fajr,
          time: '05:10',
          dateTime: DateTime(2026, 10, 25, 5, 10),
        ),
      ];

      final original = PrayerSchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        hijriDate: '14 Cemaziyelevvel 1448 AH',
        gregorianDate: '25.10.2026',
        items: items,
      );

      final json = original.toJson();
      final restored = PrayerSchedule.fromJson(json);

      expect(restored.city, 'Tokyo');
      expect(restored.country, 'Japan');
      expect(restored.method, CalculationMethod.diyanet);
      expect(restored.items.first.time, '05:10');
    });

    test('City sanitization and validation rejects punctuation/gibberish', () {
      expect(GeocodingService.sanitize('  New   York  '), 'New York');
      expect(GeocodingService.isValidPlaceName('Ejstrupholm'), true);
      expect(GeocodingService.isValidPlaceName('  Tokyo  '), true);
      expect(GeocodingService.isValidPlaceName('Malmö'), true);
      expect(GeocodingService.isValidPlaceName('Tokyo ..dew.de.'), false);
      expect(GeocodingService.isValidPlaceName('Tokyo123'), false);
      expect(GeocodingService.isValidPlaceName('a'), false);
      expect(GeocodingService.normalize('Düsseldorf'), 'dusseldorf');
      expect(GeocodingService.countriesMatch('Turkey', 'Türkiye'), true);
    });

    test('NotificationCardRenderer generates valid PNG bitmaps for all 3 styles', () async {
      final now = DateTime(2026, 10, 25, 12, 0);
      final items = [
        PrayerItem(type: PrayerType.fajr, time: '05:10', dateTime: now),
        PrayerItem(type: PrayerType.sunrise, time: '07:08', dateTime: now),
        PrayerItem(type: PrayerType.dhuhr, time: '12:12', dateTime: now),
        PrayerItem(type: PrayerType.asr, time: '14:30', dateTime: now),
        PrayerItem(type: PrayerType.maghrib, time: '17:07', dateTime: now),
        PrayerItem(type: PrayerType.isha, time: '18:51', dateTime: now),
      ];

      final schedule = PrayerSchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        hijriDate: '14 Cemaziyelevvel 1448 AH',
        gregorianDate: '25.10.2026',
        items: items,
      );

      final next = schedule.nextPrayer(now);

      final tableBytes = await NotificationCardRenderer.renderTableCard(
        schedule: schedule,
        nextPrayer: next,
        useTurkish: true,
      );
      expect(tableBytes, isNotNull);
      expect(tableBytes!.lengthInBytes, greaterThan(1000));

      final compactBytes = await NotificationCardRenderer.renderCompactCard(
        schedule: schedule,
        nextPrayer: next,
        useTurkish: true,
      );
      expect(compactBytes, isNotNull);
      expect(compactBytes!.lengthInBytes, greaterThan(1000));

      final minimalBytes = await NotificationCardRenderer.renderMinimalCard(
        schedule: schedule,
        nextPrayer: next,
        useTurkish: true,
      );
      expect(minimalBytes, isNotNull);
      expect(minimalBytes!.lengthInBytes, greaterThan(1000));
    });

    test('WeeklySchedule correctly switches effectiveSchedule to tomorrow after Isha', () {
      final todayDate = DateTime(2026, 11, 25, 20, 30); // 20:30 (past 18:02 Isha)
      final tomorrowDate = DateTime(2026, 11, 26);

      final todayItems = [
        PrayerItem(type: PrayerType.fajr, time: '06:03', dateTime: DateTime(2026, 11, 25, 6, 3)),
        PrayerItem(type: PrayerType.sunrise, time: '08:13', dateTime: DateTime(2026, 11, 25, 8, 13)),
        PrayerItem(type: PrayerType.dhuhr, time: '12:15', dateTime: DateTime(2026, 11, 25, 12, 15)),
        PrayerItem(type: PrayerType.asr, time: '13:46', dateTime: DateTime(2026, 11, 25, 13, 46)),
        PrayerItem(type: PrayerType.maghrib, time: '16:08', dateTime: DateTime(2026, 11, 25, 16, 8)),
        PrayerItem(type: PrayerType.isha, time: '18:02', dateTime: DateTime(2026, 11, 25, 18, 2)),
      ];

      final tomorrowItems = [
        PrayerItem(type: PrayerType.fajr, time: '06:05', dateTime: DateTime(2026, 11, 26, 6, 5)),
        PrayerItem(type: PrayerType.sunrise, time: '08:15', dateTime: DateTime(2026, 11, 26, 8, 15)),
        PrayerItem(type: PrayerType.dhuhr, time: '12:15', dateTime: DateTime(2026, 11, 26, 12, 15)),
        PrayerItem(type: PrayerType.asr, time: '13:45', dateTime: DateTime(2026, 11, 26, 13, 45)),
        PrayerItem(type: PrayerType.maghrib, time: '16:06', dateTime: DateTime(2026, 11, 26, 16, 6)),
        PrayerItem(type: PrayerType.isha, time: '18:01', dateTime: DateTime(2026, 11, 26, 18, 1)),
      ];

      final todaySched = PrayerSchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        hijriDate: '16 Cemaziyelahir 1448',
        gregorianDate: '25.11.2026',
        items: todayItems,
      );

      final tomorrowSched = PrayerSchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        hijriDate: '17 Cemaziyelahir 1448',
        gregorianDate: '26.11.2026',
        items: tomorrowItems,
      );

      final weekly = WeeklySchedule(
        city: 'Tokyo',
        country: 'Japan',
        method: CalculationMethod.diyanet,
        days: [todaySched, tomorrowSched],
      );

      // At 20:30 (past Isha), effectiveSchedule MUST return tomorrow's schedule
      final eff = weekly.effectiveSchedule(todayDate);
      expect(eff.gregorianDate, '26.11.2026');
      expect(eff.items.first.time, '06:05'); // Tomorrow's Diyanet Fajr is 06:05!

      // At 12:00 (midday), effectiveSchedule MUST return today's schedule
      final midday = weekly.effectiveSchedule(DateTime(2026, 11, 25, 12, 0));
      expect(midday.gregorianDate, '25.11.2026');
      expect(midday.items.first.time, '06:03');
    });
  });
}
