import XCTest
@testable import Minar

final class MinarTests: XCTestCase {
    func testDiyanetDefaultMethod() {
        XCTAssertEqual(CalculationMethod.diyanet.id, 13)
        XCTAssertTrue(CalculationMethod.diyanet.title.contains("Diyanet"))
    }

    func testNextPrayerCalculation() {
        let calendar = Calendar.current
        let now = Date()
        var comp = calendar.dateComponents([.year, .month, .day], from: now)

        comp.hour = 5
        comp.minute = 0
        let pastDate = calendar.date(from: comp)!

        comp.hour = 23
        comp.minute = 59
        let futureDate = calendar.date(from: comp)!

        let items = [
            PrayerItem(prayer: .fajr, time: "05:00", date: pastDate),
            PrayerItem(prayer: .isha, time: "23:59", date: futureDate)
        ]

        let schedule = PrayerSchedule(
            city: "Ikast",
            country: "Denmark",
            method: .diyanet,
            hijriDate: "14-05-1448",
            gregorianDate: "25 Oct 2026",
            items: items
        )

        let next = schedule.nextPrayer(at: now)
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.item.prayer, .isha)
    }
}
