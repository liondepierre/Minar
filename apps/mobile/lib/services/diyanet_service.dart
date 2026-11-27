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

  /// District IDs cached by normalized city name to avoid cross-city ID collisions.
  final Map<String, String> _districtCache = {};

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

      final normQuery = GeocodingService.normalize(cleanQuery);
      if (_districtCache.containsKey(normQuery)) {
        final id = _districtCache[normQuery]!;
        return DiyanetDistrict(id: id, name: cleanQuery.toUpperCase());
      }

      // Extract search terms: remove common administrative noise words
      final stopWords = {
        'kommune',
        'municipality',
        'county',
        'district',
        'city',
        'town',
        'province',
        'region',
        'shahr',
        'sehir',
        'ili',
        'ilcesi'
      };
      final tokens = normQuery
          .split(RegExp(r'[\s\-_,]+'))
          .where((t) => t.isNotEmpty && !stopWords.contains(t))
          .toList();

      final searchWords = tokens.isNotEmpty ? tokens : [normQuery];

      // Try searching for the most specific word first (e.g. "ikast"), then full query
      final queriesToTry = [
        searchWords.first,
        if (searchWords.length > 1) normQuery,
      ];

      for (final q in queriesToTry) {
        final uri = Uri.parse('$_baseUrl/locations/search/districts')
            .replace(queryParameters: {'q': q.toLowerCase()});

        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;

        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>?;
        if (data == null || data.isEmpty) continue;

        // 1. Exact match pass
        for (final raw in data) {
          final item = raw as Map<String, dynamic>;
          final rawName = (item['name_en'] ?? item['name']) as String?;
          if (rawName == null) continue;

          final strippedName = rawName.split('(').first.trim();
          final normName = GeocodingService.normalize(strippedName);
          final normFull = GeocodingService.normalize(rawName);

          if (normName == normQuery || normFull == normQuery || normName == q) {
            final id = item['_id'] as String;
            _districtCache[normQuery] = id;
            return DiyanetDistrict(
              id: id,
              name: (item['name'] as String).toUpperCase(),
            );
          }
        }

        // 2. Token match pass (e.g. query has "ikast", item is "IKAST")
        for (final raw in data) {
          final item = raw as Map<String, dynamic>;
          final rawName = (item['name_en'] ?? item['name']) as String?;
          if (rawName == null) continue;

          final strippedName = rawName.split('(').first.trim();
          final normName = GeocodingService.normalize(strippedName);

          if (searchWords.contains(normName) ||
              normQuery.contains(normName) ||
              normName.contains(normQuery)) {
            final id = item['_id'] as String;
            _districtCache[normQuery] = id;
            return DiyanetDistrict(
              id: id,
              name: (item['name'] as String).toUpperCase(),
            );
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches rolling schedules covering today + 7 future days.
  /// Combines monthly and weekly endpoints to guarantee local today is always
  /// included regardless of timezone differences with Turkey (UTC+3).
  Future<WeeklySchedule?> fetchWeeklyTimings({
    required String city,
    required String country,
    String? districtId,
  }) async {
    try {
      final normCity = GeocodingService.normalize(city);
      String? targetId = districtId ?? _districtCache[normCity];

      if (targetId == null || targetId.isEmpty) {
        final district = await searchDistrict(city);
        if (district == null) return null;
        targetId = district.id;
      }

      _districtCache[normCity] = targetId;

      final uriMonthly = Uri.parse('$_baseUrl/prayer-times/$targetId/monthly');
      final uriWeekly = Uri.parse('$_baseUrl/prayer-times/$targetId/weekly');

      final responses = await Future.wait([
        http.get(uriMonthly).timeout(const Duration(seconds: 8)),
        http.get(uriWeekly).timeout(const Duration(seconds: 8)),
      ]).catchError((_) => <http.Response>[]);

      final Map<String, Map<String, dynamic>> rawDaysByDate = {};

      for (final res in responses) {
        if (res.statusCode == 200) {
          try {
            final json = jsonDecode(res.body) as Map<String, dynamic>;
            final data = json['data'] as List<dynamic>?;
            if (data != null) {
              for (final raw in data) {
                final day = raw as Map<String, dynamic>;
                final rawDate = (day['date'] as String? ?? '').split('T').first;
                if (rawDate.isNotEmpty && !rawDaysByDate.containsKey(rawDate)) {
                  rawDaysByDate[rawDate] = day;
                }
              }
            }
          } catch (_) {}
        }
      }

      if (rawDaysByDate.isEmpty) return null;

      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final sortedDates = rawDaysByDate.keys.toList()..sort();
      final futureDates =
          sortedDates.where((d) => d.compareTo(todayStr) >= 0).take(8).toList();

      final targetDates =
          futureDates.isNotEmpty ? futureDates : sortedDates.take(8).toList();

      final List<PrayerSchedule> days = [];
      for (int i = 0; i < targetDates.length; i++) {
        final dStr = targetDates[i];
        final dayMap = rawDaysByDate[dStr]!;
        final parsed =
            _parseDay(dayMap, city: city, country: country, dayIndex: i);
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
      if (rawDateStr != null && rawDateStr.isNotEmpty) {
        final datePart = rawDateStr.split('T').first;
        final parts = datePart.split('-');
        if (parts.length >= 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            targetDate = DateTime(y, m, d);
          } else {
            final base = DateTime.now().add(Duration(days: dayIndex));
            targetDate = DateTime(base.year, base.month, base.day);
          }
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

      final hijriStr = hijri != null ? '${hijri['full_date']} AH' : '';

      return PrayerSchedule(
        city: city,
        country: country,
        method: CalculationMethod.diyanet,
        hijriDate: hijriStr,
        gregorianDate:
            '${targetDate.day.toString().padLeft(2, '0')}.${targetDate.month.toString().padLeft(2, '0')}.${targetDate.year}',
        date: targetDate,
        items: items,
      );
    } catch (_) {
      return null;
    }
  }
}
