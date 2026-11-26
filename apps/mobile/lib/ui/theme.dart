import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinarTheme {
  // Dynamic App Theme Colors (Defaults to inky midnight)
  static Color midnightTop = const Color(0xFF0C1424);
  static Color midnightBottom = const Color(0xFF060A12);
  static Color surfaceSolid = const Color(0xFF0E1729);
  static Color surfaceSubtle = const Color(0xFF131F36);

  // Dynamic Accent Colors (Defaults to icon crescent gold)
  static Color goldLight = const Color(0xFFF4DC9F);
  static Color goldWarm = const Color(0xFFE8C582);
  static Color goldPill = const Color(0x1FE8C582);

  // Clean neutral typography
  static const Color textPrimary = Color(0xFFF3F5F8);
  static const Color textSecondary = Color(0xFF7E8EA6);
  static const Color sectionHeader = Color(0xFF6B7E99);
  static const Color borderFaint = Color(0x12FFFFFF);

  static LinearGradient get backgroundGradient => LinearGradient(
        colors: [midnightTop, midnightBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static void applyTheme({String theme = 'midnight', String accent = 'gold'}) {
    switch (theme) {
      case 'amoled':
        midnightTop = const Color(0xFF050505);
        midnightBottom = const Color(0xFF000000);
        surfaceSolid = const Color(0xFF0C0C0C);
        surfaceSubtle = const Color(0xFF151515);
        break;
      case 'emerald':
        midnightTop = const Color(0xFF071812);
        midnightBottom = const Color(0xFF030C09);
        surfaceSolid = const Color(0xFF0B2119);
        surfaceSubtle = const Color(0xFF112D23);
        break;
      case 'royal':
        midnightTop = const Color(0xFF101026);
        midnightBottom = const Color(0xFF070714);
        surfaceSolid = const Color(0xFF151532);
        surfaceSubtle = const Color(0xFF1E1E42);
        break;
      default: // 'midnight'
        midnightTop = const Color(0xFF0C1424);
        midnightBottom = const Color(0xFF060A12);
        surfaceSolid = const Color(0xFF0E1729);
        surfaceSubtle = const Color(0xFF131F36);
        break;
    }

    switch (accent) {
      case 'emerald':
        goldWarm = const Color(0xFF4ADE80);
        goldLight = const Color(0xFF86EFAC);
        goldPill = const Color(0x1F4ADE80);
        break;
      case 'white':
        goldWarm = const Color(0xFFFFFFFF);
        goldLight = const Color(0xFFF3F4F6);
        goldPill = const Color(0x1FFFFFFF);
        break;
      case 'blue':
        goldWarm = const Color(0xFF60A5FA);
        goldLight = const Color(0xFF93C5FD);
        goldPill = const Color(0x1F60A5FA);
        break;
      case 'rose':
        goldWarm = const Color(0xFFF472B6);
        goldLight = const Color(0xFFFBCFE8);
        goldPill = const Color(0x1FF472B6);
        break;
      default: // 'gold'
        goldWarm = const Color(0xFFE8C582);
        goldLight = const Color(0xFFF4DC9F);
        goldPill = const Color(0x1FE8C582);
        break;
    }
  }

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
      colorScheme: ColorScheme.dark(
        primary: goldWarm,
        secondary: goldLight,
        surface: surfaceSolid,
        onSurface: textPrimary,
      ),
    );
  }
}
