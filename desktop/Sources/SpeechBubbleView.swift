import AppKit

class SpeechBubbleView: NSView {
    private var textLabel: NSTextField!
    private var hideTimer: Timer?
    private var countdownLabel: NSTextField?
    private var countdownTimer: Timer?
    private var remainingTime: Int = 0
    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        alphaValue = 0

        textLabel = NSTextField(wrappingLabelWithString: "")
        textLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textLabel.textColor = .white
        textLabel.backgroundColor = .clear
        textLabel.isBordered = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.maximumNumberOfLines = 3
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            textLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        let bubbleRect = bounds.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 8, yRadius: 8)
        NSColor(white: 0.15, alpha: 0.9).setFill()
        path.fill()
        NSColor(white: 0.4, alpha: 0.8).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private var homeFrame: NSRect = .zero

    func show(text: String, duration: TimeInterval = 5.0) {
        hideTimer?.invalidate()
        countdownTimer?.invalidate()

        // Remember the correct frame on first show
        if homeFrame == .zero {
            homeFrame = frame
        }

        // Always reset to home frame first
        frame = homeFrame

        textLabel.stringValue = text
        needsDisplay = true

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            self.animator().alphaValue = 1.0
        }

        // Auto-hide after duration
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    /// Show with persistent countdown (for pomodoro, games etc)
    func showPersistent(text: String, seconds: Int) {
        hideTimer?.invalidate()
        countdownTimer?.invalidate()
        remainingTime = seconds

        textLabel.stringValue = text
        needsDisplay = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            self.animator().alphaValue = 1.0
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingTime -= 1
            if self.remainingTime <= 0 {
                self.countdownTimer?.invalidate()
                self.hide()
            }
        }
    }

    /// Update text without re-animating (for countdown updates)
    func updateText(_ text: String) {
        textLabel.stringValue = text
    }

    // MARK: - Trivia Buttons

    private var triviaButtons: [NSButton] = []
    private var triviaCallback: ((Int) -> Void)?

    /// Show trivia question with 3 answer buttons
    func showTrivia(question: String, answers: [String], onAnswer: @escaping (Int) -> Void) {
        hideTimer?.invalidate()
        countdownTimer?.invalidate()
        removeTriviaButtons()
        triviaCallback = onAnswer

        if homeFrame == .zero {
            homeFrame = frame
        }

        // Expand bubble height for buttons
        var expanded = homeFrame
        expanded.size.height = homeFrame.height + 78
        expanded.origin.y = homeFrame.origin.y - 78
        frame = expanded

        textLabel.stringValue = question
        needsDisplay = true

        // Create answer buttons
        let buttonY: CGFloat = expanded.height - 28
        for (i, answer) in answers.prefix(3).enumerated() {
            let btn = NSButton(frame: NSRect(x: 10, y: buttonY - CGFloat(i) * 24, width: expanded.width - 20, height: 22))
            btn.bezelStyle = .recessed
            btn.title = "\(i + 1)) \(answer)"
            btn.font = NSFont.systemFont(ofSize: 10, weight: .medium)
            btn.contentTintColor = .white
            btn.tag = i + 1
            btn.target = self
            btn.action = #selector(triviaButtonClicked(_:))
            addSubview(btn)
            triviaButtons.append(btn)
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            self.animator().alphaValue = 1.0
        }

        // Timeout auto-hide after 15s
        hideTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            self?.removeTriviaButtons()
            self?.hide()
        }
    }

    @objc private func triviaButtonClicked(_ sender: NSButton) {
        let answer = sender.tag
        removeTriviaButtons()
        triviaCallback?(answer)
        triviaCallback = nil

        // Shrink back to normal size after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.homeFrame != .zero else { return }
            self.frame = self.homeFrame
            self.needsDisplay = true
        }
    }

    private func removeTriviaButtons() {
        triviaButtons.forEach { $0.removeFromSuperview() }
        triviaButtons.removeAll()
    }

    // MARK: - Ask Buddy Input Mode

    private var inputField: NSTextField?
    private var inputCallback: ((String) -> Void)?

    func showInput(placeholder: String, onSubmit: @escaping (String) -> Void) {
        hideTimer?.invalidate()
        countdownTimer?.invalidate()
        removeTriviaButtons()
        removeInput()
        inputCallback = onSubmit

        if homeFrame == .zero {
            homeFrame = frame
        }

        // Expand bubble for input
        var expanded = homeFrame
        expanded.size.height = homeFrame.height + 30
        expanded.origin.y = homeFrame.origin.y - 30
        frame = expanded

        textLabel.stringValue = "🤔 Ask Buddy..."
        needsDisplay = true

        let field = NSTextField(frame: NSRect(x: 10, y: expanded.height - 24, width: expanded.width - 20, height: 22))
        field.placeholderString = placeholder
        field.font = NSFont.systemFont(ofSize: 11)
        field.bezelStyle = .roundedBezel
        field.target = self
        field.action = #selector(inputSubmitted(_:))
        addSubview(field)
        inputField = field

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            self.animator().alphaValue = 1.0
        }

        // Focus the field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            field.window?.makeFirstResponder(field)
        }
    }

    @objc private func inputSubmitted(_ sender: NSTextField) {
        let text = sender.stringValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let cb = inputCallback
        inputCallback = nil
        removeInput()

        // Shrink back
        if homeFrame != .zero {
            frame = homeFrame
            needsDisplay = true
        }

        cb?(text)
    }

    private func removeInput() {
        inputField?.removeFromSuperview()
        inputField = nil
    }

    func hide() {
        removeInput()
        hideTimer?.invalidate()
        countdownTimer?.invalidate()
        removeTriviaButtons()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self = self, self.homeFrame != .zero else { return }
            self.frame = self.homeFrame
            self.needsDisplay = true
        }
    }
}
