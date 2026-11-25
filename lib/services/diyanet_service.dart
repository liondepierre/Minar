import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculation_method.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_type.dart';
import '../models/weekly_schedule.dart';
import 'geocoding_service.dart';

class DiyanetDistrict {
  final String id;
  final String name;

  const DiyanetDistrict({required this.id, required this.name});
}

class DiyanetService {
  static const String _baseUrl = 'https://ezanvakti.imsakiyem.com/api';

  /// Cached district id from the last successful fetchTimings call.
  String? _lastDistrictId;

  DateTime _parseTime(String timeStr, DateTime targetDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );
  }

  Future<DiyanetDistrict?> searchDistrict(String cityQuery) async {
    try {
      final cleanQuery = GeocodingService.sanitize(cityQuery);
      if (!GeocodingService.isValidPlaceName(cleanQuery)) return null;

      final uri = Uri.parse('$_baseUrl/locations/search/districts')
          .replace(queryParameters: {'q': cleanQuery.toLowerCase()});

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final normQuery = GeocodingService.normalize(cleanQuery);

      for (final raw in data) {
        final item = raw as Map<String, dynamic>;
        final rawName = (item['name_en'] ?? item['name']) as String?;
        if (rawName == null) continue;

        final strippedName = rawName.split('(').first.trim();
        final normName = GeocodingService.normalize(strippedName);
        final normFull = GeocodingService.normalize(rawName);

        // Require exact normalized district match
        if (normName == normQuery || normFull == normQuery) {
          return DiyanetDistrict(
            id: item['_id'] as String,
            name: (item['name'] as String).toUpperCase(),
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches 8 days of schedules (Today + 7 future days) in a single 2KB request.
  Future<WeeklySchedule?> fetchWeeklyTimings({
    required String city,
    required String country,
    String? districtId,
  }) async {
    try {
      String? targetId = districtId ?? _lastDistrictId;

      if (targetId == null || targetId.isEmpty) {
        final district = await searchDistrict(city);
        if (district == null) return null;
        targetId = district.id;
      }

      _lastDistrictId = targetId;

      // Note: /weekly returns 8 full days in one lightweight payload!
      final uri = Uri.parse('$_baseUrl/prayer-times/$targetId/weekly');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final List<PrayerSchedule> days = [];
      for (int i = 0; i < data.length; i++) {
        final day = data[i] as Map<String, dynamic>;
        final parsed = _parseDay(day, city: city, country: country, dayIndex: i);
        if (parsed != null) {
          days.add(parsed);
        }
      }

      if (days.isEmpty) return null;

      return WeeklySchedule(
        city: city,
        country: country,
        method: CalculationMethod.diyanet,
        days: days,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PrayerSchedule?> fetchTimings({
    required String city,
    required String country,
    String? districtId,
  }) async {
    final weekly = await fetchWeeklyTimings(
      city: city,
      country: country,
      districtId: districtId,
    );
    return weekly?.effectiveSchedule();
  }

  Future<PrayerSchedule?> fetchTimingsForTomorrow({
    required String city,
    required String country,
    String? districtId,
  }) async {
    final weekly = await fetchWeeklyTimings(
      city: city,
      country: country,
      districtId: districtId,
    );
    return weekly?.tomorrow;
  }

  PrayerSchedule? _parseDay(
    Map<String, dynamic> day, {
    required String city,
    required String country,
    required int dayIndex,
  }) {
    try {
      final times = day['times'] as Map<String, dynamic>?;
      if (times == null) return null;

      final hijri = day['hijri_date'] as Map<String, dynamic>?;
      final rawDateStr = day['date'] as String?;

      DateTime targetDate;
      if (rawDateStr != null) {
        final parsed = DateTime.tryParse(rawDateStr);
        if (parsed != null) {
          final local = parsed.toLocal();
          targetDate = DateTime(local.year, local.month, local.day);
        } else {
          final base = DateTime.now().add(Duration(days: dayIndex));
          targetDate = DateTime(base.year, base.month, base.day);
        }
      } else {
        final base = DateTime.now().add(Duration(days: dayIndex));
        targetDate = DateTime(base.year, base.month, base.day);
      }

      final items = [
        PrayerItem(
          type: PrayerType.fajr,
          time: times['imsak'] as String,
          dateTime: _parseTime(times['imsak'] as String, targetDate),
        ),
        PrayerItem(
          type: PrayerType.sunrise,
          time: times['gunes'] as String,
          dateTime: _parseTime(times['gunes'] as String, targetDate),
        ),
        PrayerItem(
          type: PrayerType.dhuhr,
          time: times['ogle'] as String,
          dateTime: _parseTime(times['ogle'] as String, targetDate),
        ),
        PrayerItem(
          type: PrayerType.asr,
          time: times['ikindi'] as String,
          dateTime: _parseTime(times['ikindi'] as String, targetDate),
        ),
        PrayerItem(
          type: PrayerType.maghrib,
          time: times['aksam'] as String,
          dateTime: _parseTime(times['aksam'] as String, targetDate),
        ),
        PrayerItem(
          type: PrayerType.isha,
          time: times['yatsi'] as String,
          dateTime: _parseTime(times['yatsi'] as String, targetDate),
        ),
      ];

      final hijriStr = hijri != null
          ? '${hijri['full_date']} AH'
          : '';

      return PrayerSchedule(
        city: city,
        country: country,
        method: CalculationMethod.diyanet,
        hijriDate: hijriStr,
        gregorianDate: '${targetDate.day}.${targetDate.month}.${targetDate.year}',
        items: items,
      );
    } catch (_) {
      return null;
    }
  }
}
