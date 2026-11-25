import 'package:flutter/material.dart';
import '../../models/prayer_schedule.dart';
import '../theme.dart';

class PrayerTile extends StatelessWidget {
  final PrayerItem item;
  final bool isNext;
  final bool useTurkish;
  final String? timeRemaining;
  final bool zoomEnhanced;

  const PrayerTile({
    super.key,
    required this.item,
    required this.isNext,
    required this.useTurkish,
    this.timeRemaining,
    this.zoomEnhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.type.displayName(useTurkish: useTurkish);
    final secondary =
        useTurkish ? item.type.englishName : item.type.turkishName;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: zoomEnhanced ? 18 : 13,
      ),
      decoration: BoxDecoration(
        color: isNext
            ? MinarTheme.surfaceSubtle.withOpacity(0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: zoomEnhanced ? 8 : 6,
            height: zoomEnhanced ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNext ? MinarTheme.goldWarm : Colors.transparent,
            ),
          ),
          SizedBox(width: zoomEnhanced ? 12 : 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: MinarTheme.textPrimary,
                      fontSize: zoomEnhanced ? 22 : 16,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    secondary,
                    style: TextStyle(
                      color: MinarTheme.textSecondary.withOpacity(0.6),
                      fontSize: zoomEnhanced ? 15 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.time,
              style: TextStyle(
                color: isNext ? MinarTheme.goldLight : MinarTheme.textPrimary,
                fontSize: zoomEnhanced ? 22 : 17,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
