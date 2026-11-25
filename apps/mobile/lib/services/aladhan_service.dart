import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculation_method.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_type.dart';
import '../models/weekly_schedule.dart';

class AlAdhanService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  DateTime _parseTime(String timeStr, DateTime targetDate) {
    final cleanTime = timeStr.split(' ').first;
    final parts = cleanTime.split(':');
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

  List<PrayerItem> _parsePrayerItems(
    Map<String, dynamic> timings,
    DateTime targetDate,
  ) {
    return [
      PrayerItem(
        type: PrayerType.fajr,
        time: (timings['Fajr'] as String).split(' ').first,
        dateTime: _parseTime(timings['Fajr'] as String, targetDate),
      ),
      PrayerItem(
        type: PrayerType.sunrise,
        time: (timings['Sunrise'] as String).split(' ').first,
        dateTime: _parseTime(timings['Sunrise'] as String, targetDate),
      ),
      PrayerItem(
        type: PrayerType.dhuhr,
        time: (timings['Dhuhr'] as String).split(' ').first,
        dateTime: _parseTime(timings['Dhuhr'] as String, targetDate),
      ),
      PrayerItem(
        type: PrayerType.asr,
        time: (timings['Asr'] as String).split(' ').first,
        dateTime: _parseTime(timings['Asr'] as String, targetDate),
      ),
      PrayerItem(
        type: PrayerType.maghrib,
        time: (timings['Maghrib'] as String).split(' ').first,
        dateTime: _parseTime(timings['Maghrib'] as String, targetDate),
      ),
      PrayerItem(
        type: PrayerType.isha,
        time: (timings['Isha'] as String).split(' ').first,
        dateTime: _parseTime(timings['Isha'] as String, targetDate),
      ),
    ];
  }

  PrayerSchedule _parseAlAdhanResponse(
    Map<String, dynamic> data, {
    required String city,
    required String country,
    required CalculationMethod method,
    required DateTime targetDate,
  }) {
    final timings = data['timings'] as Map<String, dynamic>;
    final dateObj = data['date'] as Map<String, dynamic>;
    final gregorian = dateObj['readable'] as String? ?? '';
    final hijri = dateObj['hijri'] as Map<String, dynamic>?;

    String hijriFormatted = '';
    if (hijri != null) {
      final day = hijri['day'] ?? '';
      final month = (hijri['month'] as Map<String, dynamic>?)?['en'] ?? '';
      final year = hijri['year'] ?? '';
      hijriFormatted = '$day $month $year AH';
    }

    return PrayerSchedule(
      city: city,
      country: country,
      method: method,
      hijriDate: hijriFormatted,
      gregorianDate: gregorian,
      items: _parsePrayerItems(timings, targetDate),
    );
  }

  Future<WeeklySchedule?> fetchWeeklyTimingsByCoordinates({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    required CalculationMethod method,
  }) async {
    try {
      final now = DateTime.now();
      final uri = Uri.parse('$_baseUrl/calendar/${now.year}/${now.month}').replace(
        queryParameters: {
          'latitude': latitude.toStringAsFixed(5),
          'longitude': longitude.toStringAsFixed(5),
          'method': method.id.toString(),
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final todayDay = now.day;
      final days = <PrayerSchedule>[];

      for (int i = 0; i < data.length; i++) {
        final dayData = data[i] as Map<String, dynamic>;
        final dayDate = now.add(Duration(days: days.length));
        // Find days starting from today
        final dateObj = dayData['date'] as Map<String, dynamic>?;
        final gregorianObj = dateObj?['gregorian'] as Map<String, dynamic>?;
        final dNum = int.tryParse(gregorianObj?['day']?.toString() ?? '');

        if (dNum != null && dNum >= todayDay && days.length < 8) {
          final target = DateTime(now.year, now.month, dNum);
          days.add(_parseAlAdhanResponse(
            dayData,
            city: city,
            country: country,
            method: method,
            targetDate: target,
          ));
        }
      }

      if (days.isEmpty) return null;

      return WeeklySchedule(
        city: city,
        country: country,
        method: method,
        days: days,
      );
    } catch (_) {
      return null;
    }
  }

  Future<WeeklySchedule?> fetchWeeklyTimings({
    required String city,
    required String country,
    required CalculationMethod method,
  }) async {
    try {
      final now = DateTime.now();
      final uri = Uri.parse('$_baseUrl/calendarByCity/${now.year}/${now.month}').replace(
        queryParameters: {
          'city': city.trim(),
          'country': country.trim(),
          'method': method.id.toString(),
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final todayDay = now.day;
      final days = <PrayerSchedule>[];

      for (int i = 0; i < data.length; i++) {
        final dayData = data[i] as Map<String, dynamic>;
        final dateObj = dayData['date'] as Map<String, dynamic>?;
        final gregorianObj = dateObj?['gregorian'] as Map<String, dynamic>?;
        final dNum = int.tryParse(gregorianObj?['day']?.toString() ?? '');

        if (dNum != null && dNum >= todayDay && days.length < 8) {
          final target = DateTime(now.year, now.month, dNum);
          days.add(_parseAlAdhanResponse(
            dayData,
            city: city,
            country: country,
            method: method,
            targetDate: target,
          ));
        }
      }

      if (days.isEmpty) return null;

      return WeeklySchedule(
        city: city,
        country: country,
        method: method,
        days: days,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PrayerSchedule?> fetchTimingsByCoordinates({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    required CalculationMethod method,
    DateTime? forDate,
  }) async {
    final weekly = await fetchWeeklyTimingsByCoordinates(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      method: method,
    );
    if (weekly != null) return weekly.effectiveSchedule();

    // Fallback single-day call
    try {
      final date = forDate ?? DateTime.now();
      final dd = date.day.toString().padLeft(2, '0');
      final mm = date.month.toString().padLeft(2, '0');
      final dateSeg = '$dd-$mm-${date.year}';

      final uri = Uri.parse('$_baseUrl/timings/$dateSeg').replace(
        queryParameters: {
          'latitude': latitude.toStringAsFixed(5),
          'longitude': longitude.toStringAsFixed(5),
          'method': method.id.toString(),
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      return _parseAlAdhanResponse(
        data,
        city: city,
        country: country,
        method: method,
        targetDate: date,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PrayerSchedule?> fetchTimings({
    required String city,
    required String country,
    required CalculationMethod method,
  }) async {
    final weekly = await fetchWeeklyTimings(
      city: city,
      country: country,
      method: method,
    );
    if (weekly != null) return weekly.effectiveSchedule();

    try {
      final uri =
          Uri.parse('$_baseUrl/timingsByCity').replace(queryParameters: {
        'city': city.trim(),
        'country': country.trim(),
        'method': method.id.toString(),
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      return _parseAlAdhanResponse(
        data,
        city: city,
        country: country,
        method: method,
        targetDate: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
