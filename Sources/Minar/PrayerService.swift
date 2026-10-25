import Foundation

public final class PrayerService: @unchecked Sendable {
    public static let shared = PrayerService()
    private let cacheKey = "cached_prayer_schedule_json"

    // shortcut: parses 24h "HH:mm" against today's calendar
    private func parseTime(_ timeStr: String, today: Date, calendar: Calendar = .current) -> Date {
        let parts = timeStr.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return today }
        var comp = calendar.dateComponents([.year, .month, .day], from: today)
        comp.hour = h
        comp.minute = m
        comp.second = 0
        return calendar.date(from: comp) ?? today
    }

    public func fetchTimings(city: String, country: String, method: CalculationMethod) async throws -> PrayerSchedule {
        // Diyanet: fetch official published calendar directly (e.g. Ikast Yatsı: 18:51)
        if method == .diyanet {
            if let official = try? await fetchOfficialDiyanet(city: city, country: country) {
                cache(official)
                return official
            }
        }

        // Fallback or other methods: AlAdhan astronomical API
        let schedule = try await fetchAlAdhan(city: city, country: country, method: method)
        cache(schedule)
        return schedule
    }

    private let cityAliases: [String: String] = [
        "copenhagen": "kopenhag",
        "københavn": "kopenhag",
        "vienna": "viyana",
        "rome": "roma",
        "cologne": "koln",
        "munich": "munih",
        "athens": "atina",
        "damascus": "sam",
        "jerusalem": "kudus",
        "geneva": "cenevre",
        "zurich": "zurih",
        "warsaw": "varsova",
        "prague": "prag",
        "moscow": "moskova",
        "brussels": "bruksel",
        "baghdad": "bagdat",
        "beirut": "beyrut",
        "cairo": "kahire",
        "mecca": "mekke",
        "makkah": "mekke",
        "medina": "medine"
    ]

    private func fetchOfficialDiyanet(city: String, country: String) async throws -> PrayerSchedule? {
        let cleanCity = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let resolvedCity = cityAliases[cleanCity] ?? cleanCity
        guard let encodedCity = resolvedCity.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchUrl = URL(string: "https://ezanvakti.imsakiyem.com/api/locations/search/districts?q=\(encodedCity)") else {
            return nil
        }

        let (searchData, _) = try await URLSession.shared.data(from: searchUrl)
        let search = try JSONDecoder().decode(DistrictSearchResponse.self, from: searchData)
        guard let district = search.data.first else { return nil }

        guard let timesUrl = URL(string: "https://ezanvakti.imsakiyem.com/api/prayer-times/\(district._id)") else {
            return nil
        }

        let (timesData, _) = try await URLSession.shared.data(from: timesUrl)
        let res = try JSONDecoder().decode(DiyanetTimesResponse.self, from: timesData)

        let now = Date()
        let dfToday = DateFormatter()
        dfToday.dateFormat = "yyyy-MM-dd"
        let todayStr = dfToday.string(from: now)

        guard let day = res.data.first(where: { $0.date.hasPrefix(todayStr) }) ?? res.data.first else { return nil }
        let t = day.times
        let mapping: [(Prayer, String)] = [
            (.fajr, t.imsak),
            (.sunrise, t.gunes),
            (.dhuhr, t.ogle),
            (.asr, t.ikindi),
            (.maghrib, t.aksam),
            (.isha, t.yatsi)
        ]

        let items = mapping.map { prayer, timeStr in
            PrayerItem(prayer: prayer, time: timeStr, date: parseTime(timeStr, today: now))
        }

        // Exact tomorrow's Fajr from the same monthly response (zero extra network calls)
        var tomorrowFajrItem: PrayerItem? = nil
        let calendar = Calendar.current
        if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) {
            let tomorrowStr = dfToday.string(from: tomorrowDate)
            if let tomorrowDay = res.data.first(where: { $0.date.hasPrefix(tomorrowStr) }) {
                let tTime = tomorrowDay.times.imsak
                let tDate = parseTime(tTime, today: tomorrowDate, calendar: calendar)
                tomorrowFajrItem = PrayerItem(prayer: .fajr, time: tTime, date: tDate)
            }
        }

        let df = DateFormatter()
        df.dateStyle = .medium
        let gregorian = df.string(from: now)

        return PrayerSchedule(
            city: district.name.capitalized,
            country: country,
            method: .diyanet,
            hijriDate: "\(day.hijri_date.full_date) AH",
            gregorianDate: gregorian,
            items: items,
            tomorrowFajr: tomorrowFajrItem
        )
    }

    private func fetchAlAdhan(city: String, country: String, method: CalculationMethod) async throws -> PrayerSchedule {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedCountry = country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.aladhan.com/v1/timingsByCity?city=\(encodedCity)&country=\(encodedCountry)&method=\(method.rawValue)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let root = try JSONDecoder().decode(AlAdhanResponse.self, from: data)
        let now = Date()
        let timings = root.data.timings

        var items: [PrayerItem] = []
        for prayer in Prayer.allCases {
            if let timeString = timings[prayer.rawValue] {
                let prayerDate = parseTime(timeString, today: now)
                items.append(PrayerItem(prayer: prayer, time: timeString, date: prayerDate))
            }
        }

        let hijri = "\(root.data.date.hijri.day) \(root.data.date.hijri.month.en) \(root.data.date.hijri.year) AH"
        return PrayerSchedule(
            city: city,
            country: country,
            method: method,
            hijriDate: hijri,
            gregorianDate: root.data.date.readable,
            items: items
        )
    }

    private func cache(_ schedule: PrayerSchedule) {
        if let encoded = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    public func cachedSchedule() -> PrayerSchedule? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(PrayerSchedule.self, from: data)
    }
}

// Diyanet Official DTOs
private struct DistrictSearchResponse: Codable {
    let success: Bool
    let data: [DistrictItem]
}

private struct DistrictItem: Codable {
    let _id: String
    let name: String
    let name_en: String?
}

private struct DiyanetTimesResponse: Codable {
    let success: Bool
    let data: [DiyanetDayData]
}

private struct DiyanetDayData: Codable {
    let date: String
    let times: DiyanetTimes
    let hijri_date: DiyanetHijri
}

private struct DiyanetTimes: Codable {
    let imsak: String
    let gunes: String
    let ogle: String
    let ikindi: String
    let aksam: String
    let yatsi: String
}

private struct DiyanetHijri: Codable {
    let full_date: String
}

// AlAdhan Raw DTOs
private struct AlAdhanResponse: Codable {
    let data: AlAdhanData
}

private struct AlAdhanData: Codable {
    let timings: [String: String]
    let date: AlAdhanDate
}

private struct AlAdhanDate: Codable {
    let readable: String
    let hijri: AlAdhanHijri
}

private struct AlAdhanHijri: Codable {
    let day: String
    let year: String
    let month: AlAdhanHijriMonth
}

private struct AlAdhanHijriMonth: Codable {
    let en: String
}
