import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AutoLocationResult {
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;

  const AutoLocationResult({
    required this.city,
    required this.country,
    this.latitude,
    this.longitude,
  });
}

class LocationDetectOutcome {
  final AutoLocationResult? result;
  final String? errorMessage;

  const LocationDetectOutcome({this.result, this.errorMessage});
}

class LocationService {
  static const MethodChannel _channel = MethodChannel('com.minar.app/location');

  /// Zero-battery auto location via IP geolocation (0 permissions required).
  static Future<AutoLocationResult?> detectLocation() async {
    // 1. Primary HTTPS provider
    try {
      final res = await http
          .get(Uri.parse('https://free.freeipapi.com/api/v1/json'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final city = json['cityName'] as String?;
        final country = json['countryName'] as String?;
        final lat = (json['latitude'] as num?)?.toDouble();
        final lon = (json['longitude'] as num?)?.toDouble();
        if (city != null && country != null && city.isNotEmpty) {
          return AutoLocationResult(
            city: city,
            country: country,
            latitude: lat,
            longitude: lon,
          );
        }
      }
    } catch (_) {}

    // 2. Secondary HTTPS provider (ipwho.is)
    try {
      final res = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final city = json['city'] as String?;
          final country = json['country'] as String?;
          final lat = (json['latitude'] as num?)?.toDouble();
          final lon = (json['longitude'] as num?)?.toDouble();
          if (city != null && country != null && city.isNotEmpty) {
            return AutoLocationResult(
              city: city,
              country: country,
              latitude: lat,
              longitude: lon,
            );
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Privacy-first, battery-saving Android coarse location (Wi-Fi/Cell only,
  /// zero GPS hardware wakeups, ephemeral in-memory reverse geocoding).
  static Future<LocationDetectOutcome> detectCoarseDeviceLocation() async {
    if (!Platform.isAndroid) {
      final ipRes = await detectLocation();
      if (ipRes != null) {
        return LocationDetectOutcome(result: ipRes);
      }
      return const LocationDetectOutcome(
        errorMessage: 'Coarse device location is supported on Android; IP fallback also failed.',
      );
    }

    try {
      final data =
          await _channel.invokeMapMethod<String, dynamic>('getCoarseLocation');
      final lat = (data?['latitude'] as num?)?.toDouble();
      final lon = (data?['longitude'] as num?)?.toDouble();

      if (lat == null || lon == null) {
        return const LocationDetectOutcome(
          errorMessage: 'Could not read coarse device location.',
        );
      }

      final reversed = await _reverseGeocodeEphemeral(lat, lon);
      if (reversed != null) {
        return LocationDetectOutcome(result: reversed);
      }
      return const LocationDetectOutcome(
        errorMessage: 'Got location, but could not resolve city name offline.',
      );
    } on PlatformException catch (e) {
      return LocationDetectOutcome(
        errorMessage:
            e.message ?? 'Location permission unavailable. Try Network IP mode.',
      );
    } catch (_) {
      return const LocationDetectOutcome(
        errorMessage: 'Could not read battery-saver device location.',
      );
    }
  }

  /// Ephemeral reverse-geocode without storing coordinates.
  static Future<AutoLocationResult?> _reverseGeocodeEphemeral(
    double lat,
    double lon,
  ) async {
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': lat.toStringAsFixed(3), // ~100m privacy rounding
          'longitude': lon.toStringAsFixed(3),
          'localityLanguage': 'en',
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final city = (json['city'] as String?)?.trim().isNotEmpty == true
            ? (json['city'] as String).trim()
            : (json['locality'] as String?)?.trim() ?? '';
        final country = (json['countryName'] as String?)?.trim() ?? '';
        if (city.isNotEmpty && country.isNotEmpty) {
          return AutoLocationResult(
            city: city,
            country: country,
            latitude: lat,
            longitude: lon,
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
