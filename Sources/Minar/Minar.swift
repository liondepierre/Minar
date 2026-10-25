import AppKit
import Foundation
import ServiceManagement

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var displayTimer: Timer?
    private let appVersion = "1.0.4"

    private var city: String {
        get { UserDefaults.standard.string(forKey: "minar_city") ?? UserDefaults.standard.string(forKey: "adhan_city") ?? "Tokyo" }
        set { UserDefaults.standard.set(newValue, forKey: "minar_city") }
    }

    private var country: String {
        get { UserDefaults.standard.string(forKey: "minar_country") ?? UserDefaults.standard.string(forKey: "adhan_country") ?? "Japan" }
        set { UserDefaults.standard.set(newValue, forKey: "minar_country") }
    }

    private var method: CalculationMethod {
        get {
            let saved = UserDefaults.standard.object(forKey: "minar_method") != nil
                ? UserDefaults.standard.integer(forKey: "minar_method")
                : UserDefaults.standard.integer(forKey: "adhan_method")
            return CalculationMethod(rawValue: saved) ?? .diyanet
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "minar_method")
        }
    }

    private var namingStyle: PrayerNamingStyle {
        get {
            let saved = UserDefaults.standard.string(forKey: "minar_naming_style") ?? "turkish"
            return PrayerNamingStyle(rawValue: saved) ?? .turkish
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "minar_naming_style")
        }
    }

    private var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }

    private var currentSchedule: PrayerSchedule?
    private var lastFetchDay: Int = -1 // calendar day of last successful fetch
    /// Which prayer is currently shown as "next" — used to avoid rebuilding the menu when only the countdown changes.
    private var lastHighlightedPrayer: Prayer?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Menu bar only, no dock icon
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🕌 Minar..."

        if let cached = PrayerService.shared.cachedSchedule() {
            self.currentSchedule = cached
            self.updateStatusBarText()
            self.rebuildMenu()
        }

        fetchTimings()
        scheduleNextTick()
    }

    // MARK: - Smart Timer

    /// Schedule the next display update at the top of the next minute.
    /// The countdown shows whole minutes, so updating more often wastes cycles.
    private func scheduleNextTick() {
        displayTimer?.invalidate()
        // Align to the next whole minute boundary so the countdown flips cleanly
        let now = Date()
        let secondsIntoMinute = Calendar.current.component(.second, from: now)
        let delay = TimeInterval(60 - secondsIntoMinute)
        displayTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        updateStatusBarText()
        // Re-fetch once per calendar day (prayer times don't change intra-day)
        fetchIfNewDay()
        scheduleNextTick()
    }

    /// Fetch from the network only when the calendar day has changed since the last fetch.
    private func fetchIfNewDay() {
        let today = Calendar.current.component(.day, from: Date())
        guard today != lastFetchDay else { return }
        fetchTimings()
    }

    // MARK: - Network

    private func fetchTimings() {
        Task { [weak self] in
            guard let self = self else { return }
            let targetCity = self.city
            let targetCountry = self.country
            let targetMethod = self.method
            do {
                let schedule = try await PrayerService.shared.fetchTimings(
                    city: targetCity,
                    country: targetCountry,
                    method: targetMethod
                )
                self.currentSchedule = schedule
                self.lastFetchDay = Calendar.current.component(.day, from: Date())
                self.lastHighlightedPrayer = nil // force menu rebuild
                self.updateStatusBarText()
                self.rebuildMenu()
            } catch {
                self.statusItem.button?.title = "🕌 [Offline]"
            }
        }
    }

    // MARK: - UI Updates

    /// Update only the status bar title text (cheap string assignment).
    private func updateStatusBarText() {
        guard let schedule = currentSchedule else {
            statusItem.button?.title = "🕌 Loading..."
            return
        }

        let next = schedule.nextPrayer()
        if let next = next {
            let h = next.remainingMinutes / 60
            let m = next.remainingMinutes % 60
            let timeRemaining = h > 0 ? "\(h)h \(m)m" : "\(m)m"
            statusItem.button?.title = "🕌 \(next.item.prayer.displayName(style: namingStyle)) \(next.item.time) (\(timeRemaining))"

            // Rebuild the menu only when the highlighted prayer changes (e.g. Dhuhr → Asr)
            if next.item.prayer != lastHighlightedPrayer {
                lastHighlightedPrayer = next.item.prayer
                rebuildMenu()
            }
        } else {
            statusItem.button?.title = "🕌 Minar"
        }
    }

    private func rebuildMenu() {
        guard let schedule = currentSchedule else { return }
        let nextItem = schedule.nextPrayer()?.item
        let menu = NSMenu()

        // Header: Location & Dates
        let locItem = NSMenuItem(title: "📍 \(schedule.city), \(schedule.country)", action: nil, keyEquivalent: "")
        locItem.isEnabled = false
        menu.addItem(locItem)

        let dateItem = NSMenuItem(title: "📅 \(schedule.gregorianDate)  •  \(schedule.hijriDate)", action: nil, keyEquivalent: "")
        dateItem.isEnabled = false
        menu.addItem(dateItem)

        menu.addItem(NSMenuItem.separator())

        // Prayer Times List
        let now = Date()
        let isPastIsha = schedule.items.allSatisfy { $0.date <= now }
        for item in schedule.items {
            let isNext = (nextItem?.prayer == item.prayer)
            let prefix = isNext ? "👉 " : "    "
            let indicator = isNext ? (isPastIsha ? " (Tomorrow)" : " (Next)") : ""
            let displayTime = (isNext && isPastIsha && schedule.tomorrowFajr != nil) ? schedule.tomorrowFajr!.time : item.time

            let primary = item.prayer.displayName(style: namingStyle)
            let secondary = (namingStyle == .turkish) ? item.prayer.rawValue : item.prayer.arabicScript
            let title = String(format: "%@%-7@ (%-7@)  %@%@", prefix, primary, secondary, displayTime, indicator)

            let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            if isNext {
                let attrTitle = NSMutableAttributedString(string: title)
                attrTitle.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: NSRange(location: 0, length: title.count))
                menuItem.attributedTitle = attrTitle
            }
            menu.addItem(menuItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Calculation Method Submenu
        let methodMenu = NSMenu()
        for m in CalculationMethod.allCases {
            let mItem = NSMenuItem(title: m.title, action: #selector(didSelectMethod(_:)), keyEquivalent: "")
            mItem.target = self
            mItem.representedObject = m
            mItem.state = (m == self.method) ? .on : .off
            methodMenu.addItem(mItem)
        }
        let methodParent = NSMenuItem(title: "Calculation Method", action: nil, keyEquivalent: "")
        methodParent.submenu = methodMenu
        menu.addItem(methodParent)

        // Prayer Names Submenu
        let namesMenu = NSMenu()
        for style in PrayerNamingStyle.allCases {
            let nItem = NSMenuItem(title: style.title, action: #selector(didSelectNamingStyle(_:)), keyEquivalent: "")
            nItem.target = self
            nItem.representedObject = style
            nItem.state = (style == self.namingStyle) ? .on : .off
            namesMenu.addItem(nItem)
        }
        let namesParent = NSMenuItem(title: "Prayer Names", action: nil, keyEquivalent: "")
        namesParent.submenu = namesMenu
        menu.addItem(namesParent)

        // Change Location Item
        let changeLocItem = NSMenuItem(title: "Change City / Country...", action: #selector(didSelectChangeLocation), keyEquivalent: "l")
        changeLocItem.target = self
        menu.addItem(changeLocItem)

        // Refresh Now
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(didSelectRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        // Launch at Login toggle
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(didToggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = launchAtLogin ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        // Check for Updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(didSelectCheckForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        // About Minar
        let aboutItem = NSMenuItem(title: "About Minar...", action: #selector(didSelectAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit Minar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func didSelectAbout() {
        let alert = NSAlert()
        alert.messageText = "Minar (مَنَارَة) — v\(appVersion)"
        alert.informativeText = "Lightweight, battery-friendly macOS menu bar app for Islamic prayer times.\n\nPure native Swift, zero tracking, authentic calculation sources.\n\nCreated by YMA."
        alert.alertStyle = .informational
        if let icon = NSImage(named: "AppIcon") {
            alert.icon = icon
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func didSelectCheckForUpdates() {
        Task { [weak self] in
            guard let self = self else { return }
            let url = URL(string: "https://api.github.com/repos/liondepierre/Minar/releases/latest")!
            var req = URLRequest(url: url)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            req.setValue("Minar-macOS", forHTTPHeaderField: "User-Agent")

            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    self.showUpdateAlert(title: "Unable to Check for Updates", message: "Could not reach GitHub Releases. Please check your network.", downloadURL: nil)
                    return
                }
                struct GHRelease: Codable {
                    let tag_name: String
                    let html_url: String
                }
                let release = try JSONDecoder().decode(GHRelease.self, from: data)
                let latestTag = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                if latestTag.compare(self.appVersion, options: .numeric) == .orderedDescending {
                    self.showUpdateAlert(
                        title: "Update Available!",
                        message: "A new version of Minar (v\(latestTag)) is available. You are running v\(self.appVersion).",
                        downloadURL: URL(string: release.html_url)
                    )
                } else {
                    self.showUpdateAlert(
                        title: "You're Up to Date",
                        message: "Minar v\(self.appVersion) is currently the newest version available.",
                        downloadURL: nil
                    )
                }
            } catch {
                self.showUpdateAlert(title: "Unable to Check for Updates", message: "\(error.localizedDescription)", downloadURL: nil)
            }
        }
    }

    private func showUpdateAlert(title: String, message: String, downloadURL: URL?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        if let downloadURL = downloadURL {
            alert.addButton(withTitle: "Download Update")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(downloadURL)
            }
        } else {
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func didSelectMethod(_ sender: NSMenuItem) {
        guard let selected = sender.representedObject as? CalculationMethod else { return }
        self.method = selected
        fetchTimings()
    }

    @objc private func didSelectNamingStyle(_ sender: NSMenuItem) {
        guard let selected = sender.representedObject as? PrayerNamingStyle else { return }
        self.namingStyle = selected
        updateStatusBarText()
        rebuildMenu()
    }

    @objc private func didToggleLaunchAtLogin() {
        launchAtLogin = !launchAtLogin
        rebuildMenu() // refresh checkmark
    }

    @objc private func didSelectRefresh() {
        statusItem.button?.title = "🕌 Updating..."
        lastFetchDay = -1 // force re-fetch
        fetchTimings()
    }

    @objc private func didSelectChangeLocation() {
        let alert = NSAlert()
        alert.messageText = "Set Prayer Location"
        alert.informativeText = "Enter City and Country (e.g. Istanbul, Turkey or Ikast, Denmark):"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 60))
        let cityField = NSTextField(frame: NSRect(x: 0, y: 32, width: 260, height: 24))
        cityField.stringValue = self.city
        cityField.placeholderString = "City (e.g. Ikast)"

        let countryField = NSTextField(frame: NSRect(x: 0, y: 4, width: 260, height: 24))
        countryField.stringValue = self.country
        countryField.placeholderString = "Country (e.g. Denmark)"

        container.addSubview(cityField)
        container.addSubview(countryField)
        alert.accessoryView = container

        if alert.runModal() == .alertFirstButtonReturn {
            let newCity = cityField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let newCountry = countryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newCity.isEmpty && !newCountry.isEmpty {
                self.city = newCity
                self.country = newCountry
                fetchTimings()
            }
        }
    }
}
