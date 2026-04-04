import AppKit

class UsageViewController: NSViewController {
    private var stackView: NSStackView!
    private var planLabel: NSTextField!
    private var syncButton: NSButton!
    private var fiveHourBar: UsageBarView!
    private var sevenDayBar: UsageBarView!
    private var opusBar: UsageBarView!
    private var sonnetBar: UsageBarView!
    private var extraLabel: NSTextField!
    private var refreshTimer: Timer?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 280))
        container.wantsLayer = true

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])

        // Header row with plan name + sync button
        let headerRow = NSStackView()
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 8

        planLabel = NSTextField(labelWithString: "Claude Code")
        planLabel.font = .boldSystemFont(ofSize: 14)
        planLabel.textColor = .labelColor
        headerRow.addArrangedSubview(planLabel)

        // Spacer
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerRow.addArrangedSubview(spacer)

        syncButton = NSButton(title: "Sync", target: self, action: #selector(syncClicked))
        syncButton.bezelStyle = .inline
        syncButton.font = .systemFont(ofSize: 11)
        syncButton.controlSize = .small
        headerRow.addArrangedSubview(syncButton)

        stackView.addArrangedSubview(headerRow)
        headerRow.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // 5-hour bar
        fiveHourBar = UsageBarView(title: "5-Hour Session")
        stackView.addArrangedSubview(fiveHourBar)
        fiveHourBar.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // 7-day bar
        sevenDayBar = UsageBarView(title: "7-Day Overall")
        stackView.addArrangedSubview(sevenDayBar)
        sevenDayBar.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // Opus bar (hidden by default)
        opusBar = UsageBarView(title: "7-Day Opus")
        opusBar.isHidden = true
        stackView.addArrangedSubview(opusBar)
        opusBar.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // Sonnet bar (hidden by default)
        sonnetBar = UsageBarView(title: "7-Day Sonnet")
        sonnetBar.isHidden = true
        stackView.addArrangedSubview(sonnetBar)
        sonnetBar.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // Extra usage label
        extraLabel = NSTextField(labelWithString: "")
        extraLabel.font = .systemFont(ofSize: 11)
        extraLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(extraLabel)

        self.view = container
    }

    @objc private func syncClicked() {
        syncButton.isEnabled = false
        syncButton.title = "..."
        Task {
            _ = await UsageAPI.shared.forceRefresh()
            await MainActor.run {
                self.refreshUsage()
                self.syncButton.isEnabled = true
                self.syncButton.title = "Sync"
            }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        refreshUsage()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshUsage()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        refreshTimer?.invalidate()
    }

    func refreshUsage() {
        Task {
            let result = await UsageAPI.shared.fetchUsageWithStatus()
            await MainActor.run {
                switch result {
                case .success(let usage):
                    self.updateUI(usage)
                    self.extraLabel.textColor = .secondaryLabelColor
                case .cached(let usage):
                    self.updateUI(usage)
                    if let err = UsageAPI.shared.lastError {
                        self.extraLabel.stringValue = "⚠ cached — \(err)"
                        self.extraLabel.textColor = .systemOrange
                    }
                case .error(let msg):
                    self.planLabel.stringValue = "Claude Code"
                    self.extraLabel.stringValue = "⚠ \(msg)"
                    self.extraLabel.textColor = .systemOrange
                }
            }
        }
    }

    private func updateUI(_ usage: UsageResponse) {
        // Plan name from credentials
        let plan = UsageAPI.shared.planInfo
        planLabel.stringValue = "Claude Code — \(plan.displayName)"

        // 5-hour session (utilization is 0-100 from API)
        if let fh = usage.fiveHour {
            let pct = fh.utilization ?? 0
            fiveHourBar.update(percentage: pct, resetTime: fh.resetsAt)
            fiveHourBar.isHidden = false
        }

        // 7-day overall
        if let sd = usage.sevenDay {
            let pct = sd.utilization ?? 0
            sevenDayBar.update(percentage: pct, resetTime: sd.resetsAt)
            sevenDayBar.isHidden = false
        }

        // 7-day Opus (only show if data exists)
        if let opus = usage.sevenDayOpus, opus.utilization != nil {
            opusBar.update(percentage: opus.utilization ?? 0, resetTime: opus.resetsAt)
            opusBar.isHidden = false
        } else {
            opusBar.isHidden = true
        }

        // 7-day Sonnet
        if let sonnet = usage.sevenDaySonnet, sonnet.utilization != nil {
            sonnetBar.update(percentage: sonnet.utilization ?? 0, resetTime: sonnet.resetsAt)
            sonnetBar.isHidden = false
        } else {
            sonnetBar.isHidden = true
        }

        // Extra usage
        if let extra = usage.extraUsage {
            if extra.isEnabled == true {
                if let used = extra.usedCredits, let limit = extra.monthlyLimit {
                    extraLabel.stringValue = String(format: "Extra usage: $%.2f / $%.2f", used, limit)
                } else {
                    extraLabel.stringValue = "Extra usage: enabled"
                }
            } else {
                extraLabel.stringValue = "Extra usage: disabled"
            }
        } else {
            extraLabel.stringValue = ""
        }

        // Resize popover to fit content
        let fittingHeight = stackView.fittingSize.height + 32
        view.frame.size.height = max(fittingHeight, 160)
        preferredContentSize = NSSize(width: 300, height: view.frame.size.height)
    }
}

