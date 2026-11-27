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
  static const String _kZoomLevel = 'minar_zoom_level';
  static const String _kAutoLocation = 'minar_auto_location';
  static const String _kPinnedNotification = 'minar_pinned_notification';
  static const String _kPinnedStyle = 'minar_pinned_style';
  static const String _kLocationMode = 'minar_location_mode';
  static const String _kFontFamily = 'minar_font_family';
  static const String _kWidgetTheme = 'minar_widget_theme';
  static const String _kWidgetAccent = 'minar_widget_accent';
  static const String _kWidgetShowHeader = 'minar_widget_show_header';
  static const String _kWidgetTextSize = 'minar_widget_text_size';
  static const String _kAppTheme = 'minar_app_theme';
  static const String _kAppAccent = 'minar_app_accent';
  static const String _kAppLanguage = 'minar_app_language';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String get city => _prefs.getString(_kCity) ?? 'Tokyo';
  set city(String value) => _prefs.setString(_kCity, value);

  String get country => _prefs.getString(_kCountry) ?? 'Japan';
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

  bool get zoomEnhanced => zoomLevel != 'standard';
  set zoomEnhanced(bool value) {
    _prefs.setBool(_kZoomEnhanced, value);
    _prefs.setString(_kZoomLevel, value ? 'large' : 'standard');
  }

  String get zoomLevel {
    final saved = _prefs.getString(_kZoomLevel);
    if (saved != null) return saved;
    return (_prefs.getBool(_kZoomEnhanced) ?? false) ? 'large' : 'standard';
  }

  set zoomLevel(String value) {
    _prefs.setString(_kZoomLevel, value);
    _prefs.setBool(_kZoomEnhanced, value != 'standard');
  }

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

  /// Widget theme: 'midnight', 'amoled', 'glass', 'transparent'
  String get widgetTheme => _prefs.getString(_kWidgetTheme) ?? 'midnight';
  set widgetTheme(String value) => _prefs.setString(_kWidgetTheme, value);

  /// Widget accent: 'gold', 'emerald', 'white', 'blue'
  String get widgetAccent => _prefs.getString(_kWidgetAccent) ?? 'gold';
  set widgetAccent(String value) => _prefs.setString(_kWidgetAccent, value);

  /// Toggle widget top header (city and date)
  bool get widgetShowHeader => _prefs.getBool(_kWidgetShowHeader) ?? true;
  set widgetShowHeader(bool value) => _prefs.setBool(_kWidgetShowHeader, value);

  /// Widget text size scale: 'standard', 'large', 'xlarge'
  String get widgetTextSize => _prefs.getString(_kWidgetTextSize) ?? 'standard';
  set widgetTextSize(String value) => _prefs.setString(_kWidgetTextSize, value);

  /// App theme: 'midnight', 'amoled', 'emerald', 'royal'
  String get appTheme => _prefs.getString(_kAppTheme) ?? 'midnight';
  set appTheme(String value) => _prefs.setString(_kAppTheme, value);

  /// App accent: 'gold', 'emerald', 'white', 'blue', 'rose'
  String get appAccent => _prefs.getString(_kAppAccent) ?? 'gold';
  set appAccent(String value) => _prefs.setString(_kAppAccent, value);

  /// App language: 'en', 'tr', 'da', 'de', 'ar'
  String get appLanguage => _prefs.getString(_kAppLanguage) ?? 'en';
  set appLanguage(String value) => _prefs.setString(_kAppLanguage, value);
}
