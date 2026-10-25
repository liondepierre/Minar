import Foundation

public enum CalculationMethod: Int, CaseIterable, Identifiable, Codable {
    case diyanet = 13 // Diyanet İşleri Başkanlığı (Turkey) - Default
    case mwl = 3      // Muslim World League
    case isna = 2     // Islamic Society of North America
    case makkah = 4   // Umm Al-Qura University, Makkah
    case egypt = 5    // Egyptian General Authority of Survey

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .diyanet: return "Diyanet (Turkey)"
        case .mwl: return "Muslim World League"
        case .isna: return "ISNA (North America)"
        case .makkah: return "Umm Al-Qura (Makkah)"
        case .egypt: return "Egyptian Authority"
        }
    }
}

public enum PrayerNamingStyle: String, CaseIterable, Identifiable, Codable {
    case turkish = "turkish"
    case arabic = "arabic"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .turkish: return "Turkish (İmsak, Öğle...)"
        case .arabic: return "Arabic / Latin (Fajr, Dhuhr...)"
        }
    }
}

public enum Prayer: String, CaseIterable, Identifiable, Codable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    public var id: String { rawValue }

    public var turkishName: String {
        switch self {
        case .fajr: return "İmsak"
        case .sunrise: return "Güneş"
        case .dhuhr: return "Öğle"
        case .asr: return "İkindi"
        case .maghrib: return "Akşam"
        case .isha: return "Yatsı"
        }
    }

    public var arabicScript: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    public func displayName(style: PrayerNamingStyle) -> String {
        switch style {
        case .turkish: return turkishName
        case .arabic: return rawValue
        }
    }
}

public struct PrayerItem: Identifiable, Codable {
    public var id: String { prayer.rawValue }
    public let prayer: Prayer
    public let time: String // "04:57"
    public let date: Date
}

public struct PrayerSchedule: Codable {
    public let city: String
    public let country: String
    public let method: CalculationMethod
    public let hijriDate: String
    public let gregorianDate: String
    public let items: [PrayerItem]
    public let tomorrowFajr: PrayerItem?

    public init(
        city: String,
        country: String,
        method: CalculationMethod,
        hijriDate: String,
        gregorianDate: String,
        items: [PrayerItem],
        tomorrowFajr: PrayerItem? = nil
    ) {
        self.city = city
        self.country = country
        self.method = method
        self.hijriDate = hijriDate
        self.gregorianDate = gregorianDate
        self.items = items
        self.tomorrowFajr = tomorrowFajr
    }

    public func nextPrayer(at now: Date = Date()) -> (item: PrayerItem, remainingMinutes: Int)? {
        for item in items {
            if item.date > now {
                let diff = max(0, Int(item.date.timeIntervalSince(now) / 60))
                return (item, diff)
            }
        }
        // Past Isha: next is tomorrow's Fajr
        if let tomorrow = tomorrowFajr {
            let diff = max(0, Int(tomorrow.date.timeIntervalSince(now) / 60))
            return (tomorrow, diff)
        }
        // Fallback if tomorrow not available
        if let first = items.first(where: { $0.prayer == .fajr }) {
            let tomorrowFajrDate = Calendar.current.date(byAdding: .day, value: 1, to: first.date) ?? first.date
            let diff = max(0, Int(tomorrowFajrDate.timeIntervalSince(now) / 60))
            return (PrayerItem(prayer: .fajr, time: first.time, date: tomorrowFajrDate), diff)
        }
        return nil
    }
}
