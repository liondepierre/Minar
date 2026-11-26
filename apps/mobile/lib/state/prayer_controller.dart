import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/calculation_method.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_type.dart';
import '../models/weekly_schedule.dart';
import '../services/aladhan_service.dart';
import '../services/diyanet_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../ui/theme.dart';

class PrayerController extends ChangeNotifier {
  final StorageService _storage;
  final DiyanetService _diyanetService = DiyanetService();
  final AlAdhanService _aladhanService = AlAdhanService();
  final NotificationService _notifications = NotificationService();

  WeeklySchedule? _weeklySchedule;
  PrayerSchedule? _schedule;
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _ticker;

  PrayerController(this._storage) {
    MinarTheme.applyTheme(theme: _storage.appTheme, accent: _storage.appAccent);
    _weeklySchedule = _storage.cachedWeeklySchedule;
    _schedule = _weeklySchedule?.today ??
        _storage.cachedSchedule ??
        defaultSchedule(city, country);
    _startTicker();
    fetchSchedule();
  }

  static PrayerSchedule defaultSchedule(String city, String country) {
    final now = DateTime.now();
    return PrayerSchedule(
      city: city,
      country: country,
      method: CalculationMethod.diyanet,
      hijriDate: '16 Cemaziyelahir 1448 AH',
      gregorianDate: '${now.day}.${now.month}.${now.year}',
      items: [
        PrayerItem(
          type: PrayerType.fajr,
          time: '06:03',
          dateTime: DateTime(now.year, now.month, now.day, 6, 3),
        ),
        PrayerItem(
          type: PrayerType.sunrise,
          time: '08:13',
          dateTime: DateTime(now.year, now.month, now.day, 8, 13),
        ),
        PrayerItem(
          type: PrayerType.dhuhr,
          time: '12:15',
          dateTime: DateTime(now.year, now.month, now.day, 12, 15),
        ),
        PrayerItem(
          type: PrayerType.asr,
          time: '13:46',
          dateTime: DateTime(now.year, now.month, now.day, 13, 46),
        ),
        PrayerItem(
          type: PrayerType.maghrib,
          time: '16:08',
          dateTime: DateTime(now.year, now.month, now.day, 16, 8),
        ),
        PrayerItem(
          type: PrayerType.isha,
          time: '18:02',
          dateTime: DateTime(now.year, now.month, now.day, 18, 2),
        ),
      ],
    );
  }

  WeeklySchedule? get weeklySchedule => _weeklySchedule;
  PrayerSchedule? get schedule => _schedule;
  int get selectedDayIndex => _selectedDayIndex;

  /// Returns the schedule currently displayed on the home screen page.
  PrayerSchedule get displayedSchedule {
    if (_weeklySchedule != null &&
        _selectedDayIndex < _weeklySchedule!.days.length) {
      return _weeklySchedule!.days[_selectedDayIndex];
    }
    return _schedule ?? defaultSchedule(city, country);
  }

