# Minar Mobile (Flutter)

> **Pure, distraction-free Islamic prayer times for Android & iOS.**
> Zero ads, zero bloat, battery-first, and 100% Diyanet-accurate.

---

## Principles

1. **No Ads, Ever**: No banners, no interstitial popups, no tracking SDKs.
2. **Timeless Dignified Aesthetic**: Deep twilight midnight gradient (`#0D1B2A` → `#050B14`), warm champagne gold highlights (`#FFDE99`), and clean typography.
3. **Diyanet Accuracy**: Uses pre-computed official Diyanet tables directly (`ezanvakti.imsakiyem.com`) to prevent high-latitude angle drift. Fallback to AlAdhan for MWL, ISNA, Makkah, and Egypt.
4. **Offline First**: Caches schedules locally in `SharedPreferences`. Works completely without internet after sync.
5. **Battery Respect**: Only ticks a lightweight 1s/30s timer in the foreground. Notifications are scheduled via native alarms, requiring zero background RAM consumption.

---

## Project Structure

```
minar_mobile/
├── lib/
│   ├── main.dart                  # App entry point & system UI theming
│   ├── models/
│   │   ├── calculation_method.dart# Diyanet, MWL, ISNA, Makkah, Egypt
│   │   ├── prayer_schedule.dart   # Schedule, Item, and NextPrayer models
│   │   └── prayer_type.dart       # Turkish & Arabic transliterations
│   ├── services/
│   │   ├── diyanet_service.dart   # Diyanet official API integration
│   │   ├── aladhan_service.dart   # AlAdhan astronomical API fallback
│   │   ├── storage_service.dart   # SharedPreferences offline persistence
│   │   └── notification_service.dart # Local prayer alerts
│   ├── state/
│   │   └── prayer_controller.dart # Reactive store (ChangeNotifier)
│   └── ui/
│       ├── theme.dart             # Minar Midnight & Gold design system
│       ├── screens/
│       │   └── home_screen.dart   # Hero countdown & prayer table
│       └── widgets/
│           ├── countdown_card.dart# Hero countdown card with live seconds
│           ├── prayer_tile.dart   # Daily prayer row with active highlight
│           └── settings_sheet.dart# Location, Method, & Language sheet
├── assets/
│   └── icon/                      # Minar Master App Icon (2048x2048)
└── scripts/
    ├── generate_icons.sh          # Slices icon into Android & iOS folders
    └── self_check.dart            # Standalone logic & API validation
```

---

## Getting Started

### 1. Install Flutter (if not yet installed)
```bash
brew install --cask flutter
flutter doctor
```

### 2. Install Dependencies
```bash
cd /Users/yma/dev/minar_mobile
flutter pub get
```

### 3. Run on Android or iOS
* **Android (Device or Emulator):**
  ```bash
  flutter run
  ```
* **iOS Simulator:**
  ```bash
  open -a Simulator
  flutter run
  ```

---

## Building for the Google Play Store

When you are ready to upload to your Android Developer Account:

1. **Build App Bundle (AAB):**
   ```bash
   flutter build appbundle --release
   ```
   The production bundle will be generated at:
   `build/app/outputs/bundle/release/app-release.aab`

2. **Build Standalone APK (for testing or direct transfer):**
   ```bash
   flutter build apk --release
   ```
   The output APK will be at:
   `build/app/outputs/flutter-apk/app-release.apk`
