import Foundation

// MARK: - Buddy Soul (persisted in buddy.json)

struct BuddySoul: Codable {
    var name: String
    var personality: String
    var hatchDate: String
    var muted: Bool
    var hidden: Bool
    var customEye: String?
    var customHat: String?

    // Language (auto-detected or user-set; nil = auto-detect from system locale)
    var language: String?

    // Mood/Energy (optional for backward compat)
    var mood: String?
    var energy: Int?
    var streak: Int?
    var achievements: [String]?
    var feedCount: Int?
    var petCount: Int?
    var playCount: Int?
    var lastInteraction: Double?
}

// MARK: - Buddy Bones (generated from buddy.mjs card command)

struct BuddyBones: Codable {
    var species: String
    var rarity: String
    var eye: String
    var hat: String
    var shiny: Bool
    var stats: [String: Int]
    var name: String
}

struct BuddyCardResult: Codable {
    var action: String
    var bones: BuddyBones?
    var soul: BuddySoul?
    var rendered: String?
    var reaction: String?
}

// MARK: - Sprite Data (embedded, matching buddy.mjs)

struct SpriteData {
    static let sprites: [String: [String]] = [
        "duck": [
            "            ",
            "    __      ",
            "  <({E} )___  ",
            "   (  ._>   ",
            "    `--´    "
        ],
        "goose": [
            "            ",
            "     ({E}>    ",
            "     ||     ",
            "   _(__)_   ",
            "    ^^^^    "
        ],
        "blob": [
            "            ",
            "   .----.   ",
            "  ( {E}  {E} )  ",
            "  (      )  ",
            "   `----´   "
        ],
        "cat": [
            "            ",
            "   /\\_/\\    ",
            "  ( {E}   {E})  ",
            "  (  ω  )   ",
            "  (\")_(\")   "
        ],
        "dragon": [
            "            ",
            "  /^\\  /^\\  ",
            " <  {E}  {E}  > ",
            " (   ~~   ) ",
            "  `-vvvv-´  "
        ],
        "octopus": [
            "            ",
            "   .----.   ",
            "  ( {E}  {E} )  ",
            "  (______)  ",
            "  /\\/\\/\\/\\  "
        ],
        "owl": [
            "            ",
            "   /\\  /\\   ",
            "  (({E})({E}))  ",
            "  (  ><  )  ",
            "   `----´   "
        ],
        "penguin": [
            "            ",
            "  .---.     ",
            "  ({E}>{E})     ",
            " /(   )\\    ",
            "  `---´     "
        ],
        "turtle": [
            "            ",
            "   _,--._   ",
            "  ( {E}  {E} )  ",
            " /[______]\\ ",
            "  ``    ``  "
        ],
        "snail": [
            "            ",
            " {E}    .--.  ",
            "  \\  ( @ )  ",
            "   \\_`--´   ",
            "  ~~~~~~~   "
        ],
        "ghost": [
            "            ",
            "   .----.   ",
            "  / {E}  {E} \\  ",
            "  |      |  ",
            "  ~`~``~`~  "
        ],
        "axolotl": [
            "            ",
            "}~(______)~{",
            "}~({E} .. {E})~{",
            "  ( .--. )  ",
            "  (_/  \\_)  "
        ],
        "capybara": [
            "            ",
            "  n______n  ",
            " ( {E}    {E} ) ",
            " (   oo   ) ",
            "  `------´  "
        ],
        "cactus": [
            "            ",
            " n  ____  n ",
            " | |{E}  {E}| | ",
            " |_|    |_| ",
            "   |    |   "
        ],
        "robot": [
            "            ",
            "   .[||].   ",
            "  [ {E}  {E} ]  ",
            "  [ ==== ]  ",
            "  `------´  "
        ],
        "rabbit": [
            "            ",
            "   (\\__/)   ",
            "  ( {E}  {E} )  ",
            " =(  ..  )= ",
            "  (\")__(\")" + "  "
        ],
        "mushroom": [
            "            ",
            " .-o-OO-o-. ",
            "(__________)",
            "   |{E}  {E}|   ",
            "   |____|   "
        ],
        "chonk": [
            "            ",
            "  /\\    /\\  ",
            " ( {E}    {E} ) ",
            " (   ..   ) ",
            "  `------´  "
        ]
    ]

    // Hat symbol patterns (unpadded)
    static let hatSymbols: [String: String] = [
        "crown":     "\\^^^/",
        "tophat":    "[___]",
        "propeller": "-+-",
        "halo":      "(   )",
        "wizard":    "/^\\",
        "beanie":    "(___)",
        "tinyduck":  ",>"
    ]

    // Head center X position per species (0-indexed in 12-char line)
    static let headCenter: [String: Int] = [
        "duck":     5,     //     __
        "goose":    6,     //      (·>
        "blob":     6,     //    .----.
        "cat":      5,     //    /\_/\
        "dragon":   5,     //   /^\  /^\
        "octopus":  6,     //    .----.
        "owl":      5,     //    /\  /\
        "penguin":  4,     //   .---.
        "turtle":   6,     //    _,--._
        "snail":    7,     //  ·    .--.
        "ghost":    6,     //    .----.
        "axolotl":  6,     //  }~(______)~{
        "capybara": 6,     //   n______n
        "cactus":   6,     //  n  ____  n
        "robot":    6,     //    .[||].
        "rabbit":   6,     //    (\__/)
        "mushroom": 6,     //  .-o-OO-o-.
        "chonk":    6      //   /\    /\
    ]

