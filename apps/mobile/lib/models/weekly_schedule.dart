import 'calculation_method.dart';
import 'prayer_schedule.dart';

class WeeklySchedule {
  final String city;
  final String country;
  final CalculationMethod method;
  final List<PrayerSchedule> days;

  const WeeklySchedule({
    required this.city,
    required this.country,
    required this.method,
    required this.days,
  });

  PrayerSchedule get today {
    final now = DateTime.now();
    for (final day in days) {
      if (day.isSameDay(now)) return day;
    }
    return days.isNotEmpty ? days.first : _fallbackSchedule();
  }

  PrayerSchedule? get tomorrow {
    final tom = DateTime.now().add(const Duration(days: 1));
    for (final day in days) {
      if (day.isSameDay(tom)) return day;
    }
    return days.length > 1 ? days[1] : null;
  }

  /// The active timetable and dates remain today's until midnight (00:00).
  /// Looking forward past Isha is handled by nextPrayer countdown.
  PrayerSchedule effectiveSchedule([DateTime? currentTime]) {
    if (days.isEmpty) return _fallbackSchedule();
    final now = currentTime ?? DateTime.now();
    for (final day in days) {
      if (day.isSameDay(now)) return day;
    }
    return today;
  }

  PrayerSchedule getDay(int index) {
    if (index >= 0 && index < days.length) return days[index];
    return today;
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
        'method': method.id,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    return WeeklySchedule(
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      method: CalculationMethod.fromId(json['method'] as int?),
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => PrayerSchedule.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  PrayerSchedule _fallbackSchedule() {
    return PrayerSchedule(
      city: city,
      country: country,
      method: method,
      hijriDate: '',
      gregorianDate: '',
      items: const [],
    );
  }
}
