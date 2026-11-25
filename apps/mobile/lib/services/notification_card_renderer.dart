import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/prayer_schedule.dart';
import '../ui/theme.dart';

class NotificationCardRenderer {
  static const double _cardWidth = 1040;

  // ─── TABLE CARD (2x3 Panoramic Timetable) ──────────────────────────────────
  static const double _tableCardHeight = 480;

  static Future<Uint8List?> renderTableCard({
    required PrayerSchedule schedule,
    required NextPrayer? nextPrayer,
    required bool useTurkish,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, _cardWidth, _tableCardHeight),
      );

      _drawCardBackground(canvas, _cardWidth, _tableCardHeight);

      const double leftMargin = 16.0;
      const double colGap = 14.0;
      const double colWidth = 326.0;
      const double topMargin = 16.0;
      const double rowGap = 14.0;
      const double rowHeight = 215.0;

      for (int i = 0; i < schedule.items.length && i < 6; i++) {
        final item = schedule.items[i];
        final isNext = nextPrayer?.item.type == item.type;
        final name = item.type.displayName(useTurkish: useTurkish);
        final secondary =
            useTurkish ? item.type.englishName : item.type.turkishName;

        final int col = i % 3;
        final int row = i ~/ 3;
        final double cellX = leftMargin + col * (colWidth + colGap);
        final double cellY = topMargin + row * (rowHeight + rowGap);

        final cellRect = Rect.fromLTWH(cellX, cellY, colWidth, rowHeight);
        final cellRRect =
            RRect.fromRectAndRadius(cellRect, const Radius.circular(16));

        if (isNext) {
          final cellBg = Paint()..color = const Color(0xFF16233B);
          canvas.drawRRect(cellRRect, cellBg);
          canvas.drawRRect(
              cellRRect, Paint()..color = const Color(0x24E8C582));
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = MinarTheme.goldWarm
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5);

          canvas.drawCircle(
              Offset(cellX + 24, cellY + 36), 7.0, Paint()..color = MinarTheme.goldWarm);

          _drawText(canvas,
              text: name.toUpperCase(),
              offset: Offset(cellX + 46, cellY + 12),
              style: const TextStyle(
                color: MinarTheme.goldLight,
                fontSize: 54,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ));

          final badgeRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(cellX + colWidth - 80, cellY + 16, 64, 26),
            const Radius.circular(7),
          );
          canvas.drawRRect(
              badgeRect, Paint()..color = const Color(0x35E8C582));
          _drawText(canvas,
              text: 'NEXT',
              offset: Offset(cellX + colWidth - 68, cellY + 21),
              style: const TextStyle(
                color: MinarTheme.goldWarm,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ));

