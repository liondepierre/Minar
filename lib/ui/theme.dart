import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinarTheme {
  // Much deeper, inky midnight blue palette sampled directly from the icon
  static const Color midnightTop = Color(0xFF0C1424);
  static const Color midnightBottom = Color(0xFF060A12);
  static const Color surfaceSolid = Color(0xFF0E1729);
  static const Color surfaceSubtle = Color(0xFF131F36);

  // Exact icon moon crescent yellows (soft luminous butter gold)
  static const Color goldLight = Color(0xFFF4DC9F);
  static const Color goldWarm = Color(0xFFE8C582);
  static const Color goldPill = Color(0x1FE8C582);

  // Clean neutral typography (keeps yellow as a rare accent)
  static const Color textPrimary = Color(0xFFF3F5F8);
  static const Color textSecondary = Color(0xFF7E8EA6);
  static const Color sectionHeader = Color(0xFF6B7E99);
  static const Color borderFaint = Color(0x12FFFFFF);

  static LinearGradient get backgroundGradient => const LinearGradient(
        colors: [midnightTop, midnightBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static const List<String> availableFonts = [
    'System Default',
    'Inter',
    'Outfit',
    'Playfair Display',
    'Cinzel',
    'Plus Jakarta Sans',
    'Space Mono',
  ];

  static TextStyle fontTextStyle(String font, {TextStyle? baseStyle}) {
    final base = baseStyle ?? const TextStyle();
    try {
      switch (font) {
        case 'Inter':
          return GoogleFonts.inter(textStyle: base);
        case 'Outfit':
          return GoogleFonts.outfit(textStyle: base);
        case 'Playfair Display':
          return GoogleFonts.playfairDisplay(textStyle: base);
        case 'Cinzel':
          return GoogleFonts.cinzel(textStyle: base);
        case 'Plus Jakarta Sans':
          return GoogleFonts.plusJakartaSans(textStyle: base);
        case 'Space Mono':
          return GoogleFonts.spaceMono(textStyle: base);
        default:
          return base;
      }
    } catch (_) {
      return base;
    }
  }

  static ThemeData darkTheme([String font = 'System Default']) {
    TextTheme? textTheme;
    try {
      final baseTheme = ThemeData.dark().textTheme;
      switch (font) {
        case 'Inter':
          textTheme = GoogleFonts.interTextTheme(baseTheme);
          break;
        case 'Outfit':
          textTheme = GoogleFonts.outfitTextTheme(baseTheme);
          break;
        case 'Playfair Display':
          textTheme = GoogleFonts.playfairDisplayTextTheme(baseTheme);
          break;
        case 'Cinzel':
          textTheme = GoogleFonts.cinzelTextTheme(baseTheme);
          break;
        case 'Plus Jakarta Sans':
          textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTheme);
          break;
        case 'Space Mono':
          textTheme = GoogleFonts.spaceMonoTextTheme(baseTheme);
          break;
        default:
          textTheme = null;
      }
    } catch (_) {
      textTheme = null;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnightBottom,
      primaryColor: goldWarm,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: goldWarm,
        secondary: goldLight,
        surface: surfaceSolid,
        onSurface: textPrimary,
      ),
    );
  }
}
