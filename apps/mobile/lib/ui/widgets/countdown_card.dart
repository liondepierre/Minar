import 'package:flutter/material.dart';
import '../../models/prayer_schedule.dart';
import '../theme.dart';

class CountdownCard extends StatelessWidget {
  final NextPrayer? nextPrayer;
  final bool useTurkish;
  final bool zoomEnhanced;

  const CountdownCard({
    super.key,
    required this.nextPrayer,
    required this.useTurkish,
    this.zoomEnhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    if (nextPrayer == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Updating prayer times...',
            style: TextStyle(color: MinarTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final item = nextPrayer!.item;
    final name = item.type.displayName(useTurkish: useTurkish);
    final secondary =
        useTurkish ? item.type.englishName : item.type.turkishName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: MinarTheme.surfaceSubtle.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MinarTheme.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: MinarTheme.goldWarm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nextPrayer!.isTomorrowFajr
                        ? 'TOMORROW FAJR'
                        : 'NEXT PRAYER',
                    style: const TextStyle(
                      color: MinarTheme.sectionHeader,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              Text(
                item.type.arabicName,
                style: TextStyle(
                  color: MinarTheme.goldLight.withOpacity(0.7),
                  fontSize: zoomEnhanced ? 20 : 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: MinarTheme.textPrimary,
                          fontSize: zoomEnhanced ? 36 : 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($secondary)',
                        style: TextStyle(
                          color: MinarTheme.textSecondary,
                          fontSize: zoomEnhanced ? 17 : 13,
                          fontWeight: FontWeight.w400,
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
                    color: MinarTheme.goldLight,
                    fontSize: zoomEnhanced ? 30 : 25,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: MinarTheme.goldWarm,
                size: zoomEnhanced ? 18 : 14,
              ),
              const SizedBox(width: 6),
              Text(
                nextPrayer!.formattedRemaining,
                style: TextStyle(
                  color: MinarTheme.goldWarm,
                  fontSize: zoomEnhanced ? 17 : 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'remaining',
                style: TextStyle(
                  color: MinarTheme.textSecondary,
                  fontSize: zoomEnhanced ? 15 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