    static func renderHatLine(hat: String, species: String, lineWidth: Int = 12) -> String {
        guard let symbol = hatSymbols[hat] else {
            return String(repeating: " ", count: lineWidth)
        }
        let center = headCenter[species] ?? 6
        let startPos = max(0, center - symbol.count / 2)

        var line = Array(repeating: Character(" "), count: lineWidth)
        for (i, ch) in symbol.enumerated() {
            let pos = startPos + i
            if pos < lineWidth {
                line[pos] = ch
            }
        }
        return String(line)
    }

    static func renderSprite(species: String, eye: String, hat: String) -> [String] {
        guard let template = sprites[species] else { return ["???"] }
        var lines = template.map { $0.replacingOccurrences(of: "{E}", with: eye) }
        if hat != "none" {
            lines[0] = renderHatLine(hat: hat, species: species)
        }
        return lines
    }
}

// MARK: - Node.js Path Resolution

/// Finds the absolute path to `node` binary.
/// LaunchAgent apps don't inherit the user's shell PATH (nvm, homebrew etc),
/// so we search common locations.
func resolveNodePath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    // Check nvm — find latest installed version
    let nvmBase = "\(home)/.nvm/versions/node"
    if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmBase) {
        let sorted = versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        for v in sorted {
            let path = "\(nvmBase)/\(v)/bin/node"
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
    }

    // Check fnm
    let fnmBase = "\(home)/.local/share/fnm/node-versions"
    if let versions = try? FileManager.default.contentsOfDirectory(atPath: fnmBase) {
        let sorted = versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        for v in sorted {
            let path = "\(fnmBase)/\(v)/installation/bin/node"
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
    }

    // Check fixed paths
    for path in ["/usr/local/bin/node", "/opt/homebrew/bin/node", "/usr/bin/node"] {
        if FileManager.default.isExecutableFile(atPath: path) { return path }
    }

    // Fallback — hope it's in PATH
    return "/usr/bin/env"
}

/// Cached node path (resolved once at launch)
let nodePath: String = resolveNodePath()

/// Arguments to run a node script — uses absolute path to node
func nodeArgs(script: String, args: [String] = []) -> (executable: String, arguments: [String]) {
    if nodePath.hasSuffix("/env") {
        return (nodePath, ["node", script] + args)
    } else {
        return (nodePath, [script] + args)
    }
}

// MARK: - BuddyData Manager

class BuddyData {
    static let shared = BuddyData()

    private let soulPath: String
    private let buddyMjsPath: String
    private var fileMonitor: DispatchSourceFileSystemObject?

    var soul: BuddySoul?
    var bones: BuddyBones?
    var spriteLines: [String] = []
    var onUpdate: (() -> Void)?

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        soulPath = "\(home)/.claude/buddy.json"
        buddyMjsPath = "\(home)/.claude/skills/buddy/buddy.mjs"
        reload()
        watchFile()
    }

    func reload() {
        loadSoul()
        loadBones()
        if let b = bones {
            spriteLines = SpriteData.renderSprite(species: b.species, eye: b.eye, hat: b.hat)
        }
        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?()
        }
    }

    private func loadSoul() {
        guard let data = FileManager.default.contents(atPath: soulPath),
              let parsed = try? JSONDecoder().decode(BuddySoul.self, from: data) else {
            soul = nil
            return
        }
        soul = parsed
    }

    private func loadBones() {
        // Run buddy.mjs card to get bones data
        let process = Process()
        let pipe = Pipe()

        let cmd = nodeArgs(script: buddyMjsPath, args: ["card"])
        process.executableURL = URL(fileURLWithPath: cmd.executable)
        process.arguments = cmd.arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = try? JSONDecoder().decode(BuddyCardResult.self, from: data) {
                bones = result.bones
            }
        } catch {
            // If buddy.mjs fails, try to infer from soul
            bones = nil
        }
    }

    private func watchFile() {
        let fd = open(soulPath, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .global()
        )
        source.setEventHandler { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.reload()
            }
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        fileMonitor = source
    }

    // Pet action via buddy.mjs
    func pet(completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            let pipe = Pipe()

            let cmd = nodeArgs(script: self.buddyMjsPath, args: ["pet"])
            process.executableURL = URL(fileURLWithPath: cmd.executable)
            process.arguments = cmd.arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let result = try? JSONDecoder().decode(BuddyCardResult.self, from: data) {
                    DispatchQueue.main.async {
                        completion(result.reaction)
                    }
                } else {
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    // React action via buddy.mjs
    func react(reason: String = "turn", completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            let pipe = Pipe()

            let cmd = nodeArgs(script: self.buddyMjsPath, args: ["react", reason])
            process.executableURL = URL(fileURLWithPath: cmd.executable)
            process.arguments = cmd.arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let reaction = json["reaction"] as? String {
                    DispatchQueue.main.async { completion(reaction) }
                } else {
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
