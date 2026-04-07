import Foundation

// MARK: - Mood/Energy System

class MoodEnergySystem {
    static let shared = MoodEnergySystem()

    private(set) var mood: BuddyMood = .content
    private(set) var energy: Int = 80
    private(set) var streak: Int = 0
    private(set) var achievements: [String] = []
    private(set) var feedCount: Int = 0
    private(set) var petCount: Int = 0
    private(set) var playCount: Int = 0

    private var decayTimer: Timer?
    private var lastInteractionTime = Date()
    private let soulPath: String

    var onMoodChange: ((BuddyMood) -> Void)?
    var onEnergyChange: ((Int) -> Void)?
    var onAchievement: ((String) -> Void)?
    var onStatGrowth: ((String, Int) -> Void)?

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        soulPath = "\(home)/.claude/buddy.json"
        loadFromDisk()
        startDecayTimer()
    }

    // MARK: - Actions

    func pet() {
        addEnergy(5)
        petCount += 1
        lastInteractionTime = Date()
        checkStreak()
        checkAchievements()
        saveToDisk()
    }

    func feed() {
        addEnergy(15)
        feedCount += 1
        lastInteractionTime = Date()
        if mood == .sad || mood == .bored {
            setMood(.content)
        }
        checkAchievements()
        saveToDisk()
    }

    func play() {
        addEnergy(10)
        playCount += 1
        lastInteractionTime = Date()
        if mood != .excited {
            setMood(.happy)
        }
        checkAchievements()
        saveToDisk()
    }

    func noteActivity() {
        lastInteractionTime = Date()
        if mood == .bored {
            setMood(.content)
        }
    }

    // MARK: - Energy

    private func addEnergy(_ amount: Int) {
        energy = min(100, energy + amount)
        onEnergyChange?(energy)
    }

    private func drainEnergy(_ amount: Int) {
        energy = max(0, energy - amount)
        onEnergyChange?(energy)
    }

    // MARK: - Mood

    private func setMood(_ newMood: BuddyMood) {
        guard newMood != mood else { return }
        mood = newMood
        onMoodChange?(newMood)
        saveToDisk()
    }

    // MARK: - Decay Timer

    private func startDecayTimer() {
        // Every 10 minutes: energy -1, check mood degradation
        decayTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        drainEnergy(1)

        let timeSinceInteraction = Date().timeIntervalSince(lastInteractionTime)

        // Mood degradation: after 6 hours of inactivity
        if timeSinceInteraction > 6 * 3600 {
            degradeMood()
        } else if timeSinceInteraction > 3 * 3600 {
            if mood == .happy || mood == .excited {
                setMood(.content)
            }
        } else if timeSinceInteraction > 1 * 3600 {
            if mood == .excited {
                setMood(.happy)
            }
        }

        // Energy affects mood
        if energy < 20 && mood != .sad {
            setMood(.sad)
        } else if energy < 40 && mood == .happy {
            setMood(.content)
        }

        saveToDisk()
    }

    private func degradeMood() {
        switch mood {
        case .excited: setMood(.happy)
        case .happy:   setMood(.content)
        case .content: setMood(.bored)
        case .bored:   setMood(.sad)
        case .sad, .grumpy: break
        }
    }

    // MARK: - Behavior Weights

    /// Returns behavior weights adjusted for current mood
    func behaviorWeights() -> (idle: Double, wandering: Double, exploring: Double, sitting: Double) {
        switch mood {
        case .excited: return (0.15, 0.45, 0.30, 0.10)
        case .happy:   return (0.25, 0.35, 0.25, 0.15)
        case .content: return (0.30, 0.30, 0.20, 0.20)
        case .bored:   return (0.40, 0.15, 0.10, 0.35)
        case .sad:     return (0.45, 0.10, 0.05, 0.40)
        case .grumpy:  return (0.35, 0.20, 0.15, 0.30)
        }
    }

    // MARK: - Streak

    private func checkStreak() {
        let calendar = Calendar.current

        if calendar.isDateInToday(lastInteractionTime) {
            // Same day, streak continues
        } else if calendar.isDateInYesterday(lastInteractionTime) {
            streak += 1
        } else {
            streak = 1
        }
    }

    // MARK: - Achievements

    private func checkAchievements() {
        var newAchievements: [String] = []

        if petCount >= 10 && !achievements.contains("pet_10") {
            achievements.append("pet_10")
            newAchievements.append("Pet Lover (10 pets)")
        }
        if petCount >= 100 && !achievements.contains("pet_100") {
            achievements.append("pet_100")
            newAchievements.append("Pet Master (100 pets)")
        }
        if feedCount >= 10 && !achievements.contains("feed_10") {
            achievements.append("feed_10")
            newAchievements.append("Good Caretaker (10 feeds)")
        }
        if playCount >= 5 && !achievements.contains("play_5") {
            achievements.append("play_5")
            newAchievements.append("Fun Times (5 games)")
        }
        if streak >= 7 && !achievements.contains("streak_7") {
            achievements.append("streak_7")
            newAchievements.append("Week Streak (7 days)")
            incrementStat("WISDOM", by: 3)
        }
        if streak >= 30 && !achievements.contains("streak_30") {
            achievements.append("streak_30")
            newAchievements.append("Monthly Devotion (30 days)")
        }

        for a in newAchievements {
            onAchievement?(a)
        }
    }

    // MARK: - Persistence

    func loadFromDisk() {
        guard let data = FileManager.default.contents(atPath: soulPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let moodStr = json["mood"] as? String, let m = BuddyMood(rawValue: moodStr) {
            mood = m
        }
        if let e = json["energy"] as? Int {
            energy = min(100, max(0, e))
        }
        if let s = json["streak"] as? Int {
            streak = s
        }
        if let a = json["achievements"] as? [String] {
            achievements = a
        }
        if let fc = json["feedCount"] as? Int { feedCount = fc }
        if let pc = json["petCount"] as? Int { petCount = pc }
        if let plc = json["playCount"] as? Int { playCount = plc }
        if let ts = json["lastInteraction"] as? Double {
            lastInteractionTime = Date(timeIntervalSince1970: ts)
        }
    }

    func saveToDisk() {
        guard var json = readJSON() else { return }

        json["mood"] = mood.rawValue
        json["energy"] = energy
        json["streak"] = streak
        json["achievements"] = achievements
        json["feedCount"] = feedCount
        json["petCount"] = petCount
        json["playCount"] = playCount
        json["lastInteraction"] = lastInteractionTime.timeIntervalSince1970

        writeJSON(json)
    }

    private func readJSON() -> [String: Any]? {
        guard let data = FileManager.default.contents(atPath: soulPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json
    }

    private func writeJSON(_ json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else { return }
        // Suppress BuddyData file watcher — this write is internal
        BuddyData.shared.suppressFileWatcher = true
        try? data.write(to: URL(fileURLWithPath: soulPath))
    }

    // MARK: - Stat Growth

    func incrementStat(_ stat: String, by amount: Int) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let script = "\(home)/.claude/skills/buddy/buddy.mjs"

        DispatchQueue.global().async { [weak self] in
            let process = Process()
            let pipe = Pipe()
            let cmd = nodeArgs(script: script, args: ["increment-stat", stat, String(amount)])
            process.executableURL = URL(fileURLWithPath: cmd.executable)
            process.arguments = cmd.arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let actual = json["actual"] as? Int, actual > 0 {
                    DispatchQueue.main.async {
                        self?.onStatGrowth?(stat, actual)
                    }
                }
            } catch {}
        }
    }

    /// Export state as JSON for terminal commands
    func statusJSON() -> [String: Any] {
        return [
            "mood": mood.rawValue,
            "energy": energy,
            "streak": streak,
            "achievements": achievements,
            "feedCount": feedCount,
            "petCount": petCount,
            "playCount": playCount
        ]
    }
}
