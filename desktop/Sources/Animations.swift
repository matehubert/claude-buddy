import AppKit

// MARK: - Behavior State Machine

enum BuddyBehavior: CaseIterable {
    case idle
    case wandering
    case sleeping
    case exploring
    case sitting
}

// MARK: - Animation Controller

class AnimationController {
    weak var renderer: BuddyRenderer?
    weak var speechBubble: SpeechBubbleView?
    weak var buddyPanel: BuddyPanel?

    private var blinkTimer: Timer?
    private var idleTimer: Timer?
    private var idlePhase: CGFloat = 0
    private var isBlinking = false

    // Behavior state
    private(set) var currentBehavior: BuddyBehavior = .idle
    private var behaviorTimer: Timer?
    private var walkTimer: Timer?
    private var walkTarget: NSPoint?
    private var inactivityTimer: Timer?
    private var lastActivityTime = Date()

    // Direction
    private(set) var facingLeft = false

    // Callbacks
    var onBehaviorChange: ((BuddyBehavior) -> Void)?
    var onFacingChange: ((Bool) -> Void)?

    func start() {
        scheduleNextBlink()
        startIdleBob()
        scheduleBehaviorChange()
        resetInactivityTimer()
    }

    func stop() {
        blinkTimer?.invalidate()
        idleTimer?.invalidate()
        behaviorTimer?.invalidate()
        walkTimer?.invalidate()
        inactivityTimer?.invalidate()
    }

    // MARK: - Activity Tracking

