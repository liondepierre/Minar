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

  PrayerSchedule get today =>
      days.isNotEmpty ? days.first : _fallbackSchedule();

  PrayerSchedule? get tomorrow => days.length > 1 ? days[1] : null;

  /// Returns tomorrow's schedule when the current time is past today's Isha,
  /// otherwise returns today's schedule.
  PrayerSchedule effectiveSchedule([DateTime? currentTime]) {
    if (days.isEmpty) return _fallbackSchedule();
    final now = currentTime ?? DateTime.now();
    final todaySchedule = days.first;
    final next = todaySchedule.nextPrayer(now);

    // If next prayer is marked as tomorrow's Fajr (i.e. past Isha today)
    // and we have tomorrow's full schedule, switch to tomorrow!
    if (next != null && next.isTomorrowFajr && days.length > 1) {
      return days[1];
    }
    return todaySchedule;
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
