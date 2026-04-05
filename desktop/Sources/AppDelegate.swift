import AppKit
import SceneKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var buddyPanel: BuddyPanel!
    private var renderer: BuddyRenderer!
    private var speechBubble: SpeechBubbleView!
    private var animationController: AnimationController!
    private var usagePopover: NSPopover!
    private var usageVC: UsageViewController!
    private var usageRefreshTimer: Timer?

    // Mouse tracking
    private var globalMouseMonitor: Any?
    private var globalHotkeyMonitor: Any?
    private var lastMousePos: NSPoint = .zero
    private var lastMouseMoveTime = Date()
    private var mouseNearby = false

    // Shake detection
    private var recentDragPositions: [(x: CGFloat, time: Date)] = []

    private let eyes = ["·", "✦", "×", "◉", "@", "°", "♥", "★", "◆", "~", "^", "ˇ"]
    private let hats = ["none", "crown", "tophat", "propeller", "halo", "wizard", "beanie", "tinyduck"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize language from soul or system locale
        BuddyL10n.setup(soul: BuddyData.shared.soul)

        // Load render mode preference (default: 2D ASCII)
        use3D = UserDefaults.standard.bool(forKey: "buddyUse3D")

        setupMenuBar()
        setupBuddyPanel()
        setupAnimations()
        loadBuddyData()
        setupMouseTracking()
        setupGlobalHotkey()
        setupSystems()

        // Start usage refresh for menu bar display (every 5 min)
        refreshMenuBarUsage()
        usageRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshMenuBarUsage()
        }

        // Periodic reaction (every 10 minutes)
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.fetchReaction()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.fetchReaction()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalHotkeyMonitor = nil
        }
        buddyPanel.savePosition()
        MoodEnergySystem.shared.saveToDisk()
    }

    // MARK: - System Setup

    private func setupSystems() {
        // Mood/Energy
        let mood = MoodEnergySystem.shared
        mood.onMoodChange = { [weak self] newMood in
            self?.animationController.applyMood()
            self?.animationController.showReaction(self?.moodText(newMood) ?? "")
        }
        mood.onAchievement = { [weak self] achievement in
            self?.renderer.triggerParticleEffect(.confetti)
            self?.animationController.showReaction(BuddyL10n.achievementUnlocked(achievement))
        }

        // Environment
        let env = EnvironmentAwareness.shared
        env.onTimeOfDayChange = { [weak self] time in
            self?.renderer.setTimeOfDay(time)
            self?.animationController.applyEnvironment()
        }
        env.onWeatherChange = { [weak self] weather in
            self?.animationController.applyEnvironment()
            if weather == "rain" {
                self?.animationController.showReaction(BuddyL10n.itsRaining)
            }
        }
        env.start()

        // Stat Growth callback
        MoodEnergySystem.shared.onStatGrowth = { [weak self] stat, amount in
            self?.animationController.showReaction(BuddyL10n.statGrowth(stat: stat, amount: amount))
        }

        // Pomodoro
        let pomo = PomodoroTimer.shared
        pomo.onTick = { [weak self] remaining, phase in
            guard let self = self else { return }
            let minutes = remaining / 60
            let seconds = remaining % 60
            let prefix = phase == .work ? BuddyL10n.pomodoroFocusPrefix : BuddyL10n.pomodoroBreakPrefix
            self.speechBubble.updateText("\(prefix) \(String(format: "%02d:%02d", minutes, seconds))")
        }
        pomo.onPhaseChange = { [weak self] phase in
            switch phase {
            case .work:
                self?.animationController.showReaction(BuddyL10n.pomodoroWork)
            case .shortBreak:
                self?.animationController.showReaction(BuddyL10n.pomodoroShortBreak)
            case .longBreak:
                self?.animationController.showReaction(BuddyL10n.pomodoroLongBreak)
            case .idle:
                break
            }
        }
        pomo.onComplete = { [weak self] phase in
            if phase == .work {
                self?.renderer.triggerParticleEffect(.confetti)
                MoodEnergySystem.shared.incrementStat("PATIENCE", by: 2)
            }
        }

        // Productivity Monitor
        let prod = ProductivityMonitor.shared
        prod.onGitEvent = { [weak self] event in
            let msg = ProductivityMonitor.reactionForGitEvent(event)
            self?.animationController.showReaction(msg)
            switch event {
            case "commit":       MoodEnergySystem.shared.incrementStat("DEBUGGING", by: 1)
            case "conflict":     MoodEnergySystem.shared.incrementStat("DEBUGGING", by: 2)
            case "branch_switch": MoodEnergySystem.shared.incrementStat("CHAOS", by: 1)
            default: break
            }
        }
        prod.onClipboardEvent = { [weak self] event in
            let msg = ProductivityMonitor.reactionForClipboard(event)
            if !msg.isEmpty {
                self?.animationController.showReaction(msg)
            }
        }
        prod.onActiveWindowEvent = { [weak self] category, appName in
            let msg = ProductivityMonitor.reactionForWindowEvent(category, appName: appName)
            self?.animationController.showReaction(msg)
        }
        prod.onFileSystemEvent = { [weak self] intensity in
            let msg = ProductivityMonitor.reactionForFSEvent(intensity)
            self?.animationController.showReaction(msg)
            switch intensity {
            case "coding_storm":    MoodEnergySystem.shared.incrementStat("PATIENCE", by: 2)
            case "lots_of_changes": MoodEnergySystem.shared.incrementStat("PATIENCE", by: 1)
            default: break
            }
        }
        prod.onClaudeCodeEvent = { [weak self] category, detail in
            let msg = ProductivityMonitor.reactionForHookEvent(category, detail: detail)
            if !msg.isEmpty {
                self?.animationController.showReaction(msg)
            }
        }
        prod.start()

        // Mini Games
        let games = MiniGameManager.shared
        games.delegate = self

        // Apply initial environment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.animationController.applyEnvironment()
            self?.animationController.applyMood()
        }
    }

    private func moodText(_ mood: BuddyMood) -> String {
        switch mood {
        case .happy:   return BuddyL10n.moodHappy.randomElement()!
        case .content: return BuddyL10n.moodContent.randomElement()!
        case .bored:   return BuddyL10n.moodBored.randomElement()!
        case .sad:     return BuddyL10n.moodSad.randomElement()!
        case .excited: return BuddyL10n.moodExcited.randomElement()!
        case .grumpy:  return BuddyL10n.moodGrumpy.randomElement()!
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🐾"
            button.action = #selector(statusBarClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        usagePopover = NSPopover()
        usagePopover.behavior = .transient
        usageVC = UsageViewController()
        usagePopover.contentViewController = usageVC
        usagePopover.contentSize = NSSize(width: 300, height: 280)
    }

    private func refreshMenuBarUsage() {
        Task {
            guard let usage = await UsageAPI.shared.fetchUsage() else { return }
            await MainActor.run {
                let fiveHourPct = usage.fiveHour?.utilization ?? 0
                let species = BuddyData.shared.bones?.species ?? ""
                let emoji = self.speciesEmoji(species)
                self.statusItem.button?.title = "\(emoji) \(Int(fiveHourPct))%"
            }
        }
    }

    @objc private func statusBarClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu(at: statusItem.button!)
        } else {
            toggleUsagePopover()
        }
    }

    private func toggleUsagePopover() {
        if usagePopover.isShown {
            usagePopover.performClose(nil)
        } else if let button = statusItem.button {
            usageVC.refreshUsage()
            usagePopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showContextMenu(at view: NSView) {
        let menu = buildMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let data = BuddyData.shared

        if let soul = data.soul {
            let nameItem = NSMenuItem(title: "\(soul.name)", action: nil, keyEquivalent: "")
            nameItem.isEnabled = false
            menu.addItem(nameItem)

            // Mood & Energy info
            let moodStr = MoodEnergySystem.shared.mood.rawValue.capitalized
            let energyStr = "\(MoodEnergySystem.shared.energy)%"
            let infoItem = NSMenuItem(title: BuddyL10n.menuMoodEnergy(moodStr, energyStr), action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)

            menu.addItem(.separator())
        }

        let showHide = NSMenuItem(
            title: buddyPanel.isVisible ? BuddyL10n.menuHideBuddy : BuddyL10n.menuShowBuddy,
            action: #selector(toggleBuddyVisibility),
            keyEquivalent: "b"
        )
        showHide.target = self
        menu.addItem(showHide)

        let center = NSMenuItem(title: BuddyL10n.menuCenterBuddy, action: #selector(centerBuddy), keyEquivalent: "")
        center.target = self
        menu.addItem(center)

        let pet = NSMenuItem(title: BuddyL10n.menuPet, action: #selector(petBuddy), keyEquivalent: "p")
        pet.target = self
        menu.addItem(pet)

        let feed = NSMenuItem(title: BuddyL10n.menuFeed, action: #selector(feedBuddy), keyEquivalent: "f")
        feed.target = self
        menu.addItem(feed)

        let card = NSMenuItem(title: BuddyL10n.menuViewCard, action: #selector(showCard), keyEquivalent: "c")
        card.target = self
        menu.addItem(card)

        let usage = NSMenuItem(title: BuddyL10n.menuUsage, action: #selector(showUsage), keyEquivalent: "u")
        usage.target = self
        menu.addItem(usage)

        menu.addItem(.separator())

        // Pomodoro submenu
        let pomoItem = NSMenuItem(title: BuddyL10n.menuPomodoro, action: nil, keyEquivalent: "")
        let pomoMenu = NSMenu()
        if PomodoroTimer.shared.isRunning {
            let statusItem = NSMenuItem(title: PomodoroTimer.shared.statusText, action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            pomoMenu.addItem(statusItem)
            let stopItem = NSMenuItem(title: BuddyL10n.menuStop, action: #selector(stopPomodoro), keyEquivalent: "")
            stopItem.target = self
            pomoMenu.addItem(stopItem)
        } else {
            let startItem = NSMenuItem(title: BuddyL10n.menuStart25, action: #selector(startPomodoro), keyEquivalent: "")
            startItem.target = self
            pomoMenu.addItem(startItem)
        }
        pomoItem.submenu = pomoMenu
        menu.addItem(pomoItem)

        // Games submenu
        let gamesItem = NSMenuItem(title: BuddyL10n.menuGames, action: nil, keyEquivalent: "")
        let gamesMenu = NSMenu()
        if MiniGameManager.shared.currentGame != nil {
            let currentItem = NSMenuItem(title: BuddyL10n.menuGameInProgress(MiniGameManager.shared.score), action: nil, keyEquivalent: "")
            currentItem.isEnabled = false
            gamesMenu.addItem(currentItem)
            let endItem = NSMenuItem(title: BuddyL10n.menuEndGame, action: #selector(endGame), keyEquivalent: "")
            endItem.target = self
            gamesMenu.addItem(endItem)
        } else {
            for gameType in MiniGameType.allCases {
                let item = NSMenuItem(title: gameType.rawValue, action: #selector(startGame(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = gameType
                gamesMenu.addItem(item)
            }
        }
        gamesItem.submenu = gamesMenu
        menu.addItem(gamesItem)

        menu.addItem(.separator())

        // Customize submenu
        let customizeItem = NSMenuItem(title: BuddyL10n.menuCustomize, action: nil, keyEquivalent: "")
        let customizeMenu = NSMenu()

        // Eyes submenu
        let eyesItem = NSMenuItem(title: BuddyL10n.menuEyes, action: nil, keyEquivalent: "")
        let eyesMenu = NSMenu()
        let currentEye = data.bones?.eye ?? "·"
        for eye in eyes {
            let item = NSMenuItem(title: eye, action: #selector(setEye(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = eye
            if eye == currentEye { item.state = .on }
            eyesMenu.addItem(item)
        }
        eyesMenu.addItem(.separator())
        let resetEyes = NSMenuItem(title: BuddyL10n.menuResetDefault, action: #selector(resetEye), keyEquivalent: "")
        resetEyes.target = self
        eyesMenu.addItem(resetEyes)
        eyesItem.submenu = eyesMenu
        customizeMenu.addItem(eyesItem)

        // Hats submenu
        let hatsItem = NSMenuItem(title: BuddyL10n.menuHat, action: nil, keyEquivalent: "")
        let hatsMenu = NSMenu()
        let currentHat = data.bones?.hat ?? "none"
        let hatDisplayNames: [String: String] = [
            "none": "None", "crown": "👑 Crown", "tophat": "🎩 Top Hat",
            "propeller": "🧢 Propeller", "halo": "😇 Halo", "wizard": "🧙 Wizard",
            "beanie": "🧶 Beanie", "tinyduck": "🐤 Tiny Duck"
        ]
        for hat in hats {
            let displayName = hatDisplayNames[hat] ?? hat
            let item = NSMenuItem(title: displayName, action: #selector(setHat(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = hat
            if hat == currentHat { item.state = .on }
            hatsMenu.addItem(item)
        }
        hatsMenu.addItem(.separator())
        let resetHat = NSMenuItem(title: BuddyL10n.menuResetDefault, action: #selector(resetHat), keyEquivalent: "")
        resetHat.target = self
        hatsMenu.addItem(resetHat)
        hatsItem.submenu = hatsMenu
        customizeMenu.addItem(hatsItem)

        // Accessories submenu
        let accItem = NSMenuItem(title: BuddyL10n.menuAccessories, action: nil, keyEquivalent: "")
        let accMenu = NSMenu()
        for acc in AccessoryType.allCases {
            let item = NSMenuItem(title: acc.rawValue.capitalized, action: #selector(toggleAccessory(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = acc
            accMenu.addItem(item)
        }
        accItem.submenu = accMenu
        customizeMenu.addItem(accItem)

        // Language submenu
        let langItem = NSMenuItem(title: BuddyL10n.menuLanguage, action: nil, keyEquivalent: "")
        let langMenu = NSMenu()
        for lang in BuddyL10n.supportedLanguages {
            let displayName = BuddyL10n.languageNames[lang] ?? lang
            let item = NSMenuItem(title: displayName, action: #selector(setLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang
            if lang == BuddyL10n.current { item.state = .on }
            langMenu.addItem(item)
        }
        langItem.submenu = langMenu
        customizeMenu.addItem(langItem)

        let modeTitle = use3D ? "2D Mode (ASCII)" : "3D Mode (SceneKit)"
        let modeItem = NSMenuItem(title: modeTitle, action: #selector(toggleRenderMode), keyEquivalent: "")
        modeItem.target = self
        customizeMenu.addItem(modeItem)

        customizeItem.submenu = customizeMenu
        menu.addItem(customizeItem)

        menu.addItem(.separator())

        // Reroll
        let rerollItem = NSMenuItem(title: BuddyL10n.menuReroll, action: #selector(rerollBuddy), keyEquivalent: "")
        rerollItem.target = self
        menu.addItem(rerollItem)

        // Photo (3D only)
        if use3D {
            let photo = NSMenuItem(title: BuddyL10n.menuTakePhoto, action: #selector(takePhoto), keyEquivalent: "")
            photo.target = self
            menu.addItem(photo)
        }

        let muted = data.soul?.muted ?? false
        let muteItem = NSMenuItem(
            title: muted ? BuddyL10n.menuUnmuteReactions : BuddyL10n.menuMuteReactions,
            action: #selector(toggleMute),
            keyEquivalent: ""
        )
        muteItem.target = self
        menu.addItem(muteItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: BuddyL10n.menuQuit, action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    // MARK: - Buddy Panel

    private var use3D = false

    private func setupBuddyPanel() {
        if use3D {
            buddyPanel = BuddyPanel(width: 250, height: 250)
            let buddy3D = Buddy3DView(frame: NSRect(x: 0, y: 40, width: 250, height: 200))
            renderer = buddy3D

            speechBubble = SpeechBubbleView(frame: NSRect(x: 4, y: 0, width: 242, height: 48))

            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 250))
            contentView.wantsLayer = true
            contentView.layer?.isOpaque = false
            contentView.layer?.backgroundColor = CGColor.clear
            contentView.addSubview(speechBubble)
            contentView.addSubview(buddy3D)
            buddyPanel.contentView = contentView
        } else {
            buddyPanel = BuddyPanel(width: 200, height: 180)

            let buddyView = BuddyView(frame: NSRect(x: 0, y: 30, width: 200, height: 140))
            renderer = buddyView

            speechBubble = SpeechBubbleView(frame: NSRect(x: 4, y: 0, width: 192, height: 36))

            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 180))
            contentView.addSubview(speechBubble)
            contentView.addSubview(buddyView)
            buddyPanel.contentView = contentView
        }

        buddyPanel.orderFront(nil)
    }

    private func setupAnimations() {
        animationController = AnimationController()
        animationController.renderer = renderer
        animationController.speechBubble = speechBubble
        animationController.buddyPanel = buddyPanel

        renderer.onLeftClick = { [weak self] in
            self?.animationController.noteActivity()
            // Check if a game is active
            if MiniGameManager.shared.currentGame != nil {
                MiniGameManager.shared.handleClick()
            } else {
                self?.petBuddy()
            }
        }

        renderer.onDoubleClick = { [weak self] in
            self?.animationController.noteActivity()
            let species = BuddyData.shared.bones?.species ?? ""
            self?.animationController.triggerSpeciesTrick(species: species)
        }

        renderer.onRightClick = { [weak self] event in
            guard let self = self else { return }
            self.animationController.noteActivity()
            let menu = self.buildMenu()
            NSMenu.popUpContextMenu(menu, with: event, for: self.renderer.view)
        }
    }

    private func loadBuddyData() {
        let data = BuddyData.shared

        data.onUpdate = { [weak self] in
            self?.updateBuddyDisplay()
        }

        updateBuddyDisplay()
        animationController.start()

        if let species = data.bones?.species {
            statusItem.button?.title = speciesEmoji(species)
        }
    }

    private func updateBuddyDisplay() {
        let data = BuddyData.shared
        guard let bones = data.bones else { return }

        renderer.configure(
            species: bones.species,
            eye: bones.eye,
            hat: bones.hat,
            shiny: bones.shiny
        )

        let emoji = speciesEmoji(bones.species)
        let current = statusItem.button?.title ?? ""
        if current.contains("%") {
            let pctPart = current.split(separator: " ").last ?? ""
            statusItem.button?.title = "\(emoji) \(pctPart)"
        } else {
            statusItem.button?.title = emoji
        }
    }

    private func fetchReaction() {
        let data = BuddyData.shared
        guard let soul = data.soul, !soul.muted, !soul.hidden else { return }

        data.react { [weak self] reaction in
            if let text = reaction {
                self?.animationController.showReaction(text)
            }
        }
    }

    // MARK: - Mouse Tracking

    private func setupMouseTracking() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.handleGlobalMouseMove(event)
        }
    }

    private func setupGlobalHotkey() {
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Ctrl+Shift+B (layout-independent)
            if event.modifierFlags.contains(.control),
               event.modifierFlags.contains(.shift),
               event.charactersIgnoringModifiers?.lowercased() == "b" {
                DispatchQueue.main.async {
                    self?.toggleBuddyVisibility()
                }
            }
        }
    }

    private func handleGlobalMouseMove(_ event: NSEvent) {
        let mousePos = NSEvent.mouseLocation
        let buddyFrame = buddyPanel.frame
        let buddyCenter = NSPoint(x: buddyFrame.midX, y: buddyFrame.midY)

        let dx = mousePos.x - buddyCenter.x
        let dy = mousePos.y - buddyCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < 100 {
            if !mouseNearby {
                mouseNearby = true
                let shouldFaceLeft = dx < 0
                if shouldFaceLeft != animationController.facingLeft {
                    renderer.setFacingLeft(shouldFaceLeft)
                }
                animationController.onMouseNearby()
            }
            if distance < 30 {
                animationController.onMouseHover()
            }
        } else {
            if mouseNearby {
                mouseNearby = false
                let now = Date()
                let timeSinceLastMove = now.timeIntervalSince(lastMouseMoveTime)
                let moveDist = sqrt(
                    pow(mousePos.x - lastMousePos.x, 2) +
                    pow(mousePos.y - lastMousePos.y, 2)
                )
                let speed = timeSinceLastMove > 0 ? moveDist / CGFloat(timeSinceLastMove) : 0
                if speed > 2000 {
                    animationController.onMouseScared()
                }
            }
        }

        if event.type == .leftMouseDragged && buddyPanel.frame.contains(mousePos) {
            detectShake(x: mousePos.x)
        }

        lastMousePos = mousePos
        lastMouseMoveTime = Date()
    }

    // MARK: - Shake Gesture Detection

    private func detectShake(x: CGFloat) {
        let now = Date()
        recentDragPositions.append((x: x, time: now))
        recentDragPositions = recentDragPositions.filter { now.timeIntervalSince($0.time) < 0.5 }

        guard recentDragPositions.count >= 6 else { return }

        var directionChanges = 0
        for i in 2..<recentDragPositions.count {
            let d1 = recentDragPositions[i-1].x - recentDragPositions[i-2].x
            let d2 = recentDragPositions[i].x - recentDragPositions[i-1].x
            if d1 * d2 < 0 && abs(d1) > 5 && abs(d2) > 5 {
                directionChanges += 1
            }
        }

        if directionChanges >= 3 {
            recentDragPositions.removeAll()
            animationController.triggerShakeReaction()
        }
    }

    private func speciesEmoji(_ species: String) -> String {
        switch species {
        case "duck": return "🦆"
        case "goose": return "🪿"
        case "blob": return "🫧"
        case "cat": return "🐱"
        case "dragon": return "🐉"
        case "octopus": return "🐙"
        case "owl": return "🦉"
        case "penguin": return "🐧"
        case "turtle": return "🐢"
        case "snail": return "🐌"
        case "ghost": return "👻"
        case "axolotl": return "🦎"
        case "capybara": return "🦫"
        case "cactus": return "🌵"
        case "robot": return "🤖"
        case "rabbit": return "🐰"
        case "mushroom": return "🍄"
        case "chonk": return "😺"
        default: return "🐾"
        }
    }

    // MARK: - Customize Actions

    @objc private func setEye(_ sender: NSMenuItem) {
        guard let eye = sender.representedObject as? String else { return }
        runBuddyCommand(["eyes", eye]) { [weak self] in
            BuddyData.shared.reload()
            self?.animationController.showReaction("\(BuddyL10n.newLook) \(eye)")
        }
    }

    @objc private func resetEye() {
        runBuddyCommand(["eyes", "reset"]) { [weak self] in
            BuddyData.shared.reload()
            self?.animationController.showReaction(BuddyL10n.backToNormal)
        }
    }

    @objc private func setHat(_ sender: NSMenuItem) {
        guard let hat = sender.representedObject as? String else { return }
        runBuddyCommand(["hat", hat]) { [weak self] in
            BuddyData.shared.reload()
            let msg = hat == "none" ? BuddyL10n.hatRemoved : BuddyL10n.niceHat
            self?.animationController.showReaction(msg)
        }
    }

    @objc private func resetHat() {
        runBuddyCommand(["hat", "reset"]) { [weak self] in
            BuddyData.shared.reload()
            self?.animationController.showReaction(BuddyL10n.originalHat)
        }
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? String else { return }
        BuddyL10n.current = lang
        // Persist to buddy.json
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let soulPath = "\(home)/.claude/buddy.json"
        if let data = FileManager.default.contents(atPath: soulPath),
           var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json["language"] = lang
            if let updated = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
                try? updated.write(to: URL(fileURLWithPath: soulPath))
            }
        }
        animationController.showReaction(lang == "hu" ? "Magyar nyelv beállítva!" : "Language set to English!")
    }

    @objc private func toggleRenderMode() {
        use3D = !use3D
        UserDefaults.standard.set(use3D, forKey: "buddyUse3D")

        // Tear down old setup
        animationController.stop()
        buddyPanel.orderOut(nil)

        // Rebuild
        setupBuddyPanel()
        setupAnimations()
        updateBuddyDisplay()
        animationController.start()

        // Re-apply state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.animationController.applyEnvironment()
            self?.animationController.applyMood()
        }
    }

    @objc private func toggleAccessory(_ sender: NSMenuItem) {
        guard let acc = sender.representedObject as? AccessoryType else { return }
        // Toggle: if visible, hide; if hidden, show
        let visible = sender.state == .on
        renderer.setAccessory(acc, visible: !visible)
        sender.state = visible ? .off : .on
    }

    private func runBuddyCommand(_ args: [String], completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let script = "\(home)/.claude/skills/buddy/buddy.mjs"
            let cmd = nodeArgs(script: script, args: args)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cmd.executable)
            process.arguments = cmd.arguments
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
            process.waitUntilExit()
            DispatchQueue.main.async { completion() }
        }
    }

    // MARK: - Reroll

    @objc private func rerollBuddy() {
        let alert = NSAlert()
        alert.messageText = BuddyL10n.menuReroll
        alert.informativeText = BuddyL10n.menuRerollConfirm
        alert.addButton(withTitle: BuddyL10n.menuRerollConfirmButton)
        alert.addButton(withTitle: BuddyL10n.menuCancel)
        alert.alertStyle = .warning

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        runBuddyCommand(["reroll"]) { [weak self] in
            // Reset mood/energy system
            MoodEnergySystem.shared.loadFromDisk()

            // Reload buddy data (triggers onUpdate → updateBuddyDisplay)
            BuddyData.shared.reload()

            // Step 1: Hatch crack animation
            self?.renderer.triggerParticleEffect(.confetti)
            self?.animationController.showReaction("*crack* ...!")

            // Step 2: Name, species, rarity introduction
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                let name = BuddyData.shared.soul?.name ?? "?"
                let species = BuddyData.shared.bones?.species ?? "?"
                let rarity = BuddyData.shared.bones?.rarity ?? "Common"
                self?.renderer.triggerParticleEffect(.confetti)
                let greeting = BuddyL10n.hatchGreeting(name: name, species: species, rarity: rarity)
                self?.speechBubble.show(text: greeting, duration: 5.0)
            }

            // Step 3: Welcome message
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                let welcome = BuddyL10n.hatchWelcome.randomElement()!
                self?.animationController.showReaction(welcome)
            }
        }
    }

    // MARK: - Actions

    @objc private func toggleBuddyVisibility() {
        if buddyPanel.isVisible {
            buddyPanel.orderOut(nil)
        } else {
            buddyPanel.orderFront(nil)
        }
    }

    @objc private func centerBuddy() {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let panelSize = buddyPanel.frame.size
        let centerX = sf.midX - panelSize.width / 2
        let centerY = sf.midY - panelSize.height / 2
        buddyPanel.animateMove(to: NSPoint(x: centerX, y: centerY), duration: 0.3)
        buddyPanel.orderFront(nil)
    }

    @objc func petBuddy() {
        animationController.triggerPetBounce()
        MoodEnergySystem.shared.pet()

        BuddyData.shared.pet { [weak self] reaction, statGrowth in
            var text = reaction ?? BuddyL10n.petDefaults.randomElement() ?? "♥"
            if let sg = statGrowth {
                text += "\n" + BuddyL10n.statGrowth(stat: sg.stat, amount: sg.amount)
            }
            self?.animationController.showReaction(text)
        }
    }

    @objc private func feedBuddy() {
        animationController.triggerFeedBounce()
        MoodEnergySystem.shared.feed()
        animationController.showReaction(BuddyL10n.feedReaction)
    }

    @objc private func startPomodoro() {
        PomodoroTimer.shared.start()
    }

    @objc private func stopPomodoro() {
        PomodoroTimer.shared.stop()
        animationController.showReaction(BuddyL10n.pomodoroStopped)
    }

    @objc private func startGame(_ sender: NSMenuItem) {
        guard let gameType = sender.representedObject as? MiniGameType else { return }
        MiniGameManager.shared.startGame(gameType)
    }

    @objc private func endGame() {
        MiniGameManager.shared.endCurrentGame()
    }

    @objc private func takePhoto() {
        guard let view = renderer.view as? SCNView else {
            animationController.showReaction(BuddyL10n.photoRequires3D)
            return
        }

        let snapshot = view.snapshot()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "buddy_photo.png"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let tiff = snapshot.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
            }
        }
    }

    @objc private func showCard() {
        let cardPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        cardPanel.title = "Buddy Card"
        cardPanel.isFloatingPanel = true
        cardPanel.level = .floating
        cardPanel.center()

        let textView = NSTextView(frame: NSRect(x: 16, y: 16, width: 448, height: 488))
        textView.isEditable = false
        textView.backgroundColor = NSColor(white: 0.08, alpha: 1.0)
        textView.textColor = .white

        let process = Process()
        let pipe = Pipe()
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let script = "\(home)/.claude/skills/buddy/buddy.mjs"
        let cmd = nodeArgs(script: script, args: ["card"])
        process.executableURL = URL(fileURLWithPath: cmd.executable)
        process.arguments = cmd.arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = try? JSONDecoder().decode(BuddyCardResult.self, from: data) {
                let attrString = buildCardAttributedString(result: result)
                textView.textStorage?.setAttributedString(attrString)
            } else {
                textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
                textView.string = "Could not load buddy card."
            }
        } catch {
            textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            textView.string = "Error loading buddy card."
        }

        let scrollView = NSScrollView(frame: NSRect(x: 16, y: 16, width: 448, height: 488))
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        cardPanel.contentView?.addSubview(scrollView)
        cardPanel.orderFront(nil)
    }

    private func buildCardAttributedString(result: BuddyCardResult) -> NSAttributedString {
        let str = NSMutableAttributedString()
        let monoFont = NSFont(name: "Menlo", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        let subtitleFont = NSFont.systemFont(ofSize: 13, weight: .regular)
        let statFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let hintFont = NSFont.systemFont(ofSize: 11, weight: .regular)
        let white = NSColor.white
        let gray = NSColor(white: 0.55, alpha: 1.0)
        let accent = NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
        let green = NSColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 1.0)

        guard let bones = result.bones, let soul = result.soul else {
            str.append(NSAttributedString(string: result.rendered ?? "No data", attributes: [.font: monoFont, .foregroundColor: white]))
            return str
        }

        // Name
        str.append(NSAttributedString(string: "\(soul.name)\n", attributes: [.font: titleFont, .foregroundColor: white]))

        // Rarity + species
        let rarityStars = ["common": "\u{2605}", "uncommon": "\u{2605}\u{2605}", "rare": "\u{2605}\u{2605}\u{2605}", "epic": "\u{2605}\u{2605}\u{2605}\u{2605}", "legendary": "\u{2605}\u{2605}\u{2605}\u{2605}\u{2605}"]
        let stars = rarityStars[bones.rarity] ?? "\u{2605}"
        let shiny = bones.shiny ? " \u{2728} SHINY" : ""
        let species = bones.species.prefix(1).uppercased() + bones.species.dropFirst()
        let rarity = bones.rarity.prefix(1).uppercased() + bones.rarity.dropFirst()
        str.append(NSAttributedString(string: "\(stars) \(rarity) \(species)\(shiny) · Hatched: \(soul.hatchDate)\n\n", attributes: [.font: subtitleFont, .foregroundColor: gray]))

        // Sprite
        let spriteLines = SpriteData.renderSprite(species: bones.species, eye: bones.eye, hat: bones.hat)
        let sprite = spriteLines.joined(separator: "\n")
        str.append(NSAttributedString(string: "\(sprite)\n\n", attributes: [.font: monoFont, .foregroundColor: white]))

        // Stats with bonuses
        let statEmojis = ["DEBUGGING": "\u{1F41B}", "PATIENCE": "\u{23F3}", "CHAOS": "\u{1F300}", "WISDOM": "\u{1F9E0}", "SNARK": "\u{1F60F}"]
        let statHints = ["DEBUGGING": "commits · tests", "PATIENCE": "builds · pomodoro · file storms", "CHAOS": "branch switches · games", "WISDOM": "writing code · sessions", "SNARK": "petting your buddy"]
        let statNames = ["DEBUGGING", "PATIENCE", "CHAOS", "WISDOM", "SNARK"]

        for sn in statNames {
            let base = bones.stats[sn] ?? 0
            let bonus = soul.statBonuses?[sn] ?? 0
            let total = min(100, base + bonus)
            let emoji = statEmojis[sn] ?? ""
            let barWidth = 16
            let filled = Int(round(Double(total) / 100.0 * Double(barWidth)))
            let bar = String(repeating: "\u{2588}", count: filled) + String(repeating: "\u{2591}", count: barWidth - filled)
            let bonusStr = bonus > 0 ? " (+\(bonus))" : ""

            str.append(NSAttributedString(string: "\(emoji) \(sn) ", attributes: [.font: statFont, .foregroundColor: white]))
            str.append(NSAttributedString(string: bar, attributes: [.font: monoFont, .foregroundColor: accent]))
            str.append(NSAttributedString(string: " \(total)", attributes: [.font: statFont, .foregroundColor: white]))
            if bonus > 0 {
                str.append(NSAttributedString(string: bonusStr, attributes: [.font: statFont, .foregroundColor: green]))
            }
            str.append(NSAttributedString(string: "\n", attributes: [:]))

            let hint = statHints[sn] ?? ""
            str.append(NSAttributedString(string: "     \(hint)\n\n", attributes: [.font: hintFont, .foregroundColor: gray]))
        }

        return str
    }

    @objc private func showUsage() {
        toggleUsagePopover()
    }

    @objc private func toggleMute() {
        guard let soul = BuddyData.shared.soul else { return }
        let newMuted = !soul.muted

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let script = "\(home)/.claude/skills/buddy/buddy.mjs"
        let cmd = nodeArgs(script: script, args: [newMuted ? "mute" : "unmute"])
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cmd.executable)
        process.arguments = cmd.arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    @objc private func quitApp() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        buddyPanel.savePosition()
        MoodEnergySystem.shared.saveToDisk()
        EnvironmentAwareness.shared.stop()
        ProductivityMonitor.shared.stop()
        NSApp.terminate(nil)
    }
}

// MARK: - MiniGameDelegate

extension AppDelegate: MiniGameDelegate {
    func gameShowBubble(_ text: String, duration: TimeInterval) {
        speechBubble.show(text: text, duration: duration)
    }

    func gameShowTrivia(question: String, answers: [String], onAnswer: @escaping (Int) -> Void) {
        speechBubble.showTrivia(question: question, answers: answers, onAnswer: onAnswer)
    }

    func gameMoveBuddy(to point: NSPoint, duration: TimeInterval) {
        buddyPanel.animateMove(to: point, duration: duration)
    }

    func gameGetBuddyPosition() -> NSPoint {
        return buddyPanel.frame.origin
    }

    func gameGetScreenFrame() -> NSRect {
        return NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    func gameOnComplete(game: String, score: Int) {
        MoodEnergySystem.shared.play()
        MoodEnergySystem.shared.incrementStat("CHAOS", by: 1)
    }
}
