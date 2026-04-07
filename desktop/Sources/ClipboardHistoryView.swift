import AppKit

class ClipboardHistoryViewController: NSViewController {
    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var emptyLabel: NSTextField!

    var onCopy: (() -> Void)?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 350))
        container.wantsLayer = true

        // Header
        let header = NSView(frame: .zero)
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "Clipboard History")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let clearButton = NSButton(title: "Clear", target: self, action: #selector(clearHistory))
        clearButton.bezelStyle = .inline
        clearButton.font = NSFont.systemFont(ofSize: 11)
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(titleLabel)
        header.addSubview(clearButton)
        NSLayoutConstraint.activate([
            header.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            clearButton.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        // Scroll view with stack
        scrollView = NSScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = false

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let clipView = NSClipView()
        clipView.drawsBackground = false
        clipView.documentView = stackView
        scrollView.contentView = clipView

        // Empty state label
        emptyLabel = NSTextField(labelWithString: "No clipboard history yet.\nCopy something to get started!")
        emptyLabel.font = NSFont.systemFont(ofSize: 11)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.maximumNumberOfLines = 2
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(header)
        container.addSubview(scrollView)
        container.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            stackView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: clipView.topAnchor),
            stackView.widthAnchor.constraint(equalTo: clipView.widthAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 10)
        ])

        self.view = container
    }

    func reload() {
        // Force view load if not yet loaded (prevents crash when called before popover shows)
        _ = self.view

        let history = ProductivityMonitor.shared.clipboardHistory
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        emptyLabel.isHidden = !history.isEmpty
        scrollView.isHidden = history.isEmpty

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        for (index, entry) in history.enumerated() {
            let row = ClipboardHistoryRow(
                index: index,
                time: timeFmt.string(from: entry.date),
                text: entry.text,
                target: self,
                action: #selector(rowClicked(_:))
            )
            stackView.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }
    }

    @objc private func rowClicked(_ sender: NSGestureRecognizer) {
        guard let row = sender.view as? ClipboardHistoryRow else { return }
        ProductivityMonitor.shared.copyFromHistory(at: row.index)
        onCopy?()
    }

    @objc private func clearHistory() {
        ProductivityMonitor.shared.clearClipboardHistory()
        reload()
    }
}

// MARK: - Row View

class ClipboardHistoryRow: NSView {
    let index: Int
    private var trackingArea: NSTrackingArea?
    private var isHovered = false

    init(index: Int, time: String, text: String, target: AnyObject, action: Selector) {
        self.index = index
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        let timeLabel = NSTextField(labelWithString: time)
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Truncate and clean text for preview
        let preview = text
            .components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        let truncated = preview.count > 80 ? String(preview.prefix(77)) + "..." : preview

        let textLabel = NSTextField(labelWithString: truncated)
        textLabel.font = NSFont.systemFont(ofSize: 11)
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.maximumNumberOfLines = 1
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(timeLabel)
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 26),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Click gesture
        let click = NSClickGestureRecognizer(target: target, action: action)
        addGestureRecognizer(click)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        layer?.backgroundColor = NSColor(white: 0.5, alpha: 0.1).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        layer?.backgroundColor = nil
    }
}
