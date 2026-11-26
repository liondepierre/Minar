import 'package:flutter/material.dart';
import '../../state/prayer_controller.dart';
import '../theme.dart';
import '../widgets/countdown_card.dart';
import '../widgets/prayer_tile.dart';
import '../widgets/settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  final PrayerController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  final ScrollController _pillsScrollController = ScrollController();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.controller.selectedDayIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pillsScrollController.dispose();
    super.dispose();
  }

  void _scrollPillsTo(int index) {
    if (!_pillsScrollController.hasClients) return;
    const pillWidth = 90.0;
    final pillCenter = index * pillWidth + (pillWidth / 2);
    final viewportCenter = MediaQuery.of(context).size.width / 2;
    final targetOffset = (pillCenter - viewportCenter).clamp(
      0.0,
      _pillsScrollController.position.maxScrollExtent,
    );
    _pillsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatDayLabel(int index, DateTime? dt) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    if (dt != null) {
      final wd = _weekdays[dt.weekday - 1];
      return '$wd ${dt.day}';
    }
    return 'Day ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final schedule = c.schedule;
        final nextPrayer = c.nextPrayer;
        final weekly = c.weeklySchedule;
        final daysCount = weekly?.days.length ?? 1;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: MinarTheme.backgroundGradient),
            child: SafeArea(
              child: RefreshIndicator(
                color: MinarTheme.goldWarm,
                backgroundColor: MinarTheme.surfaceSolid,
                onRefresh: () => c.fetchSchedule(force: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.asset(
                                        'assets/icon/app_icon.png',
                                        width: 28,
                                        height: 28,
                                        errorBuilder: (_, __, ___) =>
                                            Icon(
                                          Icons.nightlight_round,
                                          color: MinarTheme.goldWarm,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Minar',
                                      style: TextStyle(
                                        color: MinarTheme.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (c.isLoading)
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    MinarTheme.goldWarm),
                                          ),
                                        ),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          color: MinarTheme.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            c.fetchSchedule(force: true),
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.tune_rounded,
                                        color: MinarTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          enableDrag: false,
                                          backgroundColor: Colors.transparent,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                          ),
                                          builder: (_) =>
                                              SettingsSheet(controller: c),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Location Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: c.zoomEnhanced ? 22 : 19,
                                  color: MinarTheme.goldWarm,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${c.city}, ${c.country}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: MinarTheme.textPrimary,
                                        fontSize: c.zoomEnhanced ? 21 : 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (schedule != null &&
                                (schedule.gregorianDate.isNotEmpty ||
                                    schedule.hijriDate.isNotEmpty)) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: c.zoomEnhanced ? 28 : 25,
                                ),
                                child: Text(
                                  [
                                    if (schedule.gregorianDate.isNotEmpty)
                                      schedule.gregorianDate,
                                    if (schedule.hijriDate.isNotEmpty)
                                      schedule.hijriDate,
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: MinarTheme.textSecondary,
                                    fontSize: c.zoomEnhanced ? 14 : 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],

                            if (c.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: MinarTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: MinarTheme.goldWarm.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: MinarTheme.goldWarm,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.errorMessage!,
                                        style: const TextStyle(
                                          color: MinarTheme.textPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => c.clearError(),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: MinarTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Hero Countdown Card (Minimal)
                            CountdownCard(
                              nextPrayer: nextPrayer,
                              useTurkish: c.useTurkish,
                              zoomEnhanced: c.zoomEnhanced,
                            ),

                            const SizedBox(height: 22),

                            // Day Pager Section Header + Swipe Hint
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  c.selectedDayIndex == 0
                                      ? "TODAY'S SCHEDULE"
                                      : (c.selectedDayIndex == 1
                                          ? "TOMORROW'S SCHEDULE"
                                          : "${_formatDayLabel(c.selectedDayIndex, weekly?.days[c.selectedDayIndex].items.firstOrNull?.dateTime).toUpperCase()} SCHEDULE"),
                                  style: const TextStyle(
                                    color: MinarTheme.sectionHeader,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (daysCount > 1)
                                  Row(
                                    children: [
                                      Text(
                                        'Swipe days',
                                        style: TextStyle(
                                          color: MinarTheme.goldWarm.withOpacity(0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.swipe_rounded,
                                        size: 13,
                                        color: MinarTheme.goldWarm.withOpacity(0.7),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Horizontal Day Selector Pills
                            if (daysCount > 1)
                              SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  controller: _pillsScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: daysCount,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final isSelected =
                                        c.selectedDayIndex == index;
                                    final daySchedule = weekly!.days[index];
                                    final dt = daySchedule
                                        .items.firstOrNull?.dateTime;
                                    final label = _formatDayLabel(index, dt);

                                    return GestureDetector(
                                      onTap: () {
                                        c.selectDayIndex(index);
                                        _scrollPillsTo(index);
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(
                                              milliseconds: 280),
                                          curve: Curves.easeOutCubic,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? MinarTheme.goldWarm
                                              : MinarTheme.surfaceSubtle,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? MinarTheme.goldLight
                                                : MinarTheme.borderFaint,
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF090E18)
                                                  : MinarTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (daysCount > 1) const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Swipeable PageView of Daily Timetables
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: c.zoomEnhanced ? 440 : 365,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: daysCount,
                            onPageChanged: (page) {
                              c.selectDayIndex(page);
                              _scrollPillsTo(page);
                            },
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, dayIdx) {
                              final daySchedule = weekly != null &&
                                      dayIdx < weekly.days.length
                                  ? weekly.days[dayIdx]
                                  : schedule;

                              if (daySchedule == null) {
                                return const Center(
                                  child: Text(
                                    'No prayer times available.',
                                    style: TextStyle(
                                        color: MinarTheme.textSecondary),
                                  ),
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: MinarTheme.surfaceSubtle
                                      .withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: MinarTheme.borderFaint),
                                ),
                                child: Column(
                                  children: List.generate(
                                    daySchedule.items.length,
                                    (index) {
                                      final item = daySchedule.items[index];
                                      // Only highlight next prayer if viewing Today (dayIdx == 0)
                                      final isNext = dayIdx == 0 &&
                                          nextPrayer?.item.type == item.type;
                                      return Column(
                                        children: [
                                          PrayerTile(
                                            item: item,
                                            isNext: isNext,
                                            useTurkish: c.useTurkish,
                                            zoomEnhanced: c.zoomEnhanced,
                                          ),
                                          if (index <
                                              daySchedule.items.length - 1)
                                            Divider(
                                              height: 1,
                                              thickness: 0.6,
                                              indent: 14,
                                              endIndent: 14,
                                              color: MinarTheme.borderFaint,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Bottom info label
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            c.method.title,
                            style: TextStyle(
                              color: MinarTheme.textSecondary.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
