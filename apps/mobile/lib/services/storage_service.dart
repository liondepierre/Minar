import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_method.dart';
import '../models/prayer_schedule.dart';
import '../models/weekly_schedule.dart';

class StorageService {
  static const String _kCity = 'minar_city';
  static const String _kCountry = 'minar_country';
  static const String _kDistrictId = 'minar_district_id';
  static const String _kMethod = 'minar_method';
  static const String _kUseTurkish = 'minar_use_turkish';
  static const String _kNotifications = 'minar_notifications';
  static const String _kCachedSchedule = 'minar_cached_schedule';
  static const String _kCachedWeeklySchedule = 'minar_cached_weekly_schedule';
  static const String _kZoomEnhanced = 'minar_zoom_enhanced';
  static const String _kAutoLocation = 'minar_auto_location';
  static const String _kPinnedNotification = 'minar_pinned_notification';
  static const String _kPinnedStyle = 'minar_pinned_style';
  static const String _kLocationMode = 'minar_location_mode';
  static const String _kFontFamily = 'minar_font_family';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String get city => _prefs.getString(_kCity) ?? 'Ikast';
  set city(String value) => _prefs.setString(_kCity, value);

  String get country => _prefs.getString(_kCountry) ?? 'Denmark';
  set country(String value) => _prefs.setString(_kCountry, value);

  String? get districtId => _prefs.getString(_kDistrictId);
  set districtId(String? value) {
    if (value == null) {
      _prefs.remove(_kDistrictId);
    } else {
      _prefs.setString(_kDistrictId, value);
    }
  }

  CalculationMethod get method {
    final id = _prefs.getInt(_kMethod);
    return CalculationMethod.fromId(id);
  }

  set method(CalculationMethod value) => _prefs.setInt(_kMethod, value.id);

  bool get useTurkishNames => _prefs.getBool(_kUseTurkish) ?? true;
  set useTurkishNames(bool value) => _prefs.setBool(_kUseTurkish, value);

  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  set notificationsEnabled(bool value) =>
      _prefs.setBool(_kNotifications, value);

  bool get zoomEnhanced => _prefs.getBool(_kZoomEnhanced) ?? false;
  set zoomEnhanced(bool value) => _prefs.setBool(_kZoomEnhanced, value);

  bool get autoLocationEnabled => _prefs.getBool(_kAutoLocation) ?? true;
  set autoLocationEnabled(bool value) => _prefs.setBool(_kAutoLocation, value);

  bool get pinnedNotificationEnabled =>
      _prefs.getBool(_kPinnedNotification) ?? false;
  set pinnedNotificationEnabled(bool value) =>
      _prefs.setBool(_kPinnedNotification, value);

  /// Notification shade style: 'table', 'compact', 'minimal'
  String get pinnedNotificationStyle =>
      _prefs.getString(_kPinnedStyle) ?? 'table';
  set pinnedNotificationStyle(String value) =>
      _prefs.setString(_kPinnedStyle, value);

  /// Auto location mode: 'ip' (zero permission) or 'device' (coarse battery-saver)
  String get locationMode => _prefs.getString(_kLocationMode) ?? 'ip';
  set locationMode(String value) => _prefs.setString(_kLocationMode, value);

  String get fontFamily => _prefs.getString(_kFontFamily) ?? 'System Default';
  set fontFamily(String value) => _prefs.setString(_kFontFamily, value);

  PrayerSchedule? get cachedSchedule {
    final raw = _prefs.getString(_kCachedSchedule);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PrayerSchedule.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  set cachedSchedule(PrayerSchedule? schedule) {
    if (schedule == null) {
      _prefs.remove(_kCachedSchedule);
    } else {
      _prefs.setString(_kCachedSchedule, jsonEncode(schedule.toJson()));
    }
  }

  WeeklySchedule? get cachedWeeklySchedule {
    final raw = _prefs.getString(_kCachedWeeklySchedule);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WeeklySchedule.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  set cachedWeeklySchedule(WeeklySchedule? schedule) {
    if (schedule == null) {
      _prefs.remove(_kCachedWeeklySchedule);
    } else {
      _prefs.setString(_kCachedWeeklySchedule, jsonEncode(schedule.toJson()));
    }
  }
}