    func noteActivity() {
        lastActivityTime = Date()
        if currentBehavior == .sleeping {
            wakeUp()
        }
        resetInactivityTimer()
        MoodEnergySystem.shared.noteActivity()
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: false) { [weak self] _ in
            self?.transitionTo(.sleeping)
        }
    }

    // MARK: - Behavior State Machine

    private func scheduleBehaviorChange() {
        let interval = TimeInterval.random(in: 15...45)
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.pickNextBehavior()
        }
    }

    private func pickNextBehavior() {
        guard currentBehavior != .sleeping else {
            scheduleBehaviorChange()
            return
        }

        // Mood-based weights
        let weights = MoodEnergySystem.shared.behaviorWeights()
        let candidates: [(BuddyBehavior, Double)] = [
            (.idle, weights.idle),
            (.wandering, weights.wandering),
            (.exploring, weights.exploring),
            (.sitting, weights.sitting)
        ]

        // Pomodoro override: less wandering during work
        var adjustedCandidates = candidates
        if PomodoroTimer.shared.phase == .work {
            adjustedCandidates = [
                (.idle, 0.45),
                (.wandering, 0.10),
                (.exploring, 0.10),
                (.sitting, 0.35)
            ]
        } else if PomodoroTimer.shared.phase == .shortBreak || PomodoroTimer.shared.phase == .longBreak {
            adjustedCandidates = [
                (.idle, 0.15),
                (.wandering, 0.45),
                (.exploring, 0.25),
                (.sitting, 0.15)
            ]
        }

        let roll = Double.random(in: 0..<1)
        var cumulative = 0.0
        var chosen: BuddyBehavior = .idle
        for (behavior, weight) in adjustedCandidates {
            cumulative += weight
            if roll < cumulative {
                chosen = behavior
                break
            }
        }

        if chosen == currentBehavior && chosen != .idle {
            chosen = .idle
        }

        transitionTo(chosen)
    }

    func transitionTo(_ behavior: BuddyBehavior) {
        let old = currentBehavior
        currentBehavior = behavior

        if old == .wandering {
            walkTimer?.invalidate()
            walkTimer = nil
        }

        onBehaviorChange?(behavior)

        switch behavior {
        case .idle:
            renderer?.setSleeping(false)
        case .wandering:
            renderer?.setSleeping(false)
            startWandering()
        case .sleeping:
            renderer?.setSleeping(true)
        case .exploring:
            renderer?.setSleeping(false)
            doExplore()
        case .sitting:
            renderer?.setSleeping(false)
        }

        scheduleBehaviorChange()
    }

    // MARK: - Sleep

    private func wakeUp() {
        currentBehavior = .idle
        renderer?.setSleeping(false)
        onBehaviorChange?(.idle)

        let offsets: [(CGFloat, TimeInterval)] = [
            (-4, 0.0), (-2, 0.1), (-5, 0.2), (-1, 0.3), (0, 0.4)
        ]
        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.renderer?.setBounceOffset(offset)
            }
        }

        showReaction(BuddyL10n.wakeTexts.randomElement() ?? "hmm..?")
        resetInactivityTimer()
    }

    // MARK: - Wandering

    private func startWandering() {
        guard let panel = buddyPanel, let screen = NSScreen.main else {
            transitionTo(.idle)
            return
        }

        let visibleFrame = screen.visibleFrame
        let targetX = CGFloat.random(in: visibleFrame.minX + 40...visibleFrame.maxX - 240)
        let targetY = CGFloat.random(in: visibleFrame.minY + 20...visibleFrame.minY + visibleFrame.height * 0.3)
        let target = NSPoint(x: targetX, y: targetY)
        walkTarget = target

        let currentPos = panel.frame.origin
        let dx = target.x - currentPos.x
        let dy = target.y - currentPos.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < 20 {
            transitionTo(.idle)
            return
        }

        let newFacing = dx < 0
        if newFacing != facingLeft {
            facingLeft = newFacing
            onFacingChange?(facingLeft)
            renderer?.setFacingLeft(facingLeft)
        }

        let speed: CGFloat = 8.0
        let stepX = (dx / distance) * speed
        let stepY = (dy / distance) * speed
        let totalSteps = Int(distance / speed)
        var step = 0

        walkTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let panel = self.buddyPanel else {
                timer.invalidate()
                return
            }

            step += 1
            let newX = panel.frame.origin.x + stepX
            let newY = panel.frame.origin.y + stepY
            panel.setFrameOrigin(NSPoint(x: newX, y: newY))

            if step >= totalSteps {
                timer.invalidate()
                self.walkTimer = nil
                panel.savePosition()
                if self.currentBehavior == .wandering {
                    self.transitionTo(.idle)
                }
            }
        }
    }

    // MARK: - Explore

    private func doExplore() {
        guard let panel = buddyPanel, let screen = NSScreen.main else { return }

        let frame = panel.frame
        let screenFrame = screen.visibleFrame
        let distToLeft = frame.midX - screenFrame.minX
        let distToRight = screenFrame.maxX - frame.midX

        let lookLeft = distToLeft < distToRight
        if lookLeft != facingLeft {
            facingLeft = lookLeft
            onFacingChange?(facingLeft)
            renderer?.setFacingLeft(facingLeft)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showReaction(BuddyL10n.curiosityTexts.randomElement() ?? "hmm?")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self, self.currentBehavior == .exploring else { return }
            let next: BuddyBehavior = Bool.random() ? .wandering : .idle
            self.transitionTo(next)
        }
    }

    // MARK: - Blink Animation

    private func scheduleNextBlink() {
        let interval = TimeInterval.random(in: 3.0...5.0)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.doBlink()
        }
    }

    private func doBlink() {
        guard let r = renderer else { return }
        if currentBehavior == .sleeping {
            scheduleNextBlink()
            return
        }
        isBlinking = true
        r.setBlinking(true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.isBlinking = false
            self?.renderer?.setBlinking(false)
            self?.scheduleNextBlink()
        }
    }

    // MARK: - Idle Bob Animation

    private func startIdleBob() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let r = self.renderer else { return }
            // Pause bob during sleep to save CPU/memory
            guard self.currentBehavior != .sleeping else { return }
            self.idlePhase += 0.25
            let offset = sin(self.idlePhase) * 1.5
            r.setIdleOffset(CGFloat(offset))
        }
    }

    // MARK: - Pet Bounce Animation

    func triggerPetBounce() {
        noteActivity()
        guard let r = renderer else { return }
        r.triggerParticleEffect(.hearts)
        let offsets: [(CGFloat, TimeInterval)] = [
            (-6, 0.0), (-3, 0.08), (-5, 0.16), (-1, 0.24), (0, 0.32)
        ]
        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                r.setBounceOffset(offset)
            }
        }
    }

    // MARK: - Feed Animation

    func triggerFeedBounce() {
        noteActivity()
        guard let r = renderer else { return }
        let offsets: [(CGFloat, TimeInterval)] = [
            (-3, 0.0), (-1, 0.1), (-4, 0.2), (-1, 0.3), (0, 0.4)
        ]
        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                r.setBounceOffset(offset)
            }
        }
    }

    // MARK: - Species-Specific Tricks (Double Click)

    func triggerSpeciesTrick(species: String) {
        noteActivity()
        guard let r = renderer else { return }

        switch species {
        case "duck", "goose":
            showReaction(BuddyL10n.duckQuack)
            let flaps: [(CGFloat, TimeInterval)] = [
                (-4, 0.0), (0, 0.06), (-4, 0.12), (0, 0.18),
                (-3, 0.24), (0, 0.30), (-2, 0.36), (0, 0.42)
            ]
            for (offset, delay) in flaps {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    r.setBounceOffset(offset)
                }
            }
            r.triggerParticleEffect(.waterRipple)
        case "cat":
            showReaction(BuddyL10n.catPurr)
            let jump: [(CGFloat, TimeInterval)] = [
                (-12, 0.0), (-10, 0.06), (-8, 0.12), (-5, 0.18),
                (-3, 0.24), (-1, 0.30), (0, 0.36)
            ]
            for (offset, delay) in jump {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    r.setBounceOffset(offset)
                }
            }
            r.triggerParticleEffect(.catStars)
        case "snail":
            showReaction(BuddyL10n.snailHides)
            r.setCollapsed(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                r.setCollapsed(false)
                self?.showReaction(BuddyL10n.snailHi)
            }
        case "ghost":
            showReaction(BuddyL10n.ghostBoo)
            r.triggerParticleEffect(.ghostFlame)
            do {
                let view = r.view
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.3
                    view.animator().alphaValue = 0.2
                } completionHandler: {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.5
                        view.animator().alphaValue = 1.0
                    }
                }
            }
        default:
            showReaction(BuddyL10n.defaultTrick)
            let spin: [(CGFloat, TimeInterval)] = [
                (-5, 0.0), (0, 0.05), (-5, 0.10), (0, 0.15),
                (-4, 0.20), (0, 0.25), (-3, 0.30), (0, 0.35),
                (-2, 0.40), (0, 0.45)
            ]
            for (offset, delay) in spin {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    r.setBounceOffset(offset)
                }
            }
        }
    }

    // MARK: - Shake Reaction

    func triggerShakeReaction() {
        noteActivity()
        showReaction(BuddyL10n.shakeReaction)
        guard let r = renderer else { return }
        let wobble: [(CGFloat, TimeInterval)] = [
            (-3, 0.0), (3, 0.06), (-4, 0.12), (4, 0.18),
            (-2, 0.24), (2, 0.30), (-1, 0.36), (0, 0.42)
        ]
        for (offset, delay) in wobble {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                r.setBounceOffset(offset)
            }
        }
    }

    // MARK: - Mouse Proximity Reactions

    func onMouseNearby() {
        guard currentBehavior != .sleeping else { return }
    }

    func onMouseHover() {
        guard currentBehavior != .sleeping else { return }
        renderer?.setEyeWiden(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.renderer?.setEyeWiden(false)
        }
    }

    func onMouseScared() {
        guard currentBehavior != .sleeping else { return }
        showReaction(BuddyL10n.mouseScared)
        let scare: [(CGFloat, TimeInterval)] = [
            (-5, 0.0), (-2, 0.08), (-4, 0.16), (0, 0.24)
        ]
        for (offset, delay) in scare {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.renderer?.setBounceOffset(offset)
            }
        }
    }

    // MARK: - Environment Hooks

    func applyEnvironment() {
        let env = EnvironmentAwareness.shared
        renderer?.setTimeOfDay(env.timeOfDay)

        // Weather accessories
        if let accessory = env.weatherAccessory() {
            renderer?.setAccessory(accessory, visible: true)
        } else {
            renderer?.setAccessory(.umbrella, visible: false)
            renderer?.setAccessory(.sunglasses, visible: false)
        }
    }

    func applyMood() {
        renderer?.setMoodExpression(MoodEnergySystem.shared.mood)
    }

    // MARK: - Speech Bubble

    func showReaction(_ text: String) {
        guard let bubble = speechBubble else { return }
        bubble.show(text: text)
    }
}
