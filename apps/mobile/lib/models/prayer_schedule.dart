import 'calculation_method.dart';
import 'prayer_type.dart';

class PrayerItem {
  final PrayerType type;
  final String time; // "HH:mm"
  final DateTime dateTime;

  const PrayerItem({
    required this.type,
    required this.time,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'type': type.englishName,
        'time': time,
        'timestamp': dateTime.millisecondsSinceEpoch,
      };

  factory PrayerItem.fromJson(Map<String, dynamic> json) {
    return PrayerItem(
      type: PrayerType.fromKey(json['type'] as String),
      time: json['time'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

class NextPrayer {
  final PrayerItem item;
  final Duration remaining;
  final bool isTomorrowFajr;

  const NextPrayer({
    required this.item,
    required this.remaining,
    this.isTomorrowFajr = false,
  });

  String get formattedRemaining {
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    final secs = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else if (mins > 0) {
      return '${mins}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

class PrayerSchedule {
  final String city;
  final String country;
  final CalculationMethod method;
  final String hijriDate;
  final String gregorianDate;
  final List<PrayerItem> items;
  final DateTime? date;

  const PrayerSchedule({
    required this.city,
    required this.country,
    required this.method,
    required this.hijriDate,
    required this.gregorianDate,
    required this.items,
    this.date,
  });

  DateTime get effectiveDate {
    if (date != null) return date!;
    if (items.isNotEmpty) return items.first.dateTime;
    return DateTime.now();
  }

  bool isSameDay(DateTime other) {
    final d = effectiveDate;
    return d.year == other.year && d.month == other.month && d.day == other.day;
  }

  NextPrayer? nextPrayer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();

    for (final item in items) {
      if (item.dateTime.isAfter(now)) {
        return NextPrayer(
          item: item,
          remaining: item.dateTime.difference(now),
        );
      }
    }

    // Past Isha -> Next is tomorrow's Fajr
    final fajr = items.firstWhere(
      (i) => i.type == PrayerType.fajr,
      orElse: () => items.first,
    );

    final tomorrowFajrDate = fajr.dateTime.add(const Duration(days: 1));
    final tomorrowFajrItem = PrayerItem(
      type: PrayerType.fajr,
      time: fajr.time,
      dateTime: tomorrowFajrDate,
    );

    return NextPrayer(
      item: tomorrowFajrItem,
      remaining: tomorrowFajrDate.difference(now),
      isTomorrowFajr: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
        'method': method.id,
        'hijriDate': hijriDate,
        'gregorianDate': gregorianDate,
        'date': (date ?? (items.isNotEmpty ? items.first.dateTime : null))
            ?.millisecondsSinceEpoch,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    return PrayerSchedule(
      city: json['city'] as String,
      country: json['country'] as String,
      method: CalculationMethod.fromId(json['method'] as int?),
      hijriDate: json['hijriDate'] as String,
      gregorianDate: json['gregorianDate'] as String,
      date: json['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['date'] as int)
          : null,
      items: (json['items'] as List<dynamic>)
          .map((i) => PrayerItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
