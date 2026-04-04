import AppKit

class BuddyPanel: NSPanel {
    private let posXKey = "buddyPanelX"
    private let posYKey = "buddyPanelY"

    init() {
        let savedX = UserDefaults.standard.double(forKey: posXKey)
        let savedY = UserDefaults.standard.double(forKey: posYKey)

        let width: CGFloat = 250
        let height: CGFloat = 250

        let origin: NSPoint
        if savedX != 0 || savedY != 0 {
            origin = NSPoint(x: savedX, y: savedY)
        } else {
            if let screen = NSScreen.main {
                let sf = screen.visibleFrame
                origin = NSPoint(x: sf.maxX - width - 40, y: sf.minY + 40)
            } else {
                origin = NSPoint(x: 800, y: 100)
            }
        }

        let frame = NSRect(origin: origin, size: NSSize(width: width, height: height))

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    @objc private func windowDidMove(_ notification: Notification) {
        savePosition()
        checkScreenEdgeBounce()
    }

    func savePosition() {
        UserDefaults.standard.set(frame.origin.x, forKey: posXKey)
        UserDefaults.standard.set(frame.origin.y, forKey: posYKey)
    }

    func animateMove(to point: NSPoint, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrameOrigin(point)
        } completionHandler: { [weak self] in
            self?.savePosition()
        }
    }

    // MARK: - Physics Bounce on Drop

    private func checkScreenEdgeBounce() {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        var origin = frame.origin
        var bounced = false

        // Snap to screen edges with bounce
        if origin.x < sf.minX {
            origin.x = sf.minX
            bounced = true
        }
        if origin.x + frame.width > sf.maxX {
            origin.x = sf.maxX - frame.width
            bounced = true
        }
        if origin.y < sf.minY {
            origin.y = sf.minY
            bounced = true
        }
        if origin.y + frame.height > sf.maxY {
            origin.y = sf.maxY - frame.height
            bounced = true
        }

        if bounced {
            // Bounce animation
            let overshoot = NSPoint(
                x: origin.x + (frame.origin.x < sf.minX ? -5 : frame.origin.x + frame.width > sf.maxX ? 5 : 0),
                y: origin.y + (frame.origin.y < sf.minY ? -5 : frame.origin.y + frame.height > sf.maxY ? 5 : 0)
            )

            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.1
                self.animator().setFrameOrigin(overshoot)
            }) {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.2
                    ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.animator().setFrameOrigin(origin)
                }) { [weak self] in
                    self?.savePosition()
                }
            }
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
