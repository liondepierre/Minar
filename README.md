<div align="center">

# Minar (مَنَارَة)
### Fast, Privacy-Focused Islamic Prayer Times & Native Widgets

**Minar** is a lightweight, ad-free, battery-optimized Islamic prayer times app available for **Android**, **iOS**, and **macOS Menu Bar**. Features precise astronomical calculations, official Diyanet timetables, live countdowns, persistent notification shade timetables, and four highly customizable native home screen widgets.

<br/>

[![GitHub Release](https://img.shields.io/github/v/release/liondepierre/Minar?color=4ADE80&logo=github&style=flat-square)](https://github.com/liondepierre/Minar/releases)
[![Platform](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS-E8C582?style=flat-square)](#platforms)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Zero Battery Drain](https://img.shields.io/badge/battery-0%25%20wakeups-emerald?style=flat-square)](#battery--performance)
[![Privacy](https://img.shields.io/badge/privacy-100%25%20offline-60A5FA?style=flat-square)](#privacy)

<br/>

</div>

---

## 📱 Minar Mobile (Android & iOS)

Built with Flutter and high-performance native Android AppWidget providers.

### Key Highlights
- **4 Native Home Screen Widgets**:
  - **2x2 Next Prayer Card**: Large clock display, dynamic live countdown pill, NEXT/Tomorrow badge, and Hijri calendar date.
  - **2x3 Panoramic Timetable**: Clean 6-cell grid with active prayer highlight that perfectly adapts to all launcher sizes.
  - **Vertical Timetable List**: Clean daily prayer schedule with Turkish names and Arabic script (`الفجر`, `الشروق`, `الظهر`, `العصر`, `المغرب`, `العشاء`).
  - **Minimal Bar Strip**: Compact single-row widget designed for minimal home screen layouts.
- **Widget Customization**:
  - **Themes**: *Midnight*, *AMOLED Black*, *Glass Frost*, and *Transparent*.
  - **Accent Colors**: *Gold Warm*, *Emerald*, *Pure White*, and *Sky Blue*.
  - **Font Size Scaling**: Standard, Large (+15%), and X-Large (+30%) with proportional auto-sizing.
  - **Header Toggle**: Choose to show or hide the city name and Hijri date header bar.
- **Pinned Notification Shade**:
  - Persistent, non-intrusive timetable in your Android notification shade.
  - Zero background battery drain (rendered as cached bitmaps, 0% CPU wakeups).
  - 3 customizable rendering styles: *Table View*, *Compact Cards*, and *Minimal Strip*.
- **Full App Theming**:
  - 4 app background themes (*Midnight*, *AMOLED Black*, *Emerald Night*, *Royal Navy*).
  - 5 vibrant accents (*Gold*, *Emerald*, *White*, *Sky Blue*, *Rose*).
- **Intelligent Timetable**:
  - Automatic transition to Tomorrow's Fajr schedule after Isha passes.
  - Horizontal day swiping to preview upcoming prayer times.
  - Offline timetable cache for uninterrupted access without network.

---

## 🖥️ Minar for macOS (Menu Bar)

A native Swift menu bar application for macOS.
- **Glanceable Countdown**: Shows remaining time to next prayer directly in the macOS menu bar.
- **Dropdown Schedule**: Click the 🕌 icon to see the full day's times and tomorrow's transition.
- **Native & Lightweight**: Consumes only ~20 MB RAM and 0.0% CPU between minute ticks.
- **Launch at Login**: Starts automatically on boot.

---

## 🕌 Calculation Methods

| Method | Region & Accuracy |
|---|---|
| **Diyanet (Türkiye)** *(Default)* | Türkiye, Balkans, Denmark, Germany, and throughout Europe |
| **Muslim World League** | United Kingdom, Western Europe, Far East |
| **ISNA** | North America (USA & Canada) |
| **Umm Al-Qura (Makkah)** | Saudi Arabia, Gulf Countries |
| **Egyptian General Authority** | Egypt, North Africa, Middle East |

*Diyanet timings are fetched from official calendars; astronomical calculations use AlAdhan APIs and local offline astronomical algorithms.*

---

## 📦 Installation & Download

### Android
Download the latest APK release from the [GitHub Releases](https://github.com/liondepierre/Minar/releases) page:
1. Download **`Minar-v1.1.0-android.apk`**.
2. Tap the downloaded file to install on your Android device (enable "Install unknown apps" if prompted).
3. Long-press your home screen to add any of the 4 Minar widgets.

### macOS
1. Download **`Minar.dmg`** from [Releases](https://github.com/liondepierre/Minar/releases).
2. Drag **`Minar`** into your **Applications** folder.
3. Launch Minar from Applications or Spotlight.

---

## 🔒 Privacy & Battery Guarantee

- **No tracking, no analytics, no ads, no accounts**: We don't want your data. Everything is calculated and stored locally on your device.
- **Coarse Location**: Respects battery saver mode. Only requests low-power Wi-Fi/Cell network location fixes without continuous GPS tracking.
- **Battery-First Architecture**: Zero background polling loops. Scheduled exact alarms wake the phone only at prayer boundaries to update widgets and notifications.

---

## 🛠️ Building from Source

### Mobile App (Flutter)
```bash
git clone https://github.com/liondepierre/Minar.git
cd Minar/apps/mobile
flutter pub get
flutter test
flutter build apk --release
```

### macOS Menu Bar (Swift)
```bash
cd Minar/apps/macos-menubar
swift build -c release
./scripts/bundle.sh
```

---

## 📂 Repository Layout

```
Minar/
├── apps/
│   ├── mobile/             # Flutter mobile app (Android & iOS)
│   │   ├── android/        # Native Kotlin AppWidget providers & notification services
│   │   ├── lib/            # Flutter UI, controllers, and offline timetable models
│   │   └── test/           # Unit and logic tests
│   └── macos-menubar/      # Native Swift macOS menu bar application
└── README.md
```

---

## 📄 License

Open-source and available under the [MIT License](LICENSE).
