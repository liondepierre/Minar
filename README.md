# Minar — Prayer Times for macOS Menu Bar

**Minar** is a lightweight, battery-optimised macOS menu bar app that shows Islamic prayer times (Salah times) with a live countdown — always visible, never in your way.

> Built for Muslims who use a Mac and want accurate prayer times without opening a browser or a heavy app.

---

## Features

- **Live countdown** to the next prayer, updated every minute
- **Six daily prayers** — Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
- **Turkish names** (İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı) alongside Arabic transliterations
- **Diyanet-official times** by default — fetched directly from the Turkish Directorate of Religious Affairs API for maximum accuracy
- **Fallback calculation methods** — Muslim World League, ISNA, Umm Al-Qura (Makkah), Egyptian Authority
- **Any city, any country** — change location at any time from the menu
- **Launch at Login** toggle built in
- **Battery-first design** — one network request per day, one CPU wake per minute, menu rebuilt only on prayer transitions (~6×/day)
- **No account, no tracking, no ads** — fully offline after daily fetch

---

## Requirements

| | |
|---|---|
| **macOS** | 13 Ventura or later |
| **Architecture** | Apple Silicon (arm64) + Intel (x86_64) universal |

---

## Installation

### Option A — Download the pre-built app

1. Download **`Minar.zip`** from the [Releases](../../releases) page.
2. Unzip and move **`Minar.app`** to your `/Applications` folder.
3. Double-click to open. If macOS blocks it: **System Settings → Privacy & Security → Open Anyway**.
4. The 🕌 icon appears in your menu bar immediately.

> **Tip:** First launch will ask for the city and country. Type any city name (e.g. `Tokyo`, `London`, `Istanbul`).

### Option B — Build from source

```bash
git clone https://github.com/yourusername/minar.git
cd minar
swift build -c release
# Or build a signed universal .app bundle:
./scripts/bundle.sh
open build/Minar.app
```

Requires Xcode Command Line Tools (`xcode-select --install`).

---

## Usage

| Action | How |
|---|---|
| See next prayer & countdown | Glance at the menu bar |
| See all today's times | Click the 🕌 icon |
| Change city / country | Menu → **Change City / Country...** |
| Change calculation method | Menu → **Calculation Method** |
| Force refresh | Menu → **Refresh Now** |
| Enable launch at login | Menu → **Launch at Login** (tick to enable) |
| Quit | Menu → **Quit Minar** or ⌘Q |

---

## Calculation Methods

| Method | Best For |
|---|---|
| **Diyanet (Turkey)** *(default)* | Turkey, Balkans, Denmark, Germany, most of Europe |
| Muslim World League | UK, Europe, Far East |
| ISNA | North America |
| Umm Al-Qura (Makkah) | Saudi Arabia, Gulf |
| Egyptian Authority | Egypt, North Africa |

Diyanet times are fetched directly from the official published calendar at **ezanvakti.imsakiyem.com**. All other methods use the **AlAdhan** astronomical API.

---

## Privacy

- **No data is collected.** Ever.
- Your city and country are stored **locally** in `UserDefaults` on your own Mac.
- The app makes **one outbound network request per day** to fetch prayer times for your chosen city. No other network activity.
- No analytics, no crash reporting, no third-party SDKs.

---

## Battery & Performance

Minar is intentionally minimal:

- **1 network request / day** — prayer times don't change intra-day
- **1 CPU wake / minute** — aligned to the clock boundary, updates the countdown string
- **~6 menu rebuilds / day** — only when the active prayer transitions
- **~20–30 MB RAM** — static, does not grow over time
- CPU usage in Activity Monitor: `0.0%` between ticks

---

## Building & Distributing

```bash
# Debug build
swift build

# Universal release + signed .app + .zip
./scripts/bundle.sh
# Output: build/Minar.app  build/Minar.zip
```

The bundle script signs with an ad-hoc certificate (`-s -`). For App Store or Gatekeeper-notarised distribution, replace with a Developer ID certificate.

---

## Project Structure

```
Minar/
├── Sources/Minar/
│   ├── Minar.swift          # App delegate, menu bar UI, smart timer
│   ├── PrayerService.swift  # Network fetching, caching, DTOs
│   └── PrayerModel.swift    # Data types: Prayer, PrayerSchedule, CalculationMethod
├── Tests/
│   └── self_check.swift     # Live integration check (run with: swift Tests/self_check.swift)
├── Resources/
│   └── AppIcon.icns
├── scripts/
│   ├── bundle.sh            # Universal .app builder & signer
│   └── generate_icon.swift  # Icon generation utility
└── Package.swift
```

---

## Contributing

PRs welcome. Keep it lean — this app exists to do one thing well.
Before opening a PR, run:
```bash
swift Tests/self_check.swift
swift build
```

---

## About

**Minar** (مَنَارَة) — from the Arabic for *minaret*, the tower from which the call to prayer is made. A fitting name for an app that lives at the top of your screen and marks the hours of prayer.

Designed and built for personal use, then open-sourced so others can benefit.

No AI will maintain this in the morning — the code is written to be read and modified by a human developer without assistance.

---

*— YMA*
