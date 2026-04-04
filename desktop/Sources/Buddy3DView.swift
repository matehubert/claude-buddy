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
        let scn = SCNScene()
        scn.background.contents = NSColor.clear
        self.scene = scn
        self.backgroundColor = .clear
        self.allowsCameraControl = false
        self.autoenablesDefaultLighting = false
        self.antialiasingMode = .multisampling4X
        self.isJitteringEnabled = false

        // Ortho camera
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 3.0
        camera.zNear = 0.1
        camera.zFar = 100

        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.8, 5)
        cameraNode.look(at: SCNVector3(0, 0.6, 0))
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

        // Remove old model
        speciesModel?.rootNode.removeFromParentNode()
        hatNode?.removeFromParentNode()

        currentSpecies = species
        currentHat = hat
        isShiny = shiny

        // Build species model
        let model = SpeciesModelBuilder.shared.build(species: species, shiny: shiny)
        scene.rootNode.addChildNode(model.rootNode)
        speciesModel = model

        // Build hat
        if hat != "none" {
            if let hNode = HatModelBuilder.shared.build(hat: hat) {
                hNode.position = model.hatAttachPoint
                scene.rootNode.addChildNode(hNode)
                hatNode = hNode
            }
        }

        // Shiny hue-shift animation
        if shiny {
            startShinyAnimation()
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
        let targetY: Float = left ? Float.pi : 0
        let action = SCNAction.rotateTo(x: 0, y: CGFloat(targetY), z: 0, duration: 0.3)
        action.timingMode = .easeInEaseOut
        speciesModel?.rootNode.runAction(action)
    }

    func setSleeping(_ sleeping: Bool) {
        isSleepingState = sleeping
        updateEyes()
        if sleeping {
            // Lean and close eyes
            let lean = SCNAction.rotateTo(x: 0.1, y: CGFloat(speciesModel?.rootNode.eulerAngles.y ?? 0), z: 0.05, duration: 0.5)
            speciesModel?.rootNode.runAction(lean)
        } else {
            let upright = SCNAction.rotateTo(x: 0, y: CGFloat(speciesModel?.rootNode.eulerAngles.y ?? 0), z: 0, duration: 0.3)
            speciesModel?.rootNode.runAction(upright)
        }
    }

    func setCollapsed(_ collapsed: Bool) {
        isCollapsedState = collapsed
        guard let model = speciesModel else { return }
        if collapsed {
            let squish = SCNAction.group([
                SCNAction.scale(to: 0.3, duration: 0.3),
                SCNAction.move(to: SCNVector3(0, 0.1, 0), duration: 0.3)
            ])
            model.rootNode.runAction(squish)
        } else {
            let unsquish = SCNAction.group([
                SCNAction.scale(to: 1.0, duration: 0.4),
                SCNAction.move(to: SCNVector3(0, 0, 0), duration: 0.4)
            ])
            model.rootNode.runAction(unsquish)
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
        scene.rootNode.addChildNode(emitter)

        // Auto-remove
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            emitter.removeFromParentNode()
        }
    }

    func setAccessory(_ accessory: AccessoryType, visible: Bool) {
        if visible {
            guard accessoryNodes[accessory] == nil, let scene = self.scene else { return }
            let node = HatModelBuilder.shared.buildAccessory(accessory)
            // Position based on accessory type
            switch accessory {
            case .umbrella:
                node.position = SCNVector3(0.4, (speciesModel?.boundingHeight ?? 1.0) + 0.2, 0)
            case .sunglasses:
                let eyeY = speciesModel?.leftEyeNode.position.y ?? 1.0
                node.position = SCNVector3(0, eyeY, 0.35)
            case .scarf:
                let hatY = Float(speciesModel?.hatAttachPoint.y ?? 1.3)
                let bh = Float(speciesModel?.boundingHeight ?? 1.0)
                let neckY = (hatY + bh / 2) / 2
                node.position = SCNVector3(0, neckY - 0.1, 0)
            case .wings:
                node.position = SCNVector3(0, (speciesModel?.boundingHeight ?? 1.0) * 0.5, -0.2)
            }
            scene.rootNode.addChildNode(node)
            accessoryNodes[accessory] = node
        } else {
            accessoryNodes[accessory]?.removeFromParentNode()
            accessoryNodes[accessory] = nil
        }
    }

    // MARK: - Private Helpers

    private func updatePosition() {
        guard let model = speciesModel else { return }
        let totalOffset = CGFloat(idleOffset + bounceOffset) * 0.02  // scale from px to scene units
        model.rootNode.position.y = totalOffset
        let hatY = CGFloat(speciesModel?.hatAttachPoint.y ?? 1.3)
        hatNode?.position.y = hatY + totalOffset
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
        guard let model = speciesModel else { return }

        // Hue-shifting emission on all child geometry
        func applyShiny(to node: SCNNode) {
            if let geo = node.geometry, let mat = geo.firstMaterial {
                let hueShift = SCNAction.customAction(duration: 10.0) { node, elapsed in
                    let hue = CGFloat(elapsed) / 10.0
                    mat.emission.contents = NSColor(hue: hue, saturation: 0.5, brightness: 0.3, alpha: 1.0)
                }
                node.runAction(SCNAction.repeatForever(hueShift))
            }
            for child in node.childNodes {
                applyShiny(to: child)
            }
        }
        applyShiny(to: model.rootNode)
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
        } else {
            onLeftClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(event)
    }
}
