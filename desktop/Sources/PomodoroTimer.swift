import Foundation

enum PomodoroPhase: String {
    case idle
    case work
    case shortBreak = "short_break"
    case longBreak = "long_break"
}

class PomodoroTimer {
    static let shared = PomodoroTimer()

    private(set) var phase: PomodoroPhase = .idle
    private(set) var remainingSeconds: Int = 0
    private(set) var completedPomodoros: Int = 0

    private var timer: Timer?
    private let workDuration = 25 * 60       // 25 min
    private let shortBreakDuration = 5 * 60  // 5 min
    private let longBreakDuration = 15 * 60  // 15 min
    private let longBreakInterval = 4        // long break every 4 pomodoros

    var onTick: ((Int, PomodoroPhase) -> Void)?
    var onPhaseChange: ((PomodoroPhase) -> Void)?
    var onComplete: ((PomodoroPhase) -> Void)?

    private init() {}

    // MARK: - Controls

    func start() {
        guard phase == .idle else { return }
        beginWork()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        remainingSeconds = 0
        onPhaseChange?(.idle)
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        phaseComplete()
    }

    // MARK: - Phase Management

    private func beginWork() {
        phase = .work
        remainingSeconds = workDuration
        onPhaseChange?(.work)
        startCountdown()
    }

    private func beginBreak() {
        let isLong = completedPomodoros > 0 && completedPomodoros % longBreakInterval == 0
        phase = isLong ? .longBreak : .shortBreak
        remainingSeconds = isLong ? longBreakDuration : shortBreakDuration
        onPhaseChange?(phase)
        startCountdown()
    }

    private func phaseComplete() {
        let completedPhase = phase
        onComplete?(completedPhase)

        switch completedPhase {
        case .work:
            completedPomodoros += 1
            MoodEnergySystem.shared.addPomodoroComplete()
            beginBreak()
        case .shortBreak, .longBreak:
            beginWork()
        case .idle:
            break
        }
    }

    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            self.onTick?(self.remainingSeconds, self.phase)

            if self.remainingSeconds <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                self.phaseComplete()
            }
        }
    }

    // MARK: - Status

    var isRunning: Bool { phase != .idle }

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var statusText: String {
        switch phase {
        case .idle: return "Not running"
        case .work: return "Focus \(formattedTime)"
        case .shortBreak: return "Break \(formattedTime)"
        case .longBreak: return "Long break \(formattedTime)"
        }
    }

    func statusJSON() -> [String: Any] {
        return [
            "phase": phase.rawValue,
            "remaining": remainingSeconds,
            "formatted": formattedTime,
            "completedPomodoros": completedPomodoros,
            "isRunning": isRunning
        ]
    }
}

// MARK: - MoodEnergySystem Pomodoro Extension

extension MoodEnergySystem {
    func addPomodoroComplete() {
        // Reuse feed for energy boost on pomodoro completion
        feed()
    }
}
