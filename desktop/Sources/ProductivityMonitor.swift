import AppKit
import CoreServices

// MARK: - ProjectContext

struct ProjectContext {
    let directoryName: String
    let gitBranch: String
    let detectedLanguage: String

    func toDict() -> [String: String] {
        return [
            "project": directoryName,
            "gitBranch": gitBranch,
            "projectLanguage": detectedLanguage
        ]
    }
}

// MARK: - DailyActivityLog

class DailyActivityLog {
    static let shared = DailyActivityLog()

    private let logPath: String
    private(set) var date: String = ""
    private(set) var commitCount: Int = 0
    private(set) var branchSwitches: Int = 0
    private(set) var claudeSessionCount: Int = 0
    private(set) var codingStorms: Int = 0
    private(set) var firstActivityTime: String? = nil

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        logPath = "\(home)/.claude/buddy-daily-log.json"
        load()
    }

    func logEvent(_ event: String) {
        checkDayReset()
        if firstActivityTime == nil {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            firstActivityTime = fmt.string(from: Date())
        }
        switch event {
        case "commit": commitCount += 1
        case "branch_switch": branchSwitches += 1
        case "session_start": claudeSessionCount += 1
        case "coding_storm": codingStorms += 1
        default: break
        }
        save()
    }

    func dailySummaryText() -> String {
        let parts: [String] = [
            "\(commitCount) commit\(commitCount == 1 ? "" : "s")",
            "\(claudeSessionCount) session\(claudeSessionCount == 1 ? "" : "s")",
            firstActivityTime.map { "started at \($0)" } ?? ""
        ].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    private func checkDayReset() {
        let today = todayString()
        if date != today {
            date = today
            commitCount = 0
            branchSwitches = 0
            claudeSessionCount = 0
            codingStorms = 0
            firstActivityTime = nil
        }
    }

    private func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private func load() {
        guard let data = FileManager.default.contents(atPath: logPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            date = todayString()
            return
        }
        let savedDate = json["date"] as? String ?? ""
        if savedDate == todayString() {
            date = savedDate
            commitCount = json["commitCount"] as? Int ?? 0
            branchSwitches = json["branchSwitches"] as? Int ?? 0
            claudeSessionCount = json["claudeSessionCount"] as? Int ?? 0
            codingStorms = json["codingStorms"] as? Int ?? 0
            firstActivityTime = json["firstActivityTime"] as? String
        } else {
            date = todayString()
        }
    }

    private func save() {
        let dict: [String: Any] = [
            "date": date,
            "commitCount": commitCount,
            "branchSwitches": branchSwitches,
            "claudeSessionCount": claudeSessionCount,
            "codingStorms": codingStorms,
            "firstActivityTime": firstActivityTime ?? ""
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            try? data.write(to: URL(fileURLWithPath: logPath))
        }
    }
}

class ProductivityMonitor {
    static let shared = ProductivityMonitor()

    private var gitWatcher: DispatchSourceFileSystemObject?
    private var clipboardTimer: Timer?
    private var lastClipboardCount: Int = 0
    private var lastGitHead: String = ""
    private var gitDir: String?

    // Active window monitoring
    private var windowObserver: NSObjectProtocol?
    private var lastWindowReactionTime: Date = .distantPast

    // File system monitoring
    private var fsEventStream: FSEventStreamRef?
    private var fsChangeCount: Int = 0
    private var fsBatchTimer: Timer?
    private var lastFSReactionTime: Date = .distantPast
    private(set) var watchedProjectDir: String?
    var currentProjectDir: String? { watchedProjectDir }

    // Claude Code hook monitoring
    private var hookFileWatcher: DispatchSourceFileSystemObject?
    private var lastHookEventTime: Date = .distantPast
    private var lastHookProcessedTimestamp: Double = 0

    var onGitEvent: ((String) -> Void)?      // "commit", "push", "conflict", "branch_switch"
    var onClipboardEvent: ((String) -> Void)  // "large_paste", "code_copy"
    var onActiveWindowEvent: ((String, String) -> Void)?  // (category, appName)
    var onFileSystemEvent: ((String) -> Void)?  // "coding_storm", "lots_of_changes", "file_activity"
    var onClaudeCodeEvent: ((String, String) -> Void)?  // (category, detail)

    init() {
        onClipboardEvent = { _ in }
    }

