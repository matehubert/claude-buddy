import AppKit
import SceneKit

class Buddy3DView: SCNView, BuddyRenderer {
    var view: NSView { self }

    var onLeftClick: (() -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    var onDoubleClick: (() -> Void)?

    private var speciesModel: SpeciesModel?
    private var hatNode: SCNNode?
    private var accessoryNodes: [AccessoryType: SCNNode] = [:]
    private var currentSpecies: String = ""
    private var currentHat: String = "none"
    private var isShiny: Bool = false
    private var shinyAction: SCNAction?

    // Base position of model rootNode (set once during configure, never overwritten)
    private var modelBasePosition: SCNVector3 = SCNVector3Zero

    // Rigged model support
    private var isRiggedModel = false
    private var riggedRootNode: SCNNode?
    private var walkAnimation: SCNAnimationPlayer?
    private var runAnimation: SCNAnimationPlayer?
    private var currentAnimState: RiggedAnimState = .idle

    private var riggedSpeciesName: String?
    enum RiggedAnimState { case idle, walking, running }

    // All 18 species have rigged USDZ models
    static let riggedSpecies: Set<String> = [
        "robot", "cat", "dragon", "duck", "mushroom", "octopus",
        "axolotl", "blob", "cactus", "capybara", "chonk", "ghost",
        "goose", "owl", "penguin", "rabbit", "snail", "turtle"
    ]

    // State
    private var idleOffset: CGFloat = 0
    private var bounceOffset: CGFloat = 0
    private var isSleepingState = false
    private var isBlinkingState = false
    private var facingLeftState = false
    private var isCollapsedState = false
    private var isEyeWidenedState = false

    // Camera & scene
    private var cameraNode: SCNNode!
    private var ambientLight: SCNNode!
    private var directionalLight: SCNNode!

    override init(frame: NSRect) {
        super.init(frame: frame, options: nil)
        setupScene()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        // Layer-backed rendering is required for transparent SCNView in borderless panels
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = CGColor.clear

        let scn = SCNScene()
        scn.background.contents = NSColor.clear
        self.scene = scn
        self.backgroundColor = .clear
        self.allowsCameraControl = false
        self.autoenablesDefaultLighting = false
        self.antialiasingMode = .none
        self.isJitteringEnabled = false
        self.preferredFramesPerSecond = 15
        self.rendersContinuously = false  // Only render on changes, saves GPU memory

        // Force Metal rendering for proper transparency compositing
        if self.renderingAPI == .metal {
            // Metal is default on modern macOS — good
        }

        // Ortho camera
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.8  // Zoomed in (was 3.0)
        camera.zNear = 0.1
        camera.zFar = 100

        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.6, 5)
        cameraNode.look(at: SCNVector3(0, 0.5, 0))
        scn.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 600
        ambient.color = NSColor(white: 1.0, alpha: 1.0)
        ambientLight = SCNNode()
        ambientLight.light = ambient
        scn.rootNode.addChildNode(ambientLight)

        // Directional light
        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 400
        directional.color = NSColor(white: 1.0, alpha: 1.0)
        directional.castsShadow = false
        directionalLight = SCNNode()
        directionalLight.light = directional
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 6, 0)
        scn.rootNode.addChildNode(directionalLight)
    }

    // MARK: - BuddyRenderer

    func configure(species: String, eye: String, hat: String, shiny: Bool) {
        guard let scene = self.scene else { return }

        currentSpecies = species
        currentHat = hat
        isShiny = shiny

        // Check if rigged model is available
        let useRigged = Self.riggedSpecies.contains(species)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if useRigged {
                self?.loadRiggedModel(species: species, hat: hat, shiny: shiny, scene: scene)
            } else {
                self?.loadProceduralModel(species: species, hat: hat, shiny: shiny, scene: scene)
            }
        }
    }

    private func loadRiggedModel(species: String, hat: String, shiny: Bool, scene: SCNScene) {
        guard let resourcePath = Bundle.main.resourcePath else { return }
        let riggedPath = "\(resourcePath)/Models/rigged/\(species)_rigged.usdz"

        guard let riggedScene = try? SCNScene(url: URL(fileURLWithPath: riggedPath), options: [.checkConsistency: false]) else {
            // Fallback to procedural
            loadProceduralModel(species: species, hat: hat, shiny: shiny, scene: scene)
            return
        }

        // Extract the rigged model into a pivot node that fixes Z-up → Y-up
        let pivot = SCNNode()
        pivot.name = "rigged_pivot_\(species)"
        // Blender exports Z-up; SceneKit uses Y-up → rotate -90° around X
        pivot.eulerAngles.x = -CGFloat.pi / 2

        let content = SCNNode()
        content.name = "rigged_content_\(species)"
        for child in riggedScene.rootNode.childNodes {
            content.addChildNode(child.clone())
        }
        pivot.addChildNode(content)

        // Outer root for positioning/scaling (no rotation — pivot handles that)
        let root = SCNNode()
        root.name = "rigged_\(species)"
        root.addChildNode(pivot)

        // Normalize scale after rotation: measure effective bounding box
        let (bbMin, bbMax) = root.boundingBox
        let modelHeight = Float(bbMax.y - bbMin.y)
        let targetHeight: Float = 1.5
        let scale = targetHeight / max(modelHeight, 0.01)
        root.scale = SCNVector3(scale, scale, scale)
        let centerX = Float(bbMin.x + bbMax.x) / 2
        root.position = SCNVector3(-centerX * scale, -Float(bbMin.y) * scale, 0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Remove old model
            self.speciesModel?.rootNode.removeFromParentNode()
            self.riggedRootNode?.removeFromParentNode()
            self.hatNode = nil
            self.accessoryNodes.removeAll()
            self.isRiggedModel = true
            self.riggedRootNode = root
            self.riggedSpeciesName = species
            self.currentAnimState = .idle
            self.walkAnimation = nil
            self.runAnimation = nil

            scene.rootNode.addChildNode(root)
            self.modelBasePosition = root.position

            // No dummy SpeciesModel for rigged — not needed
            self.speciesModel = nil

            if shiny {
                self.startShinyAnimation()
            }
        }
    }

    /// Lazy-load walk/run animations on first use (each USDZ is 20-40MB)
    private func ensureAnimationsLoaded() {
        guard isRiggedModel, walkAnimation == nil, let species = riggedSpeciesName,
              let resourcePath = Bundle.main.resourcePath else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let walkPath = "\(resourcePath)/Models/rigged/\(species)_walking.usdz"
            let runPath = "\(resourcePath)/Models/rigged/\(species)_running.usdz"

            var walkPlayer: SCNAnimationPlayer?
            var runPlayer: SCNAnimationPlayer?

            if let walkScene = try? SCNScene(url: URL(fileURLWithPath: walkPath), options: [.checkConsistency: false]) {
                walkPlayer = Self.extractAnimation(from: walkScene)
                walkPlayer?.animation.isRemovedOnCompletion = false
                walkPlayer?.animation.repeatCount = .infinity
                walkPlayer?.stop()
            }
            if let runScene = try? SCNScene(url: URL(fileURLWithPath: runPath), options: [.checkConsistency: false]) {
                runPlayer = Self.extractAnimation(from: runScene)
                runPlayer?.animation.isRemovedOnCompletion = false
                runPlayer?.animation.repeatCount = .infinity
                runPlayer?.stop()
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self, let root = self.riggedRootNode else { return }
                if let wp = walkPlayer {
                    root.addAnimationPlayer(wp, forKey: "walk")
                    self.walkAnimation = wp
                }
                if let rp = runPlayer {
                    root.addAnimationPlayer(rp, forKey: "run")
                    self.runAnimation = rp
                }
                // Auto-play if state was already set before load finished
                if self.currentAnimState == .walking {
                    self.rendersContinuously = true
                    walkPlayer?.play()
                } else if self.currentAnimState == .running {
                    self.rendersContinuously = true
                    runPlayer?.play()
                }
            }
        }
    }

    private func loadProceduralModel(species: String, hat: String, shiny: Bool, scene: SCNScene) {
        let model = SpeciesModelBuilder.shared.build(species: species, shiny: shiny)
        let hatNode: SCNNode? = hat != "none" ? HatModelBuilder.shared.build(hat: hat) : nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.speciesModel?.rootNode.removeFromParentNode()
            self.riggedRootNode?.removeFromParentNode()
            self.hatNode = nil
            self.accessoryNodes.removeAll()
            self.isRiggedModel = false
            self.riggedRootNode = nil
            self.walkAnimation = nil
            self.runAnimation = nil

            scene.rootNode.addChildNode(model.rootNode)
            self.speciesModel = model
            self.modelBasePosition = model.rootNode.position

            if let hNode = hatNode {
                hNode.position = model.hatAttachPoint
                model.rootNode.addChildNode(hNode)
                self.hatNode = hNode
            }

            if shiny {
                self.startShinyAnimation()
            }
        }
    }

    private static func extractAnimation(from scene: SCNScene) -> SCNAnimationPlayer? {
        // Recursively find first animation in the scene
        func find(in node: SCNNode) -> SCNAnimationPlayer? {
            for key in node.animationKeys {
                if let player = node.animationPlayer(forKey: key) {
                    return player
                }
            }
            for child in node.childNodes {
                if let found = find(in: child) { return found }
            }
            return nil
        }
        return find(in: scene.rootNode)
    }

    // MARK: - Rigged Animation Control

    func setRiggedAnimState(_ state: RiggedAnimationType) {
        guard isRiggedModel else { return }
        let mapped: RiggedAnimState = {
            switch state {
            case .idle: return .idle
            case .walking: return .walking
            case .running: return .running
            }
        }()
        guard mapped != currentAnimState else { return }
        currentAnimState = mapped

        // Lazy-load animations on first non-idle state
        if mapped != .idle && walkAnimation == nil {
            ensureAnimationsLoaded()
            // Animations will play once loaded; for now just mark the state
            return
        }

        self.rendersContinuously = (mapped != .idle)

        switch mapped {
        case .idle:
            walkAnimation?.stop(withBlendOutDuration: 0.3)
            runAnimation?.stop(withBlendOutDuration: 0.3)
        case .walking:
            runAnimation?.stop(withBlendOutDuration: 0.3)
            walkAnimation?.play()
        case .running:
            walkAnimation?.stop(withBlendOutDuration: 0.3)
            runAnimation?.play()
        }
    }

    func setBlinking(_ blinking: Bool) {
        isBlinkingState = blinking
        updateEyes()
    }

    func setIdleOffset(_ offset: CGFloat) {
        idleOffset = offset
        updatePosition()
    }

    func setBounceOffset(_ offset: CGFloat) {
        bounceOffset = offset
        updatePosition()
    }

    func setFacingLeft(_ left: Bool) {
        guard left != facingLeftState else { return }
        facingLeftState = left
        let node = isRiggedModel ? riggedRootNode : speciesModel?.rootNode
        guard let node = node else { return }
        // Cancel any existing rotation before starting new one
        node.removeAction(forKey: "facing")
        let targetY: Float = left ? Float.pi : 0
        let action = SCNAction.rotateTo(x: 0, y: CGFloat(targetY), z: 0, duration: 0.3)
        action.timingMode = .easeInEaseOut
        node.runAction(action, forKey: "facing")
    }

    func setSleeping(_ sleeping: Bool) {
        isSleepingState = sleeping
        updateEyes()
        let node = isRiggedModel ? riggedRootNode : speciesModel?.rootNode
        guard let node = node else { return }
        node.removeAction(forKey: "sleep")
        if sleeping {
            let currentY = node.eulerAngles.y
            let lean = SCNAction.rotateTo(x: 0.1, y: CGFloat(currentY), z: 0.05, duration: 0.5)
            node.runAction(lean, forKey: "sleep")
        } else {
            let currentY = node.eulerAngles.y
            let upright = SCNAction.rotateTo(x: 0, y: CGFloat(currentY), z: 0, duration: 0.3)
            node.runAction(upright, forKey: "sleep")
        }
    }

    func setCollapsed(_ collapsed: Bool) {
        isCollapsedState = collapsed
        let node = isRiggedModel ? riggedRootNode : speciesModel?.rootNode
        guard let node = node else { return }
        node.removeAction(forKey: "collapse")
        if collapsed {
            let squish = SCNAction.group([
                SCNAction.scale(to: 0.3, duration: 0.3),
                SCNAction.move(to: SCNVector3(modelBasePosition.x, modelBasePosition.y + 0.1, modelBasePosition.z), duration: 0.3)
            ])
            node.runAction(squish, forKey: "collapse")
        } else {
            let unsquish = SCNAction.group([
                SCNAction.scale(to: 1.0, duration: 0.4),
                SCNAction.move(to: modelBasePosition, duration: 0.4)
            ])
            node.runAction(unsquish, forKey: "collapse")
        }
    }

    func setEyeWiden(_ widen: Bool) {
        isEyeWidenedState = widen
        updateEyes()
    }

    // MARK: - 3D-Specific

    func setMoodExpression(_ mood: BuddyMood) {
        guard let model = speciesModel else { return }

        // Adjust eye/mouth based on mood
        switch mood {
        case .happy, .excited:
            // Slightly larger eyes, slight upward tilt
            model.leftEyeNode.scale = SCNVector3(1.1, 1.1, 1.1)
            model.rightEyeNode.scale = SCNVector3(1.1, 1.1, 1.1)
        case .sad:
            model.leftEyeNode.scale = SCNVector3(0.85, 0.7, 0.85)
            model.rightEyeNode.scale = SCNVector3(0.85, 0.7, 0.85)
            // Droop
            model.leftEyeNode.eulerAngles.z = 0.1
            model.rightEyeNode.eulerAngles.z = -0.1
        case .bored:
            // Half-lidded
            model.leftEyeNode.scale = SCNVector3(1.0, 0.6, 1.0)
            model.rightEyeNode.scale = SCNVector3(1.0, 0.6, 1.0)
        case .grumpy:
            model.leftEyeNode.eulerAngles.z = -0.15
            model.rightEyeNode.eulerAngles.z = 0.15
        case .content:
            model.leftEyeNode.scale = SCNVector3(1.0, 1.0, 1.0)
            model.rightEyeNode.scale = SCNVector3(1.0, 1.0, 1.0)
            model.leftEyeNode.eulerAngles.z = 0
            model.rightEyeNode.eulerAngles.z = 0
        }
    }

    func setTimeOfDay(_ time: TimeOfDay) {
        guard let ambient = ambientLight.light, let directional = directionalLight.light else { return }

        switch time {
        case .morning:
            ambient.color = NSColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
            ambient.intensity = 550
            directional.color = NSColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
            directional.intensity = 450
        case .afternoon:
            ambient.color = NSColor(white: 1.0, alpha: 1.0)
            ambient.intensity = 600
            directional.color = NSColor(white: 1.0, alpha: 1.0)
            directional.intensity = 400
        case .evening:
            ambient.color = NSColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1.0)
            ambient.intensity = 450
            directional.color = NSColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0)
            directional.intensity = 350
        case .night:
            ambient.color = NSColor(red: 0.6, green: 0.65, blue: 0.85, alpha: 1.0)
            ambient.intensity = 300
            directional.color = NSColor(red: 0.7, green: 0.75, blue: 1.0, alpha: 1.0)
            directional.intensity = 200
        }
    }

    func triggerParticleEffect(_ effect: ParticleEffectType) {
        guard let scene = self.scene else { return }

        let particle = SCNParticleSystem()
        particle.birthRate = 15
        particle.particleLifeSpan = 1.5
        particle.spreadingAngle = 30
        particle.emissionDuration = 0.8
        particle.loops = false
        particle.particleSize = 0.04

        switch effect {
        case .hearts:
            particle.particleColor = NSColor.systemRed
            particle.birthRate = 10
            particle.emittingDirection = SCNVector3(0, 1, 0)
            particle.speedFactor = 0.5
        case .confetti:
            particle.particleColor = NSColor.systemYellow
            particle.birthRate = 40
            particle.spreadingAngle = 180
            particle.particleColorVariation = SCNVector4(0.5, 0.5, 0.5, 0)
        case .catStars:
            particle.particleColor = NSColor.systemYellow
            particle.birthRate = 8
            particle.emittingDirection = SCNVector3(0, 1, 0)
        case .slimeTrail:
            particle.particleColor = NSColor.systemGreen
            particle.birthRate = 5
            particle.emittingDirection = SCNVector3(0, -1, 0)
            particle.particleLifeSpan = 2.0
        case .waterRipple:
            particle.particleColor = NSColor.systemCyan
            particle.birthRate = 6
            particle.emittingDirection = SCNVector3(0, -1, 0)
        case .ghostFlame:
            particle.particleColor = NSColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.7)
            particle.birthRate = 12
            particle.emittingDirection = SCNVector3(0, 1, 0)
        case .raindrops:
            particle.particleColor = NSColor.systemBlue
            particle.birthRate = 20
            particle.emittingDirection = SCNVector3(0, -1, 0)
            particle.speedFactor = 2.0
        }

        let emitter = SCNNode()
        emitter.position = SCNVector3(0, (speciesModel?.boundingHeight ?? 1.0) / 2, 0)
        emitter.addParticleSystem(particle)
        // Add to model rootNode so particles follow the model
        if isRiggedModel, let root = riggedRootNode {
            root.addChildNode(emitter)
        } else if let modelRoot = speciesModel?.rootNode {
            modelRoot.addChildNode(emitter)
        } else {
            scene.rootNode.addChildNode(emitter)
        }

        // Auto-remove
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            emitter.removeFromParentNode()
        }
    }

    func setAccessory(_ accessory: AccessoryType, visible: Bool) {
        if visible {
            guard accessoryNodes[accessory] == nil, let model = speciesModel else { return }
            let node = HatModelBuilder.shared.buildAccessory(accessory)
            let bh = Float(model.boundingHeight)
            // Position relative to model rootNode (accessories are children of model)
            switch accessory {
            case .umbrella:
                node.position = SCNVector3(0.4, bh + 0.2, 0)
            case .sunglasses:
                let eyeY = Float(model.leftEyeNode.position.y)
                node.position = SCNVector3(0, eyeY, 0.35)
            case .scarf:
                let hatY = Float(model.hatAttachPoint.y)
                let neckY = (hatY + bh / 2) / 2
                node.position = SCNVector3(0, neckY - 0.1, 0)
            case .wings:
                node.position = SCNVector3(0, bh * 0.5, -0.2)
            }
            model.rootNode.addChildNode(node)
            accessoryNodes[accessory] = node
        } else {
            accessoryNodes[accessory]?.removeFromParentNode()
            accessoryNodes[accessory] = nil
        }
    }

    // MARK: - Private Helpers

    private func updatePosition() {
        let totalOffset = CGFloat(idleOffset + bounceOffset) * 0.02
        if isRiggedModel, let root = riggedRootNode {
            root.position.y = modelBasePosition.y + totalOffset
        } else if let model = speciesModel {
            model.rootNode.position.y = modelBasePosition.y + totalOffset
        }
    }

    private func updateEyes() {
        guard let model = speciesModel else { return }

        if isSleepingState || isBlinkingState {
            // Close eyes (scale Y to near 0)
            model.leftEyeNode.scale = SCNVector3(1.0, 0.05, 1.0)
            model.rightEyeNode.scale = SCNVector3(1.0, 0.05, 1.0)
        } else if isEyeWidenedState {
            model.leftEyeNode.scale = SCNVector3(1.3, 1.3, 1.3)
            model.rightEyeNode.scale = SCNVector3(1.3, 1.3, 1.3)
        } else {
            model.leftEyeNode.scale = SCNVector3(1.0, 1.0, 1.0)
            model.rightEyeNode.scale = SCNVector3(1.0, 1.0, 1.0)
        }
    }

    private func startShinyAnimation() {
        let targetNode: SCNNode?
        if isRiggedModel {
            targetNode = riggedRootNode
        } else {
            targetNode = speciesModel?.rootNode
        }
        guard let root = targetNode else { return }

        func applyShiny(to node: SCNNode) {
            if let geo = node.geometry, let mat = geo.firstMaterial {
                let hueShift = SCNAction.customAction(duration: 10.0) { node, elapsed in
                    let hue = CGFloat(elapsed) / 10.0
                    mat.emission.contents = NSColor(hue: hue, saturation: 0.5, brightness: 0.3, alpha: 1.0)
                }
                node.runAction(SCNAction.repeatForever(hueShift))
            }
            for child in node.childNodes { applyShiny(to: child) }
        }
        applyShiny(to: root)
    }

    // MARK: - Mouse Events
    private var singleClickTimer: Timer?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            singleClickTimer?.invalidate()
            singleClickTimer = nil
            onDoubleClick?()
        } else {
            singleClickTimer?.invalidate()
            singleClickTimer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval, repeats: false) { [weak self] _ in
                self?.singleClickTimer = nil
                self?.onLeftClick?()
            }
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(event)
    }
}
