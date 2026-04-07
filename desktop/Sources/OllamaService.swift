import Foundation

// MARK: - Ollama Service (Local LLM via Ollama)

actor OllamaService {
    static let shared = OllamaService()

    private var baseURL = "http://localhost:11434"
    private var model = "qwen3-coder:30b"

    struct Config {
        var baseURL: String?
        var model: String?
    }

    func configure(_ config: Config) {
        if let url = config.baseURL { baseURL = url }
        if let m = config.model { model = m }
    }

    func isAvailable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Simple Reaction (max 150 tokens, ~2-3s)

    func react(systemPrompt: String, userMessage: String) async -> String? {
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userMessage]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": false,
            "options": ["num_predict": 150]
        ]

        return await chatRequest(body: body)
    }

    // MARK: - Agent Loop (tool calling)

    func executeAgent(systemPrompt: String, task: String, projectDir: String) async -> String {
        let tools = agentToolDefinitions()

        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": task]
        ]

        let maxIterations = 10
        let deadline = Date().addingTimeInterval(60)

        for _ in 0..<maxIterations {
            guard Date() < deadline else { break }

            let body: [String: Any] = [
                "model": model,
                "messages": messages,
                "stream": false,
                "tools": tools
            ]

            guard let url = URL(string: "\(baseURL)/api/chat") else { return "Error: invalid URL" }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
                return "Error: failed to serialize request"
            }
            request.httpBody = httpBody

            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = json["message"] as? [String: Any] else {
                    return "Error: invalid response"
                }

                // Check for tool calls
                if let toolCalls = message["tool_calls"] as? [[String: Any]], !toolCalls.isEmpty {
                    // Append assistant message with tool calls
                    messages.append(message)

                    // Execute each tool call
                    for tc in toolCalls {
                        guard let function = tc["function"] as? [String: Any],
                              let name = function["name"] as? String,
                              let args = function["arguments"] as? [String: Any] else { continue }

                        let result = await AgentToolExecutor.execute(
                            name: name,
                            args: args,
                            projectDir: projectDir
                        )

                        messages.append([
                            "role": "tool",
                            "content": result
                        ])
                    }
                    continue // Next iteration
                }

                // No tool calls — final text response
                if let content = message["content"] as? String, !content.isEmpty {
                    return content
                }
                return "Done (no response text)"

            } catch {
                return "Error: \(error.localizedDescription)"
            }
        }

        return "Agent reached iteration limit"
    }

    // MARK: - Helpers

    private func chatRequest(body: [String: Any]) async -> String? {
        guard let url = URL(string: "\(baseURL)/api/chat") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = json["message"] as? [String: Any],
                  let content = message["content"] as? String else { return nil }
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private func agentToolDefinitions() -> [[String: Any]] {
        return [
            toolDef("read_file", "Read contents of a file", [
                "path": ["type": "string", "description": "Relative path to file"]
            ]),
            toolDef("write_file", "Write contents to a file", [
                "path": ["type": "string", "description": "Relative path to file"],
                "content": ["type": "string", "description": "File content to write"]
            ]),
            toolDef("list_files", "List files in a directory", [
                "path": ["type": "string", "description": "Relative directory path (default: .)"]
            ]),
            toolDef("search_code", "Search for a pattern in project files", [
                "pattern": ["type": "string", "description": "Search pattern (grep-style)"]
            ]),
            toolDef("run_command", "Run a shell command (sandboxed)", [
                "command": ["type": "string", "description": "Command to run"]
            ])
        ]
    }

    private func toolDef(_ name: String, _ desc: String, _ props: [String: [String: String]]) -> [String: Any] {
        var required: [String] = []
        var properties: [String: Any] = [:]
        for (key, val) in props {
            properties[key] = val
            required.append(key)
        }
        return [
            "type": "function",
            "function": [
                "name": name,
                "description": desc,
                "parameters": [
                    "type": "object",
                    "properties": properties,
                    "required": required
                ]
            ]
        ]
    }
}
