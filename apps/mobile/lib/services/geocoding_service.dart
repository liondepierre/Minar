import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodedPlace {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  const GeocodedPlace({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  static final RegExp _validPlaceRegex =
      RegExp(r"^[\p{L}][\p{L}\s\-']*[\p{L}]$|^[\p{L}]{2}$", unicode: true);

  /// Trims whitespace and collapses repeated spaces.
  static String sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Rejects punctuation/gibberish like "Ikast ..dew.de." or digits.
  static bool isValidPlaceName(String input) {
    final clean = sanitize(input);
    if (clean.length < 2 || clean.length > 60) return false;
    if (clean.contains('..') || clean.contains('--')) return false;
    return _validPlaceRegex.hasMatch(clean);
  }

  /// Normalizes accents & casing for strict place-name comparisons.
  static String normalize(String input) {
    const replacements = {
      'ı': 'i',
      'İ': 'i',
      'ş': 's',
      'Ş': 's',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c',
      'ä': 'a',
      'Ä': 'a',
      'å': 'a',
      'Å': 'a',
      'ø': 'o',
      'Ø': 'o',
      'æ': 'ae',
      'Æ': 'ae',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'í': 'i',
      'î': 'i',
      'ó': 'o',
      'ô': 'o',
      'ú': 'u',
      'û': 'u',
      'ß': 'ss',
    };

    final buf = StringBuffer();
    for (final rune in sanitize(input).runes) {
      final ch = String.fromCharCode(rune);
      buf.write(replacements[ch] ?? ch.toLowerCase());
    }
    return buf.toString();
  }

  static bool countriesMatch(String candidate, String query) {
    final c = normalize(candidate);
    final q = normalize(query);
    if (q.isEmpty) return true;
    if (c == q) return true;

    const aliases = {
      'turkiye': 'turkey',
      'danmark': 'denmark',
      'deutschland': 'germany',
      'usa': 'united states',
      'us': 'united states',
      'united states of america': 'united states',
      'uk': 'united kingdom',
      'sverige': 'sweden',
      'norge': 'norway',
      'nederland': 'netherlands',
    };
    return (aliases[c] ?? c) == (aliases[q] ?? q);
  }

  /// Resolves a city/village (e.g. Ejstrupholm) using fast Open-Meteo geocoding.
  static Future<GeocodedPlace?> resolvePlace({
    required String city,
    required String country,
  }) async {
    final cleanCity = sanitize(city);
    final cleanCountry = sanitize(country);
    if (!isValidPlaceName(cleanCity)) return null;
    if (cleanCountry.isNotEmpty && !isValidPlaceName(cleanCountry)) return null;

    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': cleanCity,
        'count': '10',
        'language': 'en',
        'format': 'json',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final normQuery = normalize(cleanCity);

      for (final raw in results) {
        final item = raw as Map<String, dynamic>;
        final name = item['name'] as String?;
        final itemCountry = item['country'] as String? ?? '';
        final lat = (item['latitude'] as num?)?.toDouble();
        final lon = (item['longitude'] as num?)?.toDouble();
        if (name == null || lat == null || lon == null) continue;

        final normName = normalize(name);
        if (normName != normQuery) continue;
        if (cleanCountry.isNotEmpty &&
            !countriesMatch(itemCountry, cleanCountry)) {
          continue;
        }

        return GeocodedPlace(
          city: name,
          country: itemCountry.isNotEmpty ? itemCountry : cleanCountry,
          latitude: lat,
          longitude: lon,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
