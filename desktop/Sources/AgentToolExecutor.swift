import Foundation

// MARK: - Agent Tool Executor (sandboxed tool implementations)

enum AgentToolExecutor {

    private static let maxOutputBytes = 4096

    /// Validate and resolve a relative path within the project sandbox
    static func sandboxedPath(_ relative: String, projectDir: String) -> String? {
        // Prevent absolute paths and traversal
        let cleaned = relative.replacingOccurrences(of: "../", with: "")
        guard !cleaned.hasPrefix("/") else { return nil }

        let resolved = (projectDir as NSString).appendingPathComponent(cleaned)
        let canonical = (resolved as NSString).standardizingPath

        // Must stay within project dir
        guard canonical.hasPrefix((projectDir as NSString).standardizingPath) else { return nil }
        return canonical
    }

    static func execute(name: String, args: [String: Any], projectDir: String) async -> String {
        switch name {
        case "read_file":
            return readFile(args: args, projectDir: projectDir)
        case "write_file":
            return writeFile(args: args, projectDir: projectDir)
        case "list_files":
            return listFiles(args: args, projectDir: projectDir)
        case "search_code":
            return searchCode(args: args, projectDir: projectDir)
        case "run_command":
            return await runCommand(args: args, projectDir: projectDir)
        default:
            return "Unknown tool: \(name)"
        }
    }

    // MARK: - Tool Implementations

    private static func readFile(args: [String: Any], projectDir: String) -> String {
        guard let path = args["path"] as? String,
              let resolved = sandboxedPath(path, projectDir: projectDir) else {
            return "Error: invalid path"
        }
        guard let content = try? String(contentsOfFile: resolved, encoding: .utf8) else {
            return "Error: cannot read file"
        }
        return truncate(content)
    }

    private static func writeFile(args: [String: Any], projectDir: String) -> String {
        guard let path = args["path"] as? String,
              let content = args["content"] as? String,
              let resolved = sandboxedPath(path, projectDir: projectDir) else {
            return "Error: invalid path or missing content"
        }

        // Create parent directories if needed
        let dir = (resolved as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        do {
            try content.write(toFile: resolved, atomically: true, encoding: .utf8)
            return "OK: wrote \(content.count) bytes to \(path)"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    private static func listFiles(args: [String: Any], projectDir: String) -> String {
        let path = args["path"] as? String ?? "."
        guard let resolved = sandboxedPath(path, projectDir: projectDir) else {
            return "Error: invalid path"
        }
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: resolved) else {
            return "Error: cannot list directory"
        }
        let filtered = items.filter { !$0.hasPrefix(".") }
        return truncate(filtered.joined(separator: "\n"))
    }

    private static func searchCode(args: [String: Any], projectDir: String) -> String {
        guard let pattern = args["pattern"] as? String else {
            return "Error: missing pattern"
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/grep")
        process.arguments = ["-rl", "--include=*.swift", "--include=*.ts", "--include=*.js",
                            "--include=*.py", "--include=*.rs", "--include=*.go",
                            "--include=*.json", "--include=*.toml", "--include=*.yaml",
                            "-e", pattern, projectDir]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            // Make paths relative
            let relative = output.replacingOccurrences(of: projectDir + "/", with: "")
            return truncate(relative.isEmpty ? "No matches found" : relative)
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    private static func runCommand(args: [String: Any], projectDir: String) async -> String {
        guard let command = args["command"] as? String else {
            return "Error: missing command"
        }

        // Allowlist of safe commands
        let allowedPrefixes = ["swift build", "swift test", "npm test", "npm run",
                               "cargo build", "cargo test", "go build", "go test",
                               "python -m pytest", "git status", "git log", "git diff",
                               "ls", "cat", "wc", "head", "tail", "find"]

        let isAllowed = allowedPrefixes.contains { command.hasPrefix($0) }
        guard isAllowed else {
            return "Error: command not allowed. Allowed: \(allowedPrefixes.joined(separator: ", "))"
        }

        let process = Process()
        let pipe = Pipe()
        let errPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = URL(fileURLWithPath: projectDir)
        process.standardOutput = pipe
        process.standardError = errPipe

        do {
            try process.run()

            // Timeout: 30 seconds
            let deadline = DispatchTime.now() + 30
            DispatchQueue.global().asyncAfter(deadline: deadline) {
                if process.isRunning { process.terminate() }
            }

            process.waitUntilExit()
            let outData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(data: outData, encoding: .utf8) ?? ""
            let stderr = String(data: errData, encoding: .utf8) ?? ""

            let exitCode = process.terminationStatus
            var result = "Exit code: \(exitCode)\n"
            if !stdout.isEmpty { result += "stdout:\n\(stdout)\n" }
            if !stderr.isEmpty { result += "stderr:\n\(stderr)\n" }
            return truncate(result)
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private static func truncate(_ text: String) -> String {
        if text.utf8.count <= maxOutputBytes { return text }
        let truncated = String(text.prefix(maxOutputBytes))
        return truncated + "\n... (truncated at \(maxOutputBytes) bytes)"
    }
}