    func start() {
        findGitDir()
        startGitWatcher()
        startClipboardMonitor()
        startActiveWindowMonitor()
        startFileSystemWatcher()
        startHookFileWatcher()
    }

    func stop() {
        gitWatcher?.cancel()
        gitWatcher = nil
        clipboardTimer?.invalidate()
        clipboardTimer = nil

        if let observer = windowObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            windowObserver = nil
        }

        stopFileSystemWatcher()
        fsBatchTimer?.invalidate()
        fsBatchTimer = nil

        hookFileWatcher?.cancel()
        hookFileWatcher = nil
    }

    // MARK: - Project Context

    func getProjectContext() -> ProjectContext {
        let dirName: String
        if let dir = watchedProjectDir {
            dirName = (dir as NSString).lastPathComponent
        } else {
            dirName = "unknown"
        }

        var branch = "unknown"
        if let gd = gitDir {
            let headPath = "\(gd)/HEAD"
            if let headContent = try? String(contentsOfFile: headPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
                if headContent.hasPrefix("ref: refs/heads/") {
                    branch = String(headContent.dropFirst("ref: refs/heads/".count))
                } else if headContent.count >= 7 {
                    branch = String(headContent.prefix(7))
                }
            }
        }

        let lang = detectProjectLanguage()
        return ProjectContext(directoryName: dirName, gitBranch: branch, detectedLanguage: lang)
    }

    private func detectProjectLanguage() -> String {
        guard let dir = watchedProjectDir else { return "unknown" }
        let fm = FileManager.default
        let checks: [(String, String)] = [
            ("Package.swift", "Swift"),
            ("package.json", "TypeScript/JavaScript"),
            ("Cargo.toml", "Rust"),
            ("go.mod", "Go"),
            ("requirements.txt", "Python"),
            ("pyproject.toml", "Python"),
            ("Gemfile", "Ruby"),
            ("pom.xml", "Java"),
            ("build.gradle", "Kotlin/Java"),
            ("CMakeLists.txt", "C/C++")
        ]
        for (file, language) in checks {
            if fm.fileExists(atPath: "\(dir)/\(file)") {
                return language
            }
        }
        return "unknown"
    }

    // MARK: - Git Monitoring

    private func findGitDir() {
        // Look for .git in common locations
        let candidates = [
            FileManager.default.currentDirectoryPath,
            FileManager.default.homeDirectoryForCurrentUser.path
        ]

        for dir in candidates {
            let gitPath = "\(dir)/.git"
            if FileManager.default.fileExists(atPath: gitPath) {
                gitDir = gitPath
                return
            }
        }

        // Try to find via `git rev-parse`
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "rev-parse", "--git-dir"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                gitDir = path
            }
        } catch {}
    }

    private func startGitWatcher() {
        guard let gitDir = gitDir else { return }
        let headPath = "\(gitDir)/HEAD"

        guard FileManager.default.fileExists(atPath: headPath) else { return }

        // Read initial HEAD
        lastGitHead = (try? String(contentsOfFile: headPath, encoding: .utf8)) ?? ""

        let fd = open(headPath, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .global()
        )

        source.setEventHandler { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.checkGitChanges()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        gitWatcher = source
    }

    private func checkGitChanges() {
        guard let gitDir = gitDir else { return }
        let headPath = "\(gitDir)/HEAD"
        guard let newHead = try? String(contentsOfFile: headPath, encoding: .utf8) else { return }

        if newHead != lastGitHead {
            let oldHead = lastGitHead
            lastGitHead = newHead

            // Detect what changed
            if oldHead.contains("ref:") && newHead.contains("ref:") {
                let oldBranch = oldHead.split(separator: "/").last ?? ""
                let newBranch = newHead.split(separator: "/").last ?? ""
                if oldBranch != newBranch {
                    onGitEvent?("branch_switch")
                }
            } else {
                // HEAD changed to a commit hash - likely a commit
                onGitEvent?("commit")
            }
        }

        // Check for merge conflicts
        let mergeHeadPath = "\(gitDir)/MERGE_HEAD"
        if FileManager.default.fileExists(atPath: mergeHeadPath) {
            onGitEvent?("conflict")
        }
    }

    // MARK: - Clipboard Monitoring

    private func startClipboardMonitor() {
        lastClipboardCount = NSPasteboard.general.changeCount

        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func checkClipboard() {
        let current = NSPasteboard.general.changeCount
        guard current != lastClipboardCount else { return }
        lastClipboardCount = current

        guard let text = NSPasteboard.general.string(forType: .string) else { return }

        if text.count > 500 {
            onClipboardEvent("large_paste")
        } else if text.contains("func ") || text.contains("class ") || text.contains("import ") ||
                  text.contains("function ") || text.contains("const ") || text.contains("def ") {
            onClipboardEvent("code_copy")
        }
    }

    // MARK: - Git Reaction Messages

    static func reactionForGitEvent(_ event: String) -> String {
        switch event {
        case "commit":
            return BuddyL10n.gitCommit.randomElement()!
        case "conflict":
            return BuddyL10n.gitConflict.randomElement()!
        case "branch_switch":
            return BuddyL10n.gitBranchSwitch.randomElement()!
        case "push":
            return BuddyL10n.gitPush.randomElement()!
        default:
            return BuddyL10n.gitDefault
        }
    }

    static func reactionForClipboard(_ event: String) -> String {
        switch event {
        case "large_paste":
            return BuddyL10n.clipboardLargePaste.randomElement()!
        case "code_copy":
            return BuddyL10n.clipboardCodeCopy.randomElement()!
        default:
            return ""
        }
    }

    // MARK: - Active Window Monitoring

    private func startActiveWindowMonitor() {
        windowObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }

            // Debounce: max 1 reaction per 15s
            let now = Date()
            guard now.timeIntervalSince(self.lastWindowReactionTime) >= 15 else { return }
            self.lastWindowReactionTime = now

            let category = Self.categorizeApp(bundleId)
            let friendlyName = Self.friendlyAppName(bundleId, localizedName: app.localizedName)

            if category == "coding" {
                MoodEnergySystem.shared.noteActivity()
            }

            self.onActiveWindowEvent?(category, friendlyName)
        }
    }

    private static let codingBundleIds: Set<String> = [
        "com.microsoft.VSCode", "com.microsoft.VSCodeInsiders",
        "com.apple.dt.Xcode",
        "com.apple.Terminal", "com.googlecode.iterm2", "dev.warp.Warp-Stable",
        "com.todesktop.230313mzl4w4u92"  // Claude Code desktop
    ]

    private static let browserBundleIds: Set<String> = [
        "com.apple.Safari", "com.google.Chrome", "company.thebrowser.Browser",
        "org.mozilla.firefox", "com.brave.Browser", "com.microsoft.edgemac"
    ]

    static func categorizeApp(_ bundleId: String) -> String {
        if codingBundleIds.contains(bundleId) { return "coding" }
        if browserBundleIds.contains(bundleId) { return "browser" }
        return "other"
    }

    static func friendlyAppName(_ bundleId: String, localizedName: String?) -> String {
        let mapping: [String: String] = [
            "com.microsoft.VSCode": "VS Code",
            "com.microsoft.VSCodeInsiders": "VS Code Insiders",
            "com.apple.dt.Xcode": "Xcode",
            "com.apple.Terminal": "Terminal",
            "com.googlecode.iterm2": "iTerm2",
            "dev.warp.Warp-Stable": "Warp",
            "com.todesktop.230313mzl4w4u92": "Claude Code",
            "com.apple.Safari": "Safari",
            "com.google.Chrome": "Chrome",
            "company.thebrowser.Browser": "Arc",
        ]
        return mapping[bundleId] ?? localizedName ?? bundleId.components(separatedBy: ".").last ?? bundleId
    }

    static func reactionForWindowEvent(_ category: String, appName: String) -> String {
        switch category {
        case "coding":
            return BuddyL10n.windowCodingInApp(appName)
        case "browser":
            return BuddyL10n.windowBrowser.randomElement()!
        default:
            return BuddyL10n.windowOtherApp.randomElement()!
        }
    }

    // MARK: - File System Watcher (FSEvents)

    private func startFileSystemWatcher() {
        // Detect project dir from git dir
        if let gd = gitDir {
            let resolved = gd.hasSuffix("/.git") ? String(gd.dropLast(5)) : gd
            watchedProjectDir = resolved
        } else {
            // Fallback: watch home directory src paths
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let candidates = ["\(home)/Documents", "\(home)/Projects", "\(home)/Developer", "\(home)/src"]
            for c in candidates {
                if FileManager.default.fileExists(atPath: c) {
                    watchedProjectDir = c
                    break
                }
            }
        }

        guard let dir = watchedProjectDir else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [dir] as CFArray
        let flags: FSEventStreamCreateFlags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)

        guard let stream = FSEventStreamCreate(
            nil,
            { (_, info, numEvents, eventPaths, _, _) in
                guard let info = info else { return }
                let monitor = Unmanaged<ProductivityMonitor>.fromOpaque(info).takeUnretainedValue()
                guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }

                var validCount = 0
                for path in paths {
                    if !monitor.shouldFilterPath(path) {
                        validCount += 1
                    }
                }

                if validCount > 0 {
                    DispatchQueue.main.async {
                        monitor.fsChangeCount += validCount
                        monitor.scheduleFSBatch()
                    }
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            2.0,  // 2 second latency for batching
            flags
        ) else { return }

        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
        fsEventStream = stream
    }

    private func stopFileSystemWatcher() {
        guard let stream = fsEventStream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        fsEventStream = nil
    }

    private func shouldFilterPath(_ path: String) -> Bool {
        let filters = ["/.git/", "/.build/", "/node_modules/", "/.DS_Store", "/.swiftpm/"]
        return filters.contains { path.contains($0) }
    }

    private func scheduleFSBatch() {
        // Debounce: batch changes over 2s window
        if fsBatchTimer == nil {
            fsBatchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.processFSBatch()
            }
        }
    }

    private func processFSBatch() {
        fsBatchTimer = nil
        let count = fsChangeCount
        fsChangeCount = 0

        guard count > 0 else { return }

        // Debounce: max 1 reaction per 20s
        let now = Date()
        guard now.timeIntervalSince(lastFSReactionTime) >= 20 else { return }
        lastFSReactionTime = now

        let intensity: String
        if count >= 10 {
            intensity = "coding_storm"
        } else if count >= 5 {
            intensity = "lots_of_changes"
        } else {
            intensity = "file_activity"
        }

        MoodEnergySystem.shared.noteActivity()
        onFileSystemEvent?(intensity)
    }

    static func reactionForFSEvent(_ intensity: String) -> String {
        switch intensity {
        case "coding_storm":
            return BuddyL10n.fsCodingStorm.randomElement()!
        case "lots_of_changes":
            return BuddyL10n.fsLotsOfChanges.randomElement()!
        default:
            return BuddyL10n.fsFileActivity.randomElement()!
        }
    }

    // MARK: - Claude Code Hook Event Watcher

    private func startHookFileWatcher() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let eventsPath = "\(home)/.claude/buddy-events.json"

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: eventsPath) {
            FileManager.default.createFile(atPath: eventsPath, contents: "[]".data(using: .utf8))
        }

        let fd = open(eventsPath, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .global()
        )

        source.setEventHandler { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.processHookEvents()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        hookFileWatcher = source
    }

    private func processHookEvents() {
        // Debounce: max 1 reaction per 10s
        let now = Date()
        guard now.timeIntervalSince(lastHookEventTime) >= 10 else { return }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let eventsPath = "\(home)/.claude/buddy-events.json"

        guard let data = FileManager.default.contents(atPath: eventsPath),
              let events = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }

        // Find new events since last processed timestamp
        var latestEvent: [String: Any]?
        for event in events {
            if let ts = event["timestamp"] as? Double, ts > lastHookProcessedTimestamp {
                latestEvent = event
                lastHookProcessedTimestamp = ts
            }
        }

        guard let event = latestEvent,
              let category = event["category"] as? String else { return }

        lastHookEventTime = now
        let detail = event["detail"] as? String ?? ""
        onClaudeCodeEvent?(category, detail)
    }

    static func reactionForHookEvent(_ category: String, detail: String = "") -> String {
        switch category {
        case "session_start":
            return BuddyL10n.hookSessionStart.randomElement()!
        case "session_end":
            return BuddyL10n.hookSessionEnd.randomElement()!
        case "running_tests":
            return BuddyL10n.hookRunningTests.randomElement()!
        case "building":
            return BuddyL10n.hookBuilding.randomElement()!
        case "running_command":
            return BuddyL10n.hookRunningCommand.randomElement()!
        case "writing_code":
            if !detail.isEmpty && detail != "Write" && detail != "Edit" {
                let hu = BuddyL10n.current == "hu"
                return hu ? "Claude \(detail)-tel dolgozik!" : "Claude using \(detail)!"
            }
            return BuddyL10n.hookWritingCode.randomElement()!
        default:
            return ""
        }
    }
}
