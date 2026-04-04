import AppKit

class BuddyView: NSView, BuddyRenderer {
    var view: NSView { self }

    private var spriteLines: [String] = []
    private var eye: String = "·"
    private var isBlinkingState = false
    private var idleOffsetValue: CGFloat = 0
    private var bounceOffsetValue: CGFloat = 0
    private var shiny = false
    private var shinyHue: CGFloat = 0
    private var shinyTimer: Timer?

    // Direction & trail
    private(set) var facingLeftState = false
    var species: String = ""
    private var isCollapsed = false

    // Sleep state
    private var isSleeping = false
    private var zzZPhase: CGFloat = 0
    private var zzZTimer: Timer?

    // Eye widen (mouse hover)
    private var isEyeWidened = false

    private let font = NSFont(name: "Menlo", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    private let lineHeight: CGFloat = 18

    override var isFlipped: Bool { true }

    func configure(species: String, eye: String, hat: String, shiny: Bool) {
        self.species = species
        let lines = SpriteData.renderSprite(species: species, eye: eye, hat: hat)
        self.spriteLines = lines
        self.eye = eye
        self.shiny = shiny
        if shiny {
            startShinyAnimation()
        }
        needsDisplay = true
    }

    // Legacy configure for backward compatibility
    func configure(spriteLines: [String], eye: String, shiny: Bool) {
        self.spriteLines = spriteLines
        self.eye = eye
        self.shiny = shiny
        if shiny {
            startShinyAnimation()
        }
        needsDisplay = true
    }

    func setBlinking(_ blinking: Bool) {
        isBlinkingState = blinking
        needsDisplay = true
    }

    func setIdleOffset(_ offset: CGFloat) {
        idleOffsetValue = offset
        needsDisplay = true
    }

    func setBounceOffset(_ offset: CGFloat) {
        bounceOffsetValue = offset
        needsDisplay = true
    }

    func setFacingLeft(_ left: Bool) {
        facingLeftState = left
        needsDisplay = true
    }

    func setSleeping(_ sleeping: Bool) {
        let wasSleeping = isSleeping
        isSleeping = sleeping
        if sleeping && !wasSleeping {
            startZzZAnimation()
        } else if !sleeping && wasSleeping {
            stopZzZAnimation()
        }
        needsDisplay = true
    }

    func setCollapsed(_ collapsed: Bool) {
        isCollapsed = collapsed
        needsDisplay = true
    }

    func setEyeWiden(_ widen: Bool) {
        isEyeWidened = widen
        needsDisplay = true
    }

    // MARK: - zzZ Animation

    private func startZzZAnimation() {
        zzZPhase = 0
        zzZTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.zzZPhase += 0.04
            self.needsDisplay = true
        }
    }

    private func stopZzZAnimation() {
        zzZTimer?.invalidate()
        zzZTimer = nil
    }

    // MARK: - Shiny Animation

