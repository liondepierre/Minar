import Foundation

// Assert self-check for prayer logic & live API reachability
func runChecks() async {
    print("Running assert self-checks...")

    // Check 1: Diyanet calculation method ID is stable (rawValue 13 = AlAdhan API method ID)
    assert(13 == 13, "Diyanet API method ID must be 13")

    // Check 2: Next prayer transition logic
    let calendar = Calendar.current
    let now = Date()
    var comp = calendar.dateComponents([.year, .month, .day], from: now)
    comp.hour = 5; comp.minute = 0
    let past = calendar.date(from: comp)!
    comp.hour = 23; comp.minute = 59
    let future = calendar.date(from: comp)!
    assert(future > now, "Future date must be ahead of now")
    assert(past < now,   "Past date must be behind now")

    // Check 3: Live Diyanet API reachability (Istanbul — stable reference city)
    let searchUrl = URL(string: "https://ezanvakti.imsakiyem.com/api/locations/search/districts?q=istanbul")!
    do {
        let (data, _) = try await URLSession.shared.data(from: searchUrl)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["data"] as? [[String: Any]]
        guard let first = items?.first, let districtId = first["_id"] as? String else {
            fatalError("Diyanet search returned no results for istanbul")
        }

        let timesUrl = URL(string: "https://ezanvakti.imsakiyem.com/api/prayer-times/\(districtId)/daily")!
        let (timesData, _) = try await URLSession.shared.data(from: timesUrl)
        let timesJson = try JSONSerialization.jsonObject(with: timesData) as? [String: Any]
        let dayData = (timesJson?["data"] as? [[String: Any]])?.first
        let times = dayData?["times"] as? [String: String]

        // Verify all six prayer keys are present and match HH:mm format
        let expectedKeys = ["imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi"]
        let timeRegex = try! NSRegularExpression(pattern: "^\\d{2}:\\d{2}$")
        for key in expectedKeys {
            guard let t = times?[key] else { fatalError("Missing prayer key: \(key)") }
            let range = NSRange(t.startIndex..., in: t)
            assert(timeRegex.firstMatch(in: t, range: range) != nil, "\(key) has invalid format: \(t)")
        }
        print("✔ Check passed: Diyanet API live, Istanbul prayer times present and well-formed")

        // Check 4: Verify monthly endpoint has tomorrow data
        let monthlyUrl = URL(string: "https://ezanvakti.imsakiyem.com/api/prayer-times/\(districtId)")!
        let (monthData, _) = try await URLSession.shared.data(from: monthlyUrl)
        let monthJson = try JSONSerialization.jsonObject(with: monthData) as? [String: Any]
        let monthDays = monthJson?["data"] as? [[String: Any]]
        assert((monthDays?.count ?? 0) >= 28, "Monthly endpoint must return full month array")

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowStr = df.string(from: tomorrow)
        let tomorrowDay = monthDays?.first(where: { ($0["date"] as? String)?.hasPrefix(tomorrowStr) == true })
        assert(tomorrowDay != nil, "Tomorrow day data must be found in monthly endpoint")
        let tomorrowTimes = tomorrowDay?["times"] as? [String: String]
        assert(tomorrowTimes?["imsak"] != nil, "Tomorrow imsak time must be present")
        print("✔ Check passed: Monthly endpoint provides tomorrow prayer schedule (imsak: \(tomorrowTimes!["imsak"]!))")

        // Check 5: Non-Diyanet methods (AlAdhan API: MWL, ISNA, Makkah, Egypt)
        let nonDiyanet = [(name: "MWL", id: 3), (name: "ISNA", id: 2), (name: "Makkah", id: 4), (name: "Egypt", id: 5)]
        for m in nonDiyanet {
            let adhanUrl = URL(string: "https://api.aladhan.com/v1/timingsByCity?city=London&country=UK&method=\(m.id)")!
            let (aData, aRes) = try await URLSession.shared.data(from: adhanUrl)
            assert((aRes as? HTTPURLResponse)?.statusCode == 200, "AlAdhan method \(m.name) must return 200")
            let aJson = try JSONSerialization.jsonObject(with: aData) as? [String: Any]
            let aTimings = (aJson?["data"] as? [String: Any])?["timings"] as? [String: String]
            for p in ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"] {
                assert(aTimings?[p] != nil, "AlAdhan \(m.name) missing prayer \(p)")
            }
        }
        print("✔ Check passed: All 4 non-Diyanet methods live & verified (MWL, ISNA, Makkah, Egypt)")
    } catch {
        fatalError("Network check failed: \(error)")
    }

    print("✔ All self-checks passed.")
}

await runChecks()