  /// Returns tomorrow's schedule when past Isha, otherwise today's schedule.
  PrayerSchedule get effectiveSchedule {
    if (_weeklySchedule != null) {
      return _weeklySchedule!.effectiveSchedule();
    }
    return _schedule ?? defaultSchedule(city, country);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get city => _storage.city;
  String get country => _storage.country;
  CalculationMethod get method => _storage.method;
  bool get useTurkish => _storage.useTurkishNames;
  bool get notificationsEnabled => _storage.notificationsEnabled;
  bool get zoomEnhanced => _storage.zoomEnhanced;
  bool get autoLocation => _storage.autoLocationEnabled;
  String get locationMode => _storage.locationMode;
  bool get pinnedNotificationEnabled => _storage.pinnedNotificationEnabled;
  String get pinnedNotificationStyle => _storage.pinnedNotificationStyle;
  String get fontFamily => _storage.fontFamily;

  /// Returns the live next prayer countdown.
  /// When current time is past today's Isha, accurately shows tomorrow's Fajr
  /// with tomorrow's real time and date.
  NextPrayer? get nextPrayer {
    final today = _schedule;
    if (today == null) return null;
    final raw = today.nextPrayer();
    if (raw != null && !raw.isTomorrowFajr) return raw;

    final tomorrow = _weeklySchedule?.tomorrow;
    if (tomorrow != null) {
      final tNext = tomorrow.nextPrayer();
      if (tNext != null) return tNext;
    }
    return raw;
  }

  void selectDayIndex(int index) {
    if (_selectedDayIndex != index) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  Future<WeeklySchedule?> _fetchWeeklyForPlace({
    required String targetCity,
    required String targetCountry,
    String? districtId,
    double? lat,
    double? lon,
  }) async {
    WeeklySchedule? weekly;

    if (method == CalculationMethod.diyanet) {
      weekly = await _diyanetService.fetchWeeklyTimings(
        city: targetCity,
        country: targetCountry,
        districtId: districtId,
      );
    }

    if (weekly != null) return weekly;

    // Coordinate-first fallback
    if (lat != null && lon != null) {
      weekly = await _aladhanService.fetchWeeklyTimingsByCoordinates(
        latitude: lat,
        longitude: lon,
        city: targetCity,
        country: targetCountry,
        method: method,
      );
      if (weekly != null) return weekly;
    }

    final place = await GeocodingService.resolvePlace(
      city: targetCity,
      country: targetCountry,
    );
    if (place != null) {
      weekly = await _aladhanService.fetchWeeklyTimingsByCoordinates(
        latitude: place.latitude,
        longitude: place.longitude,
        city: targetCity,
        country: targetCountry,
        method: method,
      );
      if (weekly != null) return weekly;
    }

    return _aladhanService.fetchWeeklyTimings(
      city: targetCity,
      country: targetCountry,
      method: method,
    );
  }

  Future<void> _syncNotificationsAndWidgets(WeeklySchedule weekly) async {
    final eff = weekly.effectiveSchedule();

    if (notificationsEnabled) {
      await _notifications.schedulePrayerReminders(
        eff,
        useTurkish: useTurkish,
      );
    }
    if (pinnedNotificationEnabled) {
      await _notifications.updatePinnedNotification(
        eff,
        nextPrayer,
        useTurkish: useTurkish,
        style: pinnedNotificationStyle,
      );
    }

    // Sync native Android home screen widgets
    await WidgetService.updateWidgets(
      schedule: eff,
      nextPrayer: nextPrayer,
      useTurkish: useTurkish,
      widgetTheme: widgetTheme,
      widgetAccent: widgetAccent,
      widgetShowHeader: widgetShowHeader,
      widgetTextSize: widgetTextSize,
    );
  }

  Future<void> fetchSchedule({
    bool force = false,
    double? latHint,
    double? lonHint,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final weekly = await _fetchWeeklyForPlace(
        targetCity: city,
        targetCountry: country,
        districtId: _storage.districtId,
        lat: latHint,
        lon: lonHint,
      );

      if (weekly != null && weekly.days.isNotEmpty) {
        _weeklySchedule = weekly;
        _storage.cachedWeeklySchedule = weekly;
        _schedule = weekly.today;
        _storage.cachedSchedule = weekly.today;
        _errorMessage = null;

        await _syncNotificationsAndWidgets(weekly);
      } else {
        if (_schedule == null) {
          _errorMessage = 'Offline mode. Showing saved prayer times for $city.';
        }
      }
    } catch (_) {
      if (_schedule == null) {
        _errorMessage = 'Offline mode. Showing saved prayer times for $city.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> autoDetectLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final AutoLocationResult result;
    if (locationMode == 'device') {
      final outcome = await LocationService.detectCoarseDeviceLocation();
      final detected = outcome.result;
      if (detected == null) {
        _isLoading = false;
        _errorMessage = outcome.errorMessage ??
            'Could not read battery-saver device location.';
        notifyListeners();
        return false;
      }
      result = detected;
    } else {
      final detected = await LocationService.detectLocation();
      if (detected == null) {
        _isLoading = false;
        _errorMessage =
            'Could not detect location over network. Check connection or switch mode.';
        notifyListeners();
        return false;
      }
      result = detected;
    }

    _storage.autoLocationEnabled = true;
    _storage.city = GeocodingService.sanitize(result.city);
    _storage.country = GeocodingService.sanitize(result.country);
    _storage.districtId = null;
    await fetchSchedule(
      force: true,
      latHint: result.latitude,
      lonHint: result.longitude,
    );
    return true;
  }

  Future<void> setAutoLocation(bool enabled) async {
    _storage.autoLocationEnabled = enabled;
    if (enabled) {
      await autoDetectLocation();
    } else {
      notifyListeners();
    }
  }

  Future<void> setLocationMode(String mode) async {
    _storage.locationMode = mode;
    if (autoLocation) {
      await autoDetectLocation();
    } else {
      notifyListeners();
    }
  }

  void toggleZoomEnhanced() {
    _storage.zoomEnhanced = !_storage.zoomEnhanced;
    notifyListeners();
  }

  Future<bool> updateLocation({
    required String newCity,
    required String newCountry,
    bool isManual = true,
  }) async {
    final cleanCity = GeocodingService.sanitize(newCity);
    final cleanCountry = GeocodingService.sanitize(newCountry);

    if (cleanCity.isEmpty) {
      _errorMessage = 'Please enter a city name.';
      notifyListeners();
      return false;
    }

    if (!GeocodingService.isValidPlaceName(cleanCity)) {
      _errorMessage =
          "Invalid city '$cleanCity'. Use letters, spaces, or hyphens only.";
      notifyListeners();
      return false;
    }

    if (cleanCountry.isNotEmpty &&
        !GeocodingService.isValidPlaceName(cleanCountry)) {
      _errorMessage =
          "Invalid country '$cleanCountry'. Use letters, spaces, or hyphens only.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final place = await GeocodingService.resolvePlace(
        city: cleanCity,
        country: cleanCountry,
      );
      final diyanetDistrict =
          place == null ? await _diyanetService.searchDistrict(cleanCity) : null;

      if (place == null && diyanetDistrict == null) {
        _errorMessage =
            "Could not find '$cleanCity'${cleanCountry.isNotEmpty ? ' in $cleanCountry' : ''}. Kept $city.";
        return false;
      }

      final resolvedCity = place?.city ?? cleanCity;
      final resolvedCountry = (place != null && place.country.isNotEmpty)
          ? place.country
          : cleanCountry;

      final weekly = await _fetchWeeklyForPlace(
        targetCity: resolvedCity,
        targetCountry: resolvedCountry,
        districtId: diyanetDistrict?.id,
        lat: place?.latitude,
        lon: place?.longitude,
      );

      if (weekly == null || weekly.days.isEmpty) {
        _errorMessage =
            "Could not load prayer times for '$resolvedCity'. Kept $city.";
        return false;
      }

      if (isManual) {
        _storage.autoLocationEnabled = false;
      }
      _storage.city = resolvedCity;
      _storage.country = resolvedCountry;
      _storage.districtId = diyanetDistrict?.id;
      _weeklySchedule = weekly;
      _storage.cachedWeeklySchedule = weekly;
      _schedule = weekly.today;
      _storage.cachedSchedule = weekly.today;
      _errorMessage = null;

      await _syncNotificationsAndWidgets(weekly);
      return true;
    } catch (_) {
      _errorMessage =
          "Network issue looking up '$cleanCity'. Kept previous location ($city).";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFontFamily(String font) {
    _storage.fontFamily = font;
    notifyListeners();
  }

  Future<void> togglePinnedNotification() async {
    _storage.pinnedNotificationEnabled = !_storage.pinnedNotificationEnabled;
    if (_storage.pinnedNotificationEnabled && _schedule != null) {
      await _notifications.requestPermissions();
      await _notifications.updatePinnedNotification(
        effectiveSchedule,
        nextPrayer,
        useTurkish: useTurkish,
        style: pinnedNotificationStyle,
      );
    } else {
      await _notifications.cancelPinnedNotification();
    }
    notifyListeners();
  }

  Future<void> setPinnedNotificationStyle(String style) async {
    _storage.pinnedNotificationStyle = style;
    if (pinnedNotificationEnabled && _schedule != null) {
      await _notifications.updatePinnedNotification(
        effectiveSchedule,
        nextPrayer,
        useTurkish: useTurkish,
        style: style,
      );
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateMethod(CalculationMethod newMethod) async {
    _storage.method = newMethod;
    await fetchSchedule(force: true);
  }

  Future<void> clearCache() async {
    _storage.cachedSchedule = null;
    _storage.cachedWeeklySchedule = null;
    await fetchSchedule(force: true);
  }

  void toggleTurkishNames() {
    _storage.useTurkishNames = !_storage.useTurkishNames;
    if (pinnedNotificationEnabled && _schedule != null) {
      _notifications.updatePinnedNotification(
        effectiveSchedule,
        nextPrayer,
        useTurkish: useTurkish,
        style: pinnedNotificationStyle,
      );
    }
    if (_schedule != null) {
      syncWidgets();
    }
    notifyListeners();
  }

  String get widgetTheme => _storage.widgetTheme;
  String get widgetAccent => _storage.widgetAccent;
  bool get widgetShowHeader => _storage.widgetShowHeader;
  String get widgetTextSize => _storage.widgetTextSize;

  Future<void> setWidgetTheme(String theme) async {
    _storage.widgetTheme = theme;
    await syncWidgets();
    notifyListeners();
  }

  Future<void> setWidgetAccent(String accent) async {
    _storage.widgetAccent = accent;
    await syncWidgets();
    notifyListeners();
  }

  Future<void> setWidgetShowHeader(bool show) async {
    _storage.widgetShowHeader = show;
    await syncWidgets();
    notifyListeners();
  }

  Future<void> setWidgetTextSize(String size) async {
    _storage.widgetTextSize = size;
    await syncWidgets();
    notifyListeners();
  }

  String get appTheme => _storage.appTheme;
  String get appAccent => _storage.appAccent;

  Future<void> setAppTheme(String theme) async {
    _storage.appTheme = theme;
    MinarTheme.applyTheme(theme: theme, accent: appAccent);
    notifyListeners();
  }

  Future<void> setAppAccent(String accent) async {
    _storage.appAccent = accent;
    MinarTheme.applyTheme(theme: appTheme, accent: accent);
    notifyListeners();
  }

  Future<void> syncWidgets() async {
    if (_schedule == null) return;
    await WidgetService.updateWidgets(
      schedule: effectiveSchedule,
      nextPrayer: nextPrayer,
      useTurkish: useTurkish,
      widgetTheme: widgetTheme,
      widgetAccent: widgetAccent,
      widgetShowHeader: widgetShowHeader,
      widgetTextSize: widgetTextSize,
    );
  }

  Future<void> toggleNotifications() async {
    _storage.notificationsEnabled = !_storage.notificationsEnabled;
    if (_storage.notificationsEnabled && _schedule != null) {
      await _notifications.requestPermissions();
      await _notifications.schedulePrayerReminders(
        effectiveSchedule,
        useTurkish: useTurkish,
      );
    } else {
      await _notifications.cancelAll();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