// MARK: - Usage Bar View

class UsageBarView: NSView {
    private var titleLabel: NSTextField!
    private var percentLabel: NSTextField!
    private var resetLabel: NSTextField!
    private var barBackground: NSView!
    private var barFill: NSView!
    private var barWidthConstraint: NSLayoutConstraint!
    private var currentPercentage: Double = 0
    private var pulseTimer: Timer?

    convenience init(title: String) {
        self.init(frame: .zero)
        setup(title: title)
    }

    private func setup(title: String) {
        translatesAutoresizingMaskIntoConstraints = false

        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .labelColor

        percentLabel = NSTextField(labelWithString: "—")
        percentLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        percentLabel.textColor = .secondaryLabelColor
        percentLabel.alignment = .right

        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(percentLabel)
        addSubview(titleRow)

        barBackground = NSView()
        barBackground.wantsLayer = true
        barBackground.layer?.backgroundColor = NSColor(white: 0.3, alpha: 0.3).cgColor
        barBackground.layer?.cornerRadius = 4
        barBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(barBackground)

        barFill = NSView()
        barFill.wantsLayer = true
        barFill.layer?.cornerRadius = 4
        barFill.translatesAutoresizingMaskIntoConstraints = false
        barBackground.addSubview(barFill)

        resetLabel = NSTextField(labelWithString: "")
        resetLabel.font = .systemFont(ofSize: 10)
        resetLabel.textColor = .tertiaryLabelColor
        resetLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resetLabel)

        barWidthConstraint = barFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleRow.topAnchor.constraint(equalTo: topAnchor),
            titleRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleRow.trailingAnchor.constraint(equalTo: trailingAnchor),

            barBackground.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 4),
            barBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            barBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            barBackground.heightAnchor.constraint(equalToConstant: 8),

            barFill.topAnchor.constraint(equalTo: barBackground.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
            barFill.heightAnchor.constraint(equalTo: barBackground.heightAnchor),
            barWidthConstraint,

            resetLabel.topAnchor.constraint(equalTo: barBackground.bottomAnchor, constant: 2),
            resetLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            resetLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// percentage: 0-100 value directly from API (e.g. 9.0 means 9%)
    func update(percentage: Double, resetTime: String?) {
        self.currentPercentage = percentage
        percentLabel.stringValue = String(format: "%.0f%%", percentage)

        // Color: green < 50%, yellow 50-80%, red > 80%
        let color: NSColor
        if percentage < 50 {
            color = NSColor.systemGreen
        } else if percentage < 80 {
            color = NSColor.systemYellow
        } else {
            color = NSColor.systemRed
        }
        barFill.layer?.backgroundColor = color.cgColor

        // Bar fill ratio: percentage / 100
        let ratio = CGFloat(min(percentage, 100.0)) / 100.0
        let maxWidth = barBackground.bounds.width
        if maxWidth > 0 {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.4
                barWidthConstraint.animator().constant = maxWidth * ratio
            }
        } else {
            barWidthConstraint.constant = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                let w = self.barBackground.bounds.width
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.4
                    self.barWidthConstraint.animator().constant = w * ratio
                }
            }
        }

        if let rt = resetTime {
            resetLabel.stringValue = "Resets in \(formatResetTime(rt))"
        } else {
            resetLabel.stringValue = ""
        }

        if percentage > 80 {
            startPulse()
        } else {
            stopPulse()
        }
    }

    private func formatResetTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: isoString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: isoString)
        }
        guard let d = date else { return isoString }
        return formatRelative(d)
    }

    private func formatRelative(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "now" }
        let totalMinutes = Int(interval / 60)
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours < 24 { return "\(hours)h \(minutes)m" }
        let days = hours / 24
        let remainingHours = hours % 24
        return "\(days)d \(remainingHours)h"
    }

    private func startPulse() {
        guard pulseTimer == nil else { return }
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.5
                self.barFill.animator().alphaValue = 0.5
            }) {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.5
                    self.barFill.animator().alphaValue = 1.0
                }
            }
        }
    }

    private func stopPulse() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        barFill.alphaValue = 1.0
    }
}