          _drawText(canvas,
              text: item.time,
              offset: Offset(cellX + 18, cellY + 82),
              style: const TextStyle(
                color: MinarTheme.goldLight,
                fontSize: 102,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ));
        } else {
          canvas.drawRRect(
              cellRRect, Paint()..color = const Color(0xFF0D1728));
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = const Color(0x18FFFFFF)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2);

          canvas.drawCircle(
              Offset(cellX + 24, cellY + 36),
              5.5,
              Paint()..color = const Color(0x30FFFFFF));

          _drawText(canvas,
              text: name.toUpperCase(),
              offset: Offset(cellX + 46, cellY + 12),
              style: const TextStyle(
                color: MinarTheme.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ));

          _drawText(canvas,
              text: secondary,
              offset: Offset(cellX + colWidth - 94, cellY + 22),
              style: const TextStyle(
                color: MinarTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ));

          _drawText(canvas,
              text: item.time,
              offset: Offset(cellX + 18, cellY + 82),
              style: const TextStyle(
                color: MinarTheme.textPrimary,
                fontSize: 96,
                fontWeight: FontWeight.w700,
                letterSpacing: -2.2,
                fontFeatures: [FontFeature.tabularFigures()],
              ));
        }
      }

      return _finalize(recorder, _cardWidth, _tableCardHeight);
    } catch (_) {
      return null;
    }
  }

  // ─── COMPACT CARD (Balanced 2x3 Widget Style) ──────────────────────────────
  static const double _compactCardHeight = 330;

  static Future<Uint8List?> renderCompactCard({
    required PrayerSchedule schedule,
    required NextPrayer? nextPrayer,
    required bool useTurkish,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, _cardWidth, _compactCardHeight),
      );

      _drawCardBackground(canvas, _cardWidth, _compactCardHeight);

      const double leftMargin = 18.0;
      const double colGap = 14.0;
      const double colWidth = 324.0;
      const double topMargin = 18.0;
      const double rowGap = 14.0;
      const double rowHeight = 140.0;

      for (int i = 0; i < schedule.items.length && i < 6; i++) {
        final item = schedule.items[i];
        final isNext = nextPrayer?.item.type == item.type;
        final name = item.type.displayName(useTurkish: useTurkish);

        final int col = i % 3;
        final int row = i ~/ 3;
        final double cellX = leftMargin + col * (colWidth + colGap);
        final double cellY = topMargin + row * (rowHeight + rowGap);

        final cellRect = Rect.fromLTWH(cellX, cellY, colWidth, rowHeight);
        final cellRRect =
            RRect.fromRectAndRadius(cellRect, const Radius.circular(16));

        final isPast = nextPrayer != null &&
            schedule.items.indexOf(item) <
                schedule.items.indexWhere(
                    (e) => e.type == nextPrayer.item.type);

        if (isNext) {
          canvas.drawRRect(cellRRect, Paint()..color = const Color(0xFF16233B));
          canvas.drawRRect(
              cellRRect, Paint()..color = const Color(0x22E8C582));
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = MinarTheme.goldWarm
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.2);

          // Dot indicator
          canvas.drawCircle(
              Offset(cellX + 22, cellY + 30), 6.0, Paint()..color = MinarTheme.goldWarm);

          // Name
          _drawText(canvas,
              text: name.toUpperCase(),
              offset: Offset(cellX + 38, cellY + 16),
              style: const TextStyle(
                color: MinarTheme.goldLight,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ));

          // Next Pill
          final badgeRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(cellX + colWidth - 76, cellY + 18, 58, 22),
            const Radius.circular(6),
          );
          canvas.drawRRect(
              badgeRect, Paint()..color = const Color(0x35E8C582));
          _drawText(canvas,
              text: 'NEXT',
              offset: Offset(cellX + colWidth - 65, cellY + 22),
              style: const TextStyle(
                color: MinarTheme.goldWarm,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ));

          // Time
          _drawText(canvas,
              text: item.time,
              offset: Offset(cellX + 20, cellY + 62),
              style: const TextStyle(
                color: MinarTheme.goldLight,
                fontSize: 66,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
                fontFeatures: [FontFeature.tabularFigures()],
              ));
        } else {
          canvas.drawRRect(
              cellRRect, Paint()..color = const Color(0xFF0C1526));
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = const Color(0x14FFFFFF)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0);

          final nameColor = isPast
              ? const Color(0xFF4A5568)
              : MinarTheme.textSecondary;
          final timeColor = isPast
              ? const Color(0xFF4A5568)
              : MinarTheme.textPrimary;

          canvas.drawCircle(
              Offset(cellX + 22, cellY + 30),
              4.0,
              Paint()..color = isPast ? const Color(0x18FFFFFF) : const Color(0x35FFFFFF));

          _drawText(canvas,
              text: name.toUpperCase(),
              offset: Offset(cellX + 38, cellY + 18),
              style: TextStyle(
                color: nameColor,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ));

          _drawText(canvas,
              text: item.time,
              offset: Offset(cellX + 20, cellY + 62),
              style: TextStyle(
                color: timeColor,
                fontSize: 64,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ));
        }
      }

      return _finalize(recorder, _cardWidth, _compactCardHeight);
    } catch (_) {
      return null;
    }
  }

  // ─── MINIMAL CARD (Single-Row Modern Strip) ────────────────────────────────
  static const double _minimalCardHeight = 180;

  static Future<Uint8List?> renderMinimalCard({
    required PrayerSchedule schedule,
    required NextPrayer? nextPrayer,
    required bool useTurkish,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, _cardWidth, _minimalCardHeight),
      );

      _drawCardBackground(canvas, _cardWidth, _minimalCardHeight);

      const double pad = 16.0;
      const double gap = 12.0;
      const double colW = (_cardWidth - pad * 2 - gap * 5) / 6; // ~158px
      const double cellH = _minimalCardHeight - pad * 2; // 148px

      for (int i = 0; i < schedule.items.length && i < 6; i++) {
        final item = schedule.items[i];
        final isNext = nextPrayer?.item.type == item.type;
        final name = item.type.displayName(useTurkish: useTurkish);

        final double x = pad + i * (colW + gap);
        const double y = pad;

        final cellRect = Rect.fromLTWH(x, y, colW, cellH);
        final cellRRect =
            RRect.fromRectAndRadius(cellRect, const Radius.circular(14));

        final isPast = nextPrayer != null &&
            schedule.items.indexOf(item) <
                schedule.items.indexWhere(
                    (e) => e.type == nextPrayer.item.type);

        final centerX = x + colW / 2;

        if (isNext) {
          canvas.drawRRect(cellRRect, Paint()..color = const Color(0xFF16253D));
          canvas.drawRRect(
              cellRRect, Paint()..color = const Color(0x22E8C582));
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = MinarTheme.goldWarm
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.2);

          // Top Accent Gold Pill
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(centerX - 24, y + 6, 48, 3.5),
                  const Radius.circular(2)),
              Paint()..color = MinarTheme.goldWarm);

          // Name (centered)
          _drawCenteredText(canvas,
              text: name.toUpperCase(),
              centerX: centerX,
              topY: y + 20,
              style: const TextStyle(
                color: MinarTheme.goldLight,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ));

          // Time (centered)
          _drawCenteredText(canvas,
              text: item.time,
              centerX: centerX,
              topY: y + 66,
              style: const TextStyle(
                color: MinarTheme.goldLight,
                fontSize: 50,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.6,
                fontFeatures: [FontFeature.tabularFigures()],
              ));
        } else {
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = isPast
                    ? const Color(0xFF090E18)
                    : const Color(0xFF0C1526));
          canvas.drawRRect(
              cellRRect,
              Paint()
                ..color = const Color(0x12FFFFFF)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0);

          final nameColor =
              isPast ? const Color(0xFF38455A) : MinarTheme.textSecondary;
          final timeColor =
              isPast ? const Color(0xFF38455A) : MinarTheme.textPrimary;

          // Name (centered)
          _drawCenteredText(canvas,
              text: name.toUpperCase(),
              centerX: centerX,
              topY: y + 22,
              style: TextStyle(
                color: nameColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ));

          // Time (centered)
          _drawCenteredText(canvas,
              text: item.time,
              centerX: centerX,
              topY: y + 68,
              style: TextStyle(
                color: timeColor,
                fontSize: 46,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ));
        }
      }

      return _finalize(recorder, _cardWidth, _minimalCardHeight);
    } catch (_) {
      return null;
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  static void _drawCardBackground(Canvas canvas, double w, double h) {
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(20));
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, h),
        [const Color(0xFF0B1322), const Color(0xFF060A12)],
      );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0x22FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  static Future<Uint8List?> _finalize(
      ui.PictureRecorder recorder, double w, double h) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  static void _drawCenteredText(
    Canvas canvas, {
    required String text,
    required double centerX,
    required double topY,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centerX - tp.width / 2, topY));
  }
}