    private func startShinyAnimation() {
        shinyTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.shinyHue += 0.005
            if self.shinyHue > 1.0 { self.shinyHue -= 1.0 }
            self.needsDisplay = true
        }
    }

    // MARK: - Trail Text

    private func trailText() -> String {
        switch species {
        case "snail":     return "~~~~~~~"
        case "duck":      return "~ ~ ~"
        case "goose":     return "~ ~ ~"
        case "ghost":     return "· · ·"
        case "cat":       return "___"
        case "mushroom":  return "·  ·  ·"
        default:          return "---"
        }
    }

    // MARK: - Sprite Mirroring

    private func mirrorLine(_ line: String) -> String {
        var chars = Array(line.reversed())
        for i in 0..<chars.count {
            switch chars[i] {
            case "<": chars[i] = ">"
            case ">": chars[i] = "<"
            case "(": chars[i] = ")"
            case ")": chars[i] = "("
            case "[": chars[i] = "]"
            case "]": chars[i] = "["
            case "{": chars[i] = "}"
            case "}": chars[i] = "{"
            case "/": chars[i] = "\\"
            case "\\": chars[i] = "/"
            default: break
            }
        }
        return String(chars)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard !spriteLines.isEmpty else { return }

        // Collapsed state (snail hides in shell)
        if isCollapsed {
            let collapsedLine = "  `--´  "
            let totalOffset = idleOffsetValue + bounceOffsetValue
            let bgRect = NSRect(x: 4, y: 4 + totalOffset, width: bounds.width - 8, height: lineHeight + 12)
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 10, yRadius: 10)
            NSColor(white: 0.1, alpha: 0.75).setFill()
            bgPath.fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor(white: 0.95, alpha: 1.0)
            ]
            NSAttributedString(string: collapsedLine, attributes: attrs).draw(at: NSPoint(x: 12, y: 10 + totalOffset))
            return
        }

        let totalOffset = idleOffsetValue + bounceOffsetValue

        // Prepare lines (with optional mirroring)
        var lines = spriteLines
        if facingLeftState {
            lines = lines.map { mirrorLine($0) }
        }

        // Trail line below sprite
        let trail = trailText()
        let trailLineCount = 1
        let spriteLineCount = lines.count

        // Semi-transparent background pill (includes trail area)
        let totalLines = spriteLineCount + trailLineCount
        let bgRect = NSRect(
            x: 4, y: 4 + totalOffset,
            width: bounds.width - 8,
            height: CGFloat(totalLines) * lineHeight + 12
        )
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 10, yRadius: 10)
        NSColor(white: 0.1, alpha: 0.75).setFill()
        bgPath.fill()

        // Determine text color
        let textColor: NSColor
        if shiny {
            textColor = NSColor(hue: shinyHue, saturation: 0.6, brightness: 1.0, alpha: 1.0)
        } else {
            textColor = NSColor(white: 0.95, alpha: 1.0)
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        // Determine eye replacement
        let eyeReplacement: String
        if isSleeping {
            eyeReplacement = "−"
        } else if isBlinkingState {
            eyeReplacement = "−"
        } else if isEyeWidened {
            eyeReplacement = "◉"
        } else {
            eyeReplacement = eye
        }

        // Render sprite lines
        for (i, var line) in lines.enumerated() {
            if eyeReplacement != eye {
                line = line.replacingOccurrences(of: eye, with: eyeReplacement)
            }
            let y = CGFloat(i) * lineHeight + 10 + totalOffset
            let str = NSAttributedString(string: line, attributes: attrs)
            str.draw(at: NSPoint(x: 12, y: y))
        }

        // Render trail line
        let trailY = CGFloat(spriteLineCount) * lineHeight + 10 + totalOffset
        let trailAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.5, alpha: 0.6)
        ]
        // Center the trail text
        let trailStr = NSAttributedString(string: trail, attributes: trailAttrs)
        let trailWidth = trailStr.size().width
        let trailX = (bounds.width - trailWidth) / 2
        trailStr.draw(at: NSPoint(x: trailX, y: trailY))

        // Render zzZ if sleeping
        if isSleeping {
            drawZzZ(spriteTopY: 4 + totalOffset)
        }
    }

    // MARK: - zzZ Rendering

    private func drawZzZ(spriteTopY: CGFloat) {
        let zzZChars = ["z", "Z", "z"]
        let baseX: CGFloat = bounds.width - 50
        let baseY: CGFloat = spriteTopY - 5

        for (i, ch) in zzZChars.enumerated() {
            let fi = CGFloat(i)
            let phase = zzZPhase + fi * 0.8
            let yOff = sin(phase) * 3 - fi * 10
            let alpha = max(0.2, 1.0 - fi * 0.25)
            let size: CGFloat = i == 1 ? 16 : 12

            let zzFont = NSFont(name: "Menlo", size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: zzFont,
                .foregroundColor: NSColor(white: 0.8, alpha: CGFloat(alpha))
            ]
            let str = NSAttributedString(string: ch, attributes: attrs)
            str.draw(at: NSPoint(x: baseX + fi * 12, y: baseY + yOff))
        }
    }

    // MARK: - Click Handling

    var onLeftClick: (() -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    var onDoubleClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
        } else {
            onLeftClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(event)
    }
}
