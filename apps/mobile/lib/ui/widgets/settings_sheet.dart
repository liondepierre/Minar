import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../models/calculation_method.dart';
import '../../state/prayer_controller.dart';
import '../theme.dart';

const String kAppVersion = '1.1.4';
const int kAppBuild = 5;

const Map<String, List<String>> _popularLocations = {
  'Japan': [
    'Tokyo',
    'Osaka',
    'Kyoto',
    'Yokohama',
    'Nagoya',
    'Sapporo',
    'Fukuoka',
    'Kobe',
  ],
  'Türkiye': [
    'Istanbul',
    'Ankara',
    'Izmir',
    'Bursa',
    'Antalya',
    'Konya',
    'Adana',
    'Gaziantep',
    'Trabzon',
  ],
  'Germany': [
    'Berlin',
    'Munich',
    'Frankfurt',
    'Hamburg',
    'Cologne',
    'Stuttgart',
    'Düsseldorf',
  ],
  'United Kingdom': [
    'London',
    'Birmingham',
    'Manchester',
    'Leeds',
    'Glasgow',
  ],
  'Netherlands': [
    'Amsterdam',
    'Rotterdam',
    'The Hague',
    'Utrecht',
  ],
  'Sweden': [
    'Stockholm',
    'Gothenburg',
    'Malmö',
    'Uppsala',
  ],
  'Norway': [
    'Oslo',
    'Bergen',
    'Trondheim',
  ],
  'France': [
    'Paris',
    'Marseille',
    'Lyon',
  ],
  'United States': [
    'New York',
    'Chicago',
    'Los Angeles',
    'Houston',
  ],
  'Denmark': [
    'Copenhagen',
    'Aarhus',
    'Odense',
    'Aalborg',
    'Vejle',
    'Esbjerg',
  ],
};

const String _kOtherCity = 'Other city...';
const String _kOtherCountry = 'Other country...';

class SettingsSheet extends StatefulWidget {
  final PrayerController controller;

  const SettingsSheet({super.key, required this.controller});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _isDismissing = false;
  bool _dragStartedAtTop = false;

  void _dismissSheet() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  late String _selectedCountry;
  late String _selectedCity;
  late TextEditingController _customCityCtrl;
  late TextEditingController _customCountryCtrl;

  bool _isSyncing = false;
  bool _justSynced = false;
  String? _customCityError;

  @override
  void initState() {
    super.initState();
    final currentCountry = widget.controller.country;
    final currentCity = widget.controller.city;

    if (_popularLocations.containsKey(currentCountry)) {
      _selectedCountry = currentCountry;
      final cities = _popularLocations[currentCountry]!;
      if (cities.contains(currentCity)) {
        _selectedCity = currentCity;
      } else {
        _selectedCity = _kOtherCity;
      }
    } else {
      _selectedCountry = _kOtherCountry;
      _selectedCity = _kOtherCity;
    }

    _customCityCtrl = TextEditingController(text: currentCity);
    _customCountryCtrl = TextEditingController(text: currentCountry);
  }

  @override
  void dispose() {
    _customCityCtrl.dispose();
    _customCountryCtrl.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? country) {
    if (country == null) return;
    setState(() {
      _selectedCountry = country;
      if (country == _kOtherCountry) {
        _selectedCity = _kOtherCity;
      } else {
        final cities = _popularLocations[country] ?? [];
        if (cities.isNotEmpty) {
          _selectedCity = cities.first;
          _applyLocation(_selectedCity, _selectedCountry);
        } else {
          _selectedCity = _kOtherCity;
        }
      }
    });
  }

  void _onCityChanged(String? city) {
    if (city == null) return;
    setState(() {
      _selectedCity = city;
      if (city != _kOtherCity && _selectedCountry != _kOtherCountry) {
        _applyLocation(_selectedCity, _selectedCountry);
      }
    });
  }

