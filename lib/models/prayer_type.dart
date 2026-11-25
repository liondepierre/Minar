enum PrayerType {
  fajr('Fajr', 'İmsak', 'الفجر'),
  sunrise('Sunrise', 'Güneş', 'الشروق'),
  dhuhr('Dhuhr', 'Öğle', 'الظهر'),
  asr('Asr', 'İkindi', 'العصر'),
  maghrib('Maghrib', 'Akşam', 'المغرب'),
  isha('Isha', 'Yatsı', 'العشاء');

  final String englishName;
  final String turkishName;
  final String arabicName;

  const PrayerType(this.englishName, this.turkishName, this.arabicName);

  String displayName({required bool useTurkish}) {
    return useTurkish ? turkishName : englishName;
  }

  static PrayerType fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'fajr':
      case 'imsak':
        return PrayerType.fajr;
      case 'sunrise':
      case 'gunes':
      case 'güneş':
        return PrayerType.sunrise;
      case 'dhuhr':
      case 'ogle':
      case 'öğle':
        return PrayerType.dhuhr;
      case 'asr':
      case 'ikindi':
        return PrayerType.asr;
      case 'maghrib':
      case 'aksam':
      case 'akşam':
        return PrayerType.maghrib;
      case 'isha':
      case 'yatsi':
      case 'yatsı':
      default:
        return PrayerType.isha;
    }
  }
}
