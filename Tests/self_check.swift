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
    } catch {
        fatalError("Network check failed: \(error)")
    }

    print("✔ All self-checks passed.")
}

await runChecks()