  Future<void> _applyLocation(String city, String country) async {
    final cleanCity = city.trim();
    final cleanCountry = country.trim();
    if (cleanCity.isEmpty || cleanCountry.isEmpty) {
      setState(() {
        _customCityError = 'Please enter a valid city and country.';
      });
      return;
    }
    final ok = await widget.controller.updateLocation(
      newCity: cleanCity,
      newCountry: cleanCountry,
      isManual: true,
    );
    if (ok && mounted) {
      setState(() {
        _customCityError = null;
        _customCityCtrl.text = widget.controller.city;
        _customCountryCtrl.text = widget.controller.country;
      });
      FocusScope.of(context).unfocus();
    } else if (!ok && mounted) {
      setState(() {
        _customCityError = widget.controller.errorMessage ??
            "Could not find '$cleanCity'. Kept previous location.";
      });
    }
  }

  Widget _buildLocationModeOption({
    required String label,
    required String caption,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final zoom = widget.controller.zoomEnhanced;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: zoom ? 12 : 10),
          decoration: BoxDecoration(
            color: selected
                ? MinarTheme.goldWarm.withOpacity(0.16)
                : MinarTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? MinarTheme.goldWarm.withOpacity(0.8)
                  : MinarTheme.borderFaint,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: zoom ? 18 : 16,
                color: selected ? MinarTheme.goldWarm : MinarTheme.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? MinarTheme.goldLight : MinarTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  color: selected
                      ? MinarTheme.goldLight.withOpacity(0.8)
                      : MinarTheme.textSecondary,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomErrorBanner() {
    if (_customCityError == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        _customCityError!,
        style: TextStyle(
          color: MinarTheme.goldLight,
          fontSize: 11,
        ),
      ),
    );
  }

  Future<void> _syncSelectionFromController() async {
    final c = widget.controller;
    if (!mounted) return;
    setState(() {
      if (_popularLocations.containsKey(c.country)) {
        _selectedCountry = c.country;
        final cities = _popularLocations[c.country]!;
        _selectedCity = cities.contains(c.city) ? c.city : _kOtherCity;
      } else {
        _selectedCountry = _kOtherCountry;
        _selectedCity = _kOtherCity;
      }
      _customCityCtrl.text = c.city;
      _customCountryCtrl.text = c.country;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final zoom = c.zoomEnhanced;
        final textScale = zoom ? 1.25 : 1.0;
        final isCustomCountry = _selectedCountry == _kOtherCountry;
        final isCustomCity = _selectedCity == _kOtherCity;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              margin: EdgeInsets.only(
                top: (MediaQuery.of(context).size.height * (zoom ? 0.08 : 0.12)).clamp(64.0, 130.0),
              ),
              decoration: BoxDecoration(
                color: MinarTheme.surfaceSolid,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pinned Drag Handle & Header (Pinned at top, outside scroll view)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! > 2) {
                      _dismissSheet();
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! > 50) {
                      _dismissSheet();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: MinarTheme.textSecondary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.strings.settings,
                              style: const TextStyle(
                                color: MinarTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: _dismissSheet,
                              icon: const Icon(Icons.close_rounded,
                                  color: MinarTheme.textSecondary, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        _dragStartedAtTop = notification.metrics.pixels <= 0 &&
                            notification.dragDetails != null;
                      } else if (notification is OverscrollNotification) {
                        if (_dragStartedAtTop && notification.overscroll < 0) {
                          _dismissSheet();
                          return true;
                        }
                      } else if (notification is ScrollUpdateNotification) {
                        if (_dragStartedAtTop &&
                            notification.metrics.pixels <= 0 &&
                            notification.scrollDelta != null &&
                            notification.scrollDelta! < -8) {
                          _dismissSheet();
                          return true;
                        }
                      } else if (notification is ScrollEndNotification) {
                        _dragStartedAtTop = false;
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 4,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // Location Section
                Text(
                  c.strings.location,
                  style: const TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Location Mode Selector (Device Coarse, Network IP, Manual City)
                Row(
                  children: [
                    _buildLocationModeOption(
                      label: c.strings.device,
                      caption: c.strings.deviceCaption,
                      icon: Icons.my_location_rounded,
                      selected: c.autoLocation && c.locationMode == 'device',
                      onTap: () async {
                        await c.setLocationMode('device');
                        await c.setAutoLocation(true);
                        await _syncSelectionFromController();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildLocationModeOption(
                      label: c.strings.networkIp,
                      caption: c.strings.zeroPermissions,
                      icon: Icons.wifi_rounded,
                      selected: c.autoLocation && c.locationMode != 'device',
                      onTap: () async {
                        await c.setLocationMode('ip');
                        await c.setAutoLocation(true);
                        await _syncSelectionFromController();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildLocationModeOption(
                      label: c.strings.manualCity,
                      caption: c.strings.pickFromList,
                      icon: Icons.edit_location_alt_rounded,
                      selected: !c.autoLocation,
                      onTap: () async {
                        await c.setAutoLocation(false);
                        await _syncSelectionFromController();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location Status / Helper Note
                if (c.autoLocation)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: MinarTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MinarTheme.borderFaint),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          c.locationMode == 'device'
                              ? Icons.cell_tower_rounded
                              : Icons.public_rounded,
                          size: 15,
                          color: MinarTheme.goldWarm,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.locationMode == 'device'
                                ? 'Coarse cell/Wi-Fi • Zero GPS wakeups • ${c.city}, ${c.country}'
                                : 'Network IP connection • Zero permissions • ${c.city}, ${c.country}',
                            style: const TextStyle(
                              color: MinarTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Manual Location Selection
                if (!c.autoLocation) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Country Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: MinarTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MinarTheme.borderFaint),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: isCustomCountry
                                  ? _kOtherCountry
                                  : _selectedCountry,
                              isExpanded: true,
                              dropdownColor: MinarTheme.surfaceSolid,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: MinarTheme.goldWarm, size: 18),
                              items: [
                                ..._popularLocations.keys.map(
                                  (cnt) => DropdownMenuItem(
                                    value: cnt,
                                    child: Text(
                                      cnt,
                                      style: const TextStyle(
                                        color: MinarTheme.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: _kOtherCountry,
                                  child: Text(
                                    _kOtherCountry,
                                    style: TextStyle(
                                      color: MinarTheme.goldLight,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: _onCountryChanged,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // City Dropdown (only when country is recognized)
                      if (!isCustomCountry)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: MinarTheme.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MinarTheme.borderFaint),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: isCustomCity ? _kOtherCity : _selectedCity,
                                isExpanded: true,
                                dropdownColor: MinarTheme.surfaceSolid,
                                icon: Icon(Icons.arrow_drop_down,
                                    color: MinarTheme.goldWarm, size: 18),
                                items: [
                                  ...(_popularLocations[_selectedCountry] ?? [])
                                      .map((city) => DropdownMenuItem(
                                            value: city,
                                            child: Text(
                                              city,
                                              style: const TextStyle(
                                                color: MinarTheme.textPrimary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )),
                                  DropdownMenuItem(
                                    value: _kOtherCity,
                                    child: Text(
                                      _kOtherCity,
                                      style: TextStyle(
                                        color: MinarTheme.goldLight,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: _onCityChanged,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Case 1: Known Country, custom City (ONLY 1 input!)
                  if (!isCustomCountry && isCustomCity) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customCityCtrl,
                            onSubmitted: (val) =>
                                _applyLocation(val, _selectedCountry),
                            decoration: InputDecoration(
                              hintText: 'Enter city in $_selectedCountry...',
                              hintStyle: const TextStyle(
                                color: MinarTheme.textSecondary,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: MinarTheme.surfaceSubtle,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(
                              color: MinarTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _applyLocation(
                              _customCityCtrl.text,
                              _selectedCountry,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MinarTheme.goldWarm,
                            foregroundColor: MinarTheme.midnightBottom,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Apply',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    _buildCustomErrorBanner(),
                  ],

                  // Case 2: Other Country (User selected Other Country)
                  if (isCustomCountry) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customCityCtrl,
                            onSubmitted: (_) => _applyLocation(
                              _customCityCtrl.text,
                              _customCountryCtrl.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'City name',
                              hintStyle: const TextStyle(
                                color: MinarTheme.textSecondary,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: MinarTheme.surfaceSubtle,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(
                              color: MinarTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _customCountryCtrl,
                            onSubmitted: (_) => _applyLocation(
                              _customCityCtrl.text,
                              _customCountryCtrl.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Country name',
                              hintStyle: const TextStyle(
                                color: MinarTheme.textSecondary,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: MinarTheme.surfaceSubtle,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(
                              color: MinarTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _applyLocation(
                            _customCityCtrl.text,
                            _customCountryCtrl.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MinarTheme.goldWarm,
                          foregroundColor: MinarTheme.midnightBottom,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Apply Custom Location',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    _buildCustomErrorBanner(),
                  ],
                ],

                const SizedBox(height: 18),

                // Calculation Method
                const Text(
                  'CALCULATION METHOD',
                  style: TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: MinarTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MinarTheme.borderFaint),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CalculationMethod>(
                      value: c.method,
                      isExpanded: true,
                      dropdownColor: MinarTheme.surfaceSolid,
                      icon: Icon(Icons.arrow_drop_down,
                          color: MinarTheme.goldWarm),
                      items: CalculationMethod.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.title,
                            style: const TextStyle(
                                color: MinarTheme.textPrimary, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newMethod) {
                        if (newMethod != null) {
                          c.updateMethod(newMethod);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Preferences
                Text(
                  c.strings.preferences,
                  style: const TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.strings.language,
                  style: const TextStyle(color: MinarTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLanguageChip('English', 'en', c),
                      const SizedBox(width: 8),
                      _buildLanguageChip('Türkçe', 'tr', c),
                      const SizedBox(width: 8),
                      _buildLanguageChip('Dansk', 'da', c),
                      const SizedBox(width: 8),
                      _buildLanguageChip('Deutsch', 'de', c),
                      const SizedBox(width: 8),
                      _buildLanguageChip('العربية', 'ar', c),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.strings.turkishPrayerNames,
                      style: const TextStyle(
                          color: MinarTheme.textPrimary, fontSize: 14)),
                  subtitle: Text(
                    c.useTurkish
                        ? 'İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı'
                        : 'Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha',
                    style: const TextStyle(
                        color: MinarTheme.textSecondary, fontSize: 11),
                  ),
                  value: c.useTurkish,
                  activeColor: MinarTheme.goldWarm,
                  onChanged: (_) => c.toggleTurkishNames(),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.strings.zoomEnhancedMode,
                      style: const TextStyle(
                          color: MinarTheme.textPrimary, fontSize: 14)),
                  subtitle: Text(
                    c.strings.zoomEnhancedCaption,
                    style:
                        const TextStyle(color: MinarTheme.textSecondary, fontSize: 11),
                  ),
                  value: c.zoomEnhanced,
                  activeColor: MinarTheme.goldWarm,
                  onChanged: (_) => c.toggleZoomEnhanced(),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.strings.prayerNotifications,
                      style: const TextStyle(
                          color: MinarTheme.textPrimary, fontSize: 14)),
                  subtitle: Text(
                    c.strings.prayerNotificationsCaption,
                    style:
                        const TextStyle(color: MinarTheme.textSecondary, fontSize: 11),
                  ),
                  value: c.notificationsEnabled,
                  activeColor: MinarTheme.goldWarm,
                  onChanged: (_) => c.toggleNotifications(),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.strings.pinnedShadeNotification,
                      style: const TextStyle(
                          color: MinarTheme.textPrimary, fontSize: 14)),
                  subtitle: Text(
                    c.strings.pinnedShadeCaption,
                    style:
                        const TextStyle(color: MinarTheme.textSecondary, fontSize: 11),
                  ),
                  value: c.pinnedNotificationEnabled,
                  activeColor: MinarTheme.goldWarm,
                  onChanged: (_) => c.togglePinnedNotification(),
                ),
                if (c.pinnedNotificationEnabled) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: MinarTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MinarTheme.borderFaint),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: const ['table', 'compact', 'minimal']
                                .contains(c.pinnedNotificationStyle)
                            ? c.pinnedNotificationStyle
                            : 'table',
                        isExpanded: true,
                        dropdownColor: MinarTheme.surfaceSolid,
                        icon: Icon(Icons.arrow_drop_down,
                            color: MinarTheme.goldWarm),
                        items: const [
                          DropdownMenuItem(
                            value: 'table',
                            child: Text(
                              'Table View',
                              style: TextStyle(
                                  color: MinarTheme.textPrimary, fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'compact',
                            child: Text(
                              'Compact Summary',
                              style: TextStyle(
                                  color: MinarTheme.textPrimary, fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'minimal',
                            child: Text(
                              'Minimal Single Line',
                              style: TextStyle(
                                  color: MinarTheme.textPrimary, fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (style) {
                          if (style != null) {
                            c.setPinnedNotificationStyle(style);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                const SizedBox(height: 18),

                // App Theme & Accent Customization
                const Text(
                  'APP THEME & ACCENT',
                  style: TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                // App Theme Mode Picker
                const Text(
                  'App Theme Palette',
                  style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAppThemeChip('Midnight', 'midnight', c),
                      const SizedBox(width: 8),
                      _buildAppThemeChip('AMOLED Black', 'amoled', c),
                      const SizedBox(width: 8),
                      _buildAppThemeChip('Emerald Night', 'emerald', c),
                      const SizedBox(width: 8),
                      _buildAppThemeChip('Royal Navy', 'royal', c),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // App Accent Color Picker
                const Text(
                  'App Accent Color',
                  style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAppAccentDot('Gold', 'gold', const Color(0xFFE8C582), c),
                      const SizedBox(width: 8),
                      _buildAppAccentDot('Emerald', 'emerald', const Color(0xFF4ADE80), c),
                      const SizedBox(width: 8),
                      _buildAppAccentDot('White', 'white', Colors.white, c),
                      const SizedBox(width: 8),
                      _buildAppAccentDot('Sky Blue', 'blue', const Color(0xFF60A5FA), c),
                      const SizedBox(width: 8),
                      _buildAppAccentDot('Rose', 'rose', const Color(0xFFF472B6), c),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Home Screen Widgets Customization
                const Text(
                  'HOME SCREEN WIDGETS',
                  style: TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Widget Theme Picker (Midnight, AMOLED, Glass, Transparent)
                const Text(
                  'Background Style',
                  style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildThemeChip('Midnight', 'midnight', c),
                      const SizedBox(width: 8),
                      _buildThemeChip('AMOLED Black', 'amoled', c),
                      const SizedBox(width: 8),
                      _buildThemeChip('Glass Frost', 'glass', c),
                      const SizedBox(width: 8),
                      _buildThemeChip('Transparent', 'transparent', c),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Widget Accent Picker (Gold, Emerald, White, Sky Blue)
                const Text(
                  'Accent Color',
                  style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAccentDot('Gold', 'gold', const Color(0xFFE8C582), c),
                      const SizedBox(width: 8),
                      _buildAccentDot('Emerald', 'emerald', const Color(0xFF4ADE80), c),
                      const SizedBox(width: 8),
                      _buildAccentDot('White', 'white', Colors.white, c),
                      const SizedBox(width: 8),
                      _buildAccentDot('Sky Blue', 'blue', const Color(0xFF60A5FA), c),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Show Header Switch
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Header in Widgets',
                      style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13)),
                  subtitle: const Text(
                    'Display location and Hijri date header bar',
                    style: TextStyle(color: MinarTheme.textSecondary, fontSize: 11),
                  ),
                  value: c.widgetShowHeader,
                  activeColor: MinarTheme.goldWarm,
                  onChanged: (val) => c.setWidgetShowHeader(val),
                ),
                const SizedBox(height: 8),

                // Widget Font Size (Standard, Large +15%, X-Large +30%)
                const Text(
                  'Widget Font Size',
                  style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTextSizeChip('Standard', 'standard', c),
                      const SizedBox(width: 8),
                      _buildTextSizeChip('Large (+15%)', 'large', c),
                      const SizedBox(width: 8),
                      _buildTextSizeChip('X-Large (+30%)', 'xlarge', c),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // App Typography (7 Fonts with Live Previews)
                const Text(
                  'TYPOGRAPHY',
                  style: TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: MinarTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MinarTheme.borderFaint),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: MinarTheme.availableFonts.contains(c.fontFamily)
                          ? c.fontFamily
                          : MinarTheme.availableFonts.first,
                      isExpanded: true,
                      dropdownColor: MinarTheme.surfaceSolid,
                      icon: Icon(Icons.arrow_drop_down,
                          color: MinarTheme.goldWarm),
                      selectedItemBuilder: (context) {
                        return MinarTheme.availableFonts.map((font) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              font,
                              style: MinarTheme.fontTextStyle(
                                font,
                                baseStyle: const TextStyle(
                                  color: MinarTheme.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: MinarTheme.availableFonts.map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  font,
                                  overflow: TextOverflow.ellipsis,
                                  style: MinarTheme.fontTextStyle(
                                    font,
                                    baseStyle: const TextStyle(
                                      color: MinarTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '12:45',
                                style: MinarTheme.fontTextStyle(
                                  font,
                                  baseStyle: TextStyle(
                                    color: MinarTheme.goldLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newFont) {
                        if (newFont != null) {
                          c.setFontFamily(newFont);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cache & Storage
                const Text(
                  'CACHE & STORAGE',
                  style: TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offline Schedule',
                            style: TextStyle(
                                color: MinarTheme.textPrimary, fontSize: 14)),
                        Text('Saved locally for zero-network use',
                            style: TextStyle(
                                color: MinarTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: _isSyncing
                          ? null
                          : () async {
                              setState(() {
                                _isSyncing = true;
                                _justSynced = false;
                              });
                              await c.clearCache();
                              if (mounted) {
                                setState(() {
                                  _isSyncing = false;
                                  _justSynced = true;
                                });
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    setState(() => _justSynced = false);
                                  }
                                });
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MinarTheme.goldLight,
                        side: BorderSide(
                          color: _justSynced
                              ? Colors.greenAccent
                              : MinarTheme.goldWarm.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: _isSyncing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    MinarTheme.goldWarm),
                              ),
                            )
                          : _justSynced
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded,
                                        size: 14, color: Colors.greenAccent),
                                    SizedBox(width: 4),
                                    Text('Synced!',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.greenAccent)),
                                  ],
                                )
                              : const Text('Re-sync',
                                  style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ABOUT & UPDATES
                const Text(
                  'ABOUT & UPDATES',
                  style: TextStyle(
                    color: MinarTheme.sectionHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MinarTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MinarTheme.borderFaint),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: MinarTheme.surfaceSolid,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MinarTheme.borderFaint),
                            ),
                            child: Icon(Icons.nightlight_round,
                                color: MinarTheme.goldWarm, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minar Prayer Times',
                                  style: TextStyle(
                                    color: MinarTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Version $kAppVersion (Build $kAppBuild) • Open Source',
                                  style: TextStyle(
                                    color: MinarTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _checkForUpdates(context),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('Check for updates',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MinarTheme.goldWarm,
                            foregroundColor: MinarTheme.midnightBottom,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
),
);
      },
    );
  }

  Widget _buildLanguageChip(String label, String code, PrayerController c) {
    final isSelected = c.appLanguage == code;
    return GestureDetector(
      onTap: () => c.setAppLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MinarTheme.goldWarm : MinarTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MinarTheme.goldLight : MinarTheme.borderFaint,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF090E18) : MinarTheme.textPrimary,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeChip(String label, String value, PrayerController c) {
    final isSelected = c.widgetTheme == value;
    return GestureDetector(
      onTap: () => c.setWidgetTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MinarTheme.goldWarm : MinarTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MinarTheme.goldLight : MinarTheme.borderFaint,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF090E18) : MinarTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAccentDot(String label, String value, Color color, PrayerController c) {
    final isSelected = c.widgetAccent == value;
    return GestureDetector(
      onTap: () => c.setWidgetAccent(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MinarTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : MinarTheme.borderFaint,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MinarTheme.textPrimary : MinarTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeChip(String label, String value, PrayerController c) {
    final isSelected = c.widgetTextSize == value;
    return GestureDetector(
      onTap: () => c.setWidgetTextSize(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MinarTheme.goldWarm : MinarTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MinarTheme.goldLight : MinarTheme.borderFaint,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF090E18) : MinarTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppThemeChip(String label, String value, PrayerController c) {
    final isSelected = c.appTheme == value;
    return GestureDetector(
      onTap: () => c.setAppTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MinarTheme.goldWarm : MinarTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MinarTheme.goldLight : MinarTheme.borderFaint,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF090E18) : MinarTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppAccentDot(String label, String value, Color color, PrayerController c) {
    final isSelected = c.appAccent == value;
    return GestureDetector(
      onTap: () => c.setAppAccent(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MinarTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : MinarTheme.borderFaint,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MinarTheme.textPrimary : MinarTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isVersionNewer(String latest, String current) {
    try {
      final lParts = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final cParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _openUrl(String url) async {
    try {
      const channel = MethodChannel('com.minar.app/system');
      await channel.invokeMethod('openUrl', {'url': url});
    } catch (_) {}
  }

  void _showUpdateErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MinarTheme.surfaceSolid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: MinarTheme.borderFaint),
        ),
        title: const Text('Update Check Failed',
            style: TextStyle(color: MinarTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          '$error\n\nYou can manually check releases at:\ngithub.com/liondepierre/Minar/releases',
          style: const TextStyle(color: MinarTheme.textSecondary, fontSize: 12.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl('https://github.com/liondepierre/Minar/releases');
            },
            style: TextButton.styleFrom(foregroundColor: MinarTheme.goldWarm),
            child: const Text('Open GitHub'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: MinarTheme.textSecondary),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          color: MinarTheme.surfaceSolid,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(MinarTheme.goldWarm),
                  ),
                ),
                SizedBox(width: 16),
                Text('Checking GitHub...',
                    style: TextStyle(color: MinarTheme.textPrimary, fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await http
          .get(
            Uri.parse('https://api.github.com/repos/liondepierre/Minar/releases/latest'),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 8));

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final latestTag = (json['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
        final releaseUrl = json['html_url'] as String? ?? 'https://github.com/liondepierre/Minar/releases';
        final body = json['body'] as String? ?? '';

        String? apkUrl;
        final assets = json['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final a in assets) {
            final name = (a['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              apkUrl = a['browser_download_url'] as String?;
              break;
            }
          }
        }

        final isNewer = _isVersionNewer(latestTag, kAppVersion);

        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (ctx) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              textScaler: TextScaler.linear(widget.controller.zoomEnhanced ? 1.25 : 1.0),
            ),
            child: AlertDialog(
              backgroundColor: MinarTheme.surfaceSolid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: MinarTheme.borderFaint),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MinarTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isNewer
                          ? Icons.system_update_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isNewer ? MinarTheme.goldWarm : Colors.greenAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isNewer ? 'Update Available' : 'Up to Date',
                    style: const TextStyle(
                      color: MinarTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNewer
                        ? 'Minar v$latestTag is available (you have v$kAppVersion).'
                        : 'Minar v$kAppVersion is currently the latest release.',
                    style: const TextStyle(
                      color: MinarTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isNewer && body.isNotEmpty
                        ? (body.length > 250 ? '${body.substring(0, 250)}...' : body)
                        : """• Local Diyanet & AlAdhan timing engine active
• 4 native home screen widgets synchronized
• Battery-efficient offline timetable loaded
• GitHub: liondepierre/Minar""",
                    style: const TextStyle(
                      color: MinarTheme.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              actions: [
                if (isNewer && apkUrl != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openUrl(apkUrl!);
                    },
                    style: TextButton.styleFrom(foregroundColor: MinarTheme.goldWarm),
                    child: const Text('Download APK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (isNewer) {
                      _openUrl(releaseUrl);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isNewer ? MinarTheme.textSecondary : MinarTheme.goldWarm,
                  ),
                  child: Text(isNewer ? 'Later' : 'OK', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      } else {
        _showUpdateErrorDialog(context, 'GitHub API returned status ${res.statusCode}');
      }
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
      _showUpdateErrorDialog(context, 'Could not reach GitHub. Check your internet connection.');
    }
  }
}
