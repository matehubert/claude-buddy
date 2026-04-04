import AppKit

class ProductivityMonitor {
    static let shared = ProductivityMonitor()

    private var gitWatcher: DispatchSourceFileSystemObject?
    private var clipboardTimer: Timer?
    private var lastClipboardCount: Int = 0
    private var lastGitHead: String = ""
    private var gitDir: String?

    var onGitEvent: ((String) -> Void)?      // "commit", "push", "conflict", "branch_switch"
    var onClipboardEvent: ((String) -> Void)  // "large_paste", "code_copy"

    init() {
        onClipboardEvent = { _ in }
    }

    func start() {
        findGitDir()
        startGitWatcher()
        startClipboardMonitor()
    }

    func stop() {
        gitWatcher?.cancel()
        gitWatcher = nil
        clipboardTimer?.invalidate()
        clipboardTimer = nil
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
}
