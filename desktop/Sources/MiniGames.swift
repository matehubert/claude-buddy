import AppKit

// MARK: - Mini Game Protocol

protocol MiniGameDelegate: AnyObject {
    func gameShowBubble(_ text: String, duration: TimeInterval)
    func gameMoveBuddy(to point: NSPoint, duration: TimeInterval)
    func gameGetBuddyPosition() -> NSPoint
    func gameGetScreenFrame() -> NSRect
    func gameOnComplete(game: String, score: Int)
}

enum MiniGameType: String, CaseIterable {
    case clickCatch = "Click Catch"
    case hideAndSeek = "Hide & Seek"
    case trivia = "Trivia"
}

// MARK: - Mini Game Manager

class MiniGameManager {
    static let shared = MiniGameManager()
    weak var delegate: MiniGameDelegate?

    private(set) var currentGame: MiniGameType?
    private(set) var score: Int = 0
    private var gameTimer: Timer?
    private var roundCount = 0

    // Click catch state
    private var catchWindowOpen = false
    private var catchTimer: Timer?

    // Hide & seek state
    private var seekStartTime: Date?

    // Trivia state
    private var currentAnswer: Int = 0

    private init() {}

    // MARK: - Start Games

    func startGame(_ type: MiniGameType) {
        guard currentGame == nil else { return }
        currentGame = type
        score = 0
        roundCount = 0

        switch type {
        case .clickCatch:  startClickCatch()
        case .hideAndSeek: startHideAndSeek()
        case .trivia:      startTrivia()
        }
    }

    func endCurrentGame() {
        gameTimer?.invalidate()
        catchTimer?.invalidate()
        let type = currentGame?.rawValue ?? "Game"
        let finalScore = score
        currentGame = nil
        delegate?.gameShowBubble(BuddyL10n.gameOver(finalScore), duration: 5)
        delegate?.gameOnComplete(game: type, score: finalScore)
        MoodEnergySystem.shared.play()
    }

    // MARK: - Click Catch

    private func startClickCatch() {
        delegate?.gameShowBubble(BuddyL10n.clickCatchIntro, duration: 3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.nextClickCatchRound()
        }
    }

    private func nextClickCatchRound() {
        guard currentGame == .clickCatch else { return }
        roundCount += 1

        if roundCount > 5 {
            endCurrentGame()
            return
        }

        // Random delay before "GO!"
        let delay = Double.random(in: 1.5...4.0)
        delegate?.gameShowBubble(BuddyL10n.clickCatchWait, duration: delay)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.currentGame == .clickCatch else { return }
            self.catchWindowOpen = true
            self.delegate?.gameShowBubble(BuddyL10n.clickCatchGo, duration: 2)

            // 2 second window to click
            self.catchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.catchWindowOpen {
                    self.catchWindowOpen = false
                    self.delegate?.gameShowBubble(BuddyL10n.clickCatchTooSlow, duration: 1.5)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.nextClickCatchRound()
                    }
                }
            }
        }
    }

    func handleClick() {
        guard let game = currentGame else { return }

        switch game {
        case .clickCatch:
            if catchWindowOpen {
                catchWindowOpen = false
                catchTimer?.invalidate()
                score += 1
                delegate?.gameShowBubble(BuddyL10n.clickCatchNice(score), duration: 1.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.nextClickCatchRound()
                }
            }

        case .hideAndSeek:
            // Found the buddy!
            if let start = seekStartTime {
                let elapsed = Date().timeIntervalSince(start)
                let bonus = max(1, Int(10 - elapsed))
                score += bonus
                delegate?.gameShowBubble(BuddyL10n.hideAndSeekFound(bonus, score), duration: 2)
                roundCount += 1
                if roundCount >= 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        self?.endCurrentGame()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        self?.nextHideAndSeekRound()
                    }
                }
            }

        case .trivia:
            break // Trivia uses numbered answers
        }
    }

    // MARK: - Hide & Seek

    private func startHideAndSeek() {
        delegate?.gameShowBubble(BuddyL10n.hideAndSeekIntro, duration: 3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.nextHideAndSeekRound()
        }
    }

    private func nextHideAndSeekRound() {
        guard currentGame == .hideAndSeek else { return }

        let screen = delegate?.gameGetScreenFrame() ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        // Random position on screen
        let x = CGFloat.random(in: screen.minX + 50...screen.maxX - 250)
        let y = CGFloat.random(in: screen.minY + 50...screen.maxY - 200)

        delegate?.gameShowBubble(BuddyL10n.hideAndSeekHides, duration: 0.5)
        delegate?.gameMoveBuddy(to: NSPoint(x: x, y: y), duration: 0.1)
        seekStartTime = Date()

        // Timeout after 15 seconds
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            guard let self = self, self.currentGame == .hideAndSeek else { return }
            self.delegate?.gameShowBubble(BuddyL10n.hideAndSeekTooSlow, duration: 2)
            self.roundCount += 1
            if self.roundCount >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.endCurrentGame()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.nextHideAndSeekRound()
                }
            }
        }
    }

    // MARK: - Trivia

    private static let triviaQuestions: [(q: String, a: [String], correct: Int)] = [
        ("What does HTTP stand for?", ["HyperText Transfer Protocol", "High Tech Transport Protocol", "Hybrid Text Transfer Process"], 0),
        ("Which is NOT a JS framework?", ["React", "Angular", "Photon"], 2),
        ("What does CSS stand for?", ["Cascading Style Sheets", "Computer Style System", "Creative Style Syntax"], 0),
        ("What is 0x1F in decimal?", ["31", "16", "25"], 0),
        ("Which company created Git?", ["Linux community", "Microsoft", "Google"], 0),
        ("What does API stand for?", ["Application Programming Interface", "Advanced Protocol Integration", "Automated Process Input"], 0),
        ("Which is a valid HTTP method?", ["PATCH", "PUSH", "SEND"], 0),
        ("What year was Python created?", ["1991", "1995", "2000"], 0),
        ("What does SQL stand for?", ["Structured Query Language", "Simple Question Language", "Sequential Query Logic"], 0),
        ("Which port is HTTPS?", ["443", "80", "8080"], 0),
    ]

    private func startTrivia() {
        delegate?.gameShowBubble(BuddyL10n.triviaIntro, duration: 2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.nextTriviaRound()
        }
    }

    private func nextTriviaRound() {
        guard currentGame == .trivia else { return }
        roundCount += 1

        if roundCount > 3 {
            endCurrentGame()
            return
        }

        let questions = MiniGameManager.triviaQuestions
        let q = questions[Int.random(in: 0..<questions.count)]
        currentAnswer = q.correct

        let text = "\(q.q)\n1) \(q.a[0])\n2) \(q.a[1])\n3) \(q.a[2])"
        delegate?.gameShowBubble(text, duration: 15)

        // Timeout
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            guard let self = self, self.currentGame == .trivia else { return }
            self.delegate?.gameShowBubble(BuddyL10n.triviaTimesUp(q.a[q.correct]), duration: 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                self?.nextTriviaRound()
            }
        }
    }

    /// Handle trivia answer (1, 2, or 3)
    func answerTrivia(_ answer: Int) {
        guard currentGame == .trivia else { return }
        gameTimer?.invalidate()

        if answer - 1 == currentAnswer {
            score += 1
            delegate?.gameShowBubble(BuddyL10n.triviaCorrect(score), duration: 2)
        } else {
            delegate?.gameShowBubble(BuddyL10n.triviaWrong, duration: 2)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.nextTriviaRound()
        }
    }
}
