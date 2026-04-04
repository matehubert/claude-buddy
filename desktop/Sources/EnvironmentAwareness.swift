import AppKit

class EnvironmentAwareness {
    static let shared = EnvironmentAwareness()

    private(set) var timeOfDay: TimeOfDay = .afternoon
    private(set) var isDarkMode: Bool = false
    private(set) var weather: String = "clear"
    private(set) var temperature: Int? = nil

    private var weatherTimer: Timer?
    private var timeCheckTimer: Timer?
    private var appearanceObserver: NSObjectProtocol?

    var onTimeOfDayChange: ((TimeOfDay) -> Void)?
    var onDarkModeChange: ((Bool) -> Void)?
    var onWeatherChange: ((String) -> Void)?

    private init() {}

    func start() {
        updateTimeOfDay()
        updateDarkMode()
        fetchWeather()

        // Check time every 5 minutes
        timeCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateTimeOfDay()
        }

        // Weather every 30 minutes
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.fetchWeather()
        }

        // Dark mode observer
        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDarkMode()
        }
    }

    func stop() {
        weatherTimer?.invalidate()
        timeCheckTimer?.invalidate()
        if let obs = appearanceObserver {
            DistributedNotificationCenter.default().removeObserver(obs)
        }
    }

    // MARK: - Time of Day

    private func updateTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        let newTime: TimeOfDay
        switch hour {
        case 5..<12:  newTime = .morning
        case 12..<17: newTime = .afternoon
        case 17..<21: newTime = .evening
        default:      newTime = .night
        }

        if newTime != timeOfDay {
            timeOfDay = newTime
            onTimeOfDayChange?(newTime)
        }
    }

    // MARK: - Dark Mode

    private func updateDarkMode() {
        let appearance = NSApp.effectiveAppearance
        let newDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if newDark != isDarkMode {
            isDarkMode = newDark
            onDarkModeChange?(newDark)
        }
    }

    // MARK: - Weather (wttr.in)

    private func fetchWeather() {
        guard let url = URL(string: "https://wttr.in/?format=%C|%t") else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("curl/7.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, let text = String(data: data, encoding: .utf8) else { return }
            let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|")
            guard parts.count >= 1 else { return }

            let condition = String(parts[0]).trimmingCharacters(in: .whitespaces).lowercased()
            let temp = parts.count >= 2 ? Int(parts[1].trimmingCharacters(in: .whitespaces).filter { $0.isNumber || $0 == "-" }) : nil

            DispatchQueue.main.async {
                guard let self = self else { return }
                let oldWeather = self.weather
                self.weather = self.classifyWeather(condition)
                self.temperature = temp
                if self.weather != oldWeather {
                    self.onWeatherChange?(self.weather)
                }
            }
        }.resume()
    }

    private func classifyWeather(_ condition: String) -> String {
        if condition.contains("rain") || condition.contains("drizzle") || condition.contains("shower") {
            return "rain"
        } else if condition.contains("snow") || condition.contains("sleet") || condition.contains("blizzard") {
            return "snow"
        } else if condition.contains("cloud") || condition.contains("overcast") {
            return "cloudy"
        } else if condition.contains("sun") || condition.contains("clear") {
            return "sunny"
        } else if condition.contains("thunder") || condition.contains("storm") {
            return "storm"
        } else if condition.contains("fog") || condition.contains("mist") {
            return "fog"
        }
        return "clear"
    }

    // MARK: - Screen Edge Detection

    /// Returns accessory suggestion based on weather
    func weatherAccessory() -> AccessoryType? {
        switch weather {
        case "rain", "storm": return .umbrella
        case "sunny": return .sunglasses
        default: return nil
        }
    }

    /// Check if panel is near screen edge, returns which edge (or nil)
    static func detectScreenEdge(panelFrame: NSRect) -> String? {
        guard let screen = NSScreen.main else { return nil }
        let sf = screen.visibleFrame
        let threshold: CGFloat = 10

        if panelFrame.minY <= sf.minY + threshold { return "bottom" }
        if panelFrame.maxY >= sf.maxY - threshold { return "top" }
        if panelFrame.minX <= sf.minX + threshold { return "left" }
        if panelFrame.maxX >= sf.maxX - threshold { return "right" }
        return nil
    }
}
