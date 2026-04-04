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

    func hide() {
        countdownTimer?.invalidate()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            self.animator().alphaValue = 0
        }
    }
}
